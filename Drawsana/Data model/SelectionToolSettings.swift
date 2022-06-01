//
//  SelectionToolSettings.swift
//  Drawsana
//
//  Created by 朴根佑 on 2022/03/03.
//  Copyright © 2022 Asana. All rights reserved.
//

import Foundation
import UIKit

public class SelectionToolSettings {
    public static let shared: SelectionToolSettings = .init()
    
    public var rotateButtonImage: UIImage?
    public var deleteButtonImage: UIImage?
    public var changeButtonImage: UIImage?
}
