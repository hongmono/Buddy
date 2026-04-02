// Buddy/Views/ChatView.swift
import SwiftUI

struct ChatView: View {
    @ObservedObject var messageStore: ChatMessageStore
    @State private var inputText: String = ""
    var onSend: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "a8edea"), Color(hex: "7dd3cc")],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: 24, height: 24)
                Text("Buddy")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "a8edea"))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(hex: "1e2332").opacity(0.95))

            Divider().background(Color.white.opacity(0.06))

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messageStore.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(12)
                }
                .onChange(of: messageStore.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
            }

            Divider().background(Color.white.opacity(0.06))

            // Input
            HStack(spacing: 6) {
                TextField("메시지 입력...", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(7)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
                    .onSubmit { send() }

                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "1e2332"))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "7dd3cc"))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(10)
        }
        .frame(width: 280, height: 400)
        .background(Color(hex: "1e2332").opacity(0.95))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        onSend(text)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let last = messageStore.messages.last {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            Text(message.content)
                .font(.system(size: 12))
                .foregroundColor(message.role == .assistant ? Color(hex: "a8edea") : .white.opacity(0.85))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    message.role == .assistant
                        ? Color(hex: "a8edea").opacity(0.15)
                        : Color.white.opacity(0.1)
                )
                .cornerRadius(12)
                .frame(maxWidth: 220, alignment: message.role == .user ? .trailing : .leading)
            if message.role == .assistant { Spacer() }
        }
    }
}
