//
//  NgonShape.swift
//  Drawsana
//
//  Created by Madan Gupta on 24/12/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public class NgonShape:
    ShapeWithTwoPoints,
    ShapeWithStandardState,
    ShapeSelectable
{
    private enum CodingKeys: String, CodingKey {
        case id, a, b, strokeColor, fillColor, strokeWidth, capStyle, joinStyle,
        dashPhase, dashLengths, transform, type, selectionBoundingRect, boundingRectOrigin, points
    }
    
    public static let type: String = "Ngon"
    
    public var id: String = UUID().uuidString
    public var a: CGPoint = .zero
    public var b: CGPoint = .zero
    public var strokeColor: UIColor? = .black
    public var fillColor: UIColor? = .clear
    public var strokeWidth: CGFloat = 10
    public var capStyle: CGLineCap = .round
    public var joinStyle: CGLineJoin = .round
    public var dashPhase: CGFloat?
    public var dashLengths: [CGFloat]?
    public var transform: ShapeTransform = .identity
    public var sides: Int = 0
    public var selectionBoundingRect: CGRect = .zero
    public var boundingRectOrigin: CGPoint = .zero
    public var points: [CGPoint]?
    
    public var boundingRect: CGRect {
        return squareRect
    }
    
    public init(_ sides: Int) {
        self.sides = sides
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try values.decode(String.self, forKey: .type)
        if type != NgonShape.type {
            throw DrawsanaDecodingError.wrongShapeTypeError
        }
        
        id = try values.decode(String.self, forKey: .id)
        a = try values.decode(CGPoint.self, forKey: .a)
        b = try values.decode(CGPoint.self, forKey: .b)
        
        strokeColor = try values.decodeColorIfPresent(forKey: .strokeColor)
        fillColor = try values.decodeColorIfPresent(forKey: .fillColor)
        
        strokeWidth = try values.decode(CGFloat.self, forKey: .strokeWidth)
        transform = try values.decodeIfPresent(ShapeTransform.self, forKey: .transform) ?? .identity
        
        capStyle = CGLineCap(rawValue: try values.decodeIfPresent(Int32.self, forKey: .capStyle) ?? CGLineCap.round.rawValue)!
        joinStyle = CGLineJoin(rawValue: try values.decodeIfPresent(Int32.self, forKey: .joinStyle) ?? CGLineJoin.round.rawValue)!
        dashPhase = try values.decodeIfPresent(CGFloat.self, forKey: .dashPhase)
        dashLengths = try values.decodeIfPresent([CGFloat].self, forKey: .dashLengths)
        selectionBoundingRect = try values.decodeIfPresent(CGRect.self, forKey: .selectionBoundingRect) ?? .zero
        boundingRectOrigin = try values.decodeIfPresent(CGPoint.self, forKey: .boundingRectOrigin) ?? .zero
        points = try values.decodeIfPresent([CGPoint].self, forKey: .points) ?? []
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(NgonShape.type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(a, forKey: .a)
        try container.encode(b, forKey: .b)
        try container.encode(strokeColor?.hexString, forKey: .strokeColor)
        try container.encode(fillColor?.hexString, forKey: .fillColor)
        try container.encode(strokeWidth, forKey: .strokeWidth)
        
        if !transform.isIdentity {
            try container.encode(transform, forKey: .transform)
        }
        
        if capStyle != .round {
            try container.encode(capStyle.rawValue, forKey: .capStyle)
        }
        if joinStyle != .round {
            try container.encode(joinStyle.rawValue, forKey: .joinStyle)
        }
        try container.encodeIfPresent(dashPhase, forKey: .dashPhase)
        try container.encodeIfPresent(dashLengths, forKey: .dashLengths)
        try container.encodeIfPresent(selectionBoundingRect, forKey: .selectionBoundingRect)
        try container.encodeIfPresent(boundingRectOrigin, forKey: .boundingRectOrigin)
        try container.encodeIfPresent(points, forKey: .points)
    }
    
    public func render(in context: CGContext) {
        shapeRender(in: context)
        pointRender(in: context)
    }
    private func shapeRender(in context: CGContext) {
        transform.begin(context: context)
        
        if let fillColor = fillColor {
            context.setFillColor(fillColor.cgColor)
            context.addPath(polygonPath())   //Pentagon
            context.fillPath()
        }
        
        context.setLineCap(capStyle)
        context.setLineJoin(joinStyle)
        context.setLineWidth(strokeWidth)
        
        if let strokeColor = strokeColor {
            context.setStrokeColor(strokeColor.cgColor)
            if let dashPhase = dashPhase, let dashLengths = dashLengths {
                context.setLineDash(phase: dashPhase, lengths: dashLengths)
            } else {
                context.setLineDash(phase: 0, lengths: [])
            }
        
            context.addPath(polygonPath())   //Pentagon
            context.strokePath()
        }
        
        transform.end(context: context)
    }
    
    private func pointRender(in context: CGContext) {
        guard let points = points else {
            return
        }

        for point in points {
            transform.begin(context: context)
            context.setLineCap(capStyle)
            context.setLineJoin(joinStyle)
            
            context.setFillColor(UIColor.rgba(red: 255, green: 0, blue: 59, alpha: 1.0).cgColor)
            context.setLineDash(phase: 0, lengths: [])
            
            let pointWidth: CGFloat = strokeWidth * 2
            let identityStrokeWidth = pointWidth / transform.scale
            let originDiff = identityStrokeWidth / 2
            
            context.addEllipse(in: CGRect(origin: .init(x: point.x - originDiff, y: point.y - originDiff), size: .init(width: identityStrokeWidth, height: identityStrokeWidth)))
            context.fillPath()
            
            transform.end(context: context)
        }
    }

    func polygonPath() -> CGPath {
        let path = CGMutablePath()
        let points = self.points ?? polygonPoints()
        let cpg = points[0]
        path.move(to: cpg)
        for p in points {
            path.addLine(to: p)
        }
        path.closeSubpath()
        return path
    }
}

extension NgonShape {
    func polygonPointArray(sides:Int,x:CGFloat,y:CGFloat,radius:CGFloat,offset:CGFloat)->[CGPoint] {
        let angle = (360/CGFloat(sides)).radians
        let cx = x // x origin
        let cy = y // y origin
        let r = radius // radius of circle
        var i = 0
        var points = [CGPoint]()
        while i <= sides {
            let xpo = cx + r * cos(angle * CGFloat(i) - offset.radians)
            let ypo = cy + r * sin(angle * CGFloat(i) - offset.radians)
            points.append(CGPoint(x: xpo, y: ypo))
            i += 1
        }
        return points
    }
    func createPoints() {
        points = polygonPoints()
    }
    
    private func polygonPoints() -> [CGPoint] {
        polygonPointArray(sides: sides,x: squareRect.midX,y: squareRect.midY,radius: (squareRect.width - strokeWidth)/2, offset: 90)
    }
}
