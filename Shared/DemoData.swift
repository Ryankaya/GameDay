import Foundation

enum DemoData {
    static func game(referenceDate: Date = Date()) -> Game {
        let kickoffTime = Calendar.current.date(byAdding: .hour, value: 8, to: referenceDate) ?? referenceDate
        return Game(title: "Upcoming Game", kickoffTime: kickoffTime)
    }

    static func metrics(referenceDate: Date = Date()) -> AthleteMetrics {
        let hour = Calendar.current.component(.hour, from: referenceDate)

        let sleepHours = max(5.5, min(9.0, 7.2 + (hour < 12 ? 0.3 : -0.2)))
        let soreness = hour < 12 ? 4 : 5
        let stress = hour < 18 ? 5 : 6
        let hydrationOz = hour < 12 ? 56.0 : 78.0
        let trainingIntensity = hour < 15 ? 6 : 4

        return AthleteMetrics(
            athleteType: .soccer,
            sleepHours: sleepHours,
            soreness: soreness,
            stress: stress,
            hydrationOz: hydrationOz,
            trainingIntensity: trainingIntensity
        )
    }
}
