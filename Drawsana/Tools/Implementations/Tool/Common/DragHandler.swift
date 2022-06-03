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
    var shape: CommonShape
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
//        shape.transform = originalTransform
//        context.toolSettings.isPersistentBufferDirty = true
//        selectionTool?.updateShapeFrame()
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
        var changeAngle = shape.transform.rotation
//        print("changeAngle : \(changeAngle * .pi)")
        if changeAngle < 0 {
//            print("changeAngle < 0 : \(changeAngle)")
            changeAngle += 2 * .pi
        }
        changeAngle = changeAngle * 180 / .pi
//        print("changeAngle * 180 : \(changeAngle)")
//
//        var conditionMinAngle = -0.00001 + 2 * .pi
//        conditionMinAngle = conditionMinAngle * 180 / .pi
//        print("conditionMinAngle : \(conditionMinAngle)")
        selectionTool?.updateShapeView()
    }
    
    override func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
        context.operationStack.apply(operation: ChangeTransformOperation(
            shape: shape,
            transform: getResizeAndRotateTransform(point: point),
            originalTransform: originalTransform))
    }
    
    override func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
//        shape.transform = originalTransform
//        context.toolSettings.isPersistentBufferDirty = true
//        selectionTool?.updateShapeFrame()
    }
    
    private func makeDeltaAngle(targetPoint: CGPoint, center: CGPoint) -> CGFloat {
        // 中心点を座標の(0, 0)に揃える
        let dx = targetPoint.x - center.x
        let dy = targetPoint.y - center.y
        // 座標と中心の角度を返却
        return atan2(dy, dx)
    }
}

class ChangeShapeHandler: DragHandler {
    private var originalTransform: ShapeTransform = .identity
    private var originalRect: CGRect = .zero
    private var changePoints: [CGPoint] = []
    private var changePointIndexs: [Int] = []
    
    override init(
        shape: CommonShape,
        selectionTool: SelectionTool)
    {
        super.init(shape: shape, selectionTool: selectionTool)
    }
    
    private func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }

    private func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(CGPointDistanceSquared(from: from, to: to))
    }
    
    private func makeDeltaAngle(targetPoint: CGPoint, center: CGPoint) -> CGFloat {
        // 中心点を座標の(0, 0)に揃える
        let dx = targetPoint.x - center.x
        let dy = targetPoint.y - center.y
        // 座標と中心の角度を返却
        var angle = atan2(dy, dx)
        if angle < 0 {
            angle += 2 * .pi
        }
        angle = 360 - (angle * 180 / .pi)
        
        return angle
    }
    
    //方向を決めて設定の距離分座標を再設定
    private func offset(byDistance distance: CGFloat, inDirection degrees: CGFloat) -> CGPoint {
        let radians = (degrees - 90) * .pi / 180
        let vertical = sin(radians) * distance
        let horizontal = cos(radians) * distance
        return CGPoint(x: horizontal, y: vertical)
    }
    
    override func handleDragStart(context: ToolOperationContext, point: CGPoint) {
        super.handleDragStart(context: context, point: point)
        
        guard let ngonShape = context.toolSettings.selectedShape as? NgonShape else { return }
        guard let shapePoints = ngonShape.points else { return }
        
        self.originalTransform = ngonShape.transform
        self.originalRect = ngonShape.boundingRect
        
        changePointIndexs = []
        for (index, shapePoint) in shapePoints.enumerated() {
            let resetShapePoint = shapePoint.applying(ngonShape.transform.affineTransform)
            if CGPointDistance(from: startPoint, to: resetShapePoint) < 10 {
                changePointIndexs.append(index)
            }
        }
    }
    
    override func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
        guard !changePointIndexs.isEmpty else { return }
        guard let ngonShape = context.toolSettings.selectedShape as? NgonShape else { return }
        
        print("----------------------------------------------------------------")
//        print("shape.boundingRect.middle:\(ngonShape.boundingRect.middle)")
//        print("ngonShape.boundingRect:\(ngonShape.boundingRect)")
//        print("shape.transform:\(ngonShape.transform.translation)")
//        print("ngonShape.boundingRectOrigin:\(ngonShape.boundingRectOrigin)")
//        print("ngonShape.selectionBoundingRect:\(ngonShape.selectionBoundingRect)")
        
        let resetTransform = ngonShape.transform.affineTransform.inverted()
        let resetPoint = point.applying(resetTransform)
        
        for changePointIndex in changePointIndexs {
            ngonShape.points?[changePointIndex] = resetPoint
        }
        
        print("originalTransform.translation:\(originalTransform.translation)")
        
        var middlePoint = originalRect.origin + CGPoint(x: originalRect.width / 2, y: originalRect.height / 2)
        
        middlePoint = middlePoint.applying(originalTransform.affineTransform)
        
        print("middlePoint:\(middlePoint)")
        
        ngonShape.selectionBoundingRect = .init(origin: .zero, size: ngonShape.boundingRect.size)
        context.toolSettings.selectedShape = ngonShape
        selectionTool?.updateShapeView()
    }
    
    override func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
        context.operationStack.apply(operation: ChangeTransformOperation(
            shape: shape,
            transform: shape.transform,
            originalTransform: originalTransform))
    }
    
    override func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    }
}
