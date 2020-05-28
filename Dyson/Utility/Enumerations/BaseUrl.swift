//
//  BaseUrl.swift
//  Dyson
//
//  Created by Administrator on 2018-09-03.
//  Copyright © 2018 Syn. All rights reserved.
//

public enum BaseURL: String {
    case tstprod = "https://jemr.testjustenergy.com/"
    case tstsys = "https://jem.testjustenergy.com/"
    case prod = "https://jem.justenergy.com/"
    case devprod = "https://jemdevprod.testjustenergy.com/"
    case devsys = "https://jemdevsys.testjustenergy.com/"
    case devdev = "https://jemdev.testjustenergy.com/"
    
    init?(environment: Environment) {
        switch environment {
        case Environment.TESTPROD: self = .tstprod
        case Environment.TESTSYS: self = .tstsys
        case Environment.PROD: self = .prod
        case Environment.DEVPROD: self = .devprod
        case Environment.DEVSYS: self = .devsys
        case Environment.DEVDEV: self = .devdev
        }
    }
    
}
