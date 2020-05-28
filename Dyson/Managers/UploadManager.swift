import Foundation

@available(iOS 10.0, *)
public class UploadManager {
    
    public let version : String!
    public var environment : String!
    public var isUploaderActive : Bool!
    public var pendingUploads : Int = 0
    public var totalUploadedItems : Int = 0
    
    public static let sharedInstance = UploadManager()
    private init()
    {
        version = "v0.0.1"
        isUploaderActive = false
        pendingUploads = DBManager.sharedInstance.getPendingItemsFromDB()
    }
    
    //MARK: Private Dyson Helper Functions
    
    public func startTransmissionOfCompleteEnrollment(entry : EnrollmentEntry, onCompletion: @escaping (Error?,String?) -> Void)
    {
        Logger.sharedInstance.logInfo(info: "startTransmissionOfEnrollmentEntry initialized")
        KeychainHelper.sharedInstance.saveEnrollmentEntry(entry: entry)
        {
            (_, _) in
            DBManager.sharedInstance.createAzureEnrollment(entry: entry)
            {
                (error, response) in
                if(error != nil)
                {
                    self.changeStatusTo(status: .SAVED_AZURE_PAYLOAD_TO_DATABASE_FAILURE, forEntry: entry, ofType: .AZURE_PAYLOAD)
                    {
                        let error = NSError(domain:"", code:0, userInfo:[ NSLocalizedDescriptionKey: "SAVED_AZURE_PAYLOAD_TO_DATABASE_FAILURE"])
                        Logger.sharedInstance.logError(error: "SAVED_AZURE_PAYLOAD_TO_DATABASE_FAILURE")
                        onCompletion(error,response)
                    }
                }
                else
                {
                    self.onSuccesfulUploadInsertionToDB(status: .SAVED_AZURE_PAYLOAD_TO_DATABASE_SUCCESSFUL, entry: entry, type: .AZURE_PAYLOAD, response: response!, onCompletion: onCompletion)
                }
            }
        }
    }
    
    public func startTransmissionOfBlob(entry : EnrollmentEntry, blobFolder : String, onCompletion: @escaping (Error?,String?) -> Void)
    {
        Logger.sharedInstance.logInfo(info: "startTransmissionOfBlob initialized")
        KeychainHelper.sharedInstance.saveBlobEntry(entry: entry, blobFolder: blobFolder)
        {
            (_, _) in
            
            let isBlobOfTypePhoto = blobFolder == "docs"
            DBManager.sharedInstance.createBlobEnrollment(entry: entry, blobContainer: blobFolder, ofTypePhoto: isBlobOfTypePhoto)
            {
                (error, response) in
                
                if(error != nil)
                {
                    self.changeStatusTo(status: .SAVED_BLOB_TO_DATABASE_FAILURE, forEntry: entry, ofType: .BLOB)
                    {
                        let error = NSError(domain:"", code:0, userInfo:[ NSLocalizedDescriptionKey: "SAVED_BLOB_TO_DATABASE_FAILURE"])
                        Logger.sharedInstance.logError(error: "SAVED_BLOB_TO_DATABASE_FAILURE")
                        onCompletion(error,response)
                    }
                }
                else
                {
                    self.onSuccesfulUploadInsertionToDB(status: .SAVED_BLOB_TO_DATABASE_SUCCESSFUL, entry: entry, type: .BLOB, response: response!, onCompletion: onCompletion)
                }
            }
        }
    }
    
    public func startUploadingEnrollmentsFromDB(andKeychain uploadFromKeychainEnabled: Bool)
    {
        Logger.sharedInstance.logInfo(info: "startUploadingEnrollmentsFromDBandKeychain : \(uploadFromKeychainEnabled)")
//        let isconnectionAvailable = NetworkStatusHelper.sharedInstance.isConnectionAvailable
        let isconnectionAvailable = NetworkManager.sharedInstance.isConnectionAvailable!
        Logger.sharedInstance.logInfo(info: "Is connection Available : \(isconnectionAvailable)")
        if !isUploaderActive && isconnectionAvailable
        {
            let nextEntry = DBManager.sharedInstance.retrieveNextEnrollmentToUpload()
            if let entry = nextEntry.0,
                let blobFolder = nextEntry.1
            {
                isUploaderActive = true
                
                Logger.sharedInstance.logInfo(info: blobFolder)
                self.callRespectiveUploadFunctionFor(entry: entry, blobFolder: blobFolder, withCallBackForKeychain: uploadFromKeychainEnabled)
            }
            else
            {
                if uploadFromKeychainEnabled
                {
                    Logger.sharedInstance.logInfo(info: "Initiating Upload from KC!")
                    let pendingAzurePayloadsFromKeychain = KeychainHelper.sharedInstance.getAllPendingAzurePayloadItemsFromKeychain()
                    startTransmissionOf(pendingAzurePayloadsFromKeychain: pendingAzurePayloadsFromKeychain, atIndex: 0)
                }
                
                self.resetTotalUploadedItems()
            }
            
        }
        
    }
    
    public func removeSuccessfulRecordsFromDevice()
    {
        Logger.sharedInstance.logInfo(info: "removeSuccessfulRecordsFromDevice")
        DBManager.sharedInstance.removeSuccessfulRecordsFromDB()
        {
            KeychainHelper.sharedInstance.startRemovingSuccessfulAzurePayloadsAndBlobsFromKeychain()
        }
    }
    
    public func getEnrollmentProgress() -> Int
    {
        let result = self.getPercentageCompleted()
        Logger.sharedInstance.logInfo(info: "getEnrollmentProgress : \(result)")
        return result
    }
    
    public func getTotalPendingUploads() -> Int
    {
        let pendingItemsCount = self.pendingUploads
        Logger.sharedInstance.logInfo(info: "getTotalPendingUploads : \(pendingItemsCount)")
        return pendingItemsCount
    }
    
    public func emptyDataBase()
    {
        Logger.sharedInstance.logInfo(info: "emptyDataBase")
        DBManager.sharedInstance.emptyCoreData()
    }
    
    //MARK: Private Functions
    
    private func onSuccesfulUploadInsertionToDB(status: EnrollmentStatusType, entry: EnrollmentEntry, type: EnrollmentType, response: String, onCompletion: @escaping (Error?,String?) -> Void)
    {
        Logger.sharedInstance.logInfo(info: "onSuccesfulUploadInsertionToDB For Type : \(type)")
        self.updatePendingUploads(1)
        
        self.changeStatusTo(status: status, forEntry: entry, ofType: type)
        {
//            let isconnectionAvailable = NetworkStatusHelper.sharedInstance.isConnectionAvailable
            let isconnectionAvailable = NetworkManager.sharedInstance.isConnectionAvailable!
            if(isconnectionAvailable)
            {
                self.startUploadingEnrollmentsFromDB(andKeychain: false)
                onCompletion(nil,response)
            }
            else
            {
                //TODO: Create Error that states the device is offline!
                let error = NSError(domain:"", code:0, userInfo:[ NSLocalizedDescriptionKey: "No network available!"])
                Logger.sharedInstance.logError(error: "No network available!")
                onCompletion(error,response)
            }
        }
    }
    
    private func callRespectiveUploadFunctionFor(entry: EnrollmentEntry, blobFolder: String, withCallBackForKeychain uploadFromKeychainEnabled: Bool)
    {
        Logger.sharedInstance.logInfo(info: "callRespectiveUploadFunctionFor For blobFolder : \(blobFolder)")
        if blobFolder == "none"
        {
            self.uploadAzureFunctionEnrollment(entry: entry)
            {
                self.startUploadingEnrollmentsFromDB(andKeychain: uploadFromKeychainEnabled)
            }
        }
        else if blobFolder == "docs"
        {
            self.uploadPhotoBlobEnrollment(entry: entry, blobFolder: blobFolder)
            {
                self.startUploadingEnrollmentsFromDB(andKeychain: uploadFromKeychainEnabled)
            }
        }
        else
        {
            self.uploadBlobEnrollment(entry: entry, blobFolder: blobFolder)
            {
                self.startUploadingEnrollmentsFromDB(andKeychain: uploadFromKeychainEnabled)
            }
        }
    }
    
    private func uploadAzureFunctionEnrollment(entry : EnrollmentEntry, onCompletion: @escaping () -> Void)
    {
        Logger.sharedInstance.logInfo(info: "uploadAzureFunctionEnrollment")
        AzureFunctionHelper.sharedInstance.sendEntryToAzureFunction(entry: entry)
        {
            (error, response) in
            self.isUploaderActive = false
            self.updateStatusOnAzureCompletion(error: error, response: response, entry: entry, enrollmentType: .AZURE_PAYLOAD, onCompletion: onCompletion)
        }
    }
    
    private func uploadBlobEnrollment(entry : EnrollmentEntry, blobFolder : String, onCompletion: @escaping () -> Void)
    {
        Logger.sharedInstance.logInfo(info: "uploadBlobEnrollment for BlobFolder : \(blobFolder)")
        AzureFunctionHelper.sharedInstance.sendBlobEntryToAzureFunction(entry: entry, blobFolder: blobFolder)
        {
            (error, response) in
            self.isUploaderActive = false
            self.updateStatusOnAzureCompletion(error: error, response: response, entry: entry, enrollmentType: .BLOB, onCompletion: onCompletion)
        }
    }
    
    private func uploadPhotoBlobEnrollment(entry : EnrollmentEntry, blobFolder : String, onCompletion: @escaping () -> Void)
    {
        Logger.sharedInstance.logInfo(info: "uploadPhotoBlobEnrollment for BlobFolder : \(blobFolder)")
        AzureFunctionHelper.sharedInstance.sendPhotoBlobEntryToAzureFunction(entry: entry, blobFolder: blobFolder)
        {
            (error, response) in
            self.isUploaderActive = false
            self.updateStatusOnAzureCompletion(error: error, response: response, entry: entry, enrollmentType: .PHOTO_BLOB, onCompletion: onCompletion)
        }
    }
    
    private func updateStatusOnAzureCompletion(error: Error?, response: String?, entry: EnrollmentEntry, enrollmentType: EnrollmentType, onCompletion: @escaping () -> Void)
    {
        Logger.sharedInstance.logInfo(info: "updateStatusOnAzureCompletion for Enrollment Type : \(enrollmentType)")
        let isEnrollmentTypeBlob = enrollmentType == .BLOB || enrollmentType == .PHOTO_BLOB
        let successStatus : EnrollmentStatusType = isEnrollmentTypeBlob ? .SENT_TO_BLOB_FUNCTION_SUCCESSFUL : .SENT_TO_AZURE_FUNCTION_SUCCESSFUL
        let failureStatus : EnrollmentStatusType = isEnrollmentTypeBlob ? .SENT_TO_BLOB_FUNCTION_FAILURE : .SENT_TO_AZURE_FUNCTION_FAILURE
        
        if error != nil
        {
            self.changeStatusTo(status: failureStatus, forEntry: entry, ofType: enrollmentType)
            {
                Logger.sharedInstance.logError(error: error.debugDescription)
                self.postNotificationsFor(status: failureStatus, entry: entry, enrollmentType: enrollmentType)
                onCompletion()
            }
        }
        else
        {
            self.updatePendingUploads(-1)
            self.incrementTotalUploadedItems()
            self.changeStatusTo(status: successStatus, forEntry: entry, ofType: .AZURE_PAYLOAD)
            {
                Logger.sharedInstance.logInfo(info: response!)
                self.postNotificationsFor(status: successStatus, entry: entry, enrollmentType: enrollmentType)
                onCompletion()
            }
        }
    }
    
    private func startTransmissionOf(pendingAzurePayloadsFromKeychain : [EnrollmentEntry], atIndex index: Int)
    {
        Logger.sharedInstance.logInfo(info: "startTransmissionOfpendingAzurePayloadsFromKeychain : \(pendingAzurePayloadsFromKeychain)")
        if index < pendingAzurePayloadsFromKeychain.count
        {
            let enrollmentEntry = pendingAzurePayloadsFromKeychain[index]
            
            Logger.sharedInstance.logInfo(info: "Uploading Azure Payload from KC! : \(enrollmentEntry.status)")
            
            AzureFunctionHelper.sharedInstance.sendEntryToAzureFunction(entry: enrollmentEntry)
            {
                (_,_) in
                self.startTransmissionOf(pendingAzurePayloadsFromKeychain: pendingAzurePayloadsFromKeychain, atIndex: index + 1)
            }
            
        }
        else
        {
            let pendingBlobsFromKeychain = KeychainHelper.sharedInstance.getAllPendingBlobItemsFromKeychain()
            startTransmissionOf(pendingBlobsFromKeychain: pendingBlobsFromKeychain, atIndex: 0)
        }
    }
    
    private func startTransmissionOf(pendingBlobsFromKeychain : [(EnrollmentEntry,String)], atIndex index: Int)
    {
        Logger.sharedInstance.logInfo(info: "startTransmissionOfpendingBlobsFromKeychain : \(pendingBlobsFromKeychain)")
        if index < pendingBlobsFromKeychain.count
        {
            let enrollmentEntry = pendingBlobsFromKeychain[index].0
            let blobFolder = pendingBlobsFromKeychain[index].1
            
            Logger.sharedInstance.logInfo(info: "Uploading Blob Payload from KC! : \(enrollmentEntry.status)")
            
            AzureFunctionHelper.sharedInstance.sendBlobEntryToAzureFunction(entry: enrollmentEntry, blobFolder: blobFolder)
            {
                (_,_) in
                self.startTransmissionOf(pendingBlobsFromKeychain: pendingBlobsFromKeychain, atIndex: index + 1)
            }
        }
        else
        {
            Logger.sharedInstance.logInfo(info: "Uploading completed!")
            //            let pendingAzurePayloadsFromDB = SQLiteHelper.sharedInstance.getAllPendingAzurePayloadItemsFromDB()
            //            startTransmissionOf(pendingAzurePayloadsFromDB: pendingAzurePayloadsFromDB, atIndex: 0)
        }
    }
    
    //MARK: Helper methods
    
    private func changeStatusTo(status: EnrollmentStatusType, forEntry entry: EnrollmentEntry, ofType enrollmentType: EnrollmentType, onCompletion: @escaping () -> Void)
    {
        Logger.sharedInstance.logInfo(info: "Changing status of enrollment type : \(enrollmentType)")
        
        //Updating status in DB
        DBManager.sharedInstance.changeStatusTo(status: status, forEnrollmentEntry: entry, onCompletion: onCompletion)
        
        //Updating status in Keychain
        if enrollmentType == .BLOB
        {
            KeychainHelper.sharedInstance.changeStatusTo(status: status, forBlobEntry: entry)
        }
        else
        {
            KeychainHelper.sharedInstance.changeStatusTo(status: status, forEntry: entry)
        }
    }
    
    private func updatePendingUploads(_ value:Int)
    {
        self.pendingUploads += value
        Logger.sharedInstance.logInfo(info: "******* Pending uploads:\(self.pendingUploads)")

        if self.pendingUploads < 0
        {
            self.pendingUploads = 0
        }
        NotificationHelper.sharedInstance.postPendingUploadsEvent()
    }
    
    private func incrementTotalUploadedItems()
    {
        self.totalUploadedItems += 1
    }
    
    private func resetTotalUploadedItems()
    {
        self.totalUploadedItems = 0;
    }
    
    public func getPercentageCompleted()-> Int
    {
        var result = -1;
        
        if NetworkManager.sharedInstance.isConnectionAvailable
        {
            let pendingUploads = Float(self.pendingUploads)
            let totalUploadedItems = Float(self.totalUploadedItems)
            let totalUploads = pendingUploads + totalUploadedItems
            result = totalUploads == 0 ? 100 : Int(totalUploadedItems/totalUploads * 100)
            Logger.sharedInstance.logInfo(info: "Total Uploads = \(totalUploads)")
            Logger.sharedInstance.logInfo(info: "Total Items Uploaded = \(totalUploadedItems)")
            Logger.sharedInstance.logInfo(info: "Total Pending Uploads = \(pendingUploads)")
            
            Logger.sharedInstance.logInfo(info: "Enrollment Upload Progress = \(result)")
        }
        
        return result;
    }
    
    private func postNotificationsFor(status: EnrollmentStatusType, entry: EnrollmentEntry, enrollmentType: EnrollmentType)
    {
        Logger.sharedInstance.logInfo(info: "postNotificationsForStatus : \(status), and enrollmentType : \(enrollmentType)")
        if enrollmentType != .PHOTO_BLOB
        {
            NotificationHelper.sharedInstance.postUploadCompletedEvent(messageId: entry.uniqueMessageID)
        }
        
        let percentageCompleted = self.getPercentageCompleted()
        NotificationHelper.sharedInstance.postChangeStatusEvent(status: percentageCompleted);
    }

}
