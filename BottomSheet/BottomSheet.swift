import Foundation
import UIKit
import WebKit.WKWebView

public protocol BottomSheetProtocol {
    typealias BottomSheetClosure = () -> Void
    typealias BottomSheetPositionChangedClosure = (CGFloat) -> Void
    /// Position for the `BottomSheet` to animate to on initial presentation. `dismissed` is not a valid  value.
    var initialPresentationPosition: BottomSheetPosition { get set }

    /// Closure to be called once the `BottomSheet` has been dismissed.
    var bottomSheetDismissedClosure: BottomSheetClosure? { get set }

    /// Closure to be called once the `BottomSheet` has been presented.
    var bottomSheetPresentedClosure: BottomSheetClosure? { get set }

    /// Closure to be called once the `BottomSheet` has been expanded (to the 'tall' state).
    var bottomSheetExpandedClosure: BottomSheetClosure? { get set }

    /// Closure to be called once the `BottomSheet` has been collapsed (to the 'short' state).
    var bottomSheetCollapsedClosure: BottomSheetClosure? { get set }

    /// Closure used to track the change in position of the `BottomSheet` as it is moved by the user in real time.
    /// The value is given as an offset from the top of the presenting view. When the `BottomSheet` is animated
    /// into a final position when the user releases the handle, this closure will be fired once more at the end of the animation.
    var bottomSheetPositionChangedClosure: BottomSheetPositionChangedClosure? { get set }

    /// Configuration used to customize the presentation, dismissal and change in position animations.
    var bottomSheetAnimationConfiguration: BottomSheetAnimationConfiguration { get set }

    /// Override the default screen percentage coverage for the `BottomSheet` for the expanded and collapsed states.
    /// The value for `collapsed` should be lower than the value for `expanded` and greater than 0.0.
    /// - Parameters:
    ///   - collapsed: the percentage of the screen that the `BottomSheet` should cover when collapsed,
    ///   described as a number between 0.0 and 1.0
    ///   - expanded: the percentage of the screen that the `BottomSheet` should cover when expanded,
    ///   described as a number between 0.0 and 1.0
    func setBottomSheetCoveragePercentage(collapsed: CGFloat, expanded: CGFloat)

    /// Initializer for BottomSheet
    /// - Parameters:
    ///   - title: Title for the header section of the `BottomSheet`
    ///   - subtitle: Subtitle for the header section of the `BottomSheet`
    ///   - contentView: Content view for the `BottomSheet` to show below the header.
    init(title: String?, subtitle: String?, contentView: UIView)

    /// Function to call to present the `BottomSheet` within a parent view.
    /// - Parameter view: Parent view to present the `BottomSheet`
    func present(in view: UIView)
}

/// `BottomSheetPosition` describes the discrete positions that the `BottomSheet` can settle into.
public enum BottomSheetPosition {
    /// The `BottomSheet` has been dismissed and is no longer visible to the user.
    case dismissed
    /// The `BottomSheet` is presented in a "short" state.
    case collapsed
    /// The `BottomSheet` is presented in a "tall" state.
    case expanded
}

/// `BottomSheetAnimationConfiguration` describes the animation properties to be used when the sheet is presented, and when it locks into
/// one of its positions. These properties correspond to the properties in
/// `UIView.animate(withDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)`
public struct BottomSheetAnimationConfiguration {
    var animationDuration: TimeInterval = 0.6
    var springDampening: CGFloat = 0.8
    var springVelocity: CGFloat = 1.0
    var animationOptions: UIView.AnimationOptions = [.curveEaseInOut]
}

class BottomSheet: UIView, BottomSheetProtocol {
    var bottomSheetAnimationConfiguration = BottomSheetAnimationConfiguration()
    var bottomSheetPresentedClosure: BottomSheetClosure?
    var bottomSheetDismissedClosure: BottomSheetClosure?
    var bottomSheetExpandedClosure: BottomSheetClosure?
    var bottomSheetCollapsedClosure: BottomSheetClosure?
    var bottomSheetPositionChangedClosure: BottomSheetPositionChangedClosure?
    var initialPresentationPosition: BottomSheetPosition = .collapsed {
        willSet(newPosition) {
            if newPosition == .dismissed {
                fatalError("Dismissed is not a valid initial presentation position")
            }
        }
    }

    /// Internal UIStackView which contains the header and content view.
    private let stackView = UIStackView()
    private let panGestureRecognizer = UIPanGestureRecognizer()
    private var topAnchorConstraint: NSLayoutConstraint!
    private weak var presentingView: UIView?
    private var expandedStateCoveragePercentage: CGFloat = 0.9
    private var collapsedStateCoveragePercentage: CGFloat = 0.5

    private var title: String?
    private var subtitle: String?
    private var contentView: UIView

    /// Variable used to keep track of original top anchor constant when calculating pan gesture offset.
    private var originalConstant: CGFloat = 0

    required init(title: String?, subtitle: String?, contentView: UIView) {
        self.contentView = contentView
        super.init(frame: .zero)
        self.title = title
        self.subtitle = subtitle
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Corner Radius
        self.layer.cornerRadius = 10
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        self.backgroundColor = .systemBackground
        self.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        self.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.pinToParent()
        
        let headerView = BottomSheetHeaderView(title: title, subtitle: subtitle, closeAction:
                                                UIAction(handler: { [weak self] _ in
                                                    self?.dismiss()
                                                }))

        stackView.addArrangedSubview(headerView)

        // Pan Gesture Recognizer
        headerView.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.addTarget(self, action: #selector(handlePan(recognizer:)))

        // Content View
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // If the content view is a scrollview, add it directly to the StackView, otherwise embed in a ScrollView
        if contentView is UIScrollView || contentView is WKWebView {
            self.stackView.addArrangedSubview(contentView)
        } else {
            let contentScrollView = UIScrollView()
            contentScrollView.translatesAutoresizingMaskIntoConstraints = false
            contentScrollView.addSubview(contentView)
            contentView.pinToParent()
            self.stackView.addArrangedSubview(contentScrollView)
        }

        // Add a tiny drop shadow
        self.layer.shadowColor = UIColor.systemGray.cgColor
        self.layer.shadowOpacity = 0.15
    }

    func present(in presentingView: UIView) {
        self.presentingView = presentingView
        presentingView.addSubview(self)

        // Start at bottom with a fixed height to prevent weird resizing animations
        let heightConstraint = self.heightAnchor.constraint(equalToConstant: presentingView.frame.height)
        heightConstraint.isActive = true

        let topConstant = self.getTopOffsetForPosition(.dismissed)
        self.topAnchorConstraint = self.topAnchor.constraint(equalTo: presentingView.safeAreaLayoutGuide.topAnchor,
                                                             constant: topConstant)
        self.topAnchorConstraint.isActive = true
        self.widthAnchor.constraint(equalTo: presentingView.widthAnchor).isActive = true
        self.centerXAnchor.constraint(equalTo: presentingView.centerXAnchor).isActive = true
        presentingView.layoutIfNeeded()
        
        UIView.animate(withDuration: self.bottomSheetAnimationConfiguration.animationDuration,
                       delay: 0.0,
                       usingSpringWithDamping: self.bottomSheetAnimationConfiguration.springDampening,
                       initialSpringVelocity: self.bottomSheetAnimationConfiguration.springVelocity,
                       options: self.bottomSheetAnimationConfiguration.animationOptions,
                       animations: {
                        self.topAnchorConstraint?.constant =
                            self.getTopOffsetForPosition(self.initialPresentationPosition)
                        presentingView.layoutIfNeeded()
                       }, completion: { _ in
                        heightConstraint.isActive = false
                        self.bottomAnchor.constraint(equalTo: presentingView.bottomAnchor).isActive = true
                        
                        UIAccessibility.post(notification: .screenChanged, argument: self)
                        let position = self.getTopOffsetForPosition(self.initialPresentationPosition)
                        self.bottomSheetPositionChangedClosure?(position)
                       })
    }
    
    func dismiss() {
        self.animateToPosition(.dismissed)
    }
    
    func setBottomSheetCoveragePercentage(collapsed: CGFloat, expanded: CGFloat) {
        guard collapsed > 0.0 && collapsed < 1.0 && expanded > 0.0 && expanded > collapsed else {
            fatalError("Custom BottomSheet coverage percentages are weird")
        }

        self.collapsedStateCoveragePercentage = collapsed
        self.expandedStateCoveragePercentage = expanded
    }

    @objc
    private func handlePan(recognizer: UIPanGestureRecognizer) {
        guard let presentingView = self.presentingView else {
            return
        }

        switch recognizer.state {
        case .began:
            originalConstant = self.topAnchorConstraint.constant
        case .changed:
            let newConstant = originalConstant + recognizer.translation(in: self).y
            self.topAnchorConstraint.constant = newConstant
            self.bottomSheetPositionChangedClosure?(newConstant)
        case .ended:
            let height = presentingView.frame.height
            let offset = originalConstant + recognizer.translation(in: self).y
            let percentage = 1 - (offset/height)
            let newPosition = self.getPositionForSheetCoverage(percentage)
            self.animateToPosition(newPosition)
        default:
            break
        }
    }

    private func getTopOffsetForPosition(_ position: BottomSheetPosition) -> CGFloat {
        guard let presentingView = self.presentingView else {
            fatalError("BottomSheet presenting view was nil")
        }

        switch position {
        case .dismissed:
            return presentingView.frame.height
        case .collapsed:
            return presentingView.frame.height * (1 - collapsedStateCoveragePercentage)
        case .expanded:
            return presentingView.frame.height * (1 - expandedStateCoveragePercentage)
        }
    }
    
    /// Determines the correct ending position when the `BottomSheet` has been released at a certain coverage percentage.
    /// - Parameter percentage: The amount of the screen that the `BottomSheet` is covering.
    /// - Returns: The correct position for the `BottomSheet` to settle into.
    private func getPositionForSheetCoverage(_ percentage: CGFloat) -> BottomSheetPosition {
        if percentage > 1.0 || abs(percentage - expandedStateCoveragePercentage) <
            abs(percentage - collapsedStateCoveragePercentage) {
            return .expanded
        } else if abs(percentage - collapsedStateCoveragePercentage) < abs(percentage - 0) {
            return .collapsed
        } else {
            return .dismissed
        }
    }

    private func animateToPosition(_ position: BottomSheetPosition) {
        var completion: (Bool) -> Void
        switch position {
        case .expanded:
            completion = { [weak self] _ in
                self?.bottomSheetExpandedClosure?()
                if let position = self?.getTopOffsetForPosition(.expanded) {
                    self?.bottomSheetPositionChangedClosure?(position)
                }
            }
        case .collapsed:
            completion = { [weak self] _ in
                self?.bottomSheetCollapsedClosure?()
                if let position = self?.getTopOffsetForPosition(.collapsed) {
                    self?.bottomSheetPositionChangedClosure?(position)
                }
            }
        case .dismissed:
            completion = { [weak self] _ in
                self?.bottomSheetDismissedClosure?()
                if let position = self?.getTopOffsetForPosition(.dismissed) {
                    self?.bottomSheetPositionChangedClosure?(position)
                }
                self?.removeFromSuperview()
            }
        }

        UIView.animate(withDuration: self.bottomSheetAnimationConfiguration.animationDuration,
                       delay: 0.0,
                       usingSpringWithDamping: self.bottomSheetAnimationConfiguration.springDampening,
                       initialSpringVelocity: self.bottomSheetAnimationConfiguration.springVelocity,
                       options: self.bottomSheetAnimationConfiguration.animationOptions,
                       animations: {
                        self.topAnchorConstraint.constant = self.getTopOffsetForPosition(position)
                        self.presentingView?.layoutIfNeeded()
                       }, completion: completion)
    }

    override func accessibilityPerformEscape() -> Bool {
        self.dismiss()
        return true
    }
}

private class BottomSheetHeaderView: UIView {
    var title: String?
    var subtitle: String?
    var closeAction: UIAction

    init(title: String?, subtitle: String?, closeAction: UIAction) {
        self.closeAction = closeAction
        super.init(frame: .zero)
        self.title = title
        self.subtitle = subtitle
        self.setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let stackView = UIStackView()
        stackView.spacing = 8
        stackView.axis = .vertical
        self.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .equalSpacing
        stackView.pinToParent()

        // Spacer
        stackView.addArrangedSubview(UIView())

        // Handle View
        let handleView = setUpHandleView()
        stackView.addArrangedSubview(handleView)

        // Horizontal Stack view that contains the header text and close button
        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.distribution = .equalCentering
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false

        // Title and Subtitle labels
        let textStackView = self.setUpTextViews()

        // Close button (TODO: Make this more modular, e.g. different button types and actions)
        let buttonContainer = self.setUpCloseButton()

        // TODO: RTL support? Would place the close button on the left
        // Spacer View on left
        horizontalStackView.addArrangedSubview(UIView())
        horizontalStackView.addArrangedSubview(textStackView)
        horizontalStackView.addArrangedSubview(buttonContainer)
        
        // This helps the header text stay centered while resizing, but won't overlap the close button
        textStackView.centerXAnchor.constraint(equalTo: horizontalStackView.centerXAnchor).isActive = true

        stackView.addArrangedSubview(horizontalStackView)
        stackView.addArrangedSubview(UIView())
    }
    
    private func setUpHandleView() -> UIView {
        let handleView = UIView()
        handleView.backgroundColor = .systemGray5
        handleView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        handleView.heightAnchor.constraint(equalToConstant: 4).isActive = true
        handleView.layer.cornerRadius = 2
        let handleStackView = UIStackView(arrangedSubviews: [UIView(), handleView, UIView()])
        handleStackView.distribution = .equalSpacing
        return handleStackView
    }
    
    private func setUpTextViews() -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
        titleLabel.text = self.title
        titleLabel.isAccessibilityElement = false

        let subtitleLabel = UILabel()
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textAlignment = .center
        subtitleLabel.text = self.subtitle
        subtitleLabel.textColor = .systemGray
        subtitleLabel.numberOfLines = 2
        subtitleLabel.isAccessibilityElement = false

        let textStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStackView.accessibilityLabel = (self.title ?? "") + ". " + (self.subtitle ?? "")
        textStackView.isAccessibilityElement = true
        textStackView.axis = .vertical
        return textStackView
    }
    
    private func setUpCloseButton() -> UIView {
        let buttonContainer = UIView()
        let button = HighlightableButton()
        button.addAction(closeAction, for: .touchUpInside)
        button.setImage(UIImage.init(named: "close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .label
        button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 1).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(button)
        button.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor, constant: -16).isActive = true
        button.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor).isActive = true
        button.topAnchor.constraint(equalTo: buttonContainer.topAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor).isActive = true
        return buttonContainer
    }
}

private class HighlightableButton: UIButton {
    init() {
        super.init(frame: .zero)
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .systemGray5 : .systemBackground
        }
    }}

extension UIView {
    func pinToParent() {
        guard let parent = self.superview else {
            return
        }

        NSLayoutConstraint.activate([
            self.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            self.topAnchor.constraint(equalTo: parent.topAnchor),
            self.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ])
    }
}
