//
//  PreViewController.swift
//  RealityCaptureImages
//
//  Created by sytz on 2021/7/9.
//

import UIKit

class PreViewController: UIViewController {
    
    @IBOutlet weak var _collectionView: UICollectionView!
    
    var curImgIndex = -1
    
    var imgNames:[String] = []
    
    @IBOutlet weak var preViewImage: PreViewImage!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //先检查thumb文件夹是否存在
        self.fetchImgNamesWithThumb()

        self.loadImgIfNeeds()
    }
    
    @IBAction func bactToCameraView(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier:"CapturePhoto")
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    func loadImgIfNeeds() {
        if self.curImgIndex < 0, self.imgNames.count < 1 {
            return
        }
        
        self.preViewImage.scene.loadingImg(self.imgNames[self.curImgIndex])
    }
    
    func fetchImgNamesWithThumb() {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: generateFilePath(nil, "Thumb")) else {
            fatalError()
        }
        
        self.imgNames = names.filter {
            $0.contains(".jpg")
        }
        
        if self.imgNames.count > 0 {
            self.curImgIndex = 0
        }
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier:"LogoView")
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func btnSaveAction(_ sender: Any) {
        
    }
    @IBAction func btnDelAction(_ sender: Any) {
        if imgNames.count == 4 {
            let alertController = UIAlertController(title: "警告", message: "照片数量不能低于4张!", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "确定", style: .default)
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let alertController = UIAlertController(title: "提示", message: "确认删除图片?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "确定", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            
            let imgName = self.imgNames[self.curImgIndex]
            self.imgNames.remove(at: self.curImgIndex)
            if self.curImgIndex > 0 {
                self.curImgIndex -= 1
            }
            
            self._collectionView.reloadData()
            self.loadImgIfNeeds()
            
            deleteFileFromPath(imgName, "Cache")
            deleteFileFromPath(imgName, "Thumb")
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func highlightCollectionViewCell(_ col:UICollectionViewCell, hidden isHidden:Bool) {
        guard let bgLayer = col.viewWithTag(102) as? UIImageView else {
            fatalError()
        }
        
        bgLayer.isHidden = isHidden
    }
}

extension PreViewController:UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        curImgIndex = indexPath.row
        collectionView.reloadData()
        self.loadImgIfNeeds()
    }
}

extension PreViewController:UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.imgNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let col = collectionView.dequeueReusableCell(withReuseIdentifier: "sytz", for: indexPath)
        
        guard let img = col.viewWithTag(101) as? UIImageView, let lab = col.viewWithTag(103) as? UILabel else {
            fatalError()
        }
        
        if curImgIndex == indexPath.row {
            //需要高亮处理
            self.highlightCollectionViewCell(col, hidden: false)
        }
        else {
            self.highlightCollectionViewCell(col, hidden: true)
        }
        
        img.image = UIImage.init(contentsOfFile: generateFilePath(self.imgNames[indexPath.row], "Thumb"))
        
        lab.text = String.init(format: "%02d", indexPath.row + 1)
        
        return col
    }
}