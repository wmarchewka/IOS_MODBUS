//
//  BackgroundUtils.swift
//  IOS_Modbus
//
//  Created by Walter Marchewka on 1/10/16.
//  Copyright © 2016 Walter Marchewka. All rights reserved.
//

import Foundation

class Utils
{
    func doSomeJob()
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            //All stuff here

        })
        
    }
}