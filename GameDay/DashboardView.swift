import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var vm: GameDayViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                readinessCard
                factorsCard
                liveActivityCard
            }
            .padding()
        }
        .navigationTitle("GameDay Live")
        .navigationBarTitleDisplayMode(.inline)
        .background(GameDayBackground())
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dashboard")
                    .font(.headline)
                Text(vm.game.title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            GameDayStatusPill(text: vm.kickoffBadge, systemImage: "clock")
        }
    }

    private var readinessCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Text("\(vm.readiness.score)")
                    .gameDayMetricNumber()
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.readiness.label)
                        .font(.headline)
                    Text("Current readiness")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            readinessBar

            Text(vm.recommendation.nextAction)
                .font(.body.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Label(vm.aiModeStatus, systemImage: "cpu")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gameDayGlassCard()
    }

    private var readinessBar: some View {
        GeometryReader { geometry in
            let progress = CGFloat(max(0, min(100, vm.readiness.score))) / 100
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(GameDayPalette.readinessTrack(for: colorScheme))

                Capsule(style: .continuous)
                    .fill(GameDayPalette.readinessGradient(score: vm.readiness.score))
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 8)
        .animation(.snappy(duration: 0.35), value: vm.readiness.score)
    }

    private var factorsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top Factors")
                .font(.headline)

            if vm.readiness.topFactors.isEmpty {
                Text("Generate coach tips to inspect the dominant readiness factors.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(vm.readiness.topFactors, id: \.self) { factor in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(factor)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gameDayGlassCard()
    }

    private var liveActivityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Live Activity")
                .font(.headline)

            Text(vm.liveActivityMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button("Start") { Task { await vm.startLiveActivity() } }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                Button("Update") { Task { await vm.updateLiveActivity() } }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                Button("End") { Task { await vm.endLiveActivity() } }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .controlSize(.regular)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gameDayGlassCard()
    }
}
