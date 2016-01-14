/*
ViewController.swift

Created by Walter Marchewka on 12/6/15.
Copyright © 2015 Walter Marchewka. All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit



class ViewController: UIViewController, SettingsViewDelegate, GraphicsViewDelegate {

    var glbIpAddress = "10.0.0.202"
    var glbSendError = false
    var log = ""

    var sendPacketCounter=0
    var glbTimerCounter = 0
    var testCounter = 0


    @IBOutlet weak var lblBatteryVoltageVal: UILabel!
    @IBOutlet weak var lblErrorVal: UILabel!
    @IBOutlet weak var lblIpAddressVal: UILabel!
    @IBOutlet weak var lblIdVal: UILabel!
    @IBOutlet weak var lblRssiSignalVal: UILabel!
    @IBOutlet weak var lblSendCounterVal: UILabel!

    @IBOutlet weak var txtAutoPollTime: UITextField!
    @IBOutlet weak var txtCoilRegister: UITextField!
    @IBOutlet weak var txtNumberofReadRegisters: UITextField!
    @IBOutlet weak var txtReadRegister: UITextField!
    @IBOutlet weak var txtWriteRegister: UITextField!
    @IBOutlet weak var txtWriteRegisterValue: UITextField!

    @IBOutlet weak var switchCoilValue: UISwitch!
    @IBOutlet weak var switchAutoPoll: UISwitch!

    @IBOutlet weak var btnClearLog: UIButton!
    @IBOutlet weak var btnDebugOff: UIButton!
    @IBOutlet weak var btnDebugON: UIButton!
    @IBOutlet weak var btnReboot: UIButton!
    @IBOutlet weak var btnRegisterDef: UIButton!
    @IBOutlet weak var btnReadRegister: UIButton!
    @IBOutlet weak var btnUpdate: UIButton!
    @IBOutlet weak var btnWriteCoil: UIButton!
    @IBOutlet weak var btnWriteRegisters: UIButton!
    @IBOutlet weak var btnWriteRegister: UIButton!


    @IBOutlet weak var imvLED16: UIImageView!

    @IBOutlet weak var stpCoilRegister: UIStepper!

    @IBOutlet weak var txtvLog: UITextView!

    var stream1 = StreamClass()

    override func viewDidLoad() {
        super.viewDidLoad()
        LC_SetupViewUI()
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

    @IBAction func IB_DebugOnPushed(sender: AnyObject) {
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

    @IBAction func IB_ClearLogButtonPushed(sender: AnyObject) {
        NSLog("Clear Log pushed")
        log=""
        self.txtvLog.text=log
    }

    @IBAction func IB_DebugOffPushed(sender: AnyObject) {
        NSLog("GDebug off pushed")
        //writeSingleCoil(21,DataByte: 0xff00)
    }

    @IBAction func IB_AutoSendButtonToggled(sender: AnyObject) {
        LC_AutoSendButtonPushed(switchAutoPoll.on)
    }

    @IBAction func IB_UpdatePushed(sender: AnyObject) {
        NSLog("OTA update button pushed")
        //writeSingleCoil(20,DataByte: 0xff00)
    }

    @IBAction func IB_AutoPollTimeChanged(sender: AnyObject) {
        stream1.StopAutoSendTimer()
        NSLog("Auto send timer killed")
        glbOkToFire=false
        NSLog("OK to fire is false")
        switchAutoPoll.on=false
        NSLog("Auto poll button is false")
        NSLog("Autopoll time changed")
        let newTime=(Double(txtAutoPollTime.text!)!)/1000
        stream1.SetupTimers(newTime)
        glbOkToFire=true
        NSLog("OK to fire set to true")
        switchAutoPoll.on=true
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

    @IBAction func IB_coilStepperRegisterChanged(sender: UIStepper) {
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
        lblIpAddressVal.text=ipAddress
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

    func LC_AutoSendButtonPushed(state: Bool ) {
        if state==false {
            NSLog("Auto poll button is off")
            stream1.StopAutoSendTimer()
            NSLog("Auto send timer terminated")
            glbOkToFire=false
            NSLog("OK to fire set to false")
            switchAutoPoll.on=false
        }
        else{
            NSLog("Auto poll button is on")
            stream1.SetupTimers(0.100)
            glbOkToFire=true
            NSLog("OK to fire set to true")
            switchAutoPoll.on=true
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

 
    func LC_SetupViewUI(){

        txtWriteRegister.text="5"
        txtReadRegister.text="23"
        txtCoilRegister.text="5"
        txtWriteRegisterValue.text="65521"
        txtAutoPollTime.text=String(glbAutoSendTimerValue)
        txtNumberofReadRegisters.text="2"

        lblIpAddressVal.text=glbIpAddress

        switchAutoPoll.on=false
        glbConnectionOpen=false

        btnWriteRegister.layer.backgroundColor = UIColor.blackColor().CGColor
        btnWriteRegister.layer.borderWidth = 3
        btnWriteRegister.layer.borderColor = UIColor.whiteColor().CGColor
        btnWriteRegister.layer.cornerRadius = 10
        btnWriteRegister.tintColor = UIColor.yellowColor()

        btnWriteRegisters.layer.backgroundColor = UIColor.blackColor().CGColor
        btnWriteRegisters.layer.borderWidth = 3
        btnWriteRegisters.layer.borderColor = UIColor.whiteColor().CGColor
        btnWriteRegisters.layer.cornerRadius = 10
        btnWriteRegisters.tintColor = UIColor.yellowColor()

        btnReadRegister.layer.backgroundColor = UIColor.blackColor().CGColor
        btnReadRegister.layer.borderWidth = 3
        btnReadRegister.layer.borderColor = UIColor.whiteColor().CGColor
        btnReadRegister.layer.cornerRadius = 10
        btnReadRegister.tintColor = UIColor.yellowColor()

        btnWriteCoil.layer.backgroundColor = UIColor.blackColor().CGColor
        btnWriteCoil.layer.borderWidth = 3
        btnWriteCoil.layer.borderColor = UIColor.whiteColor().CGColor
        btnWriteCoil.layer.cornerRadius = 10
        btnWriteCoil.tintColor = UIColor.yellowColor()
        
        stpCoilRegister.wraps = true
        stpCoilRegister.autorepeat = true
        stpCoilRegister.maximumValue = 50
        stpCoilRegister.minimumValue = 0

        
    }
}