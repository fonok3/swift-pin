@MainActor
func run() {
    let app = AppComponent()

    print("App: \(app.config.appName)")

    // FeatureTwo's Dashboard uses FeatureOne's Logger — wired automatically.
    app.featureTwo.dashboard.show()

    // Direct access to FeatureOne
    app.featureOne.analytics.track("app_launched")
    app.featureOne.logger.log("All wired up!")
}

run()
