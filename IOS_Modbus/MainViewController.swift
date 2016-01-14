//
//  ViewController.swift
//
//
//  Created by Walter Marchewka on 12/6/15.
//  Copyright © 2015 Walter Marchewka. All rights reserved.
//

import UIKit

var glbOkToFire = true

class ViewController: UIViewController, SettingsViewDelegate, GraphicsViewDelegate {

    var glbIpAddress = "10.0.0.202"
    var glbSendError = false
    var ReadyToSend = true
    var log = ""


    var SendPacketCounter=0
    var glbTimerCounter = 0
    var testCounter = 0



    @IBOutlet weak var IdLabel: UILabel!
    @IBOutlet weak var SendCounter: UILabel!
    @IBOutlet weak var connectedLabel: UILabel!
    @IBOutlet weak var rssiSignalLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var BatteryVoltageLabel: UILabel!
    @IBOutlet weak var txtIPAddress: UILabel!

    @IBOutlet weak var txtWriteRegister: UITextField!
    @IBOutlet weak var txtReadRegister: UITextField!
    @IBOutlet weak var txtReturnRegisters: UITextField!
    @IBOutlet weak var txtCoilRegister: UITextField!
    @IBOutlet weak var txtWriteRegisterValue: UITextField!
    @IBOutlet weak var txtAutoPollTime: UITextField!
    @IBOutlet weak var txtNumberofReadRegisters: UITextField!

    @IBOutlet weak var switchCoilValue: UISwitch!
    @IBOutlet weak var autoPollButton: UISwitch!

    @IBOutlet weak var writeRegistersButton: UIButton!
    @IBOutlet weak var writeRegisterButton: UIButton!
    @IBOutlet weak var readRegisterButton: UIButton!
    @IBOutlet weak var writeCoilButton: UIButton!
    @IBOutlet weak var txtDebugOff: UIButton!
    @IBOutlet weak var txtDebugON: UIButton!
    @IBOutlet weak var txtUpdateButton: UIButton!
    @IBOutlet weak var testbutton: UIButton!
    @IBOutlet weak var rebootButton: UIButton!
    @IBOutlet weak var clearLogButton: UIButton!
    @IBOutlet weak var registerDefButton: UIButton!

    @IBOutlet weak var LED16: UIImageView!

    @IBOutlet weak var CoilRegisterStepper: UIStepper!

    @IBOutlet weak var txtViewError: UITextView!

    var stream1 = StreamClass()


    override func viewDidLoad() {
        super.viewDidLoad()
        SetupViewUI()
    }

    //this listens for call back from the seques create to other viewcontrolls
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showSettingsViewController") {
            NSLog("Setting view controller segue prepared")
            let destinationSettings = segue.destinationViewController as! SettingsViewController
            destinationSettings.delegate = self
            destinationSettings.ipAddressText=glbIpAddress
            destinationSettings.awake=UIApplication.sharedApplication().idleTimerDisabled
        }

        if (segue.identifier == "showGraphicsViewController") {
            NSLog("Setting view controller segue prepared")
            let destinationGraphics = segue.destinationViewController as! GraphicsViewController
            destinationGraphics.delegate = self
            //destination.awake=UIApplication.sharedApplication().idleTimerDisabled
        }
    }

    @IBAction func IB_RebootPushed(sender: AnyObject) {
        NSLog("Reboot button pushed")
        //writeSingleCoil(20,DataByte: 0)
    }

    @IBAction func TestButtonPushed(sender: AnyObject) {

    }

    @IBAction func IB_txtDebugOnPushed(sender: AnyObject) {
        NSLog("Debug on pushed")
        //      writeSingleCoil(21,DataByte: 0)

    }

    @IBAction func IB_registerDefButtonPushed(sender: AnyObject) {
        NSLog("Get Register Def pushed")
        stream1.outgoingQueue.append(StreamClass.outgoing_queue_t(
            UnitID: 1,
            FunctionCode: READ_HOLDING_REGISTERS,
            DataAddress:200,
            NumberofRegisters: 225,
            dataRegisters: []))
        NSLog("packet added to outgoing queue")

        stream1.outgoingQueue.append(StreamClass.outgoing_queue_t(
            UnitID: 1,
            FunctionCode: READ_HOLDING_REGISTERS,
            DataAddress:425,
            NumberofRegisters: 150,
            dataRegisters: []))
        NSLog("packet added to outgoing queue")
    }

    @IBAction func IB_clearlogButtonPushed(sender: AnyObject) {
        NSLog("Clear Log pushed")
        log=""
        self.txtViewError.text=log
    }

    @IBAction func IB_txtDebugOffPushed(sender: AnyObject) {
        NSLog("GDebug off pushed")
        //writeSingleCoil(21,DataByte: 0xff00)
    }
    @IBAction func IB_AutoSendButtonToggled(sender: AnyObject) {
        AutoSendButtonPushed(autoPollButton.on)
    }

    @IBAction func IB_txtUpdatePushed(sender: AnyObject) {
        NSLog("OTA update button pushed")
        //writeSingleCoil(20,DataByte: 0xff00)
    }

    @IBAction func IB_AutoPollTimeChanged(sender: AnyObject) {
        stream1.StopAutoSendTimer()
        NSLog("Auto send timer killed")
        glbOkToFire=false
        NSLog("OK to fire is false")
        autoPollButton.on=false
        NSLog("Auto poll button is false")
        NSLog("Autopoll time changed")
        let newTime=(Double(txtAutoPollTime.text!)!)/1000
        stream1.SetupTimers(newTime)
        glbOkToFire=true
        NSLog("OK to fire set to true")
        autoPollButton.on=true
        NSLog("Auto poll button is true")
    }

    @IBAction func IB_writeSingleCoil(sender : UIButton) {
        let DataAddress = UInt16(txtCoilRegister.text!)!
        var tmpDataRegisters = [UInt16]()
        if (switchCoilValue.on) {
            tmpDataRegisters.append(0xff00)
        }
        else {
            tmpDataRegisters.append(0x0000)
        }
        NSLog("Write single coil to address \(DataAddress) value of \(tmpDataRegisters)")
        stream1.outgoingQueue.append(StreamClass.outgoing_queue_t(
            UnitID: 1,
            FunctionCode: 5,
            DataAddress:DataAddress,
            NumberofRegisters: 0,
            dataRegisters: tmpDataRegisters))
        NSLog("packet added to outgoing queue")
    }

    @IBAction func IB_coilRegisterChanged(sender: UIStepper) {
        NSLog("Coil register stepper pushed")
        txtCoilRegister.text=Int(sender.value).description
    }

    @IBAction func IB_writeRegister(sender : AnyObject) {
        var tmpDataRegisters = [UInt16]()
        let tmpValue = UInt16(txtWriteRegisterValue.text!)!
        tmpDataRegisters.append(tmpValue)
        let DataAddress = UInt16(txtWriteRegister.text!)!
        let NumberOfRegisters:UInt16 = 1
        NSLog("Write register pushed")
        NSLog("Write register to address \(DataAddress) value of \(tmpValue)")
        stream1.outgoingQueue.append(StreamClass.outgoing_queue_t(
            UnitID: 1,
            FunctionCode:6,
            DataAddress:DataAddress,
            NumberofRegisters: NumberOfRegisters,
            dataRegisters: tmpDataRegisters))
        NSLog("packet added to outgoing queue")
    }

    @IBAction func IB_readRegister(sender : AnyObject?) {
        let tmpDataAddressStart = UInt16(txtReadRegister.text!)!
        let tmpNumberofReadRegisters = UInt16(txtNumberofReadRegisters.text!)!

        NSLog("Read register pushed")
        NSLog("Read from address \(tmpDataAddressStart) for \(tmpNumberofReadRegisters) registers")
        stream1.outgoingQueue.append(StreamClass.outgoing_queue_t(
            UnitID: 1,
            FunctionCode: 3,
            DataAddress:tmpDataAddressStart,
            NumberofRegisters: tmpNumberofReadRegisters,
            dataRegisters: []))
        NSLog("packet added to outgoing queue")
    }

    func DG_setIPAddress(ipAddress: String) {
        NSLog("set IP Address called")
        txtIPAddress.text=ipAddress
        glbIpAddress=ipAddress
    }

    func  DG_setTestButtonVal(testButtonVal: Bool) {
        NSLog("Graphics view controller set test button pushed")
        UIApplication.sharedApplication().idleTimerDisabled = testButtonVal
    }

    func DG_TestReturnFunction() -> Array<UInt16> {
        NSLog("Test return function called")
        return glbioPins
    }

    // Received from the SettingsViewController via delegation
    func  DG_setAwake(Awake: Bool) {
        NSLog("Settings view controller set awake button pushed")
        UIApplication.sharedApplication().idleTimerDisabled = Awake
    }

    func AutoSendButtonPushed(state: Bool ) {
        if state==false {
            NSLog("Auto poll button is off")
            stream1.StopAutoSendTimer()
            NSLog("Auto send timer terminated")
            glbOkToFire=false
            NSLog("OK to fire set to false")
            autoPollButton.on=false
        }
        else{
            NSLog("Auto poll button is on")
            stream1.SetupTimers(0.100)
            glbOkToFire=true
            NSLog("OK to fire set to true")
            autoPollButton.on=true
        }
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
        NSLog("Touches began")
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

 
    func SetupViewUI(){
        txtWriteRegister.text="5"
        txtReadRegister.text="23"
        txtCoilRegister.text="5"
        txtWriteRegisterValue.text="65521"
        txtIPAddress.text=glbIpAddress
        connectedLabel.text="Waiting connection"
        txtAutoPollTime.text=String(glbAutoSendTimerValue)
        autoPollButton.on=true
        txtNumberofReadRegisters.text="2"

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

        readRegisterButton.layer.backgroundColor = UIColor.blackColor().CGColor
        readRegisterButton.layer.borderWidth = 3
        readRegisterButton.layer.borderColor = UIColor.whiteColor().CGColor
        readRegisterButton.layer.cornerRadius = 10
        readRegisterButton.tintColor = UIColor.yellowColor()

        writeCoilButton.layer.backgroundColor = UIColor.blackColor().CGColor
        writeCoilButton.layer.borderWidth = 3
        writeCoilButton.layer.borderColor = UIColor.whiteColor().CGColor
        writeCoilButton.layer.cornerRadius = 10
        writeCoilButton.tintColor = UIColor.yellowColor()
        
        CoilRegisterStepper.wraps = true
        CoilRegisterStepper.autorepeat = true
        CoilRegisterStepper.maximumValue = 50
        CoilRegisterStepper.minimumValue = 0
        autoPollButton.on=false
        glbConnectionOpen=false
        
    }
}