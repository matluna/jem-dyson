import Foundation

@available(iOS 10.0, *)
class KeychainHelper {
    
    public var version : String!
    public var serviceName : String!
    //    public var accessGroup : String!
    
    public static let sharedInstance = KeychainHelper()
    
    private let keychainWrapper : KeychainWrapper!
    
    private init()
    {
        version = "v0.0.3"
        serviceName = "Enrollment_Manager_\(version)"
        keychainWrapper = KeychainWrapper(serviceName: serviceName)
    }
    
    public func saveEnrollmentEntry(entry : EnrollmentEntry, onCompletion: @escaping (Error?,String?) -> Void)
    {
        Logger.sharedInstance.logInfo(info: "saveEnrollmentEntry")
        DispatchQueue.global(qos: .background).async
        {
            
            let keyForStatus = "En_Status_\(entry.uniqueMessageID)_\(self.version)"
            let keyForData = "En_Data_\(entry.uniqueMessageID)_\(self.version)"
            let keyForEnrollmentIdentifier = "En_EnrollmentIdentifier_\(entry.uniqueMessageID)_\(self.version)"
            
            let saveDataSuccessful : Bool = self.keychainWrapper.set(entry.data, forKey: keyForData)
            if saveDataSuccessful
            {
                //Set status to save to KC Successful
                entry.status = "\(EnrollmentStatusType.SAVED_AZURE_PAYLOAD_TO_KEYCHAIN_SUCCESSFUL)"
                let saveStatusSuccessful : Bool = self.keychainWrapper.set(entry.status, forKey: keyForStatus)
                if !saveStatusSuccessful
                {
                    Logger.sharedInstance.logError(error: "Save status to keychain failed for \(entry.uniqueMessageID)")
                    onCompletion(nil,nil)
                }
                
                let saveEnrollmentIdentifierSuccessful : Bool = self.keychainWrapper.set(entry.enrollmentIdentifier, forKey: keyForEnrollmentIdentifier)
                if !saveEnrollmentIdentifierSuccessful {
                    Logger.sharedInstance.logError(error: "Save enrollment identifier failed for : \(entry.uniqueMessageID)")
                    onCompletion(nil,nil)
                }
                
                onCompletion(nil,"Save Entry to keychain Completed!")

            }
            else
            {
                Logger.sharedInstance.logError(error: "Save data to keychain failed for \(entry.uniqueMessageID)")
                onCompletion(nil,nil)
            }
            
        }
        
    }
    
    //TODO: Remove onCompletion return parameters as they are not needed!
    public func saveBlobEntry(entry : EnrollmentEntry, blobFolder: String, onCompletion: @escaping (Error?,String?) -> Void)
    {
        Logger.sharedInstance.logInfo(info: "saveBlobEntry for blobFolder : \(blobFolder)")
        DispatchQueue.global(qos: .background).async
        {
            
            let keyForStatus = "En_Blob_Status_\(entry.uniqueMessageID)_\(self.version)"
            let keyForData = "En_Blob_\(entry.uniqueMessageID)_\(self.version)"
            let keyForBlobFolder = "En_Blob_Container_\(entry.uniqueMessageID)_\(self.version)"
            let keyForEnrollmentIdentifier = "En_EnrollmentIdentifier_\(entry.uniqueMessageID)_\(self.version)"
            
            let saveBlobDataSuccessful : Bool = self.keychainWrapper.set(entry.data, forKey: keyForData)
            let _ = self.keychainWrapper.set(blobFolder, forKey: keyForBlobFolder)
            
            if saveBlobDataSuccessful
            {
                //Set status to save to KC Successful
                entry.status = "\(EnrollmentStatusType.SAVED_BLOB_TO_KEYCHAIN_SUCCESSFUL)"
                let saveStatusSuccessful : Bool = self.keychainWrapper.set(entry.status, forKey: keyForStatus)
                if !saveStatusSuccessful
                {
                    Logger.sharedInstance.logError(error: "Save status to keychain failed for : \(entry.uniqueMessageID)")
                    onCompletion(nil,nil)
                }
                
                let saveEnrollmentIdentifierSuccessful = self.keychainWrapper.set(entry.enrollmentIdentifier, forKey: keyForEnrollmentIdentifier)
                if !saveEnrollmentIdentifierSuccessful
                {
                    Logger.sharedInstance.logError(error: "Save enrollment identifier failed for : \(entry.uniqueMessageID)")
                    onCompletion(nil,nil)
                }
                
                onCompletion(nil,"Save Entry to keychain Completed!")
                
            }
            else
            {
                Logger.sharedInstance.logError(error: "Save data to keychain failed for : \(entry.uniqueMessageID)")
                onCompletion(nil,nil)
            }
            
        }
        
    }
    
    public func changeStatusTo(status: EnrollmentStatusType, forEntry entry: EnrollmentEntry)
    {
        
        Logger.sharedInstance.logInfo(info: "Changing status of azure_payload Entry in keychain : \(status)")
        
        entry.status = "\(status)"
        let keyForStatus = "En_Status_\(entry.uniqueMessageID)_\(version)"
        
        if keychainWrapper.hasValue(forKey: keyForStatus)
        {
            let updateStatusToKCSuccess = self.keychainWrapper.set(entry.status, forKey: keyForStatus)
            if (!updateStatusToKCSuccess)
            {
                Logger.sharedInstance.logError(error: "Update status to Keychain failed")
            }
        }
        
    }
    
    public func changeStatusTo(status: EnrollmentStatusType, forBlobEntry entry: EnrollmentEntry)
    {
        
        Logger.sharedInstance.logInfo(info: "Changing status of blob Entry in keychain : \(status)")
        
        entry.status = "\(status)"
        let keyForStatus = "En_Blob_Status_\(entry.uniqueMessageID)_\(version)"
        
        if keychainWrapper.hasValue(forKey: keyForStatus)
        {
            let updateStatusToKCSuccess = self.keychainWrapper.set(entry.status, forKey: keyForStatus)
            if (!updateStatusToKCSuccess)
            {
                Logger.sharedInstance.logError(error: "Update status to Keychain failed")
            }
        }
        
    }
    
    public func getPendingUploadsInKeychain() -> [String]
    {
        let pendingAzurePayloads = getPendingAzurePayloadsMessageIdArray()
        let pendingBlobs = getPendingBlobsArray()
        var result = [String]()
        result.append(contentsOf: pendingBlobs)
        result.append(contentsOf: pendingAzurePayloads)
        return result
    }
    
    public func getPendingAzurePayloadsMessageIdArray() -> [String]
    {
        let keys = keychainWrapper.allKeys()
        var keysOfSuccessfulEnrollments = [String]()
        
        for key in keys
        {
            if key.range(of: "En_Status_") != nil
            {
                let status = keychainWrapper.string(forKey: key)!
                let messageIdWithKCVersion = key.replacingOccurrences(of: "En_Status_", with: "", options: NSString.CompareOptions.literal, range:nil)
                
                let messageId = messageIdWithKCVersion.replacingOccurrences(of: "_\(version)", with: "", options: NSString.CompareOptions.literal, range:nil)
                
                let sentToAzureFunctionSuccessStatus = "\(EnrollmentStatusType.SENT_TO_AZURE_FUNCTION_SUCCESSFUL)"
                if status != sentToAzureFunctionSuccessStatus
                {
                    keysOfSuccessfulEnrollments.append(messageId)
                }
            }
        }
        
        return keysOfSuccessfulEnrollments
    }
    
    public func getPendingBlobsArray() -> [String]
    {
        let keys = keychainWrapper.allKeys()
        var keysOfSuccessfulBlobs = [String]()
        
        for key in keys
        {
            if key.range(of: "En_Blob_Status_") != nil
            {
                let status = keychainWrapper.string(forKey: key)!
                
                let messageIdWithKCVersion = key.replacingOccurrences(of: "En_Blob_Status_", with: "", options: NSString.CompareOptions.literal, range:nil)
                
                let messageId = messageIdWithKCVersion.replacingOccurrences(of: "_\(version)", with: "", options: NSString.CompareOptions.literal, range:nil)
                
                let sentToBlobFunctionSuccessStatus = "\(EnrollmentStatusType.SENT_TO_BLOB_FUNCTION_SUCCESSFUL)"
                if status != sentToBlobFunctionSuccessStatus
                {
                    keysOfSuccessfulBlobs.append(messageId)
                }
            }
        }
        
        return keysOfSuccessfulBlobs
    }
    
    private func getSuccessfulAzurePayloadsArray() -> [String]
    {
        let keys = keychainWrapper.allKeys()
        var keysOfSuccessfulEnrollments = [String]()
        
        for key in keys
        {
            if key.range(of: "En_Status_") != nil
            {
                let status = keychainWrapper.string(forKey: key)!
                let sentToAzureFunctionSuccessStatus = "\(EnrollmentStatusType.SENT_TO_AZURE_FUNCTION_SUCCESSFUL)"
                if status == sentToAzureFunctionSuccessStatus
                {
                    keysOfSuccessfulEnrollments.append(key)
                }
            }
        }
        
        return keysOfSuccessfulEnrollments
    }
    
    private func getSuccessfulBlobsArray() -> [String]
    {
        let keys = keychainWrapper.allKeys()
        var keysOfSuccessfulBlobs = [String]()
        
        for key in keys
        {
            if key.range(of: "En_Blob_Status_") != nil
            {
                let status = keychainWrapper.string(forKey: key)!
                let sentToBlobFunctionSuccessStatus = "\(EnrollmentStatusType.SENT_TO_BLOB_FUNCTION_SUCCESSFUL)"
                if status == sentToBlobFunctionSuccessStatus
                {
                    keysOfSuccessfulBlobs.append(key)
                }
            }
        }
        
        return keysOfSuccessfulBlobs
    }

    
    public func startRemovingSuccessfulAzurePayloadsAndBlobsFromKeychain()
    {
        Logger.sharedInstance.logInfo(info: "startRemovingSuccessfulAzurePayloadsAndBlobsFromKeychain")
        Logger.sharedInstance.logDebug(debug: "In startRemovingSuccessfulAzurePayloadsAndBlobsFromKeychain")
        let keysOfSuccessfulEnrollments = getSuccessfulAzurePayloadsArray()
        removeAzurePayloadsFromKeychain(keys: keysOfSuccessfulEnrollments, atIndex: 0)
    }
    
    private func removeAzurePayloadsFromKeychain(keys : [String], atIndex index: Int)
    {
        
        if index < keys.count
        {
            let keyForStatus = keys[index]
            let messageId = keyForStatus.replacingOccurrences(of: "En_Status_", with: "", options: NSString.CompareOptions.literal, range:nil)
            let keyForData = "En_Data_\(messageId)"
            keychainWrapper.removeObject(forKey: keyForStatus)
            keychainWrapper.removeObject(forKey: keyForData)
            
            removeAzurePayloadsFromKeychain(keys: keys, atIndex: index + 1)
        }
        else
        {
            startRemovingSuccessfulBlobsFromKeychain()
        }
        
    }
    
    private func startRemovingSuccessfulBlobsFromKeychain()
    {
        let keysOfSuccessfulBlobs = getSuccessfulBlobsArray()
        removeBlobsFromKeychain(keys: keysOfSuccessfulBlobs, atIndex: 0)
    }
    
    private func removeBlobsFromKeychain(keys : [String], atIndex index: Int)
    {
        
        if index < keys.count
        {
            let keyForStatus = keys[index]
            let messageId = keyForStatus.replacingOccurrences(of: "En_Blob_Status_", with: "", options: NSString.CompareOptions.literal, range:nil)
            let keyForData = "En_Blob_\(messageId)"
            let keyForBlobFolder = "En_Blob_Container_\(messageId)"
            keychainWrapper.removeObject(forKey: keyForStatus)
            keychainWrapper.removeObject(forKey: keyForData)
            keychainWrapper.removeObject(forKey: keyForBlobFolder)
            
            removeBlobsFromKeychain(keys: keys, atIndex: index + 1)
        }
        else
        {
            Logger.sharedInstance.logInfo(info: "All succesful records deleted from keychain!")
        }
        
    }
    
    public func getAllPendingAzurePayloadItemsFromKeychain() -> [EnrollmentEntry]
    {
        
        var entries = [EnrollmentEntry]()
        
        let keys = keychainWrapper.allKeys()
        
        let azureFunctionSuccessStatus = "\(EnrollmentStatusType.SENT_TO_AZURE_FUNCTION_SUCCESSFUL)"
        
        for key in keys
        {
            if key.range(of: "En_Status_") != nil
            {
                let status = keychainWrapper.string(forKey: key)!
                let pendingStatus = status != azureFunctionSuccessStatus
                
                if pendingStatus
                {
                    let messageIdWithKCVersion = key.replacingOccurrences(of: "En_Status_", with: "", options: NSString.CompareOptions.literal, range:nil)
                    let messageId = messageIdWithKCVersion.replacingOccurrences(of: "_\(self.version)", with: "", options: NSString.CompareOptions.literal, range:nil)
                    let keyForData = "En_Data_\(messageIdWithKCVersion)"
                    let keyForEnrollmentIdentifier = "En_EnrollmentIdentifier_\(messageIdWithKCVersion)"
                    
                    let data = keychainWrapper.hasValue(forKey: keyForData) ? keychainWrapper.string(forKey: keyForData)! : ""
                    let enrollmentIdentifier = keychainWrapper.hasValue(forKey: keyForEnrollmentIdentifier) ? keychainWrapper.string(forKey: keyForEnrollmentIdentifier)! : ""
                    
                    let enrollmentEntry : EnrollmentEntry = ACPTModel(uniqueMessageID: messageId, data: data, status: status, enrollmentIdentifier: enrollmentIdentifier)
                    entries.append(enrollmentEntry)
                }
                
            }
        }
        
        return entries
    }
    
    public func getAllPendingBlobItemsFromKeychain() -> [(EnrollmentEntry,String)]
    {
        
        var entries = [(EnrollmentEntry,String)]()
        
        let keys = keychainWrapper.allKeys()
        
        let blobFunctionSuccessStatus = "\(EnrollmentStatusType.SENT_TO_BLOB_FUNCTION_SUCCESSFUL)"
        
        for key in keys
        {
            if key.range(of: "En_Blob_Status_") != nil
            {
                let status = keychainWrapper.string(forKey: key)!
                let pendingStatus = (status != blobFunctionSuccessStatus);
                
                if pendingStatus
                {
                    let messageIdWithKCVersion = key.replacingOccurrences(of: "En_Blob_Status_", with: "", options: NSString.CompareOptions.literal, range:nil)
                    let messageId = messageIdWithKCVersion.replacingOccurrences(of: "_\(self.version)", with: "", options: NSString.CompareOptions.literal, range:nil)
                    
                    let keyForData = "En_Blob_\(messageIdWithKCVersion)"
                    let keyForBlobFolder = "En_Blob_Container_\(messageIdWithKCVersion)"
                    let keyForEnrollmentIdentifier = "En_EnrollmentIdentifier_\(messageIdWithKCVersion)"
                    
                    let data = keychainWrapper.hasValue(forKey: keyForData) ? keychainWrapper.string(forKey: keyForData)! : ""
                    let enrollmentIdentifier = keychainWrapper.hasValue(forKey: keyForEnrollmentIdentifier) ? keychainWrapper.string(forKey: keyForEnrollmentIdentifier)! : ""
                    let blobFolder = keychainWrapper.hasValue(forKey: keyForBlobFolder) ? keychainWrapper.string(forKey: keyForBlobFolder)! : "partialtransaction"
                    
                    let enrollmentEntry : EnrollmentEntry = ACPTModel(uniqueMessageID: messageId, data: data, status: status, enrollmentIdentifier: enrollmentIdentifier)
                    
                    let entry = (enrollmentEntry,blobFolder)
                    
                    entries.append(entry)
                }
                
            }
        }
        
        return entries
    }
}
