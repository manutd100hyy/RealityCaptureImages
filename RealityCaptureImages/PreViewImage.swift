//
//  PreViewImage.swift
//  RealityCaptureImages
//
//  Created by sytz on 2021/7/12.
//

import UIKit

class PreViewImage: UIView {
    
    let scene:SceneForPhoto = SceneForPhoto.init()
    
    override func didMoveToSuperview() {
        self.isMultipleTouchEnabled = true //开启多指的支持
        self.scene.view = self
        self.layer.addSublayer(self.scene)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.scene.touchesBegan(touches: touches as NSSet)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.scene.touchesMoved(touches: touches as NSSet)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.scene.touchesEnded(touches: touches as NSSet)
    }
}
