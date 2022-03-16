//
//  TextShapeEditingView.swift
//  Drawsana
//
//  Created by Steve Landey on 8/8/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public class TextShapeEditingView: UIView {
  /// Upper left 'delete' button for text. You may add any subviews you want,
  /// set border & background color, etc.
  public let deleteControlView = UIView()
  /// Upper right 'rotate' button for text. You may add any subviews you want,
  /// set border & background color, etc.
  public let resizeAndRotateControlView = UIView()
  /// Right side handle to change width of text. You may add any subviews you
  /// want, set border & background color, etc.
  public let changeWidthControlView = UIView()

  /// The `UITextView` that the user interacts with during editing
  public let textView: UITextView
    
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

  init(textView: UITextView) {
    self.textView = textView
    super.init(frame: .zero)

    clipsToBounds = false
    backgroundColor = .clear
    layer.isOpaque = false

    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.backgroundColor = .clear

    deleteControlView.translatesAutoresizingMaskIntoConstraints = false
    deleteControlView.backgroundColor = .red

    resizeAndRotateControlView.translatesAutoresizingMaskIntoConstraints = false
    resizeAndRotateControlView.backgroundColor = .blue

    changeWidthControlView.translatesAutoresizingMaskIntoConstraints = false
    changeWidthControlView.backgroundColor = .yellow

    addSubview(textView)

    NSLayoutConstraint.activate([
      textView.leftAnchor.constraint(equalTo: leftAnchor),
      textView.rightAnchor.constraint(equalTo: rightAnchor),
      textView.topAnchor.constraint(equalTo: topAnchor),
      textView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  override public func sizeThatFits(_ size: CGSize) -> CGSize {
    return textView.sizeThatFits(size)
  }

  @discardableResult
  override public func becomeFirstResponder() -> Bool {
    return textView.becomeFirstResponder()
  }

  @discardableResult
  override public func resignFirstResponder() -> Bool {
    return textView.resignFirstResponder()
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
      
      addControl(dragActionType: .resizeAndRotate, view: makeView(SelectionToolSettings.shared.rotateButtonImage)) { (textView, resizeAndRotateControlView) in
          resizeAndRotateControlView.layer.anchorPoint = .zero
          resizeAndRotateControlView.frame = CGRect(origin: .init(x: -halfButtonSize, y: -halfButtonSize), size: .init(width: buttonSize, height: buttonSize))
      }
    }

  /// The user has changed the transform of the selected shape. You may leave
  /// this method empty, but unless you want your text controls to scale with
  /// the text, you'll need to do some math and apply some inverse scaling
  /// transforms here.
    public func textToolDidUpdateEditingViewTransform(_ transform: ShapeTransform) {
      for control in controls {
          
          let translatedPointX = halfButtonSize * transform.scale - halfButtonSize
          
          // -4はTextToolでTextViewを綺麗に表示させるために以下のコードを書いているため
          // TextTool.swift
          // updateShapeFrameのshape.boundingRect.origin.x += 2
          // TextToolのeditingView.bounds.size.width += 3
          // + selectedShapeのborderWidth = 1
          
          let translatedPointY = (halfButtonSize - 4) * transform.scale - halfButtonSize
          
          control.view.transform = CGAffineTransform(scaleX: 1/transform.scale, y: 1/transform.scale).translatedBy(x: translatedPointX, y: translatedPointY)
      }
  }

  public func addControl<T: UIView>(dragActionType: DragActionType, view: T, applyConstraints: (UITextView, T) -> Void) {
    addSubview(view)
    controls.append(Control(view: view, dragActionType: dragActionType))
    applyConstraints(textView, view)
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
