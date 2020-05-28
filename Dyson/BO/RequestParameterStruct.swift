//
//  RequestParameterStruct.swift
//  Dyson
//
//  Created by Administrator on 2018-09-04.
//  Copyright © 2018 Syn. All rights reserved.
//

import Foundation
import Alamofire

public struct RequestParameterStruct {
    
    public var url : String
    public var headers : [String:String]?
    public var methodType : HTTPMethod
    public var parameters : [String:Any]?
    public var isActive : Bool
    public var onCompletion : ((DefaultDataResponse) -> Void)
    
    static func == (lhs: RequestParameterStruct, rhs: RequestParameterStruct) -> Bool {
        var result = false;
        
        result = (lhs.url == rhs.url) &&
            (lhs.headers == rhs.headers) &&
            (lhs.methodType == rhs.methodType) &&
            (lhs.isActive == rhs.isActive) ;
        
        return result
    }
}

