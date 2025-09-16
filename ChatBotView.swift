import SwiftUI

struct ChatBotView: View {
    @State private var messages: [String] = ["Hello 👋 I am your support bot. How can I help you?"]
    @State private var userInput: String = ""

    var body: some View {
        VStack {
            ScrollView {
                ForEach(messages, id: \.self) { msg in
                    HStack {
                        if msg.hasPrefix("You:") {
                            Spacer()
                            Text(msg)
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(10)
                        } else {
                            Text(msg)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }

            HStack {
                TextField("Type a message...", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Send") {
                    sendMessage()
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("💬 Chat Support")
    }

    private func sendMessage() {
        guard !userInput.isEmpty else { return }
        let message = "You: \(userInput)"
        messages.append(message)

        // Fake bot reply (replace with API later)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            messages.append("Bot: Thanks for your message! I’ll help you with '\(userInput)' 😊")
        }

        userInput = ""
    }
}
