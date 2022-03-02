//
//  GuideLineShape.swift
//  Drawsana
//
//  Created by 朴根佑 on 2022/01/05.
//  Copyright © 2022 Asana. All rights reserved.
//

import UIKit

public class GuideLineShape:
    ShapeWithOnePoint,
    ShapeWithStandardState,
    ShapeSelectable
{
    
    private enum CodingKeys: String, CodingKey {
        case id, a, strokeColor, fillColor, strokeWidth, capStyle, joinStyle,
             dashPhase, dashLengths, transform, type
    }
    
    public static let type: String = "Point"
    
    public var id: String = UUID().uuidString
    public var a: CGPoint = .zero
    public var strokeColor: UIColor? = .red
    public var fillColor: UIColor? = .red
    public var strokeWidth: CGFloat = 8
    public var capStyle: CGLineCap = .round
    public var joinStyle: CGLineJoin = .round
    public var dashPhase: CGFloat?
    public var dashLengths: [CGFloat]?
    public var transform: ShapeTransform = .identity
    
    
    public var imageSize: CGSize = .zero
    public init() {
        
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try values.decode(String.self, forKey: .type)
        if type != GuideLineShape.type {
            throw DrawsanaDecodingError.wrongShapeTypeError
        }
        
        id = try values.decode(String.self, forKey: .id)
        a = try values.decode(CGPoint.self, forKey: .a)
        
        strokeColor = try values.decodeColorIfPresent(forKey: .strokeColor)
        fillColor = try values.decodeColorIfPresent(forKey: .fillColor)
        
        strokeWidth = try values.decode(CGFloat.self, forKey: .strokeWidth)
        transform = try values.decodeIfPresent(ShapeTransform.self, forKey: .transform) ?? .identity
        
        capStyle = CGLineCap(rawValue: try values.decodeIfPresent(Int32.self, forKey: .capStyle) ?? CGLineCap.round.rawValue)!
        joinStyle = CGLineJoin(rawValue: try values.decodeIfPresent(Int32.self, forKey: .joinStyle) ?? CGLineJoin.round.rawValue)!
        dashPhase = try values.decodeIfPresent(CGFloat.self, forKey: .dashPhase)
        dashLengths = try values.decodeIfPresent([CGFloat].self, forKey: .dashLengths)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(GuideLineShape.type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(a, forKey: .a)
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
    }
    
    public func render(in context: CGContext) {
        lineRender(in: context)
        pointRender(in: context)
    }
    
    private func lineRender(in context: CGContext) {
        transform.begin(context: context)
        
        let screenBounds = UIScreen.main.bounds
        let lineSize = max(screenBounds.height, screenBounds.width)
        
        let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
        
        context.move(to: CGPoint(x: centerPoint.x, y: -lineSize))
        context.addLine(to: CGPoint(x: centerPoint.x, y: lineSize))
        
        context.move(to: CGPoint(x: -lineSize, y: centerPoint.y))
        context.addLine(to: CGPoint(x: lineSize, y: centerPoint.y))
        
        if let dashPhase = dashPhase, let dashLengths = dashLengths {
            context.setLineDash(phase: dashPhase, lengths: dashLengths)
        } else {
            context.setLineDash(phase: 0, lengths: [6, 10])
        }
        
        context.setShadow(offset: CGSize.zero, blur: 1.0, color: UIColor.black.cgColor)

        context.setLineWidth(2)
        context.setLineCap(.round)
        context.setStrokeColor(UIColor.white.cgColor)
        context.strokePath()
        
        transform.end(context: context)
    }
    
    private func pointRender(in context: CGContext) {
        transform.begin(context: context)
        
        if let fillColor = fillColor {
            context.setFillColor(fillColor.cgColor)
            context.addEllipse(in: rect)
            context.fillPath()
        }
        
        context.setLineCap(capStyle)
        context.setLineJoin(joinStyle)
        context.setLineWidth(strokeWidth)
        
        context.setStrokeColor(UIColor.rgba(red: 255, green: 0, blue: 59, alpha: 1.0).cgColor)
        context.setLineDash(phase: 0, lengths: [])
        context.addEllipse(in: rect)
        context.strokePath()
        
        transform.end(context: context)
    }
    
}
