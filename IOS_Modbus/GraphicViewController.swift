//
//  GraphicViewController.swift
//  IOS_Modbus
//
//  Created by Walter Marchewka on 12/20/15.
//  Copyright © 2015 Walter Marchewka. All rights reserved.
//

import UIKit

protocol GraphicsViewDelegate {
    //    func setIPAddress(ipAddress: String);
    func DG_setTestButtonVal(testButtonVal: Bool);
    func DG_TestReturnFunction() -> Array<UInt16>;
}

class GraphicsViewController: UIViewController {

    var delegate : GraphicsViewDelegate! = nil


    @IBOutlet weak var LED16: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lblTimerData: UILabel!
    @IBOutlet weak var switchTest: UISwitch!

    @IBOutlet weak var button_Send: UIButton!

    //set up a delgate to send and receive data between viewcontrollers

    var timerCounter : Int! = nil


    var testButtonVal : Bool! = nil
    let myRedLed = RedLed()
    let myGreenLed = GreenLed()
    weak var Timer:NSTimer?


    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("Timer counter \(timerCounter)")
        Timer = NSTimer.scheduledTimerWithTimeInterval(0.1,
            target: self,
            selector: "Update",
            userInfo: nil,
            repeats: true)
    }

    override func viewWillDisappear(animated: Bool) {
        Timer?.invalidate()
        Timer = nil
    }

    func Update() {

        let glbioPins:[UInt16] = delegate.DG_TestReturnFunction()
        for var pin=0; pin < 17; pin++ {
            if glbioPins[pin]==1 {
                DrawGreenLed(pin)
            }
            else{
                DrawRedLed(pin)
            }
        }
    }


    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        //let touch = touches as Set<UITouch>

    }

    func DrawRedLed(var Pin: Int) {
        var xOffset:CGFloat = 0

        if ( Pin >= 14 ){
            xOffset = 75
            Pin = Pin - 14
        }
        else{
            xOffset = 0
        }
        let yStart:CGFloat=111
        let xStart:CGFloat=140 + xOffset
        let y:CGFloat = yStart + (CGFloat(Pin) * 36.5)
        let ledWidth = CGFloat(20)
        let ledHeight = ledWidth
        let redLed = RedLed(frame: CGRectMake(xStart, y, ledWidth, ledHeight) )
        view.addSubview(redLed)
    }

    func DrawGreenLed(var Pin: Int) {
        var xOffset:CGFloat = 0

        if ( Pin >= 14 ){
            xOffset = 75
            Pin = Pin - 14

        }
        else
        {
            xOffset = 0
        }

        let yStart:CGFloat=111
        let xStart:CGFloat=140 + xOffset
        let y:CGFloat = yStart + (CGFloat(Pin) * 36.5)
        let ledWidth = CGFloat(20)
        let ledHeight = ledWidth
        let greenLed = GreenLed(frame: CGRectMake(xStart, y, ledWidth, ledHeight) )
        view.addSubview(greenLed)
    }


    @IBAction func SendButtonPushed(sender: UIButton) {
        
        
    }
    
    @IBAction func TestSwitchPushed(sender: UISwitch) {
        delegate.DG_setTestButtonVal(sender.on)
        
    }
    
}
