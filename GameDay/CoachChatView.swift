import SwiftUI

struct CoachChatView: View {
    @EnvironmentObject private var vm: GameDayViewModel
    @StateObject private var voiceInput = VoiceInputService()
    @State private var draft = ""

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    header

                    ForEach(vm.chatMessages) { message in
                        messageRow(message)
                            .id(message.id)
                    }

                    if vm.isChatResponding {
                        typingIndicator
                    }
                }
                .padding()
                .padding(.bottom, 90)
            }
            .background(GameDayBackground())
            .navigationTitle("Coach Chat")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                composer
            }
            .onChange(of: vm.chatMessages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: voiceInput.transcript) { _, newValue in
                if !newValue.isEmpty {
                    draft = newValue
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Coach Chat")
                .font(.headline)
            Spacer()
            GameDayStatusPill(text: vm.aiModeStatus, systemImage: "cpu")
        }
    }

    private var typingIndicator: some View {
        HStack {
            Text("Coach is thinking...")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button {
                    toggleVoice()
                } label: {
                    Image(systemName: voiceInput.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(voiceInput.isRecording ? Color.red : GameDayPalette.accent)
                }
                .buttonStyle(.plain)

                TextField("Message coach...", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                Button {
                    sendDraft()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .foregroundStyle(sendDisabled ? .secondary : GameDayPalette.accent)
                .disabled(sendDisabled)
            }

            HStack {
                Text(voiceInput.status)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .gameDayGlassCard(12)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var sendDisabled: Bool {
        draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isChatResponding
    }

    private func messageRow(_ message: CoachChatMessage) -> some View {
        HStack {
            if message.role == .coach {
                bubbleContent(message: message, isCoach: true)
                Spacer(minLength: 30)
            } else {
                Spacer(minLength: 30)
                bubbleContent(message: message, isCoach: false)
            }
        }
    }

    private func bubbleContent(message: CoachChatMessage, isCoach: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: 320, alignment: .leading)
        .background(
            isCoach
                ? AnyShapeStyle(.ultraThinMaterial)
                : AnyShapeStyle(GameDayPalette.accent.opacity(0.14)),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.primary.opacity(0.10), lineWidth: 0.5)
        )
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let last = vm.chatMessages.last?.id {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(last, anchor: .bottom)
            }
        }
    }

    private func toggleVoice() {
        if voiceInput.isRecording {
            voiceInput.stopRecording()
            return
        }

        Task {
            await voiceInput.startRecording(prefill: draft)
        }
    }

    private func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        voiceInput.stopRecording()
        draft = ""

        Task {
            await vm.sendChatMessage(text)
        }
    }
}
