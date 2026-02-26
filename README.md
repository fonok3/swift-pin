[![CI](https://github.com/fonok3/swift-pin/actions/workflows/ci.yml/badge.svg)](https://github.com/fonok3/swift-pin/actions/workflows/ci.yml)
[![](https://img.shields.io/badge/Swift-5.10%2B-F05138?logo=swift&logoColor=white)](https://swift.org)
[![](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS%20%7C%20Linux-blue)]()

# Pin

Opinionated compile-time dependency injection for Swift.

## The Idea

Most DI frameworks give you a runtime container and ask you to register, resolve, and manage object lifetimes. Pin doesn't. Pin's opinion is simpler:

**Your dependency graph is just `@MainActor` classes with `lazy var` properties.**

`lazy var` *is* the lifecycle. There are no scopes, no containers, no service locators. A dependency is created once, on first access, and lives as long as its component. Swift already has the mechanism; Pin just generates the boilerplate that wires it up.

Pin never leaks into your implementations. Your view models, services, and other types use plain initializer parameters: no framework imports, no property wrappers, no protocol conformances. The component is the only layer that knows Pin exists. Everything below it is just normal Swift code you can instantiate and test directly.

```swift
// Your implementation. No Pin import. No framework types. Just a plain init.
public final class FeatureViewModel {
    private let logger: Logger
    public init(logger: Logger) { self.logger = logger }
}

// The component is the only thing that touches Pin.
@PinComponent
@MainActor public final class AppComponent {
    public lazy var logger: Logger = .init()

    @PinSubcomponent var feature: FeatureComponent
}

@PinComponent(Logger.self)
@MainActor public final class FeatureComponent {
    public lazy var viewModel = FeatureViewModel(logger: dependency.logger)
}
```

The compiler type-checks the entire graph. If a parent can't provide what a child needs, you get a build error, not a runtime crash.

## How It Works

Pin has two compile-time parts:

1. **`@PinComponent` macro** generates a `Dependency` protocol and `init(dependency:)` for each component. With no arguments, it's a root (no dependencies). With types listed, those become the dependency contract.
2. **`PinPlugin` build tool** scans your source files per target and generates `PinGenerated.swift` with `Providing` protocols and forwarding extensions that wire parent to child.

Components are `@MainActor` classes because `lazy var` is not thread-safe: concurrent first access is undefined behavior. Actor isolation eliminates this entirely. The macros enforce it.

Swift's access modifiers control what enters the graph. `public` properties are visible cross-target. `internal` properties are visible within the same target. `private` properties stay out entirely. No framework-specific annotations, just standard Swift.

## Usage

### Components

A root component has no dependencies. A child lists what it needs:

```swift
import Pin

// Root: no arguments
@PinComponent
@MainActor public final class AppComponent {
    public lazy var logger: Logger = .init()
    public lazy var httpClient: HTTPClient = .init()

    @PinSubcomponent var feature: FeatureComponent
    @PinSubcomponent var settings: SettingsComponent
}

// Child: declares Logger as a dependency
@PinComponent(Logger.self)
@MainActor public final class FeatureComponent {
    public lazy var viewModel = FeatureViewModel(logger: dependency.logger)
}
```

`@PinSubcomponent` generates a lazy backing store and injects `self` as the dependency. The property must be a plain `var` with a type annotation, no `lazy`, no initializer.

For named dependencies (multiple instances of the same type), use the verbose form:

```swift
@PinComponent(dependencies: [PinDependency(Logger.self, named: "networkLogger")])
```

### Providers

Not every component needs to be a `@PinSubcomponent`. Use `provider:` for components whose lifetime you manage yourself:

```swift
@PinComponent(Logger.self, provider: AppComponent.self)
@MainActor public final class CarPlayComponent {
    public lazy var dashboard = CarPlayDashboard(logger: dependency.logger)
}
```

Pin generates `extension AppComponent: CarPlayComponentDependency {}` so you can create the component manually:

```swift
// You control the lifetime: create and destroy as needed
carPlayComponent = CarPlayComponent(dependency: appComponent)
```

Both `@PinSubcomponent` and `provider:` are compile-time safe. The difference is ownership: `@PinSubcomponent` ties the child's lifetime to the parent, `provider:` leaves it to you.

## Testing

Pin follows the Dependency Inversion Principle strictly. Your implementations never import Pin; they use plain initializer parameters. Test them directly:

```swift
let viewModel = FeatureViewModel(logger: MockLogger())
viewModel.doSomething()
#expect(mockLogger.lastMessage == "did something")
```

No containers to configure. No mocks to register. Nothing to tear down.

## Landscape

Swift DI frameworks generally fall into two camps: **runtime containers** (Swinject, Factory) that register and resolve at runtime, and **code-generated hierarchies** (Needle) that verify the graph at compile time. Pin is in the second camp, closest to Needle architecturally, but without the base class, without the runtime registry, and using Swift macros instead of a separate code generator.

|  | Pin | Swinject | Needle | Factory | swift-dependencies | SwiftUI Environment |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| Compile-time safe | yes | no | yes | partial | partial | no |
| No framework leakage | yes | optional | no (`Component<T>`) | no (`@Injected`) | no (`@Dependency`) | no (`@Environment`) |
| Works outside views | yes | yes | yes | yes | yes | no |
| No runtime container | yes | no | no | no | no | no |

Pin's tradeoff: it requires `@MainActor` classes and an acyclic component tree. Properties flow freely from any ancestor to any descendant, but there is no runtime resolution or dynamic swapping. If your app needs those, a container-based framework is a better fit.

## Performance

**Runtime:** Nothing from Pin ships in your binary. The generated protocols and forwarding properties are inlined by the compiler. No allocations, no containers, no dynamic dispatch.

**Build time:** Two additions per target: a macro expansion (in-process, generates declarations) and a build plugin (separate process, parses source files, writes one `PinGenerated.swift`). The plugin walks the AST without type-checking. Neither step scales with project size, only with the number of `@PinComponent` classes in the target.

## Requirements

- Swift 5.10+
- Apple platforms: iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+, visionOS 1+
- Linux is supported (SwiftSyntax and Foundation work on Linux via swift-corelibs-foundation)
- Pin is compile-time only -- it adds no runtime code to your binary.

## Installation

Add Pin to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/fonok3/swift-pin.git", from: "0.1.0"),
]
```

Then add the library and plugin to each target:

```swift
.target(
    name: "MyFeature",
    dependencies: [
        .product(name: "Pin", package: "swift-pin"),
    ],
    plugins: [
        .plugin(name: "PinPlugin", package: "swift-pin"),
    ]
)
```

## License

MIT. See [LICENSE](LICENSE) for details.
