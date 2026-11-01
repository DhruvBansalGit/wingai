import Foundation
import CoreGraphics

public enum WingTone: String, CaseIterable, Codable, Sendable {
    case casual = "casual"
    case friendly = "friendly"
    case professional = "professional"
    case funny = "funny"
    case flirty = "flirty"
    case short = "short"
    case detailed = "detailed"

    public var displayName: String {
        rawValue.capitalized
    }
}

public struct ReplyItem: Codable, Equatable, Identifiable, Sendable {
    public var id: String { "\(tone):\(text)" }
    public let tone: String
    public let text: String

    public init(tone: String, text: String) {
        self.tone = tone
        self.text = text
    }
}

public struct UserProfile: Codable, Equatable, Sendable {
    public let userId: String
    public let tier: String
    public let dailyUsed: Int
    public let dailyLimit: Int?
    public let remaining: Int?
    public let usageDate: String

    public var isPaid: Bool {
        tier.lowercased() == "paid"
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case tier
        case dailyUsed = "daily_used"
        case dailyLimit = "daily_limit"
        case remaining
        case usageDate = "usage_date"
    }

    public init(
        userId: String,
        tier: String = "free",
        dailyUsed: Int = 0,
        dailyLimit: Int? = 5,
        remaining: Int? = 5,
        usageDate: String = ""
    ) {
        self.userId = userId
        self.tier = tier
        self.dailyUsed = dailyUsed
        self.dailyLimit = dailyLimit
        self.remaining = remaining
        self.usageDate = usageDate
    }
}

public struct ReplyResponse: Codable, Equatable, Sendable {
    public let status: String
    public let contextStatus: String
    public let message: String?
    public let replies: [ReplyItem]
    public let user: UserProfile?

    enum CodingKeys: String, CodingKey {
        case status
        case contextStatus = "context_status"
        case message
        case replies
        case user
    }
}

/// Shared App Group storage (`group.com.wingai.keyboard`) used between:
/// 1. WingAI Host App (`WingAIApp`)
/// 2. WingAI Keyboard Extension (`WingAIKeyboard`)
/// 3. WingAI Back-Tap Shortcut (`CaptureChatForWingAIIntent`)
/// 4. WingAI 1-Frame ReplayKit Broadcast (`WingAIBroadcast`)
public final class AppGroupStore: @unchecked Sendable {
    public static let shared = AppGroupStore()
    public static let appGroupId = "group.com.wingai.keyboard"
    public static let defaultBackendUrl = "https://wingai-backend.zardamhussain.workers.dev"

    private let defaults: UserDefaults
    private let userIdKey = "wingai_device_user_id"
    private let backendUrlKey = "wingai_backend_url"
    private let snapshotTimestampKey = "wingai_pending_snapshot_ts"

    public init(suiteName: String = AppGroupStore.appGroupId) {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    public func getOrCreateUserId() -> String {
        if let existing = defaults.string(forKey: userIdKey), !existing.isEmpty {
            return existing
        }
        let rawUuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let generated = "wing_\(rawUuid.prefix(12))"
        defaults.set(generated, forKey: userIdKey)
        return generated
    }

    public var backendUrl: String {
        get {
            let stored = defaults.string(forKey: backendUrlKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return (stored?.isEmpty == false) ? stored! : Self.defaultBackendUrl
        }
        set {
            defaults.set(newValue, forKey: backendUrlKey)
        }
    }

    private var pendingSnapshotFileURL: URL? {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupId) {
            try? FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)
            if FileManager.default.isWritableFile(atPath: container.path) {
                return container.appendingPathComponent("pending_snapshot.jpg")
            }
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("pending_snapshot.jpg")
    }

    /// Saves a single captured screenshot frame into the shared App Group container so the keyboard
    /// can immediately display the Select & Search crop overlay and then delete it.
    public func savePendingSnapshotData(_ jpegData: Data) {
        guard let url = pendingSnapshotFileURL else { return }
        try? jpegData.write(to: url, options: .atomic)
        defaults.set(Date().timeIntervalSince1970, forKey: snapshotTimestampKey)
    }

    /// Reads and consumes the pending snapshot if captured within the last 5 minutes.
    public func consumePendingSnapshotData() -> Data? {
        guard let url = pendingSnapshotFileURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        let ts = defaults.double(forKey: snapshotTimestampKey)
        let age = Date().timeIntervalSince1970 - ts
        let data = try? Data(contentsOf: url)
        clearPendingSnapshot()
        if age > 300 {
            return nil
        }
        return data
    }

    public func hasPendingSnapshot() -> Bool {
        guard let url = pendingSnapshotFileURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    public func clearPendingSnapshot() {
        if let url = pendingSnapshotFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        defaults.removeObject(forKey: snapshotTimestampKey)
    }
}
