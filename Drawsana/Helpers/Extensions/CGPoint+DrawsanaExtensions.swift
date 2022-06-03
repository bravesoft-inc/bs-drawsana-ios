//
//  CGPoint+DrawsanaExtensions.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

extension CGPoint {
    init(angle: CGFloat, radius: CGFloat) {
        self.init(x: cos(angle) * radius, y: sin(angle) * radius)
    }
    
    var length: CGFloat {
        return sqrt((x * x) + (y * y))
    }
    
    static func distance(a:CGPoint, b:CGPoint) -> CGFloat {
        return sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2))
    }
    
    func rotate(around center: CGPoint, angle: CGFloat) -> CGPoint {
        let translate = CGAffineTransform(translationX: -center.x, y: -center.y)
        let transform = translate.concatenating(CGAffineTransform(rotationAngle: angle))
        let rotated = applying(transform)
        return rotated.applying(CGAffineTransform(translationX: center.x, y: center.y))
    }
}

func +(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
    return CGPoint(x: a.x + b.x, y: a.y + b.y)
}

func -(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
    return CGPoint(x: a.x - b.x, y: a.y - b.y)
}

func *(_ a: CGPoint, _ scale: CGFloat) -> CGPoint {
    return CGPoint(x: a.x * scale, y: a.y * scale)
}
