//
//  ViewController.swift
//  
//
//  Created by Walter Marchewka on 12/6/15.
//  Copyright © 2015 Walter Marchewka. All rights reserved.
//



var glbIpAddress = "10.0.0.202"

import UIKit

let objLibModbus = ObjectiveLibModbus(TCP: glbIpAddress, port: 502, device: 1)

var log = ""


class ViewController: UIViewController, SettingsViewDelegate, GraphicsViewDelegate {
    
    var Timer = NSTimer()
    
    
    @IBOutlet weak var connectedLabel: UILabel!
    @IBOutlet weak var rssiSignalLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var BatteryVoltageLabel: UILabel!
    @IBOutlet weak var txtIPAddress: UILabel!
    
    @IBOutlet weak var txtWriteRegister: UITextField!
    @IBOutlet weak var txtReadRegister: UITextField!
    @IBOutlet weak var txtReturnRegisters: UITextField!
    @IBOutlet weak var txtCoilRegister: UITextField!
    
    @IBOutlet weak var switchCoilValue: UISwitch!
    @IBOutlet weak var autoPollButton: UISwitch!
    
    @IBOutlet weak var writeRegistersButton: UIButton!
    @IBOutlet weak var writeRegisterButton: UIButton!
    @IBOutlet weak var readRegisterButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var writeCoilButton: UIButton!
    
    @IBOutlet weak var CoilRegisterStepper: UIStepper!
    
    @IBOutlet weak var txtViewError: UITextView!
    
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        
        
        Timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "OneSecondInterval", userInfo: nil, repeats: true)
        
        
        txtWriteRegister.text="00000"
        txtReadRegister.text="00000"
        txtCoilRegister.text="0"
        txtIPAddress.text=glbIpAddress
        connectedLabel.text="Waiting connection"
        
        
        writeRegisterButton.layer.backgroundColor = UIColor.blackColor().CGColor
        writeRegisterButton.layer.borderWidth = 3
        writeRegisterButton.layer.borderColor = UIColor.whiteColor().CGColor
        writeRegisterButton.layer.cornerRadius = 10
        writeRegisterButton.tintColor = UIColor.yellowColor()
        
        writeRegistersButton.layer.backgroundColor = UIColor.blackColor().CGColor
        writeRegistersButton.layer.borderWidth = 3
        writeRegistersButton.layer.borderColor = UIColor.whiteColor().CGColor
        writeRegistersButton.layer.cornerRadius = 10
        writeRegistersButton.tintColor = UIColor.yellowColor()
        
        connectButton.layer.backgroundColor = UIColor.blackColor().CGColor
        connectButton.layer.borderWidth = 3
        connectButton.layer.borderColor = UIColor.whiteColor().CGColor
        connectButton.layer.cornerRadius = 10
        connectButton.tintColor = UIColor.yellowColor()
        
        readRegisterButton.layer.backgroundColor = UIColor.blackColor().CGColor
        readRegisterButton.layer.borderWidth = 3
        readRegisterButton.layer.borderColor = UIColor.whiteColor().CGColor
        readRegisterButton.layer.cornerRadius = 10
        readRegisterButton.tintColor = UIColor.yellowColor()
        
        disconnectButton.layer.backgroundColor = UIColor.blackColor().CGColor
        disconnectButton.layer.borderWidth = 3
        disconnectButton.layer.borderColor = UIColor.whiteColor().CGColor
        disconnectButton.layer.cornerRadius = 10
        disconnectButton.tintColor = UIColor.yellowColor()
        
        writeCoilButton.layer.backgroundColor = UIColor.blackColor().CGColor
        writeCoilButton.layer.borderWidth = 3
        writeCoilButton.layer.borderColor = UIColor.whiteColor().CGColor
        writeCoilButton.layer.cornerRadius = 10
        writeCoilButton.tintColor = UIColor.yellowColor()
        
        CoilRegisterStepper.wraps = true
        CoilRegisterStepper.autorepeat = true
        CoilRegisterStepper.maximumValue = 10
        CoilRegisterStepper.minimumValue = 0
        autoPollButton.on=false
        
        //connectToServer()
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // during viewDidLoad in the destination.
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showSettingsViewController") {
            let destination = segue.destinationViewController as! SettingsViewController
            destination.delegate = self
            destination.ipAddressText=glbIpAddress
            destination.awake=UIApplication.sharedApplication().idleTimerDisabled
        }
    }
    
    // Called from the settingsviewcontroller via delegation
    func setIPAddress(ipAddress: String) {
        txtIPAddress.text=ipAddress
        glbIpAddress=ipAddress
    }
    
    // Received from the SettingsViewController via delegation
    func  setAwake(Awake: Bool) {
        UIApplication.sharedApplication().idleTimerDisabled = Awake
    }
    
    // Received from the GraphicsViewController via delegation
    func  setTestButtonVal(testButtonVal: Bool) {
        UIApplication.sharedApplication().idleTimerDisabled = testButtonVal
    }
    
    @IBAction func sendRegister(sender : AnyObject) {
        let registerToSend = Int32(txtWriteRegister.text!)
        objLibModbus.writeRegister(25, to: registerToSend!, success: {() -> Void in
            print("Writing register suceed")
            log = "Writing single register SUCCEEDED\n" + log
            self.txtViewError.text = log
            self.errorLabel.text = "Writing single register SUCCEEDED"
            
            }, failure: {(error: NSError!) -> Void in
                print("Writing single register FAILED")
                log = "Writing single register FAILED\n" + log
                self.txtViewError.text = log
                self.errorLabel.text = "Writing single register FAILED "
                self.doErrors(error);
                self.txtViewError.text = log
        })
    }
    
    @IBAction func coilRegisterChanged(sender: UIStepper) {
        
        self.txtCoilRegister.text="\(Int(sender.value))"
        print("Switch value is ")
        print(txtCoilRegister.text)
    }
    
    
    @IBAction func writeSingleCoil(sender : AnyObject) {
        
        //var ErrorList: NSError? = nil
        print("writing single coil")
        let registerToRead = Int32(txtCoilRegister.text!)
        let switchValToSend = Bool(switchCoilValue.on)
        objLibModbus.writeBit(registerToRead!, to:switchValToSend, success: { () -> Void in
            self.errorLabel.text = "Writing single coil SUCCEEDED"
            print("Writing single coil SUCCEEDED")
            log = "Writing single coil SUCCEEDED\n" + log
            self.txtViewError.text = log
            }, failure: {(error: NSError!) -> Void in
                self.errorLabel.text = "Writing single coil FAILED"
                print("Writing single coil FAILED")
                log = "Writing single coil FAILED\n" + log
                self.doErrors(error)
                self.txtViewError.text = log
        })
    }
    
    
    
    @IBAction func readRegister(sender : AnyObject?) {
        print("Reading register")
        let registerToRead = Int32(txtReadRegister.text!)
        //var returnData: Array<AnyObject>=[]
        objLibModbus.readRegistersFrom(registerToRead!, count: 20, success: {(returnData) -> Void in
            print("Array: ", returnData)
            self.errorLabel.text = "Reading single register SUCCEEDED"
            self.txtReturnRegisters.text=String(returnData)
            log = "Reading single register SUCCEEDED\n" + log
            self.txtViewError.text = log
            let x = returnData[0].floatValue
            self.BatteryVoltageLabel.text=String.localizedStringWithFormat("%.3f", (x / 1000))
            self.rssiSignalLabel.text=String(returnData[1])
            }, failure: {(error: NSError!) -> Void in
                self.errorLabel.text = "Reading single register FAILED"
                log = "Reading single register FAILED\n" + log
                self.doErrors(error)
                self.txtViewError.text = log
        })
    }
    
    func connectToServer() {
        objLibModbus.connect({() -> Void in
            self.connectedLabel.text = "Connecting SUCCEEDED!"
            self.writeRegisterButton.enabled = true
            self.writeRegistersButton.enabled = true
            log = "Connecting SUCCEEDED!\n" + log
            self.txtViewError.text = log
            }, failure: {(error: NSError!) -> Void in
                self.connectedLabel.text = "Connecting FAILED!"
                self.errorLabel.text = "Connecting FAILED"
                log = "Connecting FAILED!\n" + log
                self.doErrors(error)
                self.txtViewError.text = log
                
        })
    }
    
    func doErrors(Error: NSError){
        let errorString = Error.localizedDescription
        print(errorString)
        log = errorString + "\n" + log
        print("i")
    }
    
    
    func disconnectServer() {
        objLibModbus.disconnect()
        self.connectedLabel.text = "DISCONNECTED"
        log = "DISCONNECTED!\n" + log
        self.txtViewError.text = log
        print("Disconnect from server....")
    }
    
    @IBAction func closeConnection(sender : AnyObject) {
        disconnectServer()
    }
    
    @IBAction func openConnection(sender : AnyObject) {
        
        connectToServer()
        print("Connect to server...")
    }
    
    func OneSecondInterval() {
        if autoPollButton.on {
            print("Firing every second")
            readRegister(nil)
        }
    }
    
}
