//
//  Singleton.swift
//  IOS_Modbus
//
//  Created by Walter Marchewka on 1/10/16.
//  Copyright © 2016 Walter Marchewka. All rights reserved.
//

import Foundation
class Singleton {
    var TimerCounter = 0


    struct Static {
        static let instance = Singleton()
    } 
}