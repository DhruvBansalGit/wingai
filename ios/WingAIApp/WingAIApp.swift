import SwiftUI
import AppIntents

#if canImport(UIKit)
import UIKit
#endif

/// iOS Back-Tap / Action Button AppIntent:
/// In iOS Shortcuts, create a 2-action shortcut:
///   1. "Take Screenshot"
///   2. "Send Screenshot to WingAI Select & Search" (this intent)
/// Bind it to Double Back-Tap (Settings -> Accessibility -> Touch -> Back Tap) or Action Button.
/// It writes the screenshot into `group.com.wingai.keyboard` RAM/container without saving to Photos!
@available(iOS 16.0, macOS 13.0, *)
public struct CaptureChatForWingAIIntent: AppIntent {
    public static var title: LocalizedStringResource = "Send Screenshot to WingAI Select & Search"
    public static var description = IntentDescription(
        "Passes a screenshot directly to WingAI Keyboard's Select & Search cropper without saving it to your Camera Roll."
    )

    @Parameter(title: "Chat Screenshot")
    public var screenshotFile: IntentFile

    public init() {}

    public func perform() async throws -> some IntentResult {
        AppGroupStore.shared.savePendingSnapshotData(screenshotFile.data)
        return .result()
    }
}

@MainActor
public final class WingAiHostViewModel: ObservableObject {
    @Published public var profile: UserProfile? = nil
    @Published public var isLoadingProfile: Bool = true
    @Published public var errorMessage: String? = nil
    @Published public var isKeyboardEnabled: Bool = false
    @Published public var isFullAccessEnabled: Bool = true
    @Published public var isBackTapConfigured: Bool = false

    private let apiClient = WingAiApiClient()

    public init() {}

    public func refreshProfile() {
        isLoadingProfile = true
        errorMessage = nil
        Task {
            do {
                let loaded = try await apiClient.fetchUserProfile()
                self.profile = loaded
                self.isLoadingProfile = false
            } catch {
                self.isLoadingProfile = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    public func checkKeyboardStatus() {
        #if canImport(UIKit)
        let modes = UITextInputMode.activeInputModes
        let found = modes.contains { mode in
            guard let id = mode.value(forKey: "identifier") as? String else { return false }
            return id.lowercased().contains("wingai")
        }
        isKeyboardEnabled = found
        #endif
    }
}

public struct WingAiOnboardingScreen: View {
    @ObservedObject public var viewModel: WingAiHostViewModel
    public let onOpenSystemSettings: () -> Void
    public let onOpenShortcutsApp: () -> Void
    public let onContinue: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    public init(
        viewModel: WingAiHostViewModel,
        onOpenSystemSettings: @escaping () -> Void,
        onOpenShortcutsApp: @escaping () -> Void,
        onContinue: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onOpenSystemSettings = onOpenSystemSettings
        self.onOpenShortcutsApp = onOpenShortcutsApp
        self.onContinue = onContinue
    }

    private var completedCount: Int {
        [viewModel.isKeyboardEnabled, viewModel.isFullAccessEnabled, viewModel.isBackTapConfigured]
            .filter { $0 }
            .count
    }

    public var body: some View {
        let palette = WingAiPalette.forScheme(colorScheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(palette.accentPrimary)
                            .frame(width: 7, height: 7)
                        Text("WINGAI BOARD SETUP")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(palette.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(palette.surface1)
                    .overlay(Capsule().stroke(palette.borderSubtle, lineWidth: 1))
                    .clipShape(Capsule())

                    Spacer()

                    CompactPillButton(
                        title: viewModel.isKeyboardEnabled ? "Done" : "Skip",
                        action: onContinue
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Set up your AI keyboard")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(palette.textPrimary)
                    Text("Complete these 3 quick steps to enable WingAI Board and Circle-to-Search AI replies on iOS.")
                        .font(.system(size: 13.5))
                        .foregroundColor(palette.textSecondary)
                }

                // 3-Step Segmented Progress Bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(completedCount) of 3 steps completed")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(palette.textSecondary)
                        Spacer()
                        if completedCount == 3 {
                            Text("Ready to use")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(palette.accentEmerald)
                        }
                    }
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            let done = [
                                viewModel.isKeyboardEnabled,
                                viewModel.isFullAccessEnabled,
                                viewModel.isBackTapConfigured
                            ][index]
                            Capsule()
                                .fill(done ? palette.accentEmerald : palette.surface3)
                                .frame(height: 6)
                        }
                    }
                }

                onboardingCard(
                    stepNumber: "01",
                    title: "Enable WingAI Board",
                    description: "Open iOS Settings → Keyboards and toggle on WingAI Board.",
                    actionLabel: "Open iOS Settings",
                    isCompleted: viewModel.isKeyboardEnabled,
                    isActive: !viewModel.isKeyboardEnabled,
                    palette: palette,
                    action: onOpenSystemSettings
                )

                onboardingCard(
                    stepNumber: "02",
                    title: "Allow Full Access",
                    description: "Enable Allow Full Access in Keyboard settings so WingAI can generate AI replies.",
                    actionLabel: "Keyboard Settings",
                    isCompleted: viewModel.isFullAccessEnabled && viewModel.isKeyboardEnabled,
                    isActive: viewModel.isKeyboardEnabled && !viewModel.isFullAccessEnabled,
                    palette: palette,
                    action: onOpenSystemSettings
                )

                onboardingCard(
                    stepNumber: "03",
                    title: "Enable Select & Search Shortcut",
                    description: "Bind 'Send Screenshot to WingAI' to Back-Tap or use Screenshot → Copy & Delete for instant cropping without gallery clutter.",
                    actionLabel: "Set Up Shortcut",
                    isCompleted: viewModel.isBackTapConfigured,
                    isActive: viewModel.isKeyboardEnabled && !viewModel.isBackTapConfigured,
                    palette: palette,
                    action: {
                        viewModel.isBackTapConfigured = true
                        onOpenShortcutsApp()
                    }
                )

                Button(action: onContinue) {
                    Text("Open WingAI Account & Plan")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(palette.onAccentPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(palette.accentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .background(palette.bgCanvas.ignoresSafeArea())
    }

    private func onboardingCard(
        stepNumber: String,
        title: String,
        description: String,
        actionLabel: String,
        isCompleted: Bool,
        isActive: Bool,
        palette: WingAiPalette,
        action: @escaping () -> Void
    ) -> some View {
        let border = isCompleted ? palette.accentEmerald : (isActive ? palette.accentPrimary : palette.borderSubtle)
        return WingAiSurfaceCard(borderColor: border) {
            HStack {
                HStack(spacing: 10) {
                    Text(isCompleted ? "✓" : stepNumber)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isCompleted ? palette.accentEmerald : palette.accentPrimary)
                        .frame(width: 28, height: 28)
                        .background(isCompleted ? palette.accentEmeraldContainer : palette.accentPrimaryContainer)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                }
                Spacer()
                Text(isCompleted ? "Completed" : (isActive ? "Next Step" : "Pending"))
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(isCompleted ? palette.accentEmerald : palette.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(isCompleted ? palette.accentEmeraldContainer : palette.surface2)
                    .clipShape(Capsule())
            }

            Text(description)
                .font(.system(size: 12.5))
                .foregroundColor(palette.textSecondary)

            if !isCompleted {
                HStack {
                    Spacer()
                    CompactPillButton(title: actionLabel, isPrimary: isActive, action: action)
                }
            }
        }
    }
}

public struct WingAiUserAccountScreen: View {
    @ObservedObject public var viewModel: WingAiHostViewModel
    public let onCopyUserId: (String) -> Void
    public let onOpenOnboarding: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    public init(
        viewModel: WingAiHostViewModel,
        onCopyUserId: @escaping (String) -> Void,
        onOpenOnboarding: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onCopyUserId = onCopyUserId
        self.onOpenOnboarding = onOpenOnboarding
    }

    public var body: some View {
        let palette = WingAiPalette.forScheme(colorScheme)
        let profile = viewModel.profile
        let isPaid = profile?.isPaid == true

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // 1. Plan & Daily Quota Hero Card
                WingAiSurfaceCard(borderColor: isPaid ? palette.accentEmerald : palette.borderAccent) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CURRENT SUBSCRIPTION")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(palette.textSecondary)
                            Text(isPaid ? "WingAI Pro" : "WingAI Free Tier")
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(palette.textPrimary)
                        }
                        Spacer()
                        Text(isPaid ? "👑 PAID • UNLIMITED" : "⚡ FREE • 5 / DAY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isPaid ? palette.accentEmerald : palette.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(isPaid ? palette.accentEmeraldContainer : palette.accentPrimaryContainer)
                            .overlay(
                                Capsule().stroke(isPaid ? palette.accentEmerald : palette.accentPrimary, lineWidth: 1)
                            )
                            .clipShape(Capsule())
                    }

                    if viewModel.isLoadingProfile && profile == nil {
                        VStack(alignment: .leading, spacing: 8) {
                            WingAiSkeletonBox(height: 14)
                                .frame(maxWidth: 220)
                            HStack(spacing: 6) {
                                ForEach(0..<5, id: \.self) { _ in
                                    WingAiSkeletonBox(height: 7, cornerRadius: 50)
                                }
                            }
                        }
                    } else if let profile {
                        let limit = profile.dailyLimit ?? 5
                        let used = profile.dailyUsed
                        let remaining = profile.remaining ?? max(0, limit - used)

                        Text(
                            isPaid
                                ? "\(used) AI requests processed today • Unlimited daily replies active"
                                : "\(used) of \(limit) daily replies used today • \(remaining) remaining (resets 00:00 UTC)"
                        )
                        .font(.system(size: 13))
                        .foregroundColor(palette.textSecondary)

                        if !isPaid {
                            HStack(spacing: 6) {
                                ForEach(1...limit, id: \.self) { slot in
                                    let consumed = slot <= used
                                    Capsule()
                                        .fill(
                                            used >= limit
                                                ? palette.accentRose
                                                : (consumed ? palette.accentPrimary : palette.surface3)
                                        )
                                        .frame(height: 7)
                                }
                            }
                        }
                    }

                    HStack {
                        Spacer()
                        CompactPillButton(
                            title: viewModel.isLoadingProfile ? "Syncing" : "Refresh Quota",
                            isDisabled: viewModel.isLoadingProfile
                        ) {
                            viewModel.refreshProfile()
                        }
                    }
                }

                // 2. Copyable Device User ID Card (No 3-dots or extra clutter)
                WingAiSurfaceCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("WINGAI DEVICE USER ID")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(palette.textSecondary)
                            if let uid = profile?.userId, !uid.isEmpty {
                                Text(uid)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(palette.textPrimary)
                            } else {
                                WingAiSkeletonBox(height: 16)
                                    .frame(maxWidth: 160)
                            }
                        }
                        Spacer()
                        CompactPillButton(title: "Copy ID", isPrimary: true) {
                            onCopyUserId(profile?.userId ?? AppGroupStore.shared.getOrCreateUserId())
                        }
                    }
                }

                // 3. Setup & Onboarding Checklist Link
                WingAiSurfaceCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Setup & Onboarding Checklist")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Text("Keyboard activation & Select-and-Search shortcut")
                                .font(.system(size: 12))
                                .foregroundColor(palette.textSecondary)
                        }
                        Spacer()
                        CompactPillButton(title: "Open", action: onOpenOnboarding)
                    }
                }
            }
            .padding(16)
        }
        .background(palette.bgCanvas.ignoresSafeArea())
        .onAppear {
            viewModel.refreshProfile()
            viewModel.checkKeyboardStatus()
        }
    }
}
