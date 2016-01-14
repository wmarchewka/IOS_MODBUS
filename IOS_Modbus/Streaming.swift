//
//  Streaming.swift
//  IOS_Modbus
//
//  Created by Walter Marchewka on 1/5/16.
//  Copyright © 2016 Walter Marchewka. All rights reserved.
//
import Foundation
//********************************************************************************************
//GLOBALS
//********************************************************************************************
var glbRTS:Bool = true
var glbSendPacketCounter:Int=0
var glbReceivePacketCounter:Int=0
var glbBytesSent:Int=0
var glbConnectionOpen:Bool=false
//********************************************************************************************
//START CLASS
//********************************************************************************************
class StreamClass: NSObject, NSStreamDelegate {

    let serverAddress: String = "10.0.0.202"
    let serverPort: Int = 502
    var RTS: Bool = true

    var inputStream: NSInputStream?
    var outputStream: NSOutputStream?
    private var dataReadCallback:((dataReceived:ArraySlice<UInt8>)->Void)?
    var SendTimeoutTimer = NSTimer()

    override init() {
        super.init()
        NSLog("Class init")
    }
    //********************************************************************************************
    //CONNECT SOCKET
    //********************************************************************************************
    func connectSocket() {
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
    //********************************************************************************************
    //SEND DATA
    //********************************************************************************************
    func SendData(word:[UInt8]) -> Int{
        //RTS=true
        //if (RTS) {
        NSLog("Attempting to send data")
        let data:NSData = NSData(bytes: word, length: word.count)
        let bytesWritten:Int = self.outputStream!.write(UnsafePointer(data.bytes), maxLength: data.length)
        RTS=false
        return bytesWritten
        //}
        //else {
        //    NSLog ("No RTS")
        //}
        //return 0
    }
    //********************************************************************************************
    //READ DATA
    //********************************************************************************************
    func read() -> ArraySlice<UInt8> {
        NSLog("Data available")
        var buffer = [UInt8](count: 1024, repeatedValue: 0)
        let len = self.inputStream!.read(&buffer, maxLength: buffer.count)
        let input = buffer[0..<len]
        let inputAsString = input.description
        glbReceivePacketCounter++
        NSLog("Total packets received \(glbReceivePacketCounter)")
        NSLog (inputAsString)
        self.dataReadCallback!(dataReceived:input)
        NSLog("Data placed into DataReadCallback")
        NSLog("Setting OK to fire to true")
        glbOkToFire=true
        return input
    }
    //********************************************************************************************
    //ON DATA RECEIVED
    //********************************************************************************************
    func onDataReceived(dataReadCallback:((dataReceived:ArraySlice<UInt8>) -> Void)) {
        NSLog("Callback established")
        self.dataReadCallback = dataReadCallback
    }
    //********************************************************************************************
    //CLOSE SOCKET
    //********************************************************************************************
    func CloseSocket() {
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
     //********************************************************************************************
    //CONNECTION FAILED
    //********************************************************************************************
    func ConnectionFailed() {
        NSLog("Connection failed")
        CloseSocket()
        //autoPollButton.on=false
        glbConnectionOpen=false
        NSLog("glbConnectionOpen set to false")
    }
    //********************************************************************************************
    //STREAM EVENTS
    //********************************************************************************************
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
                    self.read()
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
}

