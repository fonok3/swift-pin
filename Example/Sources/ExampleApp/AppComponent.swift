import FeatureOne
import FeatureTwo
import Pin

@PinComponent
@MainActor final class AppComponent {
    lazy var config: AppConfig = .init(appName: "PinExample")

    @PinSubcomponent var featureOne: FeatureOneComponent
    @PinSubcomponent var featureTwo: FeatureTwoComponent
}
