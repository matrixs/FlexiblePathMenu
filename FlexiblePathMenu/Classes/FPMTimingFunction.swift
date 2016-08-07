//
//  FPMTimingFunction.swift
//  Pods
//
//  Created by matrixs on 16/8/6.
//
//

import Foundation

public class FPMTimingFunction: NSObject {
    
    public struct FunctionIdentifier {
        // Same values as `CAMediaTimingFunction` defines, so they can be used interchangeably.
        static let kRSTimingFunctionLinear        = "linear";
        static let kRSTimingFunctionEaseIn        = "easeIn";
        static let kRSTimingFunctionEaseOut       = "easeOut";
        static let kRSTimingFunctionEaseInEaseOut = "easeInEaseOut";
        static let kRSTimingFunctionDefault       = "default";
        
        // NSCoding
        static let kControlPoint1Key = "controlPoint1";
        static let kControlPoint2Key = "controlPoint2";
        static let kDurationKey = "duration";
        
        
        // Internal constants
        static let kDurationDefault = 1.0;
    }
    
    public struct FunctionPoint {
        // Replicate exact same curves as `CAMediaTimingFunction` defines.
        static let kLinearP1        = CGPointMake(0.0,  0.0)
        static let kLinearP2        = CGPointMake(1.0,  1.0)
        static let kEaseInP1        = CGPointMake(0.42, 0.0)
        static let kEaseInP2        = CGPointMake(1.0,  1.0)
        static let kEaseOutP1       = CGPointMake(0.0,  0.0)
        static let kEaseOutP2       = CGPointMake(0.58, 1.0)
        static let kEaseInEaseOutP1 = CGPointMake(0.42, 0.0)
        static let kEaseInEaseOutP2 = CGPointMake(0.58, 1.0)
        static let kDefaultP1       = CGPointMake(0.25, 0.1)
        static let kDefaultP2       = CGPointMake(0.25, 1.0)
    }
    
    // Polynomial coefficients
    var ax: CGFloat = 0
    var bx: CGFloat = 0
    var cx: CGFloat = 0
    var ay: CGFloat = 0
    var by: CGFloat = 0
    var cy: CGFloat = 0
    
    var controlPoint1 = CGPointZero
    var controlPoint2 = CGPointZero
    var duration: Double = 1.0

    public func updateControlPoint1(controlPoint1: CGPoint) {
        if !CGPointEqualToPoint(self.controlPoint1, FPMTimingFunction.normalizedPoint(controlPoint1)) {
            self.controlPoint1 = controlPoint1
    
            calculatePolynomialCoefficients()
        }
    }
    
    public func updateControlPoint2(controlPoint2: CGPoint)
    {
        if !CGPointEqualToPoint(self.controlPoint2, FPMTimingFunction.normalizedPoint(controlPoint2)) {
        self.controlPoint2 = controlPoint2
        
        calculatePolynomialCoefficients()
    }
    }
    
    public func updateDuration(duration: NSTimeInterval)
    {
    // Only allow non-negative durations.
        let duration = max(0.0, duration)
        if (self.duration != duration) {
            self.duration = duration;
        }
    }
    
    // Private designated initializer
    public func initWithControlPoint1(controlPoint1: CGPoint, controlPoint2: CGPoint, duration: NSTimeInterval)
    {
        // Don't initialize control points through setter to avoid triggering `-calculatePolynomicalCoefficients` unnecessarily twice.
        self.controlPoint1 = FPMTimingFunction.normalizedPoint(controlPoint1)
        self.controlPoint2 = FPMTimingFunction.normalizedPoint(controlPoint2)
        
        // Manually initialize polynomial coefficients with newly set control points.
        calculatePolynomialCoefficients()
        
        // Use setter to leverage its value sanitanization.
        self.duration = duration;
    }
    
    
    init(name: String)
    {
        super.init()
        let controlPoint1 = FPMTimingFunction.controlPoint1ForTimingFunctionWithName(name)
        let controlPoint2 = FPMTimingFunction.controlPoint2ForTimingFunctionWithName(name)
        initWithControlPoint1(controlPoint1, controlPoint2: controlPoint2)
    }
    
    
    public class func timingFunctionWithName(name: String) -> FPMTimingFunction
    {
        return FPMTimingFunction(name: name)
    }
    
    public func initWithControlPoint1(controlPoint1: CGPoint, controlPoint2: CGPoint)
    {
        initWithControlPoint1(controlPoint1, controlPoint2: controlPoint2, duration: FunctionIdentifier.kDurationDefault)
    }
    
    
    public class func timingFunctionWithControlPoint1(controlPoint1: CGPoint, controlPoint2: CGPoint) -> FPMTimingFunction
    {
        let ins = FPMTimingFunction()
        ins.initWithControlPoint1(controlPoint1, controlPoint2: controlPoint2)
        return ins
    }
    
    public override init() {
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        let controlPoint1 = aDecoder.decodeCGPointForKey(FunctionIdentifier.kControlPoint1Key)
        let controlPoint2 = aDecoder.decodeCGPointForKey(FunctionIdentifier.kControlPoint2Key)
        let duration = aDecoder.decodeDoubleForKey(FunctionIdentifier.kDurationKey)
        self.initWithControlPoint1(controlPoint1, controlPoint2: controlPoint2, duration: FunctionIdentifier.kDurationDefault)
    }

    
    public func encodeWithCoder(encoder: NSCoder) {
        encoder.encodeCGPoint(self.controlPoint1, forKey: FunctionIdentifier.kControlPoint1Key)
        encoder.encodeCGPoint(self.controlPoint2, forKey: FunctionIdentifier.kControlPoint2Key)
        encoder.encodeDouble(self.duration, forKey: FunctionIdentifier.kDurationKey)
    }
    
    public func valueForX(x: CGFloat) -> CGFloat
    {
        let epsil = epsilon()
        let xSolved = solveCurveX(x, epsilon: epsil)
        let y = sampleCurveY(xSolved)
        return y;
    }
    
    // Cubic Bezier math code is based on WebCore (WebKit)
    // http://opensource.apple.com/source/WebCore/WebCore-955.66/platform/graphics/UnitBezier.h
    // http://opensource.apple.com/source/WebCore/WebCore-955.66/page/animation/AnimationBase.cpp
    
    
    public func epsilon() -> CGFloat
    {
        // Higher precision in the timing function for longer duration to avoid ugly discontinuities
        return 1.0 / (200.0 * CGFloat(self.duration));
    }
    
    
    public func calculatePolynomialCoefficients()
    {
        // Implicit first and last control points are (0,0) and (1,1).
        cx = 3.0 * self.controlPoint1.x;
        bx = 3.0 * (self.controlPoint2.x - self.controlPoint1.x) - cx;
        ax = 1.0 - cx - bx;
        
        cy = 3.0 * self.controlPoint1.y;
        by = 3.0 * (self.controlPoint2.y - self.controlPoint1.y) - cy;
        ay = 1.0 - cy - by;
    }
    
    
    public func sampleCurveX(t: CGFloat) -> CGFloat
    {
        // 'ax t^3 + bx t^2 + cx t' expanded using Horner's rule.
        return ((ax * t + bx) * t + cx) * t;
    }
    
    
    public func sampleCurveY(t: CGFloat) -> CGFloat
    {
        return ((ay * t + by) * t + cy) * t;
    }
    
    
    public func sampleCurveDerivativeX(t: CGFloat) -> CGFloat
    {
        return (3.0 * ax * t + 2.0 * bx) * t + cx;
    }
    
    
    // Given an x value, find a parametric value it came from.
    public func solveCurveX(x: CGFloat, epsilon: CGFloat) -> CGFloat
    {
        var t0 = CGFloat(0)
        var t1 = CGFloat(0)
        var t2 = CGFloat(0)
        var x2 = CGFloat(0)
        var d2 = CGFloat(0)
        var i = 0
        
        // First try a few iterations of Newton's method -- normally very fast.
        for (t2 = x, i = 0; i < 8; i++) {
        x2 = sampleCurveX(t2) - x;
        if (fabs(x2) < epsilon) {
            return t2;
        }
        d2 = sampleCurveDerivativeX(t2)
        if (fabs(d2) < 1e-6) {
            break;
        }
        t2 = t2 - x2 / d2;
        }
        
        // Fall back to the bisection method for reliability.
        t0 = 0.0;
        t1 = 1.0;
        t2 = x;
        
        if (t2 < t0) {
        return t0;
        }
        if (t2 > t1) {
        return t1;
        }
        
        while (t0 < t1) {
        x2 = sampleCurveX(t2)
        if (fabs(x2 - x) < epsilon) {
            return t2;
        }
        if (x > x2) {
            t0 = t2;
        } else {
            t1 = t2;
        }
        t2 = (t1 - t0) * 0.5 + t0;
        }
        
        // Failure.
        return t2;
    }
    
    
    public class func normalizedPoint(point: CGPoint) -> CGPoint
    {
        var normalizedPoint = CGPointZero;

        // Clamp to interval [0..1]
        normalizedPoint.x = max(0.0, min(1.0, point.x));
        normalizedPoint.y = max(0.0, min(1.0, point.y));

        return normalizedPoint;
    }
    
    
    public class func controlPoint1ForTimingFunctionWithName(name: String) -> CGPoint
    {
        var controlPoint1 = CGPointZero;
    
        if (name == FunctionIdentifier.kRSTimingFunctionLinear) {
            controlPoint1 = FunctionPoint.kLinearP1;
        } else if name == FunctionIdentifier.kRSTimingFunctionEaseIn {
            controlPoint1 = FunctionPoint.kEaseInP1;
        } else if name == FunctionIdentifier.kRSTimingFunctionEaseOut {
            controlPoint1 = FunctionPoint.kEaseOutP1;
        } else if name == FunctionIdentifier.kRSTimingFunctionEaseInEaseOut {
            controlPoint1 = FunctionPoint.kEaseInEaseOutP1;
        } else if name == FunctionIdentifier.kRSTimingFunctionDefault {
            controlPoint1 = FunctionPoint.kDefaultP1;
        } else {
            // Not a predefined timing function
        }
        
        return controlPoint1;
    }
    
    
    public class func controlPoint2ForTimingFunctionWithName(name: String) -> CGPoint
    {
        var controlPoint2 = CGPointZero;

        if name == FunctionIdentifier.kRSTimingFunctionLinear {
        controlPoint2 = FunctionPoint.kLinearP2;
        } else if name == FunctionIdentifier.kRSTimingFunctionEaseIn {
        controlPoint2 = FunctionPoint.kEaseInP2;
        } else if name == FunctionIdentifier.kRSTimingFunctionEaseOut {
        controlPoint2 = FunctionPoint.kEaseOutP2;
        } else if name == FunctionIdentifier.kRSTimingFunctionEaseInEaseOut {
        controlPoint2 = FunctionPoint.kEaseInEaseOutP2;
        } else if name == FunctionIdentifier.kRSTimingFunctionDefault {
        controlPoint2 = FunctionPoint.kDefaultP2;
        } else {
        // Not a predefined timing function
        }

        return controlPoint2;
    }
}
