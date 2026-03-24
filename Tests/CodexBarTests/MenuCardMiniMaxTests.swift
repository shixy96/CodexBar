import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

struct MenuCardMiniMaxTests {
    @Test
    func `minimax card model renders model metrics with per model reset times`() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let metadata = try #require(ProviderDefaults.metadata[.minimax])
        let snapshot = MiniMaxUsageSnapshot(
            planName: "Max",
            availablePrompts: 1500,
            currentPrompts: 50,
            remainingPrompts: 1450,
            windowMinutes: 300,
            usedPercent: Double(50) / Double(1500) * 100,
            resetsAt: now.addingTimeInterval(12 * 60 * 60),
            updatedAt: now,
            modelEntries: [
                MiniMaxModelUsageEntry(
                    modelName: "MiniMax-M*",
                    sessionTotal: 1500,
                    sessionUsed: 50,
                    sessionRemaining: 1450,
                    sessionResetsAt: now.addingTimeInterval(3 * 60 * 60),
                    weeklyTotal: nil,
                    weeklyUsed: nil,
                    weeklyRemaining: nil,
                    isWeeklyUnlimited: true),
                MiniMaxModelUsageEntry(
                    modelName: "speech-hd",
                    sessionTotal: 4000,
                    sessionUsed: 0,
                    sessionRemaining: 4000,
                    sessionResetsAt: now.addingTimeInterval(5 * 60 * 60),
                    weeklyTotal: 28000,
                    weeklyUsed: 0,
                    weeklyRemaining: 28000,
                    isWeeklyUnlimited: false),
                MiniMaxModelUsageEntry(
                    modelName: "image-01",
                    sessionTotal: 50,
                    sessionUsed: 0,
                    sessionRemaining: 50,
                    sessionResetsAt: now.addingTimeInterval(26 * 60 * 60),
                    weeklyTotal: 350,
                    weeklyUsed: 0,
                    weeklyRemaining: 350,
                    isWeeklyUnlimited: false),
            ])
            .toUsageSnapshot()

        let model = UsageMenuCardView.Model.make(.init(
            provider: .minimax,
            metadata: metadata,
            snapshot: snapshot,
            credits: nil,
            creditsError: nil,
            dashboard: nil,
            dashboardError: nil,
            tokenSnapshot: nil,
            tokenError: nil,
            account: AccountInfo(email: nil, plan: nil),
            isRefreshing: false,
            lastError: nil,
            usageBarsShowUsed: true,
            resetTimeDisplayStyle: .countdown,
            tokenCostUsageEnabled: false,
            showOptionalCreditsAndExtraUsage: true,
            hidePersonalInfo: false,
            now: now))

        #expect(model.metrics.map(\.title) == ["MiniMax-M*", "speech-hd", "image-01"])
        #expect(model.metrics.count == 3)
        #expect(model.usageNotes.isEmpty)
        #expect(model.metrics.allSatisfy { $0.percentStyle == .used })

        let primary = try #require(model.metrics.first)
        #expect(abs(primary.percent - (Double(50) / Double(1500) * 100)) < 0.01)
        #expect(primary.percentLabel.contains("used"))
        #expect(primary.resetText == "Resets in 3h")
        #expect(primary.detailLeftText == nil)
        #expect(primary.detailRightText == nil)

        let speech = try #require(model.metrics.dropFirst().first)
        #expect(speech.resetText == "Resets in 5h")
        #expect(speech.detailLeftText == nil)
        #expect(speech.detailRightText == nil)

        let image = try #require(model.metrics.last)
        #expect(image.resetText == "Resets in 1d 2h")
        #expect(image.detailLeftText == nil)
        #expect(image.detailRightText == nil)
        #expect(!model.metrics.contains(where: { $0.title == "Prompts" }))
    }

    @Test
    func `minimax card model shows overflow model reset details in usage notes`() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let metadata = try #require(ProviderDefaults.metadata[.minimax])
        let snapshot = MiniMaxUsageSnapshot(
            planName: "Max",
            availablePrompts: 1500,
            currentPrompts: 50,
            remainingPrompts: 1450,
            windowMinutes: 300,
            usedPercent: Double(50) / Double(1500) * 100,
            resetsAt: now.addingTimeInterval(12 * 60 * 60),
            updatedAt: now,
            modelEntries: [
                MiniMaxModelUsageEntry(
                    modelName: "MiniMax-M*",
                    sessionTotal: 1500,
                    sessionUsed: 50,
                    sessionRemaining: 1450,
                    sessionResetsAt: now.addingTimeInterval(3 * 60 * 60),
                    weeklyTotal: nil,
                    weeklyUsed: nil,
                    weeklyRemaining: nil,
                    isWeeklyUnlimited: true),
                MiniMaxModelUsageEntry(
                    modelName: "speech-hd",
                    sessionTotal: 4000,
                    sessionUsed: 0,
                    sessionRemaining: 4000,
                    sessionResetsAt: now.addingTimeInterval(5 * 60 * 60),
                    weeklyTotal: 28000,
                    weeklyUsed: 0,
                    weeklyRemaining: 28000,
                    isWeeklyUnlimited: false),
                MiniMaxModelUsageEntry(
                    modelName: "image-01",
                    sessionTotal: 50,
                    sessionUsed: 0,
                    sessionRemaining: 50,
                    sessionResetsAt: now.addingTimeInterval(26 * 60 * 60),
                    weeklyTotal: 350,
                    weeklyUsed: 0,
                    weeklyRemaining: 350,
                    isWeeklyUnlimited: false),
                MiniMaxModelUsageEntry(
                    modelName: "video-01",
                    sessionTotal: 100,
                    sessionUsed: 10,
                    sessionRemaining: 90,
                    sessionResetsAt: now.addingTimeInterval(7 * 60 * 60),
                    weeklyTotal: 700,
                    weeklyUsed: 10,
                    weeklyRemaining: 690,
                    isWeeklyUnlimited: false),
            ])
            .toUsageSnapshot()

        let model = UsageMenuCardView.Model.make(.init(
            provider: .minimax,
            metadata: metadata,
            snapshot: snapshot,
            credits: nil,
            creditsError: nil,
            dashboard: nil,
            dashboardError: nil,
            tokenSnapshot: nil,
            tokenError: nil,
            account: AccountInfo(email: nil, plan: nil),
            isRefreshing: false,
            lastError: nil,
            usageBarsShowUsed: false,
            resetTimeDisplayStyle: .countdown,
            tokenCostUsageEnabled: false,
            showOptionalCreditsAndExtraUsage: true,
            hidePersonalInfo: false,
            now: now))

        #expect(model.metrics.map(\.title) == ["MiniMax-M*", "speech-hd", "image-01"])
        #expect(model.metrics.allSatisfy { $0.percentStyle == .left })
        let primary = try #require(model.metrics.first)
        #expect(abs(primary.percent - (Double(1450) / Double(1500) * 100)) < 0.01)
        #expect(primary.percentLabel.contains("left"))
        #expect(model.usageNotes == ["video-01: Resets in 7h"])
    }
}
