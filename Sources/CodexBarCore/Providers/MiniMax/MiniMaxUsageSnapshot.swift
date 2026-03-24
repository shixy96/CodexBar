import Foundation

public struct MiniMaxModelUsageEntry: Sendable {
    public let modelName: String
    public let sessionTotal: Int?
    public let sessionUsed: Int?
    public let sessionRemaining: Int?
    public let sessionResetsAt: Date?
    public let weeklyTotal: Int?
    public let weeklyUsed: Int?
    public let weeklyRemaining: Int?
    public let isWeeklyUnlimited: Bool

    public init(
        modelName: String,
        sessionTotal: Int?,
        sessionUsed: Int?,
        sessionRemaining: Int?,
        sessionResetsAt: Date? = nil,
        weeklyTotal: Int?,
        weeklyUsed: Int?,
        weeklyRemaining: Int?,
        isWeeklyUnlimited: Bool)
    {
        self.modelName = modelName
        self.sessionTotal = sessionTotal
        self.sessionUsed = sessionUsed
        self.sessionRemaining = sessionRemaining
        self.sessionResetsAt = sessionResetsAt
        self.weeklyTotal = weeklyTotal
        self.weeklyUsed = weeklyUsed
        self.weeklyRemaining = weeklyRemaining
        self.isWeeklyUnlimited = isWeeklyUnlimited
    }

    public func resetText(style: ResetTimeDisplayStyle, now: Date = Date()) -> String? {
        guard let resetsAt = self.sessionResetsAt else { return nil }
        let window = RateWindow(
            usedPercent: 0,
            windowMinutes: nil,
            resetsAt: resetsAt,
            resetDescription: nil)
        return UsageFormatter.resetLine(for: window, style: style, now: now)
    }

    public func normalizedSessionUsage() -> (used: Int, remaining: Int, total: Int)? {
        guard let total = self.sessionTotal, total > 0 else { return nil }
        guard self.sessionUsed != nil || self.sessionRemaining != nil else { return nil }
        let remaining = self.sessionRemaining.map { min(max($0, 0), total) }
        let used = self.sessionUsed.map { min(max($0, 0), total) }
            ?? remaining.map { total - $0 }
        let finalRemaining = remaining ?? used.map { max(0, total - $0) }
        guard let used, let finalRemaining else { return nil }
        return (used: used, remaining: finalRemaining, total: total)
    }
}

public struct MiniMaxUsageSnapshot: Sendable {
    public let planName: String?
    public let availablePrompts: Int?
    public let currentPrompts: Int?
    public let remainingPrompts: Int?
    public let windowMinutes: Int?
    public let usedPercent: Double?
    public let resetsAt: Date?
    public let updatedAt: Date
    public let modelEntries: [MiniMaxModelUsageEntry]

    public init(
        planName: String?,
        availablePrompts: Int?,
        currentPrompts: Int?,
        remainingPrompts: Int?,
        windowMinutes: Int?,
        usedPercent: Double?,
        resetsAt: Date?,
        updatedAt: Date,
        modelEntries: [MiniMaxModelUsageEntry] = [])
    {
        self.planName = planName
        self.availablePrompts = availablePrompts
        self.currentPrompts = currentPrompts
        self.remainingPrompts = remainingPrompts
        self.windowMinutes = windowMinutes
        self.usedPercent = usedPercent
        self.resetsAt = resetsAt
        self.updatedAt = updatedAt
        self.modelEntries = modelEntries
    }
}

extension MiniMaxUsageSnapshot {
    public func toUsageSnapshot() -> UsageSnapshot {
        let used = max(0, min(100, self.usedPercent ?? 0))
        let resetDescription = self.limitDescription()
        let primary = RateWindow(
            usedPercent: used,
            windowMinutes: self.windowMinutes,
            resetsAt: self.resetsAt,
            resetDescription: resetDescription)

        let planName = self.planName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let loginMethod = (planName?.isEmpty ?? true) ? nil : planName
        let identity = ProviderIdentitySnapshot(
            providerID: .minimax,
            accountEmail: nil,
            accountOrganization: nil,
            loginMethod: loginMethod)

        return UsageSnapshot(
            primary: primary,
            secondary: nil,
            tertiary: nil,
            providerCost: nil,
            minimaxUsage: self,
            updatedAt: self.updatedAt,
            identity: identity)
    }

    private func limitDescription() -> String? {
        guard let availablePrompts, availablePrompts > 0 else {
            return self.windowDescription()
        }

        if let windowDescription = self.windowDescription() {
            return "\(availablePrompts) prompts / \(windowDescription)"
        }
        return "\(availablePrompts) prompts"
    }

    private func windowDescription() -> String? {
        guard let windowMinutes, windowMinutes > 0 else { return nil }
        if windowMinutes % (24 * 60) == 0 {
            let days = windowMinutes / (24 * 60)
            return "\(days) \(days == 1 ? "day" : "days")"
        }
        if windowMinutes % 60 == 0 {
            let hours = windowMinutes / 60
            return "\(hours) \(hours == 1 ? "hour" : "hours")"
        }
        return "\(windowMinutes) \(windowMinutes == 1 ? "minute" : "minutes")"
    }
}
