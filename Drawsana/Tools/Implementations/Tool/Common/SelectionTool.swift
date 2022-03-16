//
//  AMDrawingTool+Text.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/26/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public protocol SelectionToolDelegate: AnyObject {
    /// User tapped on a shape, but it was already selected. You might want to
    /// take this opportuny to activate a tool that can edit that shape, if one
    /// exists.
    func selectionToolDidTapOnAlreadySelectedShape(_ shape: ShapeSelectable)
    
    func selectionToolDidTapTextShape(_ shape: ShapeSelectable)
    
    func selectionIndicatorView() -> UIView
}

public class SelectionTool: NSObject, DrawingTool {
    
    /// MARK: Protocol requirements
    public let name = "Selection"
    
    public var isProgressive: Bool { return false }
    
    /// You may set yourself as the delegate to be notified when special selection
    /// events happen that you might want to react to. The core framework does
    /// not use this delegate.
    public weak var delegate: SelectionToolDelegate?
    
    private var originalTransform: ShapeTransform?
    
    private var selectedShape: CommonShape?
    
    /// The text tool has 3 different behaviors on drag depending on where your
    /// touch starts. See `DragHandler.swift` for their implementations.
    private var dragHandler: DragHandler?
    
    private weak var shapeUpdater: DrawsanaViewShapeUpdating?
    
    // internal for use by DragHandler subclasses
    internal lazy var editingView: ShapeEditingView = makeShapeEditingView()
    
    public init(delegate: SelectionToolDelegate? = nil) {
        self.delegate = delegate
    }
    
    // MARK: Tool lifecycle
    
    public func activate(shapeUpdater: DrawsanaViewShapeUpdating, context: ToolOperationContext, shape: Shape?) {
        self.shapeUpdater = shapeUpdater
    }
    
    public func deactivate(context: ToolOperationContext) {
        context.toolSettings.interactiveView = nil
        context.toolSettings.selectedShape = nil
        self.selectedShape = nil
    }
    
    public func apply(context: ToolOperationContext, userSettings: UserSettings) {
        if let shape = context.toolSettings.selectedShape {
            shape.apply(userSettings: userSettings)
            context.toolSettings.isPersistentBufferDirty = true
        } else {
            context.toolSettings.interactiveView = nil
        }
    }
    
    public func handleTap(context: ToolOperationContext, point: CGPoint) {
        if let selectedShape = context.toolSettings.selectedShape, selectedShape.hitTest(point: point) == true {
            if let delegate = delegate {
                delegate.selectionToolDidTapOnAlreadySelectedShape(selectedShape)
            } else {
                // Default behavior: deselect the shape
                context.toolSettings.selectedShape = nil
                self.selectedShape = nil
                context.toolSettings.interactiveView = nil
            }
            return
        }
        
        updateSelection(context: context, context.drawing.shapes
                            .compactMap({ $0 as? ShapeSelectable })
                            .filter({ $0.hitTest(point: point) })
                            .last)
        
        if let _ = selectedShape {
            updateShapeView()
        }
    }
    
    public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
        guard let selectedShape = context.toolSettings.selectedShape else { return }
        if let dragActionType = editingView.getDragActionType(point: point), case .resizeAndRotate = dragActionType, !(selectedShape is GuideLineShape) {
            dragHandler = ResizeAndRotateHandler(shape: selectedShape, selectionTool: self)
        } else {
            guard selectedShape.hitTest(point: point) else {
                context.toolSettings.selectedShape = nil
                dragHandler = nil
                return
            }
            dragHandler = MoveHandler(shape: selectedShape, selectionTool: self)
        }
        
        if let dragHandler = dragHandler {
            dragHandler.handleDragStart(context: context, point: point)
        }
    }
    
    public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
        guard let dragHandler = dragHandler else { return }
        dragHandler.handleDragContinue(context: context, point: point, velocity: velocity)
    }
    
    public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
        guard let dragHandler = dragHandler else { return }
        dragHandler.handleDragEnd(context: context, point: point)
    }
    
    public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
        guard let dragHandler = dragHandler else { return }
        dragHandler.handleDragCancel(context: context, point: point)
        
    }
    
    /// Update selection on context.toolSettings, but make sure that when apply()
    /// is called as a part of that change, we don't immediately change the
    /// properties of the newly selected shape.
    private func updateSelection(context: ToolOperationContext, _ newSelectedShape: ShapeSelectable?) {
        context.toolSettings.selectedShape = newSelectedShape
        selectedShape = newSelectedShape
        if let selectedShape = selectedShape {
            context.toolSettings.interactiveView = editingView
            updateShapeEditingView(selectedShape: selectedShape)
        } else {
            context.toolSettings.interactiveView = nil
        }
        dragHandler = nil
    }
}

extension SelectionTool {
    
    // MARK: Other helpers
    
    func updateShapeFrame() {
        guard let _ = selectedShape else { return }
        updateShapeView()
    }
    
    func updateShapeView() {
        guard let shape = selectedShape else { return }
        guard let selectionIndicatorView = delegate?.selectionIndicatorView() else { return }
        
        editingView.bounds = selectionIndicatorView.bounds
        editingView.transform = shape.transform.affineTransform
        
        editingView.selectionToolDidUpdateEditingView(boundingRect: shape.selectionBoundingRect, shape: shape, transform: shape.transform)
    }
    
    private func updateShapeEditingView(selectedShape: ShapeSelectable) {
        
        if selectedShape is GuideLineShape {
            editingView.resizeAndRotateControlView.isHidden = true
        } else {
            editingView.resizeAndRotateControlView.isHidden = false
        }
        
    }
    
    private func makeShapeEditingView() -> ShapeEditingView {
        let view = UIView()
        view.clipsToBounds = true
        view.backgroundColor = .clear
        let editingView = ShapeEditingView(shapeView: view)
        editingView.addStandardControls()
        return editingView
    }
}
