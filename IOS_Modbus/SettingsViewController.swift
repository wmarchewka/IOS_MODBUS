//
//  SettingsViewController.swift
//  mb_1
//
//  Created by Walter Marchewka on 12/11/15.
//  Copyright © 2015 Walter Marchewka. All rights reserved.
//


import UIKit

protocol SettingsViewDelegate {
    func DG_setIPAddress(ipAddress: String);
    func DG_setAwake(Awake: Bool);
}

class SettingsViewController: UIViewController{

    var delegate : SettingsViewDelegate! = nil
    var ipAddressText : String! = nil
    var awake : Bool! = nil

    @IBOutlet weak var txtIPAddress: UITextField!
    @IBOutlet weak var StayAwake: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        txtIPAddress.text=ipAddressText
        StayAwake.on = awake

        }


  
      // Sets the ip address delegate (MainViewController) and then pops to the root view
    @IBAction func ipChanged(sender: UITextField) {
        if let name = sender.text {
            delegate.DG_setIPAddress(name)
            self.navigationController?.popToRootViewControllerAnimated(true)
        } else {
            print("title is nil")
        }
    }
    
    @IBAction func setAwakeChanged(sender: UISwitch) {
            delegate.DG_setAwake(sender.on)
            //self.navigationController?.popToRootViewControllerAnimated(true)
        }
}
