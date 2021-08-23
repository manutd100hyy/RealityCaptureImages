//
//  SettingViewController.swift
//  RealityCaptureImages
//
//  Created by sytz on 2021/8/23.
//

import UIKit

class SettingViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    @IBAction func doOffsetingAction(_ sender: Any) {
        UserDefaults.standard.setValue((sender as! UITextField).text, forKey: "offset")
    }
}

extension SettingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "item", for: indexPath)
        
        let offsetView = cell.contentView.viewWithTag(6) as! UITextField
        offsetView.text = UserDefaults.standard.string(forKey: "offset")
        
        return cell
    }
}
