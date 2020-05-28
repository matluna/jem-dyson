import Foundation
import Alamofire

let sendContractDetailsAzureFunctionName = "SaveTransactionDetails"
let sendContractDataBlobAzureFunctionName = "SaveTransactionData"

@available(iOS 10.0, *)
class AzureFunctionHelper {
    
    private init(){}
    public static let sharedInstance = AzureFunctionHelper()
    
    private func getURLForAzureFunction(WithName functionName : String, resourceGroup : String, andAPIKey apiKey : String) -> URL{
        
        var result : URL!
        let urlString = "https://\(resourceGroup).azurewebsites.net/api/\(functionName)?code=\(apiKey)"
        result = URL(string: urlString)
        return result
        
    }
    
    private func getHeadersForEnrollment(entry : EnrollmentEntry, andPriority priority : ServiceBusPriority) -> [String:String]{
        
        var result = [String:String]()
        
        result["Content-Type"] = "application/json"
        result["blobContainer"] = sendContractDetailsAzureFunctionName.lowercased()
        result["serviceBusPriority"] = priority.rawValue
        result["messageUniqueId"] = entry.enrollmentIdentifier
        
        return result
        
    }
    
    private func getHeadersForBlob(entry : EnrollmentEntry, blobFolderName: String) -> [String:String]{
        
        var result = [String:String]()
        
        if blobFolderName == "docs"{
            result["Content-Type"] = "multipart/form-data"
        }
        else{
            result["Content-Type"] =  "application/json"
        }
        
        result["blobContainer"] = blobFolderName
        
        return result
        
    }
    
    public func sendEntryToAzureFunction(entry : EnrollmentEntry, onCompletion: @escaping (Error?,String?) -> Void) {
        
        DispatchQueue.global(qos: .background).async {
            
            let environment = Environment(rawValue: UploadManager.sharedInstance.environment)!
            let environmentDetails = Settings.sharedInstance.getEnvironmentDetailsFor(environment: environment)
            let functionResourceGroup = environmentDetails["resourceGroup"]
            let functionAPIKey = environmentDetails["saveTransactionDetailsAPIkey"]
            
            let url = self.getURLForAzureFunction(WithName: sendContractDetailsAzureFunctionName, resourceGroup: functionResourceGroup!, andAPIKey: functionAPIKey!)
            
            let headers = self.getHeadersForEnrollment(entry: entry, andPriority: .HIGH_1)
            
            let body = entry.data.data(using: .utf8)!
            
            ApiManager.sharedInstance.requestServerAtPathURL(url: url, httpBody: body, httpMethodType: .POST, httpHeaders: headers, onApiCallCompletion: { (error, statusCode, responseData) in
                
                if(error != nil){
                    onCompletion(error,nil)
                }
                else{
                    let responseString = String(data: responseData!, encoding: .utf8)
                    if (statusCode == 200){
                        onCompletion(nil,responseString)
                    }else {
                        NotificationCenter.default.post(name: Notification.Name("ReachabilityChanged"), object: nil, userInfo: ["ColorStatus" : NetworkStatusColor.RED.rawValue])
                        let error = NSError(domain:"", code:statusCode, userInfo:[ NSLocalizedDescriptionKey: "Error occured while sending data to azure function"])
                        onCompletion(error,responseString)
                    }
                }
                
                
            })
            
        }
        
    }
    
    public func sendBlobEntryToAzureFunction(entry : EnrollmentEntry, blobFolder: String, onCompletion: @escaping (Error?,String?) -> Void) {
        
        DispatchQueue.global(qos: .background).async {
            
            let environment = Environment(rawValue: UploadManager.sharedInstance.environment)!
            let environmentDetails = Settings.sharedInstance.getEnvironmentDetailsFor(environment: environment)
            let functionResourceGroup = environmentDetails["resourceGroup"]
            let functionAPIKey = environmentDetails["saveTransactionDataAPIkey"]
            
            let url = self.getURLForAzureFunction(WithName: sendContractDataBlobAzureFunctionName, resourceGroup: functionResourceGroup!, andAPIKey: functionAPIKey!)
            
            let headers = self.getHeadersForBlob(entry: entry, blobFolderName: blobFolder)
            
            let body = entry.data.data(using: .utf8)!
            
            ApiManager.sharedInstance.requestServerAtPathURL(url: url, httpBody: body, httpMethodType: .POST, httpHeaders: headers, onApiCallCompletion: { (error, statusCode, responseData) in
                
                if(error != nil){
                    onCompletion(error,nil)
                }
                else{
                    let responseString = String(data: responseData!, encoding: .utf8)
                    if (statusCode == 200){
                        onCompletion(nil,responseString)
                        
                    }else {
                        NotificationCenter.default.post(name: Notification.Name("ReachabilityChanged"), object: nil, userInfo: ["ColorStatus" : NetworkStatusColor.RED.rawValue])
                        let error = NSError(domain:"", code:statusCode, userInfo:[ NSLocalizedDescriptionKey: "Error occured while sending data to azure function"])
                        onCompletion(error,nil)
                    }
                }
                
            })
            
        }
        
    }
    
    public func sendPhotoBlobEntryToAzureFunction(entry : EnrollmentEntry, blobFolder: String, onCompletion: @escaping (Error?,String?) -> Void) {
        
        DispatchQueue.global(qos: .background).async {
            
            let environment = Environment(rawValue: UploadManager.sharedInstance.environment)!
            let environmentDetails = Settings.sharedInstance.getEnvironmentDetailsFor(environment: environment)
            let functionResourceGroup = environmentDetails["resourceGroup"]
            let functionAPIKey = environmentDetails["saveTransactionDataAPIkey"]
            
            let url = self.getURLForAzureFunction(WithName: sendContractDataBlobAzureFunctionName, resourceGroup: functionResourceGroup!, andAPIKey: functionAPIKey!)
            
            let headers = self.getHeadersForBlob(entry: entry, blobFolderName: blobFolder)
            
            Alamofire.upload(multipartFormData: { (multipartFormData) in
                multipartFormData.append(Data(entry.data.utf8), withName: "photo", fileName: entry.enrollmentIdentifier, mimeType: "image/jpeg")
                
            }, usingThreshold: UInt64.init(), to: url, method: .post, headers: headers) { (result) in
                switch result{
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        Logger.sharedInstance.logInfo(info:"Succesfully uploaded")
                        if let error = response.error{
                            onCompletion(error,nil)
                            return
                        }
                        let responseString = String(data: response.data!, encoding: .utf8)
                        let statusCode = response.response?.statusCode
                        if (statusCode == 200){
                            onCompletion(nil,responseString)
                        }else{
                            let error = NSError(domain:"", code:statusCode!, userInfo:[ NSLocalizedDescriptionKey: "Error occured while sending data to azure function"])
                            onCompletion(error,responseString)
                        }
                        onCompletion(nil,responseString)
                    }
                case .failure(let error):
                    Logger.sharedInstance.logError(error:"Error in upload: \(error.localizedDescription)")
                    NotificationCenter.default.post(name: Notification.Name("ReachabilityChanged"), object: nil, userInfo: ["ColorStatus" : NetworkStatusColor.RED.rawValue])
                    onCompletion(error,nil)
                }
            }
            
        }
        
    }
    
}
