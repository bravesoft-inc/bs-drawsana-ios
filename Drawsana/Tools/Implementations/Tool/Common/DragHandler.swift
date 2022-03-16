//
//  DragHandler.swift
//  Drawsana
//
//  Created by Steve Landey on 8/8/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

typealias CommonShape = ShapeSelectable

class DragHandler {
    let shape: CommonShape
    weak var selectionTool: SelectionTool?
    var startPoint: CGPoint = .zero
    
    init(
        shape: CommonShape,
        selectionTool: SelectionTool)
    {
        self.shape = shape
        self.selectionTool = selectionTool
    }
    
    func handleDragStart(context: ToolOperationContext, point: CGPoint) {
        startPoint = point
    }
    
    func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
        
    }
    
    func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
        
    }
    
    func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
        
    }
}

/// User is dragging the text itself to a new location
class MoveHandler: DragHandler {
    private var originalTransform: ShapeTransform
    
    override init(
        shape: CommonShape,
        selectionTool: SelectionTool)
    {
        self.originalTransform = shape.transform
        super.init(shape: shape, selectionTool: selectionTool)
    }
    
    override func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
        let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
        shape.transform = originalTransform.translated(by: delta)
        context.toolSettings.isPersistentBufferDirty = true
        selectionTool?.updateShapeView()
    }
    
    override func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
        let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
        context.operationStack.apply(operation: ChangeTransformOperation(
            shape: shape,
            transform: originalTransform.translated(by: delta),
            originalTransform: originalTransform))
        context.toolSettings.isPersistentBufferDirty = true
    }
    
    override func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
        shape.transform = originalTransform
        context.toolSettings.isPersistentBufferDirty = true
        selectionTool?.updateShapeFrame()
    }
}

/// User is dragging the lower-right handle to change the size and rotation
/// of the text box
class ResizeAndRotateHandler: DragHandler {
    private var originalTransform: ShapeTransform
    
    override init(
        shape: CommonShape,
        selectionTool: SelectionTool)
    {
        self.originalTransform = shape.transform
        super.init(shape: shape, selectionTool: selectionTool)
    }
    
    private func getResizeAndRotateTransform(point: CGPoint) -> ShapeTransform {
        //        print("----------------------------------------")
        //        print("startPoint:\(startPoint)")
        //        print("point:\(point)")
        //        print("shape.transform.translation:\(shape.transform.translation)")
        //        print("----------------------------------------")
        
        var translation = shape.transform.translation
        if shape is PenShape {
            translation = (shape.boundingRect.middle - shape.boundingRectOrigin) + translation
        } else {
            translation = shape.boundingRect.middle + translation
        }
        
        let originalDelta = startPoint - translation
        let newDelta = point - translation
        
        //        print("----------------------------------------")
        //        print("startPoint:\(startPoint)")
        //        print("point:\(point)")
        //        print("translation:\(translation)")
        //        print("originalDelta:\(originalDelta)")
        //        print("newDelta:\(newDelta)")
        //        print("----------------------------------------")
        
        let originalDistance = originalDelta.length
        let newDistance = newDelta.length
        let scaleChange = newDistance / originalDistance
        
        
        //      let originalAngle = atan2(originalDelta.y, originalDelta.x)
        //      let newAngle = atan2(newDelta.y, newDelta.x)
        
        
        //        let resetTargetPoint = CGPoint(x: shape.selectionBoundingRect.size.width / 2 * scaleChange, y: shape.selectionBoundingRect.size.height / 2 * scaleChange)
        
        let originalAngle = makeDeltaAngle(targetPoint: startPoint, center: translation)
        let newAngle = makeDeltaAngle(targetPoint: point, center: translation)
        let angleChange = originalAngle - newAngle
        
        
        //      let angleChange = newAngle - originalAngle
        
        //              print("----------------------------------------")
        //              print("originalDistance:\(originalDistance)")
        //              print("newDistance:\(newDistance)")
        //              print("scaleChange:\(scaleChange)")
        //              print("----------------------------------------")
        
        
        //              print("----------------------------------------")
        //              print("originalDelta:\(originalDelta)")
        //              print("newDelta:\(newDelta)")
        //              print("originalAngle:\(originalAngle)")
        //              print("newAngle:\(newAngle)")
        //              print("angleChange:\(angleChange)")
        //              print("----------------------------------------")
        
        let transform = originalTransform.rotated(by: -angleChange).scaled(by: scaleChange)
        //        print("----------------------------------------")
        //        print("rotation: \(transform.affineTransform)")
        //        print("----------------------------------------")
        
        return transform
    }
    
    private func rotation(from transform: CGAffineTransform) -> Double {
        var angle = atan2(Double(transform.b), Double(transform.a))
        if angle < 0 {
            angle += 2 * .pi
        }
        return (angle * 180 / .pi)
    }
    
    override func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
        shape.transform = getResizeAndRotateTransform(point: point)
        selectionTool?.updateShapeView()
    }
    
    override func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
        context.operationStack.apply(operation: ChangeTransformOperation(
            shape: shape,
            transform: getResizeAndRotateTransform(point: point),
            originalTransform: originalTransform))
    }
    
    override func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
        shape.transform = originalTransform
        context.toolSettings.isPersistentBufferDirty = true
        selectionTool?.updateShapeFrame()
    }
    
    private func makeDeltaAngle(targetPoint: CGPoint, center: CGPoint) -> CGFloat {
        // 中心点を座標の(0, 0)に揃える
        let dx = targetPoint.x - center.x
        let dy = targetPoint.y - center.y
        // 座標と中心の角度を返却
        return atan2(dy, dx)
    }
}
