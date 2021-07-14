//
//  LogoViewController.swift
//  RealityCaptureImages
//
//  Created by sytz on 2021/7/13.
//

import UIKit

class LogoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func btnNewCaseAction(_ sender: Any) {
        deleteFileFromPath(nil, "Cache")
        deleteFileFromPath(nil, "Thumb")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier:"CapturePhoto")
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func btnLoadCaseAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier:"PreView")
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func btnMoreCasesAction(_ sender: Any) {
    }
    @IBAction func btnSettingAction(_ sender: Any) {
    }
}
