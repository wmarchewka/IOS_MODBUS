//
//  StreamClass.swift
//  Streamer1
//
//  Created by Walter Marchewka on 12/21/15.
//  Copyright © 2015 Walter Marchewka. All rights reserved.
//

import Foundation



class NewStreamClass: NSObject, NSStreamDelegate {
    
    let serverAddress: String = "10.0.0.202"
    let serverPort: Int = 502
    var RTS=false
    
    var inputStream: NSInputStream?
    var outputStream: NSOutputStream?
    private var dataReadCallback:((dataReceived:ArraySlice<UInt8>)->Void)?
    var Timer = NSTimer()
    
    override init() {
        super.init()
        print("Class init")
    }
    
    func SendData(word:[UInt8]) -> Int{
        RTS=true
        if (RTS) {
            let data:NSData = NSData(bytes: word, length: word.count)
            let bytesWritten:Int = self.outputStream!.write(UnsafePointer(data.bytes), maxLength: data.length)
            print("Attempting to send data")
            RTS=false
            return bytesWritten
        }
        else {
            print ("No RTS")
        }
        return 0
    }
    
    func read() -> ArraySlice<UInt8> {
        print("Data available")
        var buffer = [UInt8](count: 1024, repeatedValue: 0)
        let len = self.inputStream!.read(&buffer, maxLength: buffer.count)
        let input = buffer[0..<len]
        print (input)
        self.dataReadCallback!(dataReceived:input)
       return input
    }
    
    func onDataReceived(dataReadCallback:((dataReceived:ArraySlice<UInt8>) -> Void)) {
        self.dataReadCallback = dataReadCallback
    }
    
    
    func CloseSocket() {
        print("Closing")
        print("**********************************************************")
        outputStream!.removeFromRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream!.close()
        outputStream!.delegate = nil
        inputStream!.removeFromRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        inputStream!.close()
        inputStream!.delegate = nil
    }
    
  
   
    
    func connectSocket() {
        NSStream.getStreamsToHostWithName(self.serverAddress,
            port: self.serverPort,
            inputStream: &self.inputStream,
            outputStream: &self.outputStream)
        if inputStream != nil && outputStream != nil {
            inputStream!.delegate = self
            outputStream!.delegate = self
            //inputStream!.scheduleInRunLoop(.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            //outputStream!.scheduleInRunLoop(.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            inputStream!.scheduleInRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            outputStream!.scheduleInRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            inputStream!.open()
            outputStream!.open()
            //[[NSRunLoop. currentRunLoop], run];
             print("**********************************************************")
            print("Attempting connection")
            Timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "ConnectionFailed", userInfo: nil, repeats: false)
           }
        else {
            print("Stream not created....")
        }
    }
    
    func ConnectionFailed() {
        
        print("Connection failed")
    }
    
    
    @objc func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        
        switch (eventCode) {
            
        case NSStreamEvent.ErrorOccurred:
            let OutputError = [outputStream?.streamError]
            let InputError = [inputStream?.streamError]
            print ("Stream \(aStream) error")
            print("Output Error is \(OutputError)");
            print("Input Error is \(InputError)");
            break
            
        case NSStreamEvent.EndEncountered:
            print ("Stream \(aStream) has ended")
            self.outputStream!.close()
            self.inputStream!.close()
            break
            
        case NSStreamEvent.None:
            break
            
        case NSStreamEvent.HasBytesAvailable:
            if (aStream == inputStream){
                print("Data arrived \(aStream)")
                if (inputStream!.hasBytesAvailable){
                    self.read()
                }
            }
            break
            
        case NSStreamEvent():
            print ("Stream \(aStream) Stream event")
            break
            
        case NSStreamEvent.OpenCompleted:
            print ("Stream \(aStream) open completed")
            
            //timer1.invalidate()
            break
            
        case NSStreamEvent.HasSpaceAvailable:
            print ("Stream \(aStream) has space")
            if (aStream==outputStream) {
                RTS=true
            }
            break
            
        default:
            break
            
        } // switch
        
    } // func
    
} // class