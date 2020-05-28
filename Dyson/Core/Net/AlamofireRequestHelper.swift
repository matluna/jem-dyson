//
//  AlamofireRequestHelper.swift
//  Rkit
//
//  Created by bamsham on 2018-03-07.
//  Copyright © 2018 Syni. All rights reserved.
//

import Foundation
import Alamofire
//import AsyncTimer
import SwiftyJSON


public class AlamofireRequestHelper
{
    public static let sharedInstance = AlamofireRequestHelper()
    
    private let logger = Logger.sharedInstance
    
    private var parameters: [String:Any]!
    
    private var BASE_URL = "https://jemdevsys.testjustenergy.com"
    
    private init()
    {
        logger.logInfo(info:" AlamofireRequestHelper")
        
    }
    
    public func initiateLoginRequest(userID:String, password:String)
    {
        logger.logInfo(info: "Login Request Initiated")
        
        // Login request parameters
        parameters = ["Login": userID, "Password": password,
                      "uuid": "2b6f0cc904d137be2e1730235f5664094b831186", "DisplayLable": "Sample Test Login",
                      "Version": "JE_007", "Build": "iOS_100"]
        
        procesLoginResponse()
    }
    
    private func procesLoginResponse() {

        /*
         // Login API Request of Async Queue
         DispatchQueue.global(qos: .background).async {
         
         let headers = [ "Content-Type" : "application/json",
         "Accept" : "application/json", ]
         
         let url = self.BASE_URL+"/Rest/api/MobileAccount/login"
         
         let methodType = HTTPMethod.post
         var userDomain = UserDomain()
         
         Alamofire.request(url, method: methodType, parameters: self.parameters, encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler:
         {
         (response) in
         do{
         let jsonData = try JSON(data: response.data!)
         if let emailId = jsonData["email"].rawString(),
         emailId != "null"{
         //Login Unsuccessful
         self.logger.logInfo(message: "Login Successful with Email : \(emailId)")
         userDomain.type = "Success"
         
         }
         else {
         //Login Unsuccessful
         self.logger.logInfo(message: "Login Failed!!")
         userDomain.type = "Failure"
         }
         }
         catch{
         
         }
         self.logger.logInfo(message: "*****************")
         self.logger.logInfo(message: "*****************")
         self.logger.logInfo(message: "Response:\(response)")
         
         
         let error = NSError()
         EventSignals.sharedInstance.onLoginCompletion.fire((userDomain, error))
         
         //response.result.error! as NSError))
         })
         }*/
        
    }
    
    public func initiateForgotPassword(userID: String)
    {
        logger.logInfo(info: "Forgot Password Request Initiated")
        
        // Forgot Password parameters
        parameters = ["LoginName": userID]
        
        procesForgotPasswordResponse()
    }
    
    private func procesForgotPasswordResponse() {
        
        //        forgotPasswordTaskTimer.start()
        DispatchQueue.global(qos: .background).async {
            
            let headers = [ "Content-Type" : "application/json",
                            "Accept" : "application/json", ]
            
            let url = self.BASE_URL+"/Rest/api/MobileAccount/forgetpassword"
            
            let methodType = HTTPMethod.post
            
            Alamofire.request(url, method: methodType, parameters: self.parameters, encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler:
                {
                    (response) in
                    
                    self.logger.logInfo(info: "Forgot Password Sucessful")
                    
                    self.logger.logInfo(info: "*****************")
                    self.logger.logInfo(info: "*****************")
                    self.logger.logInfo(info: "Response:\(response)")
                    
                    guard response.result.error == nil else {       // got an error in getting the data, need to handle it
                        
                        self.logger.logError(error: response.result.error!.localizedDescription)
                        return
                    }
                    
                    guard let json = response.result.value as? [String: AnyObject] else {       // make sure we got JSON
                        
                        self.logger.logError(error: "didn't get todo objects as JSON from API")
                        return
                    }
                    
                    let resultStr = json["ReturnMsg"] as! String
                    let error = NSError()
            })
        }
        
    }
}
