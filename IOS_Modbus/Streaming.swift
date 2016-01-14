//
//  Streaming.swift
//  IOS_Modbus
//
//  Created by Walter Marchewka on 1/5/16.
//  Copyright © 2016 Walter Marchewka. All rights reserved.
//
import Foundation

let Read_Coil_Status:UInt8 = 01
let Read_Input_Status:UInt8 = 02
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


var glbRTS:Bool = true
var glbSendPacketCounter:Int=0
var glbReceivePacketCounter:Int=0
var glbBytesSent:Int=0
var glbConnectionOpen:Bool=false
var glbioPins:[UInt16] = [UInt16](count:100, repeatedValue:0)
var Timer = NSTimer()
var glbAutoSendTimerValue:Double = 0.100
var glbOkToFire = true
var glbOutgoingBytes:[UInt8] = []



class StreamClass: NSObject, NSStreamDelegate {


    private var dataReadCallback:((dataReceived:ArraySlice<UInt8>)->Void)?
  
    let serverAddress: String = "10.0.0.202"
    let serverPort: Int = 502
    var RTS: Bool = true
    var inputStream: NSInputStream?
    var outputStream: NSOutputStream?
    var SendTimeoutTimer = NSTimer()
    struct outgoing_queue_t {
        var UnitID:UInt8 = 0x00
        var FunctionCode:UInt8 = 0x00
        var DataAddress:UInt16?
        var NumberofRegisters:UInt16? = 0x00
        var dataRegisters:[UInt16]? = [UInt16](count:512, repeatedValue:0)
    }
    var outgoingQueue = [outgoing_queue_t]()
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
    var registerDef = [registerDef_t] (count:1000, repeatedValue:registerDef_t())

    override init() {
        super.init()
        NSLog("Class init")
    }

    func OutgoingQueueProcessTimer(value:Double) {
        NSLog("Outgoing Queue proces timer started with interval \(value)")
        Timer = NSTimer.scheduledTimerWithTimeInterval(value,
            target: self,
            selector: "OutgoingQueueProcess",
            userInfo: nil,
            repeats: true)
        glbOkToFire=true
        NSLog("OK to fire set to true")
    }

    func SocketConnect() {
        NSStream.getStreamsToHostWithName(self.serverAddress,
            port: self.serverPort,
            inputStream: &self.inputStream,
            outputStream: &self.outputStream)
        glbConnectionOpen=false
        NSLog("Global connection open set to false")
        if inputStream != nil && outputStream != nil {
            inputStream!.delegate = self
            outputStream!.delegate = self
            self.inputStream!.scheduleInRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            self.outputStream!.scheduleInRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            self.inputStream!.open()
            self.outputStream!.open()
            NSLog("Attempting connection")
            NSLog("Send Timeout timer started")
            SendTimeoutTimer = NSTimer.scheduledTimerWithTimeInterval(
                1.0,
                target: self,
                selector: "ConnectionFailed",
                userInfo: nil,
                repeats: false)
        }
        else {
            NSLog("Stream not created....")
        }
    }

    func OutgoingQueueAdd(inout data: outgoing_queue_t){
        outgoingQueue.append(data)
        NSLog("packet added to outgoing queue")
    }

    func SendData(word:[UInt8]) -> Int{
        NSLog("Attempting to send data")
        let data:NSData = NSData(bytes: word, length: word.count)
        let bytesWritten:Int = self.outputStream!.write(UnsafePointer(data.bytes), maxLength: data.length)
        return bytesWritten
    }

    func ReadData()  {
        NSLog("Data available")
        var buffer = [UInt8](count: 1024, repeatedValue: 0)
        let len = self.inputStream!.read(&buffer, maxLength: buffer.count)
        let input = buffer[0..<len]
        let inputAsString = input.description
        glbReceivePacketCounter++
        NSLog("Total packets received \(glbReceivePacketCounter)")
        NSLog (inputAsString)
        NSLog("Setting OK to fire to true")
        glbOkToFire=true
        //TODO MAKE SURE THESE POINT TO THE RIGHT PLACE.
        //MAY CHANGED DEPENDING ON RETURN DATA FUNTION CODE
        self.dataReadCallback!(dataReceived:input)
        let tmpStartRegister:UInt16 = UInt16(input[10])
        let tmpNumberOfRegisters:UInt16 = UInt16(input[11])
        let returnFunctionCode = input[7]
        switch returnFunctionCode {                                            //return packet function code

        case 3:
            NSLog("Parsing needed of read holding registers")
            ParseReadReturnData(input,
                start: tmpStartRegister,
                numberOfRegister: tmpNumberOfRegisters)

        case 5:
            //write single coil
            NSLog("No parsing needed of write single coil incoming data")

        case 6:
            NSLog("No parsing needed of write register(s) incoming data")

        default:
            NSLog("Parse return data error")

        }
        SocketClose()
    }

    func onDataReceived(dataReadCallback:((dataReceived:ArraySlice<UInt8>) -> Void)) {
        NSLog("Callback established")
        self.dataReadCallback = dataReadCallback
    }

    func ParseReadReturnData(var data:ArraySlice<UInt8>, start:UInt16, numberOfRegister:UInt16) {
        NSLog("Parsing read return data")

        let glbSizeOfSingleRegisterDef = 15
        //first convert byte data to word data
        var wordData:[UInt16] = [UInt16](count:data.count / 2, repeatedValue:0)
        for var tmpRegister=0;tmpRegister < (data.count) / 2; tmpRegister++ {
            wordData[tmpRegister]=UInt16(data[tmpRegister*2])*256 + UInt16(data[tmpRegister*2+1])
        }
        //remove 10 header bytes only leaving the data
        wordData[0...4] = []
        for var register=0;register < (wordData.count); register++ {
            let actualRegister = Int(start) + Int(register)

            switch actualRegister {

            case 0:
                //self.BatteryVoltageLabel.text = String(wordData[register])
                NSLog("need to update battery voltage")

            case 1:
                //self.rssiSignalLabel.text = String(wordData[register])
                NSLog("need to update rssi")

            case 2:
                //self.IdLabel.text=String(wordData[register])
                NSLog("need to update id")

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
                    //let image = UIImage(named: "white.png")
                    //LED16.image = image
                }
                else
                {
                    //let image = UIImage(named: "red.png")
                    //LED16.image = image
                }
                let reference:Int=0b00100000
                let result:Int = Int(wordData[register]) & reference
                if (result==reference) {
                    //self.txtDebugON.hidden=false
                    //self.txtDebugOff.hidden=true
                }
                else
                {
                    //self.txtDebugON.hidden=true
                    //self.txtDebugOff.hidden=false
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
            }
        }
    }

    func SocketClose() {
        glbConnectionOpen=false
        NSLog("glbConnection set to false")
        NSLog("Closing")
        NSLog("**********************************************************")
        outputStream!.removeFromRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream!.close()
        outputStream!.delegate = nil
        inputStream!.removeFromRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        inputStream!.close()
        inputStream!.delegate = nil
    }

    func ConnectionFailed() {
        NSLog("Connection failed")
        SocketClose()
        //autoPollButton.on=false
        glbConnectionOpen=false
        NSLog("glbConnectionOpen set to false")
    }

    @objc func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch (eventCode) {
        case NSStreamEvent.ErrorOccurred:
            let OutputError = [outputStream?.streamError]
            let InputError = [inputStream?.streamError]
            NSLog ("Stream \(aStream) error")
            NSLog("Output Error is \(OutputError)");
            NSLog("Input Error is \(InputError)");
            break
        case NSStreamEvent.EndEncountered:
            NSLog ("Stream \(aStream) has ended")
            self.outputStream!.close()
            self.inputStream!.close()
            break
        case NSStreamEvent.None:
            break
        case NSStreamEvent.HasBytesAvailable:
            if (aStream == inputStream){
                NSLog("Data arrived \(aStream)")
                if (inputStream!.hasBytesAvailable){
                    self.ReadData()
                }
            }
            break
        case NSStreamEvent():
            NSLog ("Stream \(aStream) Stream event")
            break
        case NSStreamEvent.OpenCompleted:
            NSLog ("Stream \(aStream) open completed")
            //timer1.invalidate()
            break
        case NSStreamEvent.HasSpaceAvailable:
            NSLog ("Stream \(aStream) has space")
            if (aStream==outputStream) {
                if (glbRTS) {
                    glbConnectionOpen=true
                    NSLog("glbConnection set to true")
                    self.SendTimeoutTimer.invalidate()
                    NSLog("Send timeout timer killed")
                    glbBytesSent=SendData(glbOutgoingBytes)
                    glbSendPacketCounter++
                    NSLog("Total packets sent \(glbSendPacketCounter)")
                    NSLog("Bytes sent=\(glbBytesSent)")
                    glbRTS=false
                    NSLog("glbRTS set to false")
                }
            }
            break

        default:
            NSLog("Something happened in the Stream Event")
            break

        }
    }

    func OutgoingQueueProcess(){

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
            SocketConnect()
        }
    }
}