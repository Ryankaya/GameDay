import SwiftUI

struct InputsView: View {
    @EnvironmentObject private var vm: GameDayViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                gameCard
                metricsCard
                integrationCard
                generateButton
            }
            .padding()
        }
        .navigationTitle("Metrics")
        .navigationBarTitleDisplayMode(.inline)
        .background(GameDayBackground())
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Inputs")
                .font(.headline)
            Spacer()
            GameDayStatusPill(text: vm.kickoffBadge, systemImage: "clock")
        }
    }

    private var gameCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game")
                .font(.headline)

            TextField("Game Title", text: $vm.gameTitle)
                .textFieldStyle(.roundedBorder)

            DatePicker("Kickoff", selection: $vm.kickoffTime)

            Picker("Athlete Type", selection: $vm.athleteType) {
                ForEach(AthleteType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.navigationLink)
        }
        .gameDayGlassCard()
    }

    private var metricsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Metrics")
                .font(.headline)

            sliderRow(
                title: "Sleep",
                value: String(format: "%.1f h", vm.sleepHours),
                valueBinding: $vm.sleepHours,
                range: 3...10,
                step: 0.1
            )

            sliderRow(
                title: "Hydration",
                value: "\(Int(vm.hydrationOz)) oz",
                valueBinding: $vm.hydrationOz,
                range: 20...180,
                step: 1
            )

            stepperRow(title: "Soreness (1-10)", value: vm.soreness, binding: $vm.soreness)
            stepperRow(title: "Stress (1-10)", value: vm.stress, binding: $vm.stress)
            stepperRow(title: "Intensity (1-10)", value: vm.trainingIntensity, binding: $vm.trainingIntensity)
        }
        .gameDayGlassCard()
    }

    private var integrationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AI + Health")
                .font(.headline)

            Label(vm.aiModeStatus, systemImage: "cpu")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                Task { await vm.importMetricsFromHealthKit() }
            } label: {
                Label("Import Metrics From HealthKit", systemImage: "heart.text.square")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            Text(vm.healthSyncStatus)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .gameDayGlassCard()
    }

    private var generateButton: some View {
        Button {
            Task { await vm.evaluate() }
        } label: {
            Label("Generate Coach Tips", systemImage: "sparkles")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .gameDayGlassCard(14)
    }

    private func sliderRow(
        title: String,
        value: String,
        valueBinding: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.footnote.weight(.semibold))
                    .monospacedDigit()
            }
            Slider(value: valueBinding, in: range, step: step)
                .tint(GameDayPalette.accent)
        }
    }

    private func stepperRow(title: String, value: Int, binding: Binding<Int>) -> some View {
        HStack {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(value)")
                .font(.footnote.weight(.semibold))
                .monospacedDigit()
            Stepper("", value: binding, in: 1...10)
                .labelsHidden()
        }
    }
}
