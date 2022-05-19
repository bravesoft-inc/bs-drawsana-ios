//
//  DrawingToolForShapeWithTwoPoints.swift
//  Drawsana
//
//  Created by Steve Landey on 8/9/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

/**
 Base class for tools (rect, line, ellipse) that are drawn by dragging from
 one point to another
 */
open class DrawingToolForShapeWithTwoPoints: DrawingTool {
  public typealias ShapeType = Shape & ShapeWithTwoPoints

  open var name: String { fatalError("Override me") }

  public var shapeInProgress: ShapeType?

  public var isProgressive: Bool { return false }

  public init() { }

  /// Override this method to return a shape ready to be drawn to the screen.
  open func makeShape() -> ShapeType {
    fatalError("Override me")
  }

  public func handleTap(context: ToolOperationContext, point: CGPoint) {
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    shapeInProgress = makeShape()
    shapeInProgress?.a = point
    shapeInProgress?.b = point
    shapeInProgress?.apply(userSettings: context.userSettings)
  }

  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    shapeInProgress?.b = point
  }

  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    guard var shape = shapeInProgress else { return }
    shape.b = point
      
      if let ngonShape = shape as? NgonShape {
          if ngonShape.sides == 3 {
              //三角だけ正方形に修正
              let diffrence = abs(shape.rect.width - shape.rect.height)
              if shape.rect.width > shape.rect.height {
                  if shape.a.x > shape.b.x {
                      shape.b.x += diffrence
                  } else {
                      shape.b.x -= diffrence
                  }
              } else {
                  if shape.a.y > shape.b.y {
                      shape.b.y += diffrence
                  } else {
                      shape.b.y -= diffrence
                  }
              }
          }
      }
      
      let translation = shape.rect.origin
      let boundingRect = shape.boundingRect
      
      var resetRectOrigin = translation
      resetRectOrigin.x += shape.rect.size.width / 2
      resetRectOrigin.y += shape.rect.size.height / 2
      
      shape.a = shape.a - resetRectOrigin
      shape.b = shape.b - resetRectOrigin
      
      if let selectableShape = shape as? ShapeSelectable {
          selectableShape.transform.translation = resetRectOrigin
          selectableShape.boundingRectOrigin = resetRectOrigin
          selectableShape.selectionBoundingRect = CGRect(origin: .zero, size: boundingRect.size)
          context.operationStack.apply(operation: AddShapeOperation(shape: selectableShape))
      }
      
      if let ngonShape = shape as? NgonShape {
          ngonShape.createPoints()
      }
      
      shapeInProgress = nil
  }

  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    // No such thing as a cancel for this tool. If this was recognized as a tap,
    // just end the shape normally.
    handleDragEnd(context: context, point: point)
  }

  public func renderShapeInProgress(transientContext: CGContext) {
    shapeInProgress?.render(in: transientContext)
  }

  public func apply(context: ToolOperationContext, userSettings: UserSettings) {
    shapeInProgress?.apply(userSettings: userSettings)
    context.toolSettings.isPersistentBufferDirty = true
  }
}
