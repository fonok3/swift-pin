import Testing

@Suite
@MainActor
struct IntegrationTests {
    @Test
    func rootComponentInstantiates() {
        let app = AppComponent()
        #expect(app.logger.log("hello") == "[LOG] hello")
    }

    @Test
    func subcomponentAccessesParentDependency() {
        let app = AppComponent()
        let result = app.feature.dashboard.show()
        #expect(result == "[LOG] Dashboard shown")
    }

    @Test
    func subcomponentIsLazilyInitialized() {
        let app = AppComponent()
        // Accessing the subcomponent twice returns the same instance.
        let first = app.feature
        let second = app.feature
        #expect(first === second)
    }

    @Test
    func rootPropertiesAreLazilyInitialized() {
        let app = AppComponent()
        let first = app.logger
        let second = app.logger
        #expect(first === second)
    }

    @Test
    func grandchildAccessesAncestorDependency() {
        let app = AppComponent()
        // DetailComponent needs Logger, which is defined on AppComponent (grandparent).
        // FeatureComponent declares Logger as a dependency, so the macro generates
        // a forwarding property that makes it visible to DetailComponent.
        let result = app.feature.detail.detail
        #expect(result == "[LOG] Detail loaded")
    }

    @Test
    func internalPropertyFlowsThroughInternalProviding() {
        let app = AppComponent()
        // ProfileComponent needs Config, which is an internal property on
        // SettingsComponent. This works because the plugin generates an
        // InternalProviding protocol that carries internal properties
        // to subcomponents within the same target.
        let result = app.settings.profile.greeting
        #expect(result == "Hello from TestApp")
    }
}
