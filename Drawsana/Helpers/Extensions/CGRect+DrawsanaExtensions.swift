//
//  CGRect+DrawsanaExtensions.swift
//  Drawsana
//
//  Created by Steve Landey on 8/8/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

extension CGRect {
    var middle: CGPoint {
      return CGPoint(x: midX, y: midY)
    }
    
    static func changeShapeBoundingRect(points: [CGPoint]) -> CGRect {
        var x1 = points.first?.x ?? 0
        var y1 = points.first?.y ?? 0
        var x2 = points.first?.x ?? 0
        var y2 = points.first?.y ?? 0
        
        for idx in 1..<points.count {
            let point = points[idx]
            x1 = min(x1, point.x)
            y1 = min(y1, point.y)
            x2 = max(x2, point.x)
            y2 = max(y2, point.y)
        }
        
        let width = x2 - x1
        let height = y2 - y1
        return CGRect(x: x1, y: y1, width: width, height: height)
    }

}
