//
//  Indicators.swift
//  IOS_Modbus
//
//  Created by Walter Marchewka on 1/8/16.
//  Copyright © 2016 Walter Marchewka. All rights reserved.
//

import UIKit

class RedLed: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func drawCircle(rect: CGRect, color:Int) {
        // Get the Graphics Context
        let context = UIGraphicsGetCurrentContext();
        // Set the circle outerline-width
        CGContextSetLineWidth(context, 5.0);
        // Set the circle outerline-colour
        UIColor.redColor().set()
        //color.set()
        // Create Circle
        CGContextAddArc(context, (frame.size.width)/2, frame.size.height/2, (frame.size.width - 10)/2, 0.0, CGFloat(M_PI * 2.0), 1)
        // Draw
        CGContextStrokePath(context);
    }


    override func drawRect(rect: CGRect) {
        // Get the Graphics Context
        let context = UIGraphicsGetCurrentContext();
        // Set the circle outerline-width
        CGContextSetLineWidth(context, 5.0);
        // Set the circle outerline-colour
        UIColor.redColor().set()
        //color.set()
        // Create Circle
        CGContextAddArc(context, (frame.size.width)/2, frame.size.height/2, (frame.size.width - 10)/2, 0.0, CGFloat(M_PI * 2.0), 1)
        // Draw
        CGContextStrokePath(context);
    }
}

class GreenLed: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func drawCircle(rect: CGRect, color:Int) {
        // Get the Graphics Context
        let context = UIGraphicsGetCurrentContext();
        // Set the circle outerline-width
        CGContextSetLineWidth(context, 5.0);
        // Set the circle outerline-colour
        UIColor.redColor().set()
        //color.set()
        // Create Circle
        CGContextAddArc(context, (frame.size.width)/2, frame.size.height/2, (frame.size.width - 10)/2, 0.0, CGFloat(M_PI * 2.0), 1)
        // Draw
        CGContextStrokePath(context);
    }


    override func drawRect(rect: CGRect) {
        // Get the Graphics Context
        let context = UIGraphicsGetCurrentContext();
        // Set the circle outerline-width
        CGContextSetLineWidth(context, 5.0);
        // Set the circle outerline-colour
        UIColor.greenColor().set()
        //color.set()
        // Create Circle
        CGContextAddArc(context, (frame.size.width)/2, frame.size.height/2, (frame.size.width - 10)/2, 0.0, CGFloat(M_PI * 2.0), 1)
        // Draw
        CGContextStrokePath(context);
    }
}
