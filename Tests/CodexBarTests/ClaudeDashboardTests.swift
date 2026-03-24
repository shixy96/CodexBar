import AppKit
import CodexBarCore
import Testing
@testable import CodexBar

@MainActor
struct ClaudeDashboardTests {
    private func makeStatusBarForTesting() -> NSStatusBar {
        let env = ProcessInfo.processInfo.environment
        if env["GITHUB_ACTIONS"] == "true" || env["CI"] == "true" {
            return .system
        }
        return NSStatusBar()
    }

    private func makeSettings() -> SettingsStore {
        let suite = "ClaudeDashboardTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        return SettingsStore(
            userDefaults: defaults,
            configStore: configStore,
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
    }

    @Test
    func `claude subscription dashboard URL prefers subscription page`() {
        let settings = self.makeSettings()
        settings.statusChecksEnabled = false
        settings.refreshFrequency = .manual

        let fetcher = UsageFetcher()
        let store = UsageStore(fetcher: fetcher, browserDetection: BrowserDetection(cacheTTL: 0), settings: settings)
        let identity = ProviderIdentitySnapshot(
            providerID: .claude,
            accountEmail: nil,
            accountOrganization: nil,
            loginMethod: "Pro")
        store._setSnapshotForTesting(
            UsageSnapshot(primary: nil, secondary: nil, updatedAt: Date(), identity: identity),
            provider: .claude)
        let controller = StatusItemController(
            store: store,
            settings: settings,
            account: fetcher.loadAccountInfo(),
            updater: DisabledUpdaterController(),
            preferencesSelection: PreferencesSelection(),
            statusBar: self.makeStatusBarForTesting())

        let dashboardURL = controller.dashboardURL(for: .claude)?.absoluteString
        let expectedURL = ProviderDescriptorRegistry
            .descriptor(for: .claude)
            .metadata
            .subscriptionDashboardURL
        #expect(dashboardURL == expectedURL)
    }

    @Test(arguments: ["web", "Profile", "Browser profile"])
    func `claude consumer dashboard URL prefers claude app page`(loginMethod: String) {
        let settings = self.makeSettings()
        settings.statusChecksEnabled = false
        settings.refreshFrequency = .manual

        let fetcher = UsageFetcher()
        let store = UsageStore(fetcher: fetcher, browserDetection: BrowserDetection(cacheTTL: 0), settings: settings)
        let identity = ProviderIdentitySnapshot(
            providerID: .claude,
            accountEmail: nil,
            accountOrganization: nil,
            loginMethod: loginMethod)
        store._setSnapshotForTesting(
            UsageSnapshot(primary: nil, secondary: nil, updatedAt: Date(), identity: identity),
            provider: .claude)
        let controller = StatusItemController(
            store: store,
            settings: settings,
            account: fetcher.loadAccountInfo(),
            updater: DisabledUpdaterController(),
            preferencesSelection: PreferencesSelection(),
            statusBar: self.makeStatusBarForTesting())

        let dashboardURL = controller.dashboardURL(for: .claude)?.absoluteString
        let expectedURL = ProviderDescriptorRegistry
            .descriptor(for: .claude)
            .metadata
            .subscriptionDashboardURL
        #expect(dashboardURL == expectedURL)
    }

    @Test
    func `claude web source dashboard URL prefers claude app page when login method missing`() {
        let settings = self.makeSettings()
        settings.statusChecksEnabled = false
        settings.refreshFrequency = .manual

        let fetcher = UsageFetcher()
        let store = UsageStore(fetcher: fetcher, browserDetection: BrowserDetection(cacheTTL: 0), settings: settings)
        store.lastSourceLabels[.claude] = "web"
        let controller = StatusItemController(
            store: store,
            settings: settings,
            account: fetcher.loadAccountInfo(),
            updater: DisabledUpdaterController(),
            preferencesSelection: PreferencesSelection(),
            statusBar: self.makeStatusBarForTesting())

        let dashboardURL = controller.dashboardURL(for: .claude)?.absoluteString
        let expectedURL = ProviderDescriptorRegistry
            .descriptor(for: .claude)
            .metadata
            .subscriptionDashboardURL
        #expect(dashboardURL == expectedURL)
    }

    @Test
    func `claude quota cost routes to subscription page even without login method`() {
        let settings = self.makeSettings()
        settings.statusChecksEnabled = false
        settings.refreshFrequency = .manual

        let fetcher = UsageFetcher()
        let store = UsageStore(fetcher: fetcher, browserDetection: BrowserDetection(cacheTTL: 0), settings: settings)
        let cost = ProviderCostSnapshot(
            used: 50,
            limit: 100,
            currencyCode: "Quota",
            updatedAt: Date())
        store._setSnapshotForTesting(
            UsageSnapshot(primary: nil, secondary: nil, providerCost: cost, updatedAt: Date()),
            provider: .claude)
        let controller = StatusItemController(
            store: store,
            settings: settings,
            account: fetcher.loadAccountInfo(),
            updater: DisabledUpdaterController(),
            preferencesSelection: PreferencesSelection(),
            statusBar: self.makeStatusBarForTesting())

        let dashboardURL = controller.dashboardURL(for: .claude)?.absoluteString
        let expectedURL = ProviderDescriptorRegistry
            .descriptor(for: .claude)
            .metadata
            .subscriptionDashboardURL
        #expect(dashboardURL == expectedURL)
    }

    @Test
    func `claude api user routes to console dashboard`() {
        let settings = self.makeSettings()
        settings.statusChecksEnabled = false
        settings.refreshFrequency = .manual

        let fetcher = UsageFetcher()
        let store = UsageStore(fetcher: fetcher, browserDetection: BrowserDetection(cacheTTL: 0), settings: settings)
        let identity = ProviderIdentitySnapshot(
            providerID: .claude,
            accountEmail: nil,
            accountOrganization: nil,
            loginMethod: "api")
        store._setSnapshotForTesting(
            UsageSnapshot(primary: nil, secondary: nil, updatedAt: Date(), identity: identity),
            provider: .claude)
        store.lastSourceLabels[.claude] = "cli"
        let controller = StatusItemController(
            store: store,
            settings: settings,
            account: fetcher.loadAccountInfo(),
            updater: DisabledUpdaterController(),
            preferencesSelection: PreferencesSelection(),
            statusBar: self.makeStatusBarForTesting())

        let dashboardURL = controller.dashboardURL(for: .claude)?.absoluteString
        let expectedURL = ProviderDescriptorRegistry
            .descriptor(for: .claude)
            .metadata
            .dashboardURL
        #expect(dashboardURL == expectedURL)
        // Ensure it does NOT route to the subscription page
        let subscriptionURL = ProviderDescriptorRegistry
            .descriptor(for: .claude)
            .metadata
            .subscriptionDashboardURL
        #expect(dashboardURL != subscriptionURL)
    }

    @Test
    func `claude oauth source routes to subscription page when login method missing`() {
        let settings = self.makeSettings()
        settings.statusChecksEnabled = false
        settings.refreshFrequency = .manual

        let fetcher = UsageFetcher()
        let store = UsageStore(fetcher: fetcher, browserDetection: BrowserDetection(cacheTTL: 0), settings: settings)
        store.lastSourceLabels[.claude] = "oauth"
        let controller = StatusItemController(
            store: store,
            settings: settings,
            account: fetcher.loadAccountInfo(),
            updater: DisabledUpdaterController(),
            preferencesSelection: PreferencesSelection(),
            statusBar: self.makeStatusBarForTesting())

        let dashboardURL = controller.dashboardURL(for: .claude)?.absoluteString
        let expectedURL = ProviderDescriptorRegistry
            .descriptor(for: .claude)
            .metadata
            .subscriptionDashboardURL
        #expect(dashboardURL == expectedURL)
    }
}
