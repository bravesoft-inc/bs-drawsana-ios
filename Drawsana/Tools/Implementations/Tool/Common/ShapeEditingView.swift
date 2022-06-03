//
//  ShapeEditingView.swift
//  Drawsana
//
//  Created by 朴根佑 on 2022/03/03.
//  Copyright © 2022 Asana. All rights reserved.
//

import UIKit

public class ShapeEditingView: UIView {
    /// Upper left 'delete' button for text. You may add any subviews you want,
    /// set border & background color, etc.
    public var deleteControlView = UIView()
    /// Upper right 'rotate' button for text. You may add any subviews you want,
    /// set border & background color, etc.
    public var resizeAndRotateControlView = UIView()
    
    /// The `UIView` that the user interacts with during editing
    public let shapeView: UIView
    public var shapeSides: [CGPoint] = []
    public var shapeChangeViews: [UIView] = []
    private let shapeChangeViewTag: Int = 1000
    
    private let buttonSize: CGFloat = 36
    private var halfButtonSize: CGFloat {
        buttonSize / 2
    }
    
    public enum DragActionType {
        case delete
        case resizeAndRotate
        case changeWidth
        case changeShape
    }
    
    public struct Control {
        public let view: UIView
        public let dragActionType: DragActionType
    }
    
    public private(set) var controls = [Control]()
    
    init(shapeView: UIView) {
        self.shapeView = shapeView
        super.init(frame: .zero)
        
        clipsToBounds = false
        backgroundColor = .clear
        layer.isOpaque = false
        
        shapeView.translatesAutoresizingMaskIntoConstraints = false
        shapeView.backgroundColor = .clear
        
        deleteControlView.translatesAutoresizingMaskIntoConstraints = false
        deleteControlView.backgroundColor = .red
        
        resizeAndRotateControlView.translatesAutoresizingMaskIntoConstraints = false
        resizeAndRotateControlView.backgroundColor = .blue
        
        addSubview(shapeView)
        
        NSLayoutConstraint.activate([
            shapeView.leftAnchor.constraint(equalTo: leftAnchor),
            shapeView.rightAnchor.constraint(equalTo: rightAnchor),
            shapeView.topAnchor.constraint(equalTo: topAnchor),
            shapeView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    let makeView: (UIImage?) -> UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 1, height: 1)
        view.layer.shadowRadius = 3
        view.layer.shadowOpacity = 0.5
        if let image = $0 {
            view.frame = CGRect(origin: .zero, size: CGSize(width: 16, height: 16))
            let imageView = UIImageView(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = true
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .clear
            view.addSubview(imageView)
        }
        return view
    }
    
    public func addStandardControls() {
        addControl(dragActionType: .resizeAndRotate, view: makeView(SelectionToolSettings.shared.rotateButtonImage)) { (view, resizeAndRotateControlView) in
            resizeAndRotateControlView.layer.anchorPoint = .zero
//            resizeAndRotateControlView.layer.backgroundColor = UIColor.red.cgColor
        }
        
        addControl(dragActionType: .delete, view: makeView(SelectionToolSettings.shared.deleteButtonImage)) { (view, deleteControlView) in
            deleteControlView.layer.anchorPoint = .zero
//            deleteControlView.layer.backgroundColor = UIColor.blue.cgColor
        }
    }
    
    public func addShapeChangeControls() {
        guard shapeChangeViews.count != shapeSides.count else { return }
        for view in shapeChangeViews {
            view.removeFromSuperview()
        }
        shapeChangeViews = []
        for (tag, _) in shapeSides.enumerated() {
            let shapeChangeView = makeView(SelectionToolSettings.shared.changeButtonImage)
            shapeChangeView.tag = shapeChangeViewTag + tag
//            shapeChangeView.alpha = 0.3
            addControl(dragActionType: .changeShape, view: shapeChangeView) { (view, shapeChangeView) in
                shapeChangeView.layer.anchorPoint = .zero
//                shapeChangeView.backgroundColor = .yellow
//                deleteControlView.layer.backgroundColor = UIColor.green.cgColor
            }
            shapeChangeViews.append(shapeChangeView)
        }
    }
    
    /// The user has changed the transform of the selected shape. You may leave
    /// this method empty, but unless you want your text controls to scale with
    /// the text, you'll need to do some math and apply some inverse scaling
    /// transforms here.
    public func selectionToolDidUpdateEditingView(boundingRect: CGRect, shape: ShapeSelectable, transform: ShapeTransform) {
        let updateHalfButtonSize = halfButtonSize / transform.scale
        let updateButtonSize = buttonSize / transform.scale
        var updateButtonImageInset = 4 / transform.scale
        let resetBoundingRectWidth = (boundingRect.width + 8)
        let resetBoundingRectHeight = (boundingRect.height + 8)
        
        for control in controls {
            switch control.dragActionType {
            case .resizeAndRotate:
                let x = -updateHalfButtonSize //+ (boundingRect.origin.x / transform.scale)
                let y = -updateHalfButtonSize //+ (boundingRect.origin.y / transform.scale)
                control.view.frame = CGRect(origin: .init(x: x, y: y), size: .init(width: updateButtonSize, height: updateButtonSize))
                control.view.subviews.first?.frame = control.view.bounds.insetBy(dx: updateButtonImageInset, dy: updateButtonImageInset)
                control.view.isHidden = shape is GuideLineShape
            case .delete:
                let x = (resetBoundingRectWidth - updateHalfButtonSize) // + (boundingRect.origin.x / transform.scale)
                let y = -updateHalfButtonSize // + (boundingRect.origin.y / transform.scale)
                control.view.frame = CGRect(origin: .init(x: x, y: y), size: .init(width: updateButtonSize, height: updateButtonSize))
                control.view.subviews.first?.frame = control.view.bounds.insetBy(dx: updateButtonImageInset, dy: updateButtonImageInset)
            case .changeShape:
                guard !shapeSides.isEmpty else { continue }
                let tag = control.view.tag - shapeChangeViewTag
                let shapeSide = shapeSides[tag]
                
                var updateButtonX = shapeSide.x + (resetBoundingRectWidth / 2)
                updateButtonX -= updateHalfButtonSize
                updateButtonX -= shape.boundingRect.midX
                
                var updateButtonY = shapeSide.y + (resetBoundingRectHeight / 2)
                updateButtonY -= updateHalfButtonSize
                updateButtonY -= shape.boundingRect.midY
                
                updateButtonImageInset = 10 / transform.scale
                
                control.view.frame = CGRect(origin: .init(x: updateButtonX, y: updateButtonY),
                                            size: .init(width: updateButtonSize, height: updateButtonSize))
                control.view.subviews.first?.frame = control.view.bounds.insetBy(dx: updateButtonImageInset, dy: updateButtonImageInset)
                
            default:
                break
            }
        }
    }
    
    public func addControl<T: UIView>(dragActionType: DragActionType, view: T, applyConstraints: (UIView, T) -> Void) {
        addSubview(view)
        controls.append(Control(view: view, dragActionType: dragActionType))
        applyConstraints(shapeView, view)
    }
    
    public func getDragActionType(point: CGPoint) -> DragActionType? {
        guard let superview = superview else { return .none }
        for control in controls {
            if control.view.convert(control.view.bounds, to: superview).contains(point) {
                return control.dragActionType
            }
        }
        return nil
    }
}
