import SwiftUI

struct CoachPlanView: View {
    @EnvironmentObject private var vm: GameDayViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                actionCard
                tipsCard
            }
            .padding()
        }
        .navigationTitle("Coach Plan")
        .navigationBarTitleDisplayMode(.inline)
        .background(GameDayBackground())
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Coach Plan")
                    .font(.headline)
                Text("Kickoff \(vm.kickoffBadge)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            GameDayStatusPill(text: vm.aiModeStatus, systemImage: "cpu")
        }
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Action")
                .font(.headline)

            Text(vm.recommendation.nextAction)
                .font(.body.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Text("Readiness \(vm.readiness.score)")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(GameDayPalette.readinessGradient(score: vm.readiness.score), in: Capsule())
                    .foregroundStyle(.primary)

                Text(vm.readiness.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gameDayGlassCard()
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Coach Tips")
                .font(.headline)

            if vm.recommendation.tips.isEmpty {
                Text("Generate coach tips from Metrics to see personalized priorities.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(vm.recommendation.tips.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 18)

                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gameDayGlassCard()
    }
}
