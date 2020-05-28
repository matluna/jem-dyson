import Foundation
import CoreData

@available(iOS 10.0, *)
class DBManager: NSObject {
    
    fileprivate var mainContextInstance: NSManagedObjectContext
    
    let datastore: DatastoreCoordinator!
    
    public static let sharedInstance = DBManager()
    
    private override init() {
        self.datastore = UIApplication.shared.delegate?.getDataStoreCoordinator()
        Logger.sharedInstance.logDebug(debug: self.datastore.objectModelName)
        self.mainContextInstance = self.datastore.mainManagedObjectContextInstance
        super.init()
    }
    
    /**
     Get a reference to the Main Context Instance
     
     - Returns: Main NSmanagedObjectContext
     */
    func getMainContextInstance() -> NSManagedObjectContext {
        return self.mainContextInstance
    }    
    
    
    func saveWorkerContext(_ workerContext: NSManagedObjectContext) {
        do {
            try workerContext.save()
        } catch let saveError as NSError {
            Logger.sharedInstance.logError(error: "save minion worker error: \(saveError.localizedDescription)")
        }
    }
    
    func saveWorkerContext(_ workerContext: NSManagedObjectContext, entry: EnrollmentEntry?, onCompletion: @escaping (Error?,String?) -> Void) {
        
        var response = "Data Queued"
        if let uniqueMessageID = entry?.uniqueMessageID
        {
            response = uniqueMessageID
        }
        
        do {
            try workerContext.save()
            onCompletion(nil,response)
        } catch let saveError as NSError {
            Logger.sharedInstance.logError(error: "save minion worker error: \(saveError.localizedDescription)")
            onCompletion(saveError,response)
        }
    }
    
    func mergeWithMainContext() {
        do {
            try self.mainContextInstance.save()
        } catch let saveError as NSError {
            Logger.sharedInstance.logError(error: "synWithMainContext error: \(saveError.localizedDescription)")
        }
    }
    
    
    // MARK:  Add Enrollment To CoreData
    
    private func createEnrollmentEntity(entry : EnrollmentEntry, blobContainer : String, type : String, usingManagedContext managedContext : NSManagedObjectContext)
    {
        let enrollmentEntity = NSEntityDescription.entity(forEntityName: "Enrollment", in: managedContext)!
        let enrollment = NSManagedObject(entity: enrollmentEntity, insertInto: managedContext)
        
        enrollment.setValue(entry.data, forKeyPath: "enrollmentData")
        enrollment.setValue(entry.enrollmentIdentifier, forKeyPath: "enrollmentKey")
        enrollment.setValue(type, forKeyPath: "enrollmentType")
        enrollment.setValue(entry.uniqueMessageID, forKeyPath: "messageId")
        enrollment.setValue(entry.status, forKeyPath: "status")
        enrollment.setValue(blobContainer, forKeyPath: "containerData")
        enrollment.setValue(Date(), forKey: "createdAt")
    }
    
    func createAzureEnrollment(entry : EnrollmentEntry, onCompletion: @escaping (Error?,String?) -> Void)
    {
        Logger.sharedInstance.logInfo(info: "createAzureEnrollment")
        DispatchQueue.global(qos: .background).async
        {
            let managedContext: NSManagedObjectContext =
                NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
            managedContext.parent = self.mainContextInstance
            
            managedContext.performAndWait
            {
                self.createEnrollmentEntity(entry: entry, blobContainer: "none", type: "azure_payload", usingManagedContext: managedContext)
                self.saveWorkerContext(managedContext, entry: entry, onCompletion: onCompletion)
//                self.mergeWithMainContext()
            }
            
        }
    }
    
    func createBlobEnrollment(entry : EnrollmentEntry, blobContainer : String, ofTypePhoto: Bool, onCompletion: @escaping (Error?,String?) -> Void)
    {
        Logger.sharedInstance.logInfo(info: "createBlobEnrollment for blobFolder : \(blobContainer)")
        DispatchQueue.global(qos: .background).async
        {
            let managedContext: NSManagedObjectContext =
                NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
            managedContext.parent = self.mainContextInstance
            
            managedContext.performAndWait
            {
                let type = ofTypePhoto ? "photo" : "blob"
                self.createEnrollmentEntity(entry: entry, blobContainer: blobContainer, type: type, usingManagedContext: managedContext)
                self.saveWorkerContext(managedContext, entry: entry, onCompletion: onCompletion)
//                self.mergeWithMainContext()
            }
        }
    }
    
    // MARK:  Change Status of Enrollment in CoreData
    
    func changeStatusTo(status: EnrollmentStatusType, forEnrollmentEntry entry: EnrollmentEntry, onCompletion: @escaping () -> Void)
    {
        
        Logger.sharedInstance.logInfo(info: "Changing status of azure_payload Entry in DB : \(status)")
        
        entry.status = "\(status)"
        DispatchQueue.global(qos: .background).async
        {
            //            let managedContext = self.mainContextInstance
            let managedContext: NSManagedObjectContext =
                NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
            managedContext.parent = self.mainContextInstance
            
            let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "Enrollment")
            fetchRequest.predicate = NSPredicate(format: "messageId == %@", entry.uniqueMessageID)
            do
            {
                let fetchResult = try managedContext.fetch(fetchRequest)
                
                if fetchResult.count > 0,
                    let objectUpdate = fetchResult[0] as? NSManagedObject
                {
                    managedContext.performAndWait
                    {
                        objectUpdate.setValue(entry.status, forKey: "status")
                        self.saveWorkerContext(managedContext, entry: entry)
                        {
                            (_,_) in
                            onCompletion()
                        }
//                        self.mergeWithMainContext()
                    }
                }
            }
            catch
            {
                Logger.sharedInstance.logError(error: error.localizedDescription)
            }
                
        }
    }
    
    // MARK: Retrieve enrollments from CoreData
    
    public func retrieveNextEnrollmentToUpload() -> (EnrollmentEntry?,String?){
        
        var entry : EnrollmentEntry!
        var container : String!
        
        let managedContext: NSManagedObjectContext =
            NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        managedContext.parent = self.mainContextInstance
        
        let sentAzureFunctionSuccessfulStatus = "\(EnrollmentStatusType.SENT_TO_AZURE_FUNCTION_SUCCESSFUL)"
        let sentBlobFunctionSuccessfulStatus = "\(EnrollmentStatusType.SENT_TO_BLOB_FUNCTION_SUCCESSFUL)"
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Enrollment")
        
        fetchRequest.predicate = NSPredicate(format: "status != %@ AND status != %@", sentAzureFunctionSuccessfulStatus, sentBlobFunctionSuccessfulStatus)
        fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "createdAt", ascending: false)]
        
        do
        {
            let fetchResult = try managedContext.fetch(fetchRequest)
//            dump(fetchResult)
            
            Logger.sharedInstance.logInfo(info: "retrieveNextEnrollmentToUpload : fetch count\(fetchResult.count)")
            
            if fetchResult.count > 0,
                let data = fetchResult[0] as? NSManagedObject
            {
                let enrollmentData = data.value(forKey: "enrollmentData") as! String
                let enrollmentKey = data.value(forKey: "enrollmentKey") as! String
                let messageId = data.value(forKey: "messageId") as! String
                let status = data.value(forKey: "status") as! String
                
                Logger.sharedInstance.logDebug(debug: "UniqueID : \(messageId),\nStatus: \(status)")
                
                container = data.value(forKey: "containerData") as! String
                entry = ACPTModel(uniqueMessageID: messageId, data: enrollmentData, status: status, enrollmentIdentifier: enrollmentKey)
            }
        }
        catch
        {
            Logger.sharedInstance.logError(error: "Failed to retrieve Next Enrollment!")
        }
        
        return (entry,container)
    }
    
    func retrieveEnrollmentWith(messageId : String) -> EnrollmentEntry?{
        
        var result : EnrollmentEntry!
        
        let managedContext: NSManagedObjectContext =
            NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        managedContext.parent = self.mainContextInstance
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Enrollment")
        
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "messageId == %@ AND enrollmentType == azure_payload", messageId)
        do
        {
            let fetchResult = try managedContext.fetch(fetchRequest)
            if let data = fetchResult[0] as? NSManagedObject
            {
                let enrollmentData = data.value(forKey: "enrollmentData") as! String
                let enrollmentKey = data.value(forKey: "enrollmentKey") as! String
                let messageId = data.value(forKey: "messageId") as! String
                let status = data.value(forKey: "status") as! String
                
                result = ACPTModel(uniqueMessageID: messageId, data: enrollmentData, status: status, enrollmentIdentifier: enrollmentKey)
            }
        }
        catch
        {
            Logger.sharedInstance.logError(error: "Failed to retrieve Enrollment for messageID : \(messageId)")
        }
        
        return result
    }
    
    func retrieveBlobEnrollmentWith(messageId : String) -> (EnrollmentEntry?,String?){
        
        var entry : EnrollmentEntry!
        var container : String!
        
        let managedContext: NSManagedObjectContext =
            NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        managedContext.parent = self.mainContextInstance
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Enrollment")
        
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "messageId == %@ AND enrollmentType == blob", messageId)
        do
        {
            let fetchResult = try managedContext.fetch(fetchRequest)
            if let data = fetchResult[0] as? NSManagedObject
            {
                let enrollmentData = data.value(forKey: "enrollmentData") as! String
                let enrollmentKey = data.value(forKey: "enrollmentKey") as! String
                let messageId = data.value(forKey: "messageId") as! String
                let status = data.value(forKey: "status") as! String
                
                container = data.value(forKey: "containerData") as! String
                entry = ACPTModel(uniqueMessageID: messageId, data: enrollmentData, status: status, enrollmentIdentifier: enrollmentKey)
            }
        }
        catch {
            Logger.sharedInstance.logError(error: "Failed to retrieve Enrollment for messageID : \(messageId)")
        }
        
        return (entry,container)
    }
    
    // MARK: Helper Methods
    
    public func getPendingItemsFromDB() -> Int
    {
        var result = 0
        
        let managedContext: NSManagedObjectContext =
            NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        managedContext.parent = self.mainContextInstance
        
        let sentAzureFunctionSuccessfulStatus = "\(EnrollmentStatusType.SENT_TO_AZURE_FUNCTION_SUCCESSFUL)"
        let sentBlobFunctionSuccessfulStatus = "\(EnrollmentStatusType.SENT_TO_BLOB_FUNCTION_SUCCESSFUL)"
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Enrollment")
        
        fetchRequest.predicate = NSPredicate(format: "status != %@ AND status != %@", sentAzureFunctionSuccessfulStatus, sentBlobFunctionSuccessfulStatus)
        do
        {
            result = try managedContext.count(for: fetchRequest)
        }
        catch {
            Logger.sharedInstance.logError(error: "Failed to retrieve Pending items count from core data!")
        }
        
        return result
    }
    
    public func getTotalUploadedItemsFromDB() -> Int
    {
        var result = 0
        
        let managedContext: NSManagedObjectContext =
            NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        managedContext.parent = self.mainContextInstance
        
        let sentAzureFunctionSuccessfulStatus = "\(EnrollmentStatusType.SENT_TO_AZURE_FUNCTION_SUCCESSFUL)"
        let sentBlobFunctionSuccessfulStatus = "\(EnrollmentStatusType.SENT_TO_BLOB_FUNCTION_SUCCESSFUL)"
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Enrollment")
        
        fetchRequest.predicate = NSPredicate(format: "status = %@ AND status = %@", sentAzureFunctionSuccessfulStatus, sentBlobFunctionSuccessfulStatus)
        do
        {
            result = try managedContext.count(for: fetchRequest)
        }
        catch {
            Logger.sharedInstance.logError(error: "Failed to retrieve Pending items count from core data!")
        }
        
        return result
    }
    
    public func getPendingEnrollmentFromCD() -> Int
    {
        var result = 0
        
        let managedContext: NSManagedObjectContext =
            NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        managedContext.parent = self.mainContextInstance
        
        let sentAzureFunctionSuccessfulStatus = "\(EnrollmentStatusType.SENT_TO_AZURE_FUNCTION_SUCCESSFUL)"
        let sentBlobFunctionSuccessfulStatus = "\(EnrollmentStatusType.SENT_TO_BLOB_FUNCTION_SUCCESSFUL)"
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Enrollment")
        
        fetchRequest.predicate = NSPredicate(format: "status != %@ AND status != %@", sentAzureFunctionSuccessfulStatus, sentBlobFunctionSuccessfulStatus)
        fetchRequest.propertiesToFetch = ["enrollmentKey"]
        fetchRequest.returnsDistinctResults = true
        do
        {
            result = try managedContext.count(for: fetchRequest)
            Logger.sharedInstance.logInfo(info: "Pending Enrollments : \(result)")
        }
        catch {
            print()
            Logger.sharedInstance.logError(error: "Failed to retrieve Pending items count from core data!")
        }
        
        return result
    }
    
    //MARK: Delete methods
    
    func removeSuccessfulRecordsFromDB(onCompletion: @escaping () -> Void)
    {
        Logger.sharedInstance.logInfo(info: "removeSuccessfulRecordsFromDB")

        let managedContext: NSManagedObjectContext =
            NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        managedContext.parent = self.mainContextInstance
        
        let sentAzureFunctionSuccessfulStatus = "\(EnrollmentStatusType.SENT_TO_AZURE_FUNCTION_SUCCESSFUL)"
        let sentBlobFunctionSuccessfulStatus = "\(EnrollmentStatusType.SENT_TO_BLOB_FUNCTION_SUCCESSFUL)"
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Enrollment")
        
        fetchRequest.predicate = NSPredicate(format: "status == %@ OR status == %@", sentAzureFunctionSuccessfulStatus, sentBlobFunctionSuccessfulStatus)
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            
            try managedContext.execute(batchDeleteRequest)
            
            self.saveWorkerContext(managedContext, entry: nil)
            {
                (_,_) in
                onCompletion()
            }
//            self.mergeWithMainContext()
            Logger.sharedInstance.logInfo(info: "All succesful records deleted from CD!")
            
        }
        catch
        {
            Logger.sharedInstance.logError(error: error.localizedDescription)
        }
        
    }
    
    func emptyCoreData()
    {
        
        let managedContext: NSManagedObjectContext =
            NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        managedContext.parent = self.mainContextInstance
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Enrollment")
        
        do
        {
            let fetchResult = try managedContext.fetch(fetchRequest)
            
            for item in fetchResult as! [NSManagedObject]
            {
                managedContext.delete(item)
                self.saveWorkerContext(managedContext)
            }
            
//            self.mergeWithMainContext()
        }
        catch
        {
            Logger.sharedInstance.logError(error: error.localizedDescription)
        }
    }
    
    
}

