import Foundation
import HealthKit

struct HealthMetricsSnapshot: Sendable {
    var sleepHours: Double?
    var hydrationOz: Double?
    var stress: Int?
    var soreness: Int?
    var trainingIntensity: Int?

    var hasValues: Bool {
        sleepHours != nil || hydrationOz != nil || stress != nil || soreness != nil || trainingIntensity != nil
    }
}

enum HealthKitMetricsError: LocalizedError {
    case unavailable
    case notAuthorized
    case noReadableData

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Health data is not available on this device."
        case .notAuthorized:
            return "Health permission was not granted."
        case .noReadableData:
            return "No recent HealthKit values were found for your metrics."
        }
    }
}

final class HealthKitMetricsService {
    private let store = HKHealthStore()
    private let calendar = Calendar.current

    func fetchSnapshot() async throws -> HealthMetricsSnapshot {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitMetricsError.unavailable
        }

        try await requestReadAuthorization()

        async let sleepHours = fetchSleepHours()
        async let hydrationOz = fetchHydrationOzToday()
        async let hrvValue = fetchLatestHRV()
        async let restingHeartRate = fetchLatestRestingHeartRate()
        async let activeEnergy = fetchActiveEnergyToday()

        let hrv = try await hrvValue
        let restingHR = try await restingHeartRate
        let energy = try await activeEnergy

        let snapshot = HealthMetricsSnapshot(
            sleepHours: try await sleepHours,
            hydrationOz: try await hydrationOz,
            stress: hrv.map(stressScore(fromHRVMilliseconds:)),
            soreness: restingHR.map(sorenessScore(fromRestingHeartRate:)),
            trainingIntensity: energy.map(trainingIntensityScore(fromActiveEnergyKCal:))
        )

        guard snapshot.hasValues else {
            throw HealthKitMetricsError.noReadableData
        }

        return snapshot
    }

    private func requestReadAuthorization() async throws {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        let hydrationType = HKObjectType.quantityType(forIdentifier: .dietaryWater)
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
        let restingHRType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)
        let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)

        let readTypes = Set([sleepType, hydrationType, hrvType, restingHRType, activeEnergyType].compactMap { $0 })

        guard !readTypes.isEmpty else {
            throw HealthKitMetricsError.noReadableData
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.requestAuthorization(toShare: nil, read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard success else {
                    continuation.resume(throwing: HealthKitMetricsError.notAuthorized)
                    return
                }
                continuation.resume(returning: ())
            }
        }
    }

    private func fetchSleepHours() async throws -> Double? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let endDate = Date()
        let startDate = calendar.date(byAdding: .hour, value: -24, to: endDate) ?? endDate.addingTimeInterval(-24 * 3600)
        let samples = try await categorySamples(type: sleepType, from: startDate, to: endDate)

        let totalSeconds = samples.reduce(0.0) { partial, sample in
            guard isAsleep(sample.value) else { return partial }
            return partial + sample.endDate.timeIntervalSince(sample.startDate)
        }

        guard totalSeconds > 0 else { return nil }
        return totalSeconds / 3600.0
    }

    private func fetchHydrationOzToday() async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            return nil
        }

        let start = calendar.startOfDay(for: .now)
        let total = try await cumulativeQuantity(type: type, from: start, to: .now, unit: .fluidOunceUS())
        return total > 0 ? total : nil
    }

    private func fetchLatestHRV() async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return nil
        }

        return try await latestQuantityValue(type: type, unit: HKUnit.secondUnit(with: .milli))
    }

    private func fetchLatestRestingHeartRate() async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            return nil
        }

        return try await latestQuantityValue(type: type, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    private func fetchActiveEnergyToday() async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return nil
        }

        let start = calendar.startOfDay(for: .now)
        let total = try await cumulativeQuantity(type: type, from: start, to: .now, unit: .kilocalorie())
        return total > 0 ? total : nil
    }

    private func categorySamples(
        type: HKCategoryType,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HKCategorySample] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let categorySamples = (samples as? [HKCategorySample]) ?? []
                continuation.resume(returning: categorySamples)
            }

            store.execute(query)
        }
    }

    private func cumulativeQuantity(
        type: HKQuantityType,
        from startDate: Date,
        to endDate: Date,
        unit: HKUnit
    ) async throws -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }

            store.execute(query)
        }
    }

    private func latestQuantityValue(type: HKQuantityType, unit: HKUnit) async throws -> Double? {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let quantity = (samples as? [HKQuantitySample])?.first?.quantity.doubleValue(for: unit)
                continuation.resume(returning: quantity)
            }

            store.execute(query)
        }
    }

    private func isAsleep(_ value: Int) -> Bool {
        value != HKCategoryValueSleepAnalysis.inBed.rawValue &&
            value != HKCategoryValueSleepAnalysis.awake.rawValue
    }

    private func stressScore(fromHRVMilliseconds value: Double) -> Int {
        switch value {
        case ..<30: return 9
        case ..<45: return 8
        case ..<60: return 6
        case ..<80: return 4
        default: return 3
        }
    }

    private func sorenessScore(fromRestingHeartRate bpm: Double) -> Int {
        switch bpm {
        case ..<52: return 3
        case ..<60: return 4
        case ..<68: return 6
        case ..<76: return 7
        default: return 8
        }
    }

    private func trainingIntensityScore(fromActiveEnergyKCal kCal: Double) -> Int {
        switch kCal {
        case ..<180: return 3
        case ..<350: return 5
        case ..<550: return 7
        case ..<800: return 8
        default: return 9
        }
    }
}
