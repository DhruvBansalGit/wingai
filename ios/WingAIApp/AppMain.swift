#if canImport(UIKit)
import SwiftUI
import UIKit

@main
struct WingAIiOSApp: App {
    @StateObject private var hostViewModel = WingAiHostViewModel()
    @StateObject private var keyboardViewModel = WingAiKeyboardViewModel()
    @State private var selectedTab: Int = 0
    @State private var draftMessage: String = ""
    @State private var chatMessages: [(sender: String, text: String, isIncoming: Bool)] = [
        ("Aarav", "Hey! Kal sham ko 7 baje coffee pe milte hain?", true),
        ("You", "Haan sounds good, kahan milna hai?", false),
        ("Aarav", "Blue Tokai Indiranagar chalte hain, let me know if 7 PM works for you!", true)
    ]

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                liveKeyboardPlaygroundTab
                    .tabItem {
                        Label("Try Keyboard", systemImage: "keyboard")
                    }
                    .tag(0)

                NavigationStack {
                    WingAiUserAccountScreen(
                        viewModel: hostViewModel,
                        onCopyUserId: { userId in
                            UIPasteboard.general.string = userId
                        },
                        onOpenOnboarding: {
                            selectedTab = 2
                        }
                    )
                    .navigationTitle("WingAI Account & Plan")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }
                .tag(1)

                WingAiOnboardingScreen(
                    viewModel: hostViewModel,
                    onOpenSystemSettings: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    },
                    onOpenShortcutsApp: {
                        if let url = URL(string: "shortcuts://") {
                            UIApplication.shared.open(url)
                        }
                    },
                    onContinue: {
                        selectedTab = 0
                    }
                )
                .tabItem {
                    Label("Onboarding", systemImage: "checklist")
                }
                .tag(2)
            }
            .preferredColorScheme(.dark)
        }
    }

    private var liveKeyboardPlaygroundTab: some View {
        let palette = WingAiPalette.dark
        return ZStack {
            VStack(spacing: 0) {
                // Top Chat Header
                HStack {
                    Circle()
                        .fill(palette.accentPrimary)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Text("A")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Aarav • Live Chat Sandbox")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                        Text("Tap 'Select' on the keyboard below to crop & reply with AI")
                            .font(.system(size: 11.5))
                            .foregroundColor(palette.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(palette.surface0)

                // Simulated Chat Messages
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(chatMessages.enumerated()), id: \.offset) { _, msg in
                            HStack {
                                if !msg.isIncoming { Spacer() }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(msg.sender)
                                        .font(.system(size: 10.5, weight: .bold))
                                        .foregroundColor(msg.isIncoming ? palette.accentPrimary : .white.opacity(0.8))
                                    Text(msg.text)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 13)
                                .padding(.vertical, 9)
                                .background(msg.isIncoming ? palette.surface1 : palette.accentPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                if msg.isIncoming { Spacer() }
                            }
                        }
                    }
                    .padding(16)
                }
                .background(palette.bgCanvas)

                // Message Input Bar
                HStack(spacing: 8) {
                    TextField("Type a message or tap Select / AI below...", text: $draftMessage)
                        .font(.system(size: 14))
                        .foregroundColor(palette.textPrimary)
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(palette.surface1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 19)
                                .stroke(palette.borderSubtle, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 19))

                    Button {
                        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        chatMessages.append(("You", trimmed, false))
                        draftMessage = ""
                    } label: {
                        Text("Send")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .background(palette.accentPrimary)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(palette.surface0)

                // Collapse keyboard when Select & Search full-screen cropper is active, reopen right after!
                if !keyboardViewModel.isCroppingSnapshot {
                    WingAiKeyboardRootView(
                        viewModel: keyboardViewModel,
                        onInsertText: { inserted in
                            draftMessage += inserted
                        },
                        onDeleteBackward: {
                            if !draftMessage.isEmpty {
                                draftMessage.removeLast()
                            }
                        },
                        onNextKeyboard: {},
                        onReadClipboardImage: {
                            Self.captureCurrentWindowJpeg()
                        },
                        onReadClipboardText: {
                            chatMessages.map { "\($0.sender): \($0.text)" }.joined(separator: "\n")
                        },
                        onCropImageData: { rawData, rect in
                            KeyboardViewController.cropImageData(rawData, normalizedRect: rect)
                        }
                    )
                }
            }
            .background(palette.bgCanvas)

            if keyboardViewModel.isCroppingSnapshot, let rawData = keyboardViewModel.rawSnapshotData {
                SelectAndSearchCropView(
                    onCancel: {
                        keyboardViewModel.cancelCrop()
                    },
                    onConfirmCrop: { rect in
                        let cropped = KeyboardViewController.cropImageData(rawData, normalizedRect: rect) ?? rawData
                        keyboardViewModel.confirmCrop(normalizedRect: rect, croppedJpegData: cropped)
                    }
                )
                .ignoresSafeArea()
            }
        }
    }

    private static func captureCurrentWindowJpeg() -> Data? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return nil
        }
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
        return image.jpegData(compressionQuality: 0.85)
    }
}
#endif
