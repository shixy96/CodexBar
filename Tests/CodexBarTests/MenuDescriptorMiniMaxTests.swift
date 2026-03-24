import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

@MainActor
struct MenuDescriptorMiniMaxTests {
    @Test
    func `minimax menu renders model reset lines`() throws {
        let suite = "MenuDescriptorMiniMaxTests-model-details"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        let now = Date()

        let settings = SettingsStore(
            userDefaults: defaults,
            configStore: testConfigStore(suiteName: suite),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
        settings.statusChecksEnabled = false

        let store = UsageStore(
            fetcher: UsageFetcher(environment: [:]),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings)
        let minimaxSnapshot = MiniMaxUsageSnapshot(
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
        store._setSnapshotForTesting(minimaxSnapshot.toUsageSnapshot(), provider: .minimax)

        let descriptor = MenuDescriptor.build(
            provider: .minimax,
            store: store,
            settings: settings,
            account: AccountInfo(email: nil, plan: nil),
            updateReady: false,
            includeContextualActions: false)

        let textLines = descriptor.sections
            .flatMap(\.entries)
            .compactMap { entry -> String? in
                guard case let .text(text, _) = entry else { return nil }
                return text
            }

        #expect(textLines.contains(where: { $0.hasPrefix("MiniMax-M*: Resets in ") }))
        #expect(textLines.contains(where: { $0.hasPrefix("speech-hd: Resets in ") }))
        #expect(textLines.contains(where: { $0.hasPrefix("image-01: Resets in ") }))
        #expect(!textLines.contains(where: { $0.contains("weekly ") }))
    }
}
