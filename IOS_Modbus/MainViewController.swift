//
//  ViewController.swift
//
//
//  Created by Walter Marchewka on 12/6/15.
//  Copyright © 2015 Walter Marchewka. All rights reserved.
//

import UIKit

var glbOkToFire = true
var glbOutgoingBytes:[UInt8] = []

class ViewController: UIViewController, SettingsViewDelegate, GraphicsViewDelegate {

    struct registerDef_t {
        var regnum:UInt16 = 0
        var EEreg:UInt16 = 0
        var regtype:UInt16 = 0
        var write:UInt16 = 0
        var saveEE:UInt16 = 0
        var isIO:UInt16 = 0
        var isDigital:UInt16 = 0
        var ioMode:UInt16 = 0
        var ioPullup:UInt16 = 0
        var reboot:UInt16 = 0
        var name:[UInt16] = [UInt16](count:12, repeatedValue:0)
    }

    //TRANSID_1 TRANSID_2 PROTOCOLID_1 PROTOCOLID_2 PACKETLENGTH UNITID FUNCCODE DATABYTES (1-XX)
    struct outgoing_queue_t {
        var UnitID:UInt8 = 0x00
        var FunctionCode:UInt8 = 0x00
        var DataAddress:UInt16?
        var NumberofRegisters:UInt16? = 0x00
        var dataRegisters:[UInt16]? = [UInt16](count:512, repeatedValue:0)
    }

    var registerDef = [registerDef_t] (count:1000, repeatedValue:registerDef_t())
    var outgoingQueue = [outgoing_queue_t]()

    var glbIpAddress = "10.0.0.202"
    var glbSendError = false
    var ReadyToSend = true
    var log = ""

    let READ_COIL_STATUS:UInt8 = 01
    let READ_INPUT_STATUS:UInt8 = 02
    let READ_HOLDING_REGISTERS:UInt8 = 03
    let READ_INPUT_REGISTERS:UInt8 = 04
    let WRITE_SINGLE_COIL:UInt8 = 05
    let WRITE_SINGLE_REGISTER:UInt8 = 06
    let WRTIE_MULTIPLE_COILS:UInt8 = 15
    let WRITE_MUTIPLE_REGISTERS:UInt8 = 16

    var TransactionID_1:UInt8 = 0x00
    var TransactionID_2:UInt8 = 0x00
    var ProtocolID_1:UInt8 = 0x00
    var ProtocolID_2:UInt8 = 0x00
    var Timer = NSTimer()
    var SendPacketCounter=0

    var glbTimerCounter = 0
    var glbioPins:[UInt16] = [UInt16](count:100, repeatedValue:0)
    var glbAutoSendTimerValue:Double = 0.100

    let glbSizeOfSingleRegisterDef = 15

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
    var SingletonClass = Singleton()

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

    @IBAction func RebootPushed(sender: AnyObject) {
        NSLog("Reboot button pushed")
        writeSingleCoil(20,DataByte: 0)
    }

    @IBAction func TestButtonPushed(sender: AnyObject) {

    }

    @IBAction func txtDebugOnPushed(sender: AnyObject) {
        NSLog("Debug on pushed")
        //      writeSingleCoil(21,DataByte: 0)

    }

    @IBAction func registerDefButtonPushed(sender: AnyObject) {
        NSLog("Get Register Def pushed")
        outgoingQueue.append(outgoing_queue_t(
            UnitID: 1,
            FunctionCode: READ_HOLDING_REGISTERS,
            DataAddress:200,
            NumberofRegisters: 225,
            dataRegisters: []))
        NSLog("packet added to outgoing queue")

        outgoingQueue.append(outgoing_queue_t(
            UnitID: 1,
            FunctionCode: READ_HOLDING_REGISTERS,
            DataAddress:425,
            NumberofRegisters: 150,
            dataRegisters: []))
        NSLog("packet added to outgoing queue")
    }

    @IBAction func clearlogButtonPushed(sender: AnyObject) {
        NSLog("Clear Log pushed")
        log=""
        self.txtViewError.text=log
    }

    @IBAction func txtDebugOffPushed(sender: AnyObject) {
        NSLog("GDebug off pushed")
        //writeSingleCoil(21,DataByte: 0xff00)
    }
    @IBAction func AutoSendButtonToggled(sender: AnyObject) {

        AutoSendButtonPushed(autoPollButton.on)
    }
    @IBAction func txtUpdatePushed(sender: AnyObject) {
        NSLog("OTA update button pushed")
        //writeSingleCoil(20,DataByte: 0xff00)
    }
    @IBAction func AutoPollTimeChanged(sender: AnyObject) {
        Timer.invalidate()
        NSLog("Auto send timer killed")
        glbOkToFire=false
        NSLog("OK to fire is false")
        autoPollButton.on=false
        NSLog("Auto poll button is false")
        NSLog("Autopoll time changed")
        let newTime=(Double(txtAutoPollTime.text!)!)/1000
        SetupTimers(newTime)
        glbOkToFire=true
        NSLog("OK to fire set to true")
        autoPollButton.on=true
        NSLog("Auto poll button is true")
    }

    @IBAction func writeSingleCoil(sender : UIButton) {

        acceptControlReference(SendCounter)

        let DataAddress = UInt16(txtCoilRegister.text!)!
        var tmpDataRegisters = [UInt16]()
        if (switchCoilValue.on) {
            tmpDataRegisters.append(0xff00)
        }
        else {
            tmpDataRegisters.append(0x0000)
        }
        NSLog("Write single coil to address \(DataAddress) value of \(tmpDataRegisters)")
        outgoingQueue.append(outgoing_queue_t(
            UnitID: 1,
            FunctionCode: 5,
            DataAddress:DataAddress,
            NumberofRegisters: 0,
            dataRegisters: tmpDataRegisters))
        NSLog("packet added to outgoing queue")
    }

    func acceptControlReference( obj: AnyObject){

        let viewMirror = Mirror(reflecting: obj).subjectType
        print("type \(viewMirror)")

        if let sometext =  obj as? UILabel {
            sometext.text = "walt"
        }
    }

    @IBAction func coilRegisterChanged(sender: UIStepper) {
        NSLog("Coil register stepper pushed")
        txtCoilRegister.text=Int(sender.value).description
    }

    @IBAction func writeRegister(sender : AnyObject) {
        var tmpDataRegisters = [UInt16]()
        let tmpValue = UInt16(txtWriteRegisterValue.text!)!
        tmpDataRegisters.append(tmpValue)
        let DataAddress = UInt16(txtWriteRegister.text!)!
        let NumberOfRegisters:UInt16 = 1
        NSLog("Write register pushed")
        NSLog("Write register to address \(DataAddress) value of \(tmpValue)")
        outgoingQueue.append(outgoing_queue_t(UnitID: 1,
            FunctionCode:6,
            DataAddress:DataAddress,
            NumberofRegisters: NumberOfRegisters,
            dataRegisters: tmpDataRegisters))
        NSLog("packet added to outgoing queue")
    }

    @IBAction func readRegister(sender : AnyObject?) {

        let tmpDataAddressStart = UInt16(txtReadRegister.text!)!
        let tmpNumberofReadRegisters = UInt16(txtNumberofReadRegisters.text!)!

        NSLog("Read register pushed")
        NSLog("Read from address \(tmpDataAddressStart) for \(tmpNumberofReadRegisters) registers")
        outgoingQueue.append(outgoing_queue_t(UnitID: 1,
            FunctionCode: 3,
            DataAddress:tmpDataAddressStart,
            NumberofRegisters: tmpNumberofReadRegisters,
            dataRegisters: []))
        NSLog("packet added to outgoing queue")
    }



    // Called from the settingsviewcontroller via delegation
    func setIPAddress(ipAddress: String) {
        NSLog("set IP Address called")
        txtIPAddress.text=ipAddress
        glbIpAddress=ipAddress
    }

    // Received from the GraphicsViewController via delegation
    func  setTestButtonVal(testButtonVal: Bool) {
        NSLog("Graphics view controller set test button pushed")
        UIApplication.sharedApplication().idleTimerDisabled = testButtonVal
    }

    func TestReturnFunction() -> Array<UInt16> {
        NSLog("Test return function called")
        return glbioPins
    }

    // Received from the SettingsViewController via delegation
    func  setAwake(Awake: Bool) {
        NSLog("Settings view controller set awake button pushed")
        UIApplication.sharedApplication().idleTimerDisabled = Awake
    }

    func AutoSendButtonPushed(state: Bool ) {

        if state==false {
            NSLog("Auto poll button is off")
            Timer.invalidate()
            NSLog("Auto send timer terminated")
            glbOkToFire=false
            NSLog("OK to fire set to false")
            autoPollButton.on=false
        }
        else{
            NSLog("Auto poll button is on")
            SetupTimers(0.100)
            glbOkToFire=true
            NSLog("OK to fire set to true")
            autoPollButton.on=true
        }
    }

    func Process_Outgoing_Queue(){

        //NSLog("Outgoing queue length \(outgoingQueue.count)")

        if ( (outgoingQueue.count>0) && (glbOkToFire) ) {
            glbOkToFire=false
            let tmpStartRegister=outgoingQueue[0].DataAddress
            let tmpNumberOfRegisters=outgoingQueue[0].NumberofRegisters
            glbOutgoingBytes=[]
            glbOutgoingBytes.append(TransactionID_1)
            glbOutgoingBytes.append(TransactionID_2)
            glbOutgoingBytes.append(ProtocolID_1)
            glbOutgoingBytes.append(ProtocolID_2)

            switch (outgoingQueue[0].FunctionCode) {

            case 3:
                NSLog("Setting up FC3 Read Holding register")
                let DataAddress_1 = tmpStartRegister! / 256
                let DataAddress_2 = tmpStartRegister! - (DataAddress_1 * 256)
                let NumberOfRegisters_1 = tmpNumberOfRegisters! / 256
                let NumberOfRegisters_2 = tmpNumberOfRegisters! - (NumberOfRegisters_1 * 256)
                glbOutgoingBytes.append(0)
                glbOutgoingBytes.append(6)
                glbOutgoingBytes.append(outgoingQueue[0].UnitID)
                glbOutgoingBytes.append(outgoingQueue[0].FunctionCode)
                glbOutgoingBytes.append(UInt8(DataAddress_1))
                glbOutgoingBytes.append(UInt8(DataAddress_2))
                glbOutgoingBytes.append(UInt8(NumberOfRegisters_1))
                glbOutgoingBytes.append(UInt8(NumberOfRegisters_2))

            case 5:
                NSLog("Setting up FC5 Write Single Coil")
                let DataAddress_1 = tmpStartRegister! / 256
                let DataAddress_2 = tmpStartRegister! - (DataAddress_1 * 256)
                glbOutgoingBytes.append(0)
                glbOutgoingBytes.append(6)
                glbOutgoingBytes.append(outgoingQueue[0].UnitID)
                glbOutgoingBytes.append(outgoingQueue[0].FunctionCode)
                glbOutgoingBytes.append(UInt8(DataAddress_1))
                glbOutgoingBytes.append(UInt8(DataAddress_2))
                let tmpArray = outgoingQueue[0].dataRegisters!
                let count = tmpArray.count
                for var x=0; x < count; x++ {
                    glbOutgoingBytes.append(UInt8(tmpArray[x] / 256))
                    glbOutgoingBytes.append(UInt8(tmpArray[x] - (tmpArray[x] / 256) * 256 ) )
                }

            case 6:
                NSLog("Setting up FC6 Write Register(s)")
                let DataAddress_1 = tmpStartRegister! / 256
                let DataAddress_2 = tmpStartRegister! - (DataAddress_1 * 256)
                glbOutgoingBytes.append(0)
                glbOutgoingBytes.append(6)
                glbOutgoingBytes.append(outgoingQueue[0].UnitID)
                glbOutgoingBytes.append(outgoingQueue[0].FunctionCode)
                glbOutgoingBytes.append(UInt8(DataAddress_1))
                glbOutgoingBytes.append(UInt8(DataAddress_2))
                let tmpArray = outgoingQueue[0].dataRegisters!
                let count = tmpArray.count
                for var x=0; x < count; x++ {
                    glbOutgoingBytes.append(UInt8(tmpArray[x] / 256))
                    glbOutgoingBytes.append(UInt8(tmpArray[x] - (tmpArray[x] / 256) * 256 ) )
                }

            default:
                NSLog("Incorrect outgoing function number")
            }

            NSLog("Processing outgoing queue")
            outgoingQueue.removeFirst()
            NSLog("Data placed in glbOutgoingData")
            glbRTS=true
            NSLog("glbRTS set to true")
            stream1.connectSocket()

            stream1.onDataReceived { (dataReceived) -> Void in
                self.SendCounter.text=String(glbSendPacketCounter)
                NSLog("Outgoing queue callback invoked")
                self.SendCounter.text=String(glbSendPacketCounter)
                self.stream1.CloseSocket()
                glbOkToFire=true
                self.txtViewError.text = String(dataReceived)


                switch dataReceived[7] {                                            //return packet function code

                case 3:
                    NSLog("Parsing needed of read holding registers")
                    self.parseReadReturnData(dataReceived,
                        start: tmpStartRegister!,
                        numberOfRegister: tmpNumberOfRegisters!)

                case 5:                                                             //write single coil
                    NSLog("No parsing needed of write single coil incoming data")

                case 6:                                                             //write single coil
                    NSLog("No parsing needed of write register(s) incoming data")

                default:
                    NSLog("Parse return data error")

                }
            }
        }
        else{
            //NSLog("Nothing to proces in outgoing queue")
        }
    }

    func writeSingleCoil(DataAddress:Int,DataByte:Int) {
        NSLog("Write single coil function called")

    }

    func readRegister(StartRegister:Int,NumberofRegisters:Int){

    }

    func OpenTimedout() {
        NSLog("Connection timeout")
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

    func doErrors(Error: NSError){
        let errorString = Error.localizedDescription
        print(errorString)
        //log = errorString + "\n" + log
        print("i")
        glbSendError = true
    }

    func parseReadReturnData(var data:ArraySlice<UInt8>, start:UInt16, numberOfRegister:UInt16) {

        NSLog("Parsing read return data")

        var wordData:[UInt16] = [UInt16](count:data.count / 2, repeatedValue:0)

        //first convert byte data to word data
        for var tmpRegister=0;tmpRegister < (data.count) / 2; tmpRegister++ {
            wordData[tmpRegister]=UInt16(data[tmpRegister*2])*256 + UInt16(data[tmpRegister*2+1])
        }

        //remove 10 header bytes
        wordData[0...4] = []
        for var register=0;register < (wordData.count); register++ {
            let actualRegister = Int(start) + Int(register)

            switch actualRegister {


            case 0:
                self.BatteryVoltageLabel.text = String(wordData[register])

            case 1:
                self.rssiSignalLabel.text = String(wordData[register])

            case 2:
                self.IdLabel.text=String(wordData[register])

            case 23:
                glbioPins[0] =  (wordData[register] &  0b0000000000000001 ) >> 0
                glbioPins[2] =  (wordData[register] &  0b0000000000000010 ) >> 2
                glbioPins[4] =  (wordData[register] &  0b0000000000001000 ) >> 4
                glbioPins[5] =  (wordData[register] &  0b0000000000010000 ) >> 5
                glbioPins[12] = (wordData[register] &  0b0001000000000000 ) >> 12
                glbioPins[13] = (wordData[register] &  0b0010000000000000 ) >> 13
                glbioPins[14] = (wordData[register] &  0b0100000000000000 ) >> 14
                glbioPins[15] = (wordData[register] &  0b1000000000000000 ) >> 15

            case 24:
                glbioPins[16] = (wordData[register] &  0b0000000000000001 ) >> 0
                if glbioPins[16]==1 {
                    let image = UIImage(named: "white.png")
                    LED16.image = image
                }
                else
                {
                    let image = UIImage(named: "red.png")
                    LED16.image = image
                }
                let reference:Int=0b00100000
                let result:Int = Int(wordData[register]) & reference
                if (result==reference) {
                    self.txtDebugON.hidden=false
                    self.txtDebugOff.hidden=true
                }
                else
                {
                    self.txtDebugON.hidden=true
                    self.txtDebugOff.hidden=false
                }

                //try and fix this
            case 200,
            200+glbSizeOfSingleRegisterDef,
            200+glbSizeOfSingleRegisterDef*2,
            200+glbSizeOfSingleRegisterDef*3,
            200+glbSizeOfSingleRegisterDef*4,
            200+glbSizeOfSingleRegisterDef*5,
            200+glbSizeOfSingleRegisterDef*6,
            200+glbSizeOfSingleRegisterDef*7,
            200+glbSizeOfSingleRegisterDef*8,
            200+glbSizeOfSingleRegisterDef*9,
            200+glbSizeOfSingleRegisterDef*10,
            200+glbSizeOfSingleRegisterDef*11,
            200+glbSizeOfSingleRegisterDef*12,
            200+glbSizeOfSingleRegisterDef*13,
            200+glbSizeOfSingleRegisterDef*14,
            200+glbSizeOfSingleRegisterDef*15,
            200+glbSizeOfSingleRegisterDef*16,
            200+glbSizeOfSingleRegisterDef*17,
            200+glbSizeOfSingleRegisterDef*18,
            200+glbSizeOfSingleRegisterDef*19,
            200+glbSizeOfSingleRegisterDef*20,
            200+glbSizeOfSingleRegisterDef*21,
            200+glbSizeOfSingleRegisterDef*22,
            200+glbSizeOfSingleRegisterDef*23,
            200+glbSizeOfSingleRegisterDef*24,
            200+glbSizeOfSingleRegisterDef*25:
                let tmp = (actualRegister - 200) / glbSizeOfSingleRegisterDef
                registerDef[tmp].regnum =      wordData[0 + register]
                registerDef[tmp].EEreg =       wordData[1 + register]
                registerDef[tmp].regtype =    (wordData[2 + register] & 0b10000000 ) >> 7
                registerDef[tmp].write =      (wordData[2 + register] & 0b01000000 ) >> 6
                registerDef[tmp].saveEE =     (wordData[2 + register] & 0b00100000 ) >> 5
                registerDef[tmp].isIO  =      (wordData[2 + register] & 0b00010000 ) >> 4
                registerDef[tmp].isDigital =  (wordData[2 + register] & 0b00001000 ) >> 3
                registerDef[tmp].ioMode   =   (wordData[2 + register] & 0b00000100 ) >> 2
                registerDef[tmp].ioPullup =   (wordData[2 + register] & 0b00000010 ) >> 1
                registerDef[tmp].reboot =      wordData[2 + register] & 0b00000001
                for var index2 = 0; index2 <= 11;index2++ {
                    registerDef[tmp].name[index2] =  UInt16(wordData[3 + index2 + register])
                }

            default:
                break
                //NSLog("Not found \(actualRegister)")

            }
        }
    }

    func AutoSend() {

        NSLog("Auto send timer fired")
        outgoingQueue.append(outgoing_queue_t(UnitID: 1,
            FunctionCode: READ_HOLDING_REGISTERS,
            DataAddress:23,
            NumberofRegisters: 2,
            dataRegisters: []))
        Process_Outgoing_Queue()
        NSLog("Test counter in auto send \(testCounter)")
        testCounter++
    }

    func SetupTimers(value:Double) {
        NSLog("Auto send timer started with interval \(value)")
        Timer = NSTimer.scheduledTimerWithTimeInterval(value,
            target: self,
            selector: "AutoSend",
            userInfo: nil,
            repeats: true)
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