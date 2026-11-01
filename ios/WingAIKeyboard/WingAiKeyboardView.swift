import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

public final class WingAiKeyboardViewModel: ObservableObject {
    @Published public var isAiPanelOpen: Bool = false
    @Published public var isCroppingSnapshot: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var isShifted: Bool = false
    @Published public var isSymbolMode: Bool = false
    @Published public var selectedTone: String? = nil
    @Published public var pastedContext: String? = nil
    @Published public var rawSnapshotData: Data? = nil
    @Published public var croppedPreviewData: Data? = nil
    @Published public var suggestions: [ReplyItem] = []
    @Published public var errorMessage: String? = nil
    @Published public var currentWordPrefix: String = ""

    private let apiClient = WingAiApiClient()

    private let hinglishAndEnglishLexicon: [String] = [
        "haan", "nahi", "kya", "kaise", "bhai", "yaar", "acha", "theek", "hai", "milte",
        "kal", "aaj", "abhi", "chal", "chalo", "batao", "dekhte", "pakka", "zaroor", "bilkul",
        "shukriya", "dhanyawad", "karo", "karna", "raha", "rahi", "baad", "pehle", "kaam",
        "hello", "sounds", "great", "thanks", "tomorrow", "meeting", "perfect", "sure", "okay"
    ]

    public init() {}

    public var typingPredictions: [String] {
        let prefix = currentWordPrefix.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prefix.isEmpty else {
            return ["haan", "theek hai", "sounds good"]
        }
        let matches = hinglishAndEnglishLexicon.filter { $0.hasPrefix(prefix) && $0 != prefix }
        return Array(([prefix] + matches).prefix(3))
    }

    public func startSelectAndSearch(clipboardImageData: Data?) {
        errorMessage = nil
        // 1. Check Shared App Group container (from Back-Tap AppIntent or 1-Frame ReplayKit Broadcast)
        if let groupData = AppGroupStore.shared.consumePendingSnapshotData() {
            rawSnapshotData = groupData
            isCroppingSnapshot = true
            isAiPanelOpen = true
            return
        }
        // 2. Check UIPasteboard image (from iOS Screenshot -> Done -> Copy and Delete)
        if let clipData = clipboardImageData {
            rawSnapshotData = clipData
            isCroppingSnapshot = true
            isAiPanelOpen = true
            return
        }
        // 3. Guide user if no screenshot is in RAM yet
        isAiPanelOpen = true
        errorMessage = "Double-tap the back of your iPhone (or press Screenshot → Copy & Delete), then tap Select."
    }

    public func confirmCrop(normalizedRect: CGRect, croppedJpegData: Data) {
        isCroppingSnapshot = false
        rawSnapshotData = nil
        croppedPreviewData = croppedJpegData
        let base64 = croppedJpegData.base64EncodedString()
        triggerAnalyze(imageBase64: base64, conversationText: pastedContext)
    }

    public func cancelCrop() {
        isCroppingSnapshot = false
        rawSnapshotData = nil
    }

    public func analyzePastedChat(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Clipboard does not contain chat text."
            isAiPanelOpen = true
            return
        }
        pastedContext = trimmed
        isAiPanelOpen = true
        triggerAnalyze(
            imageBase64: croppedPreviewData?.base64EncodedString(),
            conversationText: trimmed
        )
    }

    public func selectTone(_ tone: String?) {
        selectedTone = (selectedTone == tone) ? nil : tone
        if croppedPreviewData != nil || pastedContext != nil {
            triggerAnalyze(
                imageBase64: croppedPreviewData?.base64EncodedString(),
                conversationText: pastedContext
            )
        }
    }

    public func triggerAnalyze(imageBase64: String?, conversationText: String?) {
        isLoading = true
        errorMessage = nil
        let tone = selectedTone
        Task { @MainActor in
            do {
                let response = try await apiClient.analyzeContext(
                    imageBase64: imageBase64,
                    conversationText: conversationText,
                    tone: tone
                )
                self.isLoading = false
                self.suggestions = response.replies
                if response.contextStatus == "insufficient" {
                    self.errorMessage = response.message ?? "Conversation is not clear. Select a clearer chat section."
                }
            } catch {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

public struct WingAiKeyboardRootView: View {
    @ObservedObject public var viewModel: WingAiKeyboardViewModel
    public let onInsertText: (String) -> Void
    public let onDeleteBackward: () -> Void
    public let onNextKeyboard: () -> Void
    public let onReadClipboardImage: () -> Data?
    public let onReadClipboardText: () -> String?
    public let onCropImageData: (Data, CGRect) -> Data?

    @Environment(\.colorScheme) private var colorScheme

    private let row1 = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
    private let row2 = ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
    private let row3 = ["z", "x", "c", "v", "b", "n", "m"]
    private let numRow1 = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    private let numRow2 = ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""]
    private let numRow3 = [".", ",", "?", "!", "'", "#", "%"]

    public init(
        viewModel: WingAiKeyboardViewModel,
        onInsertText: @escaping (String) -> Void,
        onDeleteBackward: @escaping () -> Void,
        onNextKeyboard: @escaping () -> Void,
        onReadClipboardImage: @escaping () -> Data?,
        onReadClipboardText: @escaping () -> String?,
        onCropImageData: @escaping (Data, CGRect) -> Data?
    ) {
        self.viewModel = viewModel
        self.onInsertText = onInsertText
        self.onDeleteBackward = onDeleteBackward
        self.onNextKeyboard = onNextKeyboard
        self.onReadClipboardImage = onReadClipboardImage
        self.onReadClipboardText = onReadClipboardText
        self.onCropImageData = onCropImageData
    }

    public var body: some View {
        let palette = WingAiPalette.forScheme(colorScheme)
        VStack(spacing: 0) {
            // Top Suggestion + WingAI Quick Strip
            HStack(spacing: 6) {
                CompactPillButton(
                    title: "Select",
                    isPrimary: viewModel.croppedPreviewData != nil
                ) {
                    viewModel.startSelectAndSearch(clipboardImageData: onReadClipboardImage())
                }

                // Word predictions when typing
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(viewModel.typingPredictions, id: \.self) { word in
                            Button {
                                applyPrediction(word)
                            } label: {
                                Text(word)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(palette.textPrimary)
                                    .padding(.horizontal, 10)
                                    .frame(height: 28)
                                    .background(palette.surface1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(palette.borderSubtle, lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                CompactPillButton(
                    title: viewModel.isAiPanelOpen ? "Keys" : "AI",
                    isPrimary: viewModel.isAiPanelOpen
                ) {
                    viewModel.isAiPanelOpen.toggle()
                    viewModel.isCroppingSnapshot = false
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 40)
            .background(palette.bgCanvas)

            if viewModel.isAiPanelOpen {
                if viewModel.isCroppingSnapshot, let rawData = viewModel.rawSnapshotData {
                    SelectAndSearchCropView(
                        onCancel: { viewModel.cancelCrop() },
                        onConfirmCrop: { rect in
                            let cropped = onCropImageData(rawData, rect) ?? rawData
                            viewModel.confirmCrop(normalizedRect: rect, croppedJpegData: cropped)
                        }
                    )
                    .frame(height: 236)
                    .background(palette.bgCanvas)
                } else {
                    aiControlPanel(palette: palette)
                        .frame(height: 236)
                        .background(palette.bgCanvas)
                }
            } else {
                qwertyGrid(palette: palette)
                    .frame(height: 216)
                    .background(palette.bgCanvas)
            }
        }
        .background(palette.bgCanvas)
    }

    @ViewBuilder
    private func aiControlPanel(palette: WingAiPalette) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                // Tone Selector Bar + Paste Chat
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        CompactPillButton(title: "Paste Chat") {
                            viewModel.analyzePastedChat(onReadClipboardText() ?? "")
                        }
                        ForEach(WingTone.allCases, id: \.rawValue) { tone in
                            let active = viewModel.selectedTone == tone.rawValue
                            CompactPillButton(
                                title: tone.displayName,
                                isPrimary: active
                            ) {
                                viewModel.selectTone(tone.rawValue)
                            }
                        }
                    }
                }

                if let err = viewModel.errorMessage {
                    WingAiSurfaceCard(borderColor: palette.accentRose) {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(palette.textPrimary)
                    }
                }

                if viewModel.isLoading {
                    ForEach(0..<3, id: \.self) { index in
                        WingAiSurfaceCard {
                            HStack {
                                WingAiSkeletonBox(height: 16, cornerRadius: 5)
                                    .frame(width: 68)
                                Spacer()
                                WingAiSkeletonBox(height: 12, cornerRadius: 4)
                                    .frame(width: 48)
                            }
                            WingAiSkeletonBox(height: 13, cornerRadius: 4)
                            WingAiSkeletonBox(height: 13, cornerRadius: 4)
                                .frame(maxWidth: index == 1 ? 180 : 230)
                        }
                    }
                } else if viewModel.suggestions.isEmpty {
                    WingAiSurfaceCard {
                        Text("Tap Select above to crop any chat screenshot, or tap Paste Chat to generate 3 instant replies.")
                            .font(.system(size: 12.5))
                            .foregroundColor(palette.textSecondary)
                    }
                } else {
                    ForEach(viewModel.suggestions) { reply in
                        Button {
                            onInsertText(reply.text)
                            viewModel.isAiPanelOpen = false
                        } label: {
                            WingAiSurfaceCard {
                                HStack {
                                    Text(reply.tone.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(palette.accentPrimary)
                                    Spacer()
                                    Text("Tap to insert")
                                        .font(.system(size: 10.5, weight: .medium))
                                        .foregroundColor(palette.textMuted)
                                }
                                Text(reply.text)
                                    .font(.system(size: 13.5, weight: .medium))
                                    .foregroundColor(palette.textPrimary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private func qwertyGrid(palette: WingAiPalette) -> some View {
        let r1 = viewModel.isSymbolMode ? numRow1 : row1
        let r2 = viewModel.isSymbolMode ? numRow2 : row2
        let r3 = viewModel.isSymbolMode ? numRow3 : row3

        VStack(spacing: 7) {
            HStack(spacing: 5) {
                ForEach(r1, id: \.self) { key in
                    letterKeyButton(key, palette: palette)
                }
            }
            HStack(spacing: 5) {
                ForEach(r2, id: \.self) { key in
                    letterKeyButton(key, palette: palette)
                }
            }
            HStack(spacing: 5) {
                functionalKeyButton(
                    label: viewModel.isSymbolMode ? "#+=" : (viewModel.isShifted ? "⬆" : "⇧"),
                    width: 42,
                    palette: palette
                ) {
                    viewModel.isShifted.toggle()
                }
                ForEach(r3, id: \.self) { key in
                    letterKeyButton(key, palette: palette)
                }
                functionalKeyButton(label: "⌫", width: 42, palette: palette) {
                    if !viewModel.currentWordPrefix.isEmpty {
                        viewModel.currentWordPrefix.removeLast()
                    }
                    onDeleteBackward()
                }
            }
            HStack(spacing: 6) {
                functionalKeyButton(
                    label: viewModel.isSymbolMode ? "ABC" : "123",
                    width: 48,
                    palette: palette
                ) {
                    viewModel.isSymbolMode.toggle()
                }
                functionalKeyButton(label: "🌐", width: 40, palette: palette) {
                    onNextKeyboard()
                }
                // Spacebar with clean "English" label (no Hinglish debug clutter)
                Button {
                    viewModel.currentWordPrefix = ""
                    onInsertText(" ")
                } label: {
                    Text("English")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(palette.surface1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(palette.borderSubtle, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                functionalKeyButton(label: "↵", width: 64, isAccent: true, palette: palette) {
                    viewModel.currentWordPrefix = ""
                    onInsertText("\n")
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
    }

    private func letterKeyButton(_ raw: String, palette: WingAiPalette) -> some View {
        let label = (viewModel.isShifted && !viewModel.isSymbolMode) ? raw.uppercased() : raw
        return Button {
            viewModel.currentWordPrefix.append(label)
            onInsertText(label)
            if viewModel.isShifted {
                viewModel.isShifted = false
            }
        } label: {
            Text(label)
                .font(.system(size: 18.5, weight: .regular))
                .foregroundColor(palette.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(palette.surface1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(palette.borderSubtle, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func functionalKeyButton(
        label: String,
        width: CGFloat,
        isAccent: Bool = false,
        palette: WingAiPalette,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14.5, weight: .semibold))
                .foregroundColor(isAccent ? palette.onAccentPrimary : palette.textPrimary)
                .frame(width: width, height: 42)
                .background(isAccent ? palette.accentPrimary : palette.surface2)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isAccent ? palette.accentPrimary : palette.borderSubtle, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func applyPrediction(_ word: String) {
        let count = viewModel.currentWordPrefix.count
        for _ in 0..<count {
            onDeleteBackward()
        }
        viewModel.currentWordPrefix = ""
        onInsertText(word + " ")
    }
}
