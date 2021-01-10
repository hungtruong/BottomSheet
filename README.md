# BottomSheet

BottomSheet is a reusable component built in Swift that provides a modal container that can be displayed to a user. The BottomSheet supports a user provided title, subtitle and content view which is embedded below a header. It supports scrolling in views horizontall and vertically, as well as traditional scroll views such as `MKMapView`.

## Usage

Create a `BottomSheet` with an optional `title` and `subtitle`, and a required `contentView` of type `UIView`.

```swift
let bottomSheet = BottomSheet(title: action.title, subtitle: action.subtitle, contentView: contentView)
```

Present the `BottomSheet` by calling `present(in presentingView: UIView)` in the view you'd like it to be added to.

```swift
bottomSheet.present(in: self.view)
```

You can configure the intitial position for the `BottomSheet` to appear into, either `collapsed` (short) or `expanded` (tall), before presenting it.

```swift
bottomSheet.initialPresentationPosition = .expanded
bottomSheet.present(in: self.view)
```

You can also configure many other properties, including the percentage of the screen for the sheet to cover in `collapsed` and `expanded` modes, the animation properties, callbacks for when the sheet has settled in a position or dismissed, and even real time tracking while the user is dragging the sheet up and down.

```swift
// Set the sheet to have a shorter collapsed and expanded position than normal, at 20% and 60% of the screen's height.
bottomSheet.setBottomSheetCoveragePercentage(collapsed: 0.2, expanded: 0.6)

// Adjust the duration and other properties of the presentation and settling animations.
bottomSheet.bottomSheetAnimationConfiguration = BottomSheetAnimationConfiguration(animationDuration: 2.0, springDampening: 0.1, springVelocity: 5.0)

// Fire a closure when the bottomSheet has been dismissed.
bottomSheet.bottomSheetDismissedClosure = { print("bottom sheet was dismissed") }

// Fire a closure any time the bottomSheet is moved, while dragging and after a settling animation.
bottomSheet.bottomSheetPositionChangedClosure = { offset in print("bottom sheet was dragged to \(offset)") }

bottomSheet.present(in: self.view)
```

The `BottomSheet` can be dismissed by dragging it to the bottom of the screen or tapping the close button on the upper left corner of the header. It can also be dimissed programmatically.

```swift
bottomSheet.dismiss()
```

The project includes many demo usages of the `BottomSheet`, so feel free to experiment with other types of views.

## Accessibility

When Voiceover is active, `BottomSheet` automatically sets focus on itself when it is presented. The title and subtitle text are grouped in an accessibility element. The user can use the escape gesture to easily dismiss the `BottomSheet`.

## Known Issues

It is difficult to detect when a view behaves as a `ScrollView`, so there are a few hardcoded edge cases to handle them. If a certain type of view is not recognized as such, the view will need to be added as another case.

