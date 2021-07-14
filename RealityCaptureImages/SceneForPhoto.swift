//
//  SceneForPhoto.swift
//  RealityCaptureImages
//
//  Created by sytz on 2021/7/12.
//

import UIKit

class SceneForPhoto: CALayer {
    var view:UIView?
    var transformLayer:CALayer!
    var imgLayer:CALayer!
    var transformFlag = 0xA210
    let SCALING_ACCURACY:Float = 21.0 / 768.0
    let SCALING_LIMIT_MIN:Float = 10
    let SCALING_LIMIT_MAX:Float = 1000
    
    override init() {
        super.init()
        
        self.transformLayer = CALayer.init()
        self.transformLayer.transform = CATransform3DMakeScale(CGFloat(1.0 / 200.0 / SCALING_ACCURACY),  CGFloat(1.0 / 200.0 / SCALING_ACCURACY), 1)
        self.addSublayer(transformLayer)
        
        self.imgLayer = CALayer.init()
        self.transformLayer.addSublayer(self.imgLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    func loadingImg(_ name:String) {
        let imgPath = generateFilePath(name, "Cache")!
        
        self.imgLayer.contents = nil
        guard  let pImg = UIImage.init(contentsOfFile: imgPath) else {
            fatalError()
        }
        
        let iplw = pImg.size.width
        let iplh = pImg.size.height
        let rt = CGRect.init(x: 0, y: 0, width: iplw, height: iplh)
        
        self.imgLayer.frame = rt
        self.imgLayer.contents = pImg.cgImage
        
        self.onPicCentered()
    }
    
    func onPicCentered() {
        CATransaction.begin()
        CATransaction.setValue(NSNumber.init(value:0.0), forKey: kCATransactionAnimationDuration)

        self.transformLayer.transform = CATransform3DIdentity
        //缩放
        let sz = self.view!.frame.size
        let imgLayerRt = self.imgLayer.frame
        var imgWidthPt = CGPoint.init(x: imgLayerRt.size.width, y: 0)
        imgWidthPt = self.convertPointToWindow(imgWidthPt)
        var scaled = imgWidthPt.x / sz.width
        scaled /= 0.8
        self.transformLayer.transform = CATransform3DConcat(CATransform3DMakeScale(1 / scaled, 1 / scaled, 1), self.transformLayer.transform)
        //再移动到屏幕中心
        let imgCenterPt = CGPoint.init(x:imgLayerRt.size.width / 2, y:imgLayerRt.size.height / 2)
        var winCenterPt = CGPoint.init(x:sz.width / 2, y:sz.height / 2)
        winCenterPt = self.convertPointFromWindow(winCenterPt)
        let subPt = CGPoint.init(x: winCenterPt.x - imgCenterPt.x, y: winCenterPt.y - imgCenterPt.y)
        let tmpTransform = CATransform3DConcat(CATransform3DMakeTranslation(subPt.x, subPt.y, 0), self.transformLayer.transform)
        self.transformLayer.transform = tmpTransform
        
        CATransaction.commit()
    }
    
    func convertPointToWindow(_ p:CGPoint) -> CGPoint {
        let t = transformLayer.transform
        let pt = p.applying(CATransform3DGetAffineTransform(t))
        return pt
    }
    
    func convertPointFromWindow(_ p:CGPoint) -> CGPoint {
        let t = CATransform3DInvert(transformLayer.transform)
        let pt = p.applying(CATransform3DGetAffineTransform(t))
        return pt
    }
    
    func applyHoldingTouches(_ touches:NSSet) {
        CATransaction.begin()
        CATransaction.setValue(NSNumber.init(value:0.0), forKey: kCATransactionAnimationDuration)
        
        let tmpTransform = CATransform3DConcat(TransformAssistant.transformIncrement(from: transformLayer.transform, touches: touches as? Set<AnyHashable>, flag: TransformFlag(UInt32(self.transformFlag)), in: self.view), transformLayer.transform)
        
        let scaledMT = sqrtf(powf(Float(tmpTransform.m11), 2) + powf(Float(tmpTransform.m12), 2))
        let currentAccuracy = 1.0 / scaledMT / SCALING_ACCURACY
        if (currentAccuracy < SCALING_LIMIT_MIN || currentAccuracy > SCALING_LIMIT_MAX) {
            CATransaction.commit()
            return
        }
        transformLayer.transform = tmpTransform
        
        CATransaction.commit()
    }
    
    func touchesBegan(touches:NSSet) {
    }
    
    func touchesMoved(touches:NSSet) {
        self.applyHoldingTouches(touches)
    }
    
    func touchesEnded(touches:NSSet) {
        
    }
}
