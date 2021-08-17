//
//  SaveCaseViewController.swift
//  RealityCaptureImages
//
//  Created by sytz on 2021/7/15.
//

import UIKit

class SaveCaseViewController: UIViewController {
    
    var workDir = NSHomeDirectory() + "/Documents/"

    @IBOutlet weak var caseImageView: UIImageView!
    @IBOutlet weak var caseTextfield: UITextField!
    @IBOutlet weak var caseDatePicker: UIDatePicker!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let infoDict = NSMutableDictionary.init(contentsOfFile:workDir + "infoDict.plist"),
              let imgName = infoDict.value(forKey: "preview") as? String else { return }

        // Do any additional setup after loading the view.
        let imgPath = workDir + "Cache/" + imgName + ".jpg"
        caseImageView.image = UIImage.init(contentsOfFile: imgPath)
        
        if let caseTime = infoDict.value(forKey: "caseTime") as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss_SSS"
            dateFormatter.timeZone = TimeZone.current
            dateFormatter.locale = Locale.current
            caseDatePicker.date = dateFormatter.date(from: caseTime)!
        }
        
        if let loc = infoDict.value(forKey: "location") as? String {
            caseTextfield.text = loc
        }
    }

    @IBAction func changeCurrentLocation(_ sender: UITextField) {
        guard let infoDict = NSMutableDictionary.init(contentsOfFile:workDir + "infoDict.plist") else { return }
        
        let caseLocation = caseTextfield.text
        infoDict.setValue(caseLocation, forKey: "location")
        infoDict.write(toFile: workDir + "infoDict.plist", atomically: true)
    }
    @IBAction func changeCurrentTimeAction(_ sender: UIDatePicker) {
        guard let infoDict = NSMutableDictionary.init(contentsOfFile:workDir + "infoDict.plist") else { return }
        
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy_MM_dd_HH_mm_ss_SSS"
        let caseTime = dformatter.string(from: caseDatePicker.date)
        infoDict.setValue(caseTime, forKey: "caseTime")
        
        infoDict.write(toFile: workDir + "infoDict.plist", atomically: true)
    }
    @IBAction func btnSaveCaseAction(_ sender: Any) {
        guard let infoDict = NSMutableDictionary.init(contentsOfFile: workDir + "infoDict.plist"),
              let preViewName = infoDict.value(forKey: "preview") as? String else { return }
        
        let nameArr = preViewName.components(separatedBy: CharacterSet.init(charactersIn: "_"))
        var caseDir = ""
        for i in (0..<nameArr.count - 2) {
            caseDir += nameArr[i]
        }
        
        let dirName =  workDir + "Cases/" + caseDir + "/"
        if FileManager.default.fileExists(atPath: dirName) {
            //该案例已经存在
            deleteFileFromPath(nil, "Cases/" + caseDir)
        }
        
        //开始拷贝操作
        copyFilesFrom(dirName)
        
        let alertController = UIAlertController(title: "提示", message: "保存成功", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                style: .cancel,
                                                handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    @IBAction func btnUploadCaseAction(_ sender: Any) {
        guard let infoDict = NSMutableDictionary.init(contentsOfFile: workDir + "infoDict.plist"),
              let preViewName = infoDict.value(forKey: "preview") as? String else { return }
        
        let nameArr = preViewName.components(separatedBy: CharacterSet.init(charactersIn: "_"))
        var caseDir = ""
        for i in (0..<nameArr.count - 2) {
            caseDir += nameArr[i]
        }
        
        let toPath = workDir + caseDir + ".zip"
        let srcDir = workDir + "Cache/"
        SSZipArchive.createZipFile(atPath: toPath, withContentsOfDirectory: srcDir)
        
        //开始上传服务器了
        
        try! FileManager.default.removeItem(atPath: toPath)
    }
    
    func copyFilesFrom(_ dirName:String) {
        var tarDir = dirName + "Cache/"
        try! FileManager.default.createDirectory(atPath: tarDir, withIntermediateDirectories: true, attributes: nil)
        var srcDir = workDir + "Cache/"
        if let names = try? FileManager.default.contentsOfDirectory(atPath: srcDir) {
            for nm in names {
                if nm.contains(".jpg") {
                    try? FileManager.default.copyItem(atPath:srcDir + nm, toPath: tarDir + nm)
                }
            }
        }
        
        tarDir = dirName + "Thumb/"
        try! FileManager.default.createDirectory(atPath: tarDir, withIntermediateDirectories: true, attributes: nil)
        srcDir = workDir + "Thumb/"
        if let names = try? FileManager.default.contentsOfDirectory(atPath: srcDir) {
            for nm in names {
                if nm.contains(".jpg") {
                    try? FileManager.default.copyItem(atPath:srcDir + nm, toPath: tarDir + nm)
                }
            }
        }
        
        let srcPath = workDir + "infoDict.plist"
        let tarPath = dirName + "infoDict.plist"
        try? FileManager.default.copyItem(atPath:srcPath, toPath: tarPath)
    }
}


class OpenCaseViewController: SaveCaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        caseTextfield.isUserInteractionEnabled = false
        caseDatePicker.isUserInteractionEnabled = false
    }
    @IBAction func btnOpenCaseAction(_ sender: Any) {
        deleteFileFromPath(nil, "Cache")
        deleteFileFromPath(nil, "Thumb")
        deleteFileFromPath("infoDict.plist", nil)

        //先拷贝案例文件
        copyFilesFrom(NSHomeDirectory() + "/Documents/")
        
        //再打开该场景
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier:"PreView")
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
}
