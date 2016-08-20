//
//  FlexiblePathMenu.swift
//  Pods
//
//  Created by matrixs on 16/8/3.
//
//

import UIKit

public class FlexiblePathMenu: UIView, UIGestureRecognizerDelegate {
    
    public enum ItemViewAnimationType: Int {
        case Custom
        case RotateEquation
        case RotateLinear
    }
    
    private enum AnimationViewState: Int {
        case Expand
        case Shrink
    }
    
    public var centerView: UIView {
        didSet {
            addCenterView(centerView)
        }
    }
    
    private var containerViewForAnimation = UIView()
    
    public var itemViewAniamtionType: ItemViewAnimationType = .RotateEquation {
        didSet {
            if itemViewAniamtionType == .RotateLinear {
                fpmTimingFunction = FPMTimingFunction(name: FPMTimingFunction.FunctionIdentifier.kRSTimingFunctionLinear)
            }
        }
    }
    
    private var panGesture: UIPanGestureRecognizer {
        get {
            return UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        }
    }
    
    private var dialGesture: UIPanGestureRecognizer!
    
    private var tapGesture: UITapGestureRecognizer {
        get {
            return UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        }
    }
    
    public var draggable: Bool = false {
        didSet {
            if draggable {
                centerView.addGestureRecognizer(panGesture)
            } else {
                centerView.removeGestureRecognizer(panGesture)
            }
        }
    }
    
    public var scrollable: Bool = false {
        didSet {
            if scrollable {
                dialGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDialGesture))
                containerViewForAnimation.addGestureRecognizer(dialGesture)
            } else {
                containerViewForAnimation.removeGestureRecognizer(dialGesture)
            }
        }
    }
    
    public var antialias = false {
        didSet {
            self.layer.allowsEdgeAntialiasing = antialias
            centerView.layer.allowsEdgeAntialiasing = antialias
            itemViews.forEach { (view) in
                view.layer.allowsEdgeAntialiasing = antialias
            }
        }
    }
    
    private var itemViews = [UIView]()
    
    public var menuRadius: CGFloat = 100 {
        didSet {
            updateSize()
            itemViews.forEach { (view) in
                updateItemSize(view)
            }
        }
    }
    
    public var menuStartArc: Double = 0
    public var menuEndArc: Double = -M_PI
    
    public var scrollStartArc: Double = 0 {
        didSet {
            scrollStartArc = normalize(CGFloat(scrollStartArc))
            scrollStartBoundaryArc = scrollStartArc - normalize(atan2(maxItemWidth/2, menuRadius - maxItemHeight/2))
            scrollableOfWholeCircle = false
        }
    }
    public var scrollEndArc: Double = M_PI*2 {
        didSet {
            scrollEndArc = normalize(CGFloat(scrollEndArc))
            scrollEndBoundaryArc = scrollEndArc + normalize(atan2(maxItemWidth/2, menuRadius - maxItemHeight/2))
            scrollableOfWholeCircle = false
        }
    }
    private var scrollStartBoundaryArc: Double = 0
    private var scrollEndBoundaryArc: Double = 0
    
    public var scrollableOfWholeCircle = true
    
    private var rotateAngle: CGFloat = 0
    
    public var itemViewAnimationDuration: NSTimeInterval = 0.2
    
    private var animationComplete = true
    
    private var expandableState = false
    
    private var itemAnimViews = [UIView]()
    
    private var maxItemWidth: CGFloat = 0 {
        didSet {
            scrollStartBoundaryArc = scrollStartArc - normalize(atan2(maxItemWidth/2, menuRadius - maxItemHeight/2))
            scrollEndBoundaryArc = scrollEndArc + normalize(atan2(maxItemWidth/2, menuRadius - maxItemHeight/2))
        }
    }
    private var maxItemHeight: CGFloat = 0 {
        didSet {
            scrollStartBoundaryArc = scrollStartArc - normalize(atan2(maxItemWidth/2, menuRadius - maxItemHeight/2))
            scrollEndBoundaryArc = scrollEndArc + normalize(atan2(maxItemWidth/2, menuRadius - maxItemHeight/2))
        }
    }
    
    private var containerCenterX: CGFloat = 0
    private var containerCenterY: CGFloat = 0
    
    public enum Granularity: Int {
        case Point
        case CoustomNum
    }
    
    public var scrollAngleGranularity = Granularity.Point
    public var scrollMinimiumNum: Int = 1 {
        didSet {
            scrollMinimiumNum = scrollMinimiumNum - 1
            if scrollMinimiumNum <= 0 {
                scrollMinimiumNum = 1
            }
        }
    }
    
    private var receiveTouch = false
    
    weak public var clickDelegate: FPMItemsViewClickDelegate?
    
    @objc private func handlePanGesture(gesture: UIPanGestureRecognizer) {
        self.center = gesture.locationInView(superview)
        if animationComplete {
            itemAnimViews.removeAll()
            if expandableState {
                shrinkMenu()
            }
        }
    }
    
    private var beginAngle: CGFloat = 0
    
    public var fpmTimingFunction = FPMTimingFunction(name: FPMTimingFunction.FunctionIdentifier.kRSTimingFunctionEaseInEaseOut)
    
    @objc private func handleDialGesture(gesture: UIPanGestureRecognizer) {
        if scrollAngleGranularity == .CoustomNum {
            if gesture.state != .Began && gesture.state != .Changed {
                var angle: CGFloat = 0
                if itemViews.count == 1 {
                    angle = 0
                } else {
                    angle = CGFloat(menuEndArc - menuStartArc)/CGFloat(itemViews.count - 1)
                }
                angle = CGFloat(normalize(angle))*CGFloat(scrollMinimiumNum)
                rotateAngle = atan2(containerViewForAnimation.transform.b, containerViewForAnimation.transform.a)
                if rotateAngle/angle - round(rotateAngle/angle) != 0 {
                    let n = round(rotateAngle/angle)
                    rotateAngle = angle*n
                    UIView.animateWithDuration(0.06*Double(scrollMinimiumNum), animations: { [weak self] in
                        if let self_ = self {
                            self_.containerViewForAnimation.transform = CGAffineTransformMakeRotation(self_.rotateAngle)
                            self_.itemViews.forEach({ (view) in
                                view.transform = CGAffineTransformMakeRotation(-self_.rotateAngle)
                            })
                        }
                        })
                }
                return
            }
        }
        
        let point = point2Angle(gesture.locationInView(self))
        if !scrollableOfWholeCircle {
            var rad = normalize(point)
            if rad*scrollStartBoundaryArc < 0 {
                if rad < 0 {
                    rad += M_PI*2
                }
            }
            if rad < scrollStartBoundaryArc || rad > scrollEndBoundaryArc {
                if gesture.state == .Began {
                    receiveTouch = false
                }
                return
            }
        }
        if gesture.state == .Began {
            beginAngle = point
            receiveTouch = true
        } else if gesture.state == .Changed {
            if !receiveTouch {
                return
            }
            let angle = CGFloat(normalize(point)) - CGFloat(normalize(beginAngle))
            containerViewForAnimation.transform = CGAffineTransformRotate(containerViewForAnimation.transform, angle)
            itemViews.forEach({ (view) in
                view.transform = CGAffineTransformRotate(view.transform, -angle)
            })
            if !scrollableOfWholeCircle {
                rotateAngle = atan2(containerViewForAnimation.transform.b, containerViewForAnimation.transform.a)
                if Double(rotateAngle) <= (scrollStartArc - menuStartArc) && angle <= 0 {
                    rotateAngle = CGFloat(scrollStartArc - menuStartArc)
                    containerViewForAnimation.transform = CGAffineTransformMakeRotation(rotateAngle)
                    itemViews.forEach({ (view) in
                        view.transform = CGAffineTransformMakeRotation(-rotateAngle)
                    })
                }
                if Double(rotateAngle) >= (scrollEndArc - menuEndArc) && angle >= 0 {
                    rotateAngle = CGFloat(scrollEndArc - menuEndArc)
                    containerViewForAnimation.transform = CGAffineTransformMakeRotation(rotateAngle)
                    itemViews.forEach({ (view) in
                        view.transform = CGAffineTransformMakeRotation(-rotateAngle)
                    })
                }
                rotateAngle = rotateAngle > 0 ? rotateAngle : (sin(rotateAngle) > 0 ? (rotateAngle + CGFloat(M_PI*2)) : rotateAngle)
            }
            beginAngle = point
        }
    }
    
    private func point2Angle(point: CGPoint) -> CGFloat {
        return CGFloat(atan2(Double(point.y - containerCenterY), Double(point.x - containerCenterX)))
    }
    
    private func normalize(angle: CGFloat) -> Double {
        let rad = Double(angle)%(M_PI*2)
        return rad
    }
    
    @objc private func handleTapGesture(gesture: UITapGestureRecognizer) {
        if animationComplete {
            itemAnimViews.removeAll()
            if expandableState {
                shrinkMenu()
            } else {
                expandMenu()
            }
        }
    }
    
    public init(frame: CGRect, centerView: UIView) {
        self.centerView = centerView
        super.init(frame: frame)
        addCenterView(centerView)
    }
    
    public init(centerView: UIView) {
        self.centerView = centerView
        super.init(frame: CGRectZero)
        addCenterView(centerView)
    }
    
    public func addCenterView(centerView: UIView) {
        centerView.userInteractionEnabled = true
        menuRadius = bounds.size.width/2
        if centerView.superview != nil {
            centerView.removeFromSuperview()
        }
        addSubview(containerViewForAnimation)
        addSubview(centerView)
        centerView.addGestureRecognizer(tapGesture)
    }
    
    private func updateSize() {
        if CGRectGetWidth(bounds) <= 0 {
            frame = CGRectMake(0, 0, menuRadius*2, menuRadius*2)
        }
        containerViewForAnimation.frame = CGRectMake(0, 0, CGRectGetWidth(bounds), CGRectGetHeight(bounds))
        centerView.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
        containerCenterX = CGRectGetMidX(containerViewForAnimation.bounds)
        containerCenterY = CGRectGetMidY(containerViewForAnimation.bounds)
    }
    
    public func addItemView(itemView: UIView) {
        itemViews.append(itemView)
        containerViewForAnimation.addSubview(itemView)
        itemView.userInteractionEnabled = true
        itemView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(click)))
        itemView.hidden = true
        updateItemSize(itemView)
    }
    
    @objc private func click(gestureRecognizer: UITapGestureRecognizer) {
        if expandableState {
            shrinkMenu()
        }
        if let view = gestureRecognizer.view {
            clickDelegate?.clickAt?(view)
        }
    }
    
    private func updateItemSize(itemView: UIView) {
        var maxWidth: CGFloat = 0
        var maxHeight: CGFloat = 0
        itemView.layoutIfNeeded()
        itemViews.forEach { (view) in
            maxWidth = max(maxWidth, view.bounds.size.width)
            maxHeight = max(maxHeight, view.bounds.size.height)
        }
        self.bounds = CGRectMake(0, 0, self.bounds.size.width - maxItemWidth + maxWidth, self.bounds.size.height - maxItemHeight + maxHeight)
        centerView.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
        containerViewForAnimation.frame = CGRect(origin: CGPointZero, size: self.bounds.size)
        itemView.center = centerView.center
        maxItemWidth = maxWidth
        maxItemHeight = maxHeight
    }
    
    public func removeItemView(itemView: UIView) {
        itemViews = itemViews.filter({ (view) -> Bool in
            return view != itemView
        })
    }
    
    public func shrinkMenu() {
        animationComplete = false
        expandableState = false
        clickDelegate?.menuStatus?(expandableState)
        switch itemViewAniamtionType {
        case .RotateEquation:
            for (index, view) in itemViews.enumerate() {
                addRotateAnimaton(view, state: .Shrink)
                addTranslationAnimation(view, index: index, state: .Shrink)
            }
            break
        case .Custom, .RotateLinear:
            fallthrough
        default:
            if itemViews.count == 1 {
                addRotateAnimaton(itemViews[0], state: .Shrink)
                addTranslationAnimation(itemViews[0], index: 0, state: .Shrink)
            } else {
                let interval = fpmTimingFunction.valueForX(CGFloat(itemViewAnimationDuration)/CGFloat(itemViews.count - 1))
                for (index, view) in itemViews.enumerate() {
                    let time = CGFloat(index)*interval
                    executeAfter(Double(time), action: { [weak self] in
                        if let self_ = self {
                            self_.addRotateAnimaton(view, state: .Shrink)
                            self_.addTranslationAnimation(view, index: index, state: .Shrink)
                        }
                        })
                }
            }
            break
        }
    }
    
    public func expandMenu() {
        animationComplete = false
        expandableState = true
        clickDelegate?.menuStatus?(expandableState)
        switch itemViewAniamtionType {
        case .RotateEquation:
            for (index, view) in itemViews.enumerate() {
                addRotateAnimaton(view, state: .Expand)
                addTranslationAnimation(view, index: index, state: .Expand)
            }
            break
        case .Custom, .RotateLinear:
            fallthrough
        default:
            if itemViews.count == 1 {
                addRotateAnimaton(itemViews[0], state: .Expand)
                addTranslationAnimation(itemViews[0], index: 0, state: .Expand)
            } else {
                let interval = fpmTimingFunction.valueForX(CGFloat(itemViewAnimationDuration)/CGFloat(itemViews.count - 1))
                for (index, view) in itemViews.enumerate() {
                    let time = CGFloat(index)*interval
                    executeAfter(Double(time), action: { [weak self] in
                        if let self_ = self {
                            self_.addRotateAnimaton(view, state: .Expand)
                            self_.addTranslationAnimation(view, index: index, state: .Expand)
                        }
                        })
                }
            }
            break
        }
    }
    
    private func addRotateAnimaton(view: UIView, state: AnimationViewState) {
        view.hidden = false
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.toValue = M_PI*2
        animation.duration = itemViewAnimationDuration
        animation.removedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        animation.delegate = self
        view.layer.addAnimation(animation, forKey: "rotate")
        itemAnimViews.append(view)
    }
    
    private func addTranslationAnimation(view: UIView, index: Int, state: AnimationViewState) {
        view.hidden = false
        let animation = CABasicAnimation(keyPath: "transform.translation")
        if itemViews.count > 0 {
            var angle: CGFloat = 0
            if itemViews.count == 1 {
                angle = 0
            } else {
                angle = CGFloat(menuEndArc - menuStartArc)/CGFloat(itemViews.count - 1)
            }
            angle = CGFloat(menuStartArc) + angle*CGFloat(index)
            if state == .Expand {
                animation.toValue = NSValue(CGSize: CGSizeMake(menuRadius*cos(angle), menuRadius*sin(angle)))
            } else {
                animation.toValue = NSValue(CGSize: CGSizeMake(-menuRadius*cos(angle), -menuRadius*sin(angle)))
            }
            animation.duration = itemViewAnimationDuration
            animation.removedOnCompletion = false
            animation.fillMode = kCAFillModeForwards
            animation.delegate = self
            view.layer.addAnimation(animation, forKey: "translation")
            itemAnimViews.append(view)
        }
    }
    
    public override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        for (index, view) in itemAnimViews.enumerate() {
            let layer = view.layer
            if let animation = layer.animationForKey("rotate") {
                if anim == animation {
                    itemAnimViews.removeAtIndex(index)
                    layer.removeAnimationForKey("rotate")
                    break
                }
            }
            if let animation = layer.animationForKey("translation") {
                if anim == animation {
                    itemAnimViews.removeAtIndex(index)
                    let frame = layer.presentationLayer()?.frame
                    layer.position = CGPointMake(CGRectGetMidX(frame!), CGRectGetMidY(frame!))
                    layer.removeAnimationForKey("translation")
                    if !expandableState {
                        view.hidden = true
                    }
                    break
                }
            }
        }
        if itemAnimViews.count == 0 {
            animationComplete = true
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func executeAfter(time: NSTimeInterval, action: (Void -> Void)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(time*Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            action()
        }
    }
}

@objc public protocol FPMItemsViewClickDelegate: NSObjectProtocol {
    optional func clickAt(view: UIView)
    optional func menuStatus(expand: Bool)
}
