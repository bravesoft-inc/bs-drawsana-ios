//
//  GuideLineTool.swift
//  Drawsana
//
//  Created by 朴根佑 on 2022/01/05.
//  Copyright © 2022 Asana. All rights reserved.
//

import UIKit

public class GuideLineTool: DrawingToolForShapeWithOnePoint {
  public override var name: String { return "GuideLine" }
  public override func makeShape() -> ShapeType { return GuideLineShape() }
}
