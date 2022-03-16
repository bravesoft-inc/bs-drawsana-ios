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
}

func +(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
    return CGPoint(x: a.x + b.x, y: a.y + b.y)
}

func -(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
    return CGPoint(x: a.x - b.x, y: a.y - b.y)
}

