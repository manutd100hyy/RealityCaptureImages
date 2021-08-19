//
//  BrowseCaseViewController.swift
//  RealityCaptureImages
//
//  Created by sytz on 2021/7/15.
//

import UIKit

class BrowseCaseViewController: UIViewController {
    
    @IBOutlet weak var curCollectionView: UICollectionView!
    var caseDirs:[String] = []
    var caseTimes:[String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.updateCaseFiles()
    }
    
    func updateCaseFiles() {
        caseDirs.removeAll()
        caseTimes.removeAll()
        
        caseDirs = try! FileManager.default.contentsOfDirectory(atPath:NSHomeDirectory() + "/Documents/Cases/")
        
        for dir in caseDirs {
            guard let infoDict = NSMutableDictionary.init(contentsOfFile:
                                                            generateFilePath("infoDict.plist", "Cases/" + dir)),
                  let imgName = infoDict.value(forKey: "preview") as? String else { fatalError() }
            caseTimes.append(imgName)
        }
    }
}

extension BrowseCaseViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return caseDirs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let col = collectionView.dequeueReusableCell(withReuseIdentifier: "CaseCell", for: indexPath)
        
        guard let imgView = col.contentView.viewWithTag(103) as? UIImageView,
              let labIdx = col.contentView.viewWithTag(100) as? UILabel,
              let labTime = col.contentView.viewWithTag(101) as? UILabel else {
            fatalError()
        }
        
        let jpgName = caseTimes[indexPath.row]
        let curCaseName = caseDirs[indexPath.row]
        let dir = "Cases/" + curCaseName + "/Thumb"
        imgView.image = UIImage.init(contentsOfFile: generateFilePath(jpgName + ".jpg", dir))
        
        labIdx.text = String.init(format: "%d", indexPath.row + 1)
        
        let nameArr = jpgName.components(separatedBy: CharacterSet.init(charactersIn: "_"))
        let arr = ["年", "月", "日", "时", "分"]
        var caseTimeName = ""
        for i in (0..<nameArr.count - 2) {
            caseTimeName += nameArr[i] + arr[i]
        }
        
        labTime.text = caseTimeName
        
        return col
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier:"OpenInfo") as! OpenCaseViewController
        vc.delegate = self
        vc.workDir = NSHomeDirectory() + "/Documents/Cases/" + caseDirs[indexPath.row] + "/"
        present(vc, animated: true, completion: nil)
    }
}
