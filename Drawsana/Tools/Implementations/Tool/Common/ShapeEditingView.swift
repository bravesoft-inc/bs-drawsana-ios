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
    
    private let buttonSize: CGFloat = 36
    private var halfButtonSize: CGFloat {
        buttonSize / 2
    }
    
    public enum DragActionType {
        case delete
        case resizeAndRotate
        case changeWidth
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
    
    public func addStandardControls() {
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
                imageView.frame = view.bounds.insetBy(dx: 4, dy: -4)
                imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                imageView.contentMode = .scaleAspectFit
                view.addSubview(imageView)
            }
            return view
        }
        
        addControl(dragActionType: .resizeAndRotate, view: makeView(SelectionToolSettings.shared.rotateButtonImage)) { (view, resizeAndRotateControlView) in
            resizeAndRotateControlView.layer.anchorPoint = .zero
            resizeAndRotateControlView.frame = CGRect(origin: .init(x: -halfButtonSize, y: -halfButtonSize), size: .init(width: buttonSize, height: buttonSize))
        }
    }
    
    /// The user has changed the transform of the selected shape. You may leave
    /// this method empty, but unless you want your text controls to scale with
    /// the text, you'll need to do some math and apply some inverse scaling
    /// transforms here.
    public func selectionToolDidUpdateEditingView(boundingRect: CGRect, shape: ShapeSelectable, transform: ShapeTransform) {
        for control in controls {
            switch control.dragActionType {
            case .resizeAndRotate:
                control.view.isHidden = shape is GuideLineShape
            default:
                break
            }
            
            let translatedPointX = halfButtonSize * transform.scale - halfButtonSize
            let translatedPointY = (halfButtonSize - 4) * transform.scale - halfButtonSize
            
            control.view.transform = CGAffineTransform(scaleX: 1/transform.scale, y: 1/transform.scale).translatedBy(x: translatedPointX, y: translatedPointY)
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
