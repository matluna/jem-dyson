import Foundation

@available(iOS 10.0, *)
class SQLiteHelper {
    
    //MARK: Private variables
    private var version : String!
//    private var databaseName : String!
    private var uploadTableName : String!
    private var dataBase : SQLiteDB!


    //MARK: Init methods
    private init() {
        version = "v0.0.1"
//        databaseName = "Enrollment_Manager_\(version)"
        uploadTableName = "UPLOADS"
        self.setupDatabase()
    }
    
    public static let sharedInstance = SQLiteHelper()
    
    private func setupDatabase(){
        
        dataBase = SQLiteDB.shared
        let isDatabaseOpen = dataBase.open(copyFile:true)
        if isDatabaseOpen {
            self.createTableIfNotCreatedBefore()
        }else{
            Logger.sharedInstance.logError(error: "Error Occured while creating the SQLite Database")
        }
        
    }
    
    private func createTableIfNotCreatedBefore(){

        if (!tableAlreadyExists()){
            let tableCreationSuccessful = self.createUploadsTableWith(tableName:uploadTableName)
            if tableCreationSuccessful {
                let key = Key<Bool>("UploadsTableExists")
                Defaults.shared.set(true, for: key)
            }
            else{
                //TODO: Handle error here!
                Logger.sharedInstance.logError(error: "Error Occured while creating the SQLite Table named UPLOADS")
            }
        }else{
            QueryHelper.sharedInstance.tableName = uploadTableName
        }
        
    }
    
    private func tableAlreadyExists() -> Bool {
        var result = false
        let key = Key<Bool>("UploadsTableExists")
        if Defaults.shared.has(key){
            result = Defaults.shared.get(for: key)!
        }
        return result
    }
    
    private func createUploadsTableWith(tableName : String) -> Bool{
        var result = false
        let query = QueryHelper.sharedInstance.getCreateTableQueryForTableName(tableName: tableName)
        
        let queryExecutionStatus = dataBase.execute(sql: query)
        
        result = (queryExecutionStatus == 0) ? false : true
        
        return result
    }
    
    //MARK: DataBase Methods
    
    public func saveEnrollmentEntryInDB(entry:EnrollmentEntry, onCompletion: @escaping (Error?,String?) -> Void){
        
        DispatchQueue.global(qos: .background).async {

            let insertQuery = QueryHelper.sharedInstance.getInsertQueryForEnrollmentEntry(entry: entry)
            let insertDataQueryStatus = self.dataBase.execute(sql: insertQuery)
            let isDataSavedInDBSuccessfully = (insertDataQueryStatus == 0) ? false : true
            
            if (isDataSavedInDBSuccessfully){
                //Change status to SAVED_AZURE_PAYLOAD_TO_DATABASE_SUCCESSFUL
                KeychainHelper.sharedInstance.changeStatusTo(status: .SAVED_AZURE_PAYLOAD_TO_DATABASE_SUCCESSFUL, forEntry: entry)
                let isconnectionAvailable = NetworkStatusHelper.sharedInstance.isConnectionAvailable()
                if(isconnectionAvailable){
                    let pendingEnrollments = EnrollmentHelper.sharedInstance.getTotalPendingEnrollments()
                    if pendingEnrollments == 1
                    {
                        EnrollmentHelper.sharedInstance.startUploadingEnrollmentsFromDB()
                    }
                    onCompletion(nil,"Upload Added to Queue")
                }else{
                    //TODO: Create Error that states the device is offline!
                    let error = NSError(domain:"", code:0, userInfo:[ NSLocalizedDescriptionKey: "No network available!"])
                    Logger.sharedInstance.logError(error: "No network available!")
                    onCompletion(error,nil)
                }
                
            }else {
                //Change status to SAVED_AZURE_PAYLOAD_TO_DATABASE_FAILURE
                KeychainHelper.sharedInstance.changeStatusTo(status: .SAVED_AZURE_PAYLOAD_TO_DATABASE_FAILURE, forEntry: entry)
                let error = NSError(domain:"", code:0, userInfo:[ NSLocalizedDescriptionKey: "Error occured while saving data in DB"])
                onCompletion(error,nil)
            }
            
        }
        
    }
    
    public func saveBlobEntryInDB(entry:EnrollmentEntry, blobFolder: String, onCompletion: @escaping (Error?,String?) -> Void){
        
        DispatchQueue.global(qos: .background).async {
            
            let insertQuery = QueryHelper.sharedInstance.getInsertQueryForBlobEntry(entry: entry, blobContainer: blobFolder)
            let insertDataQueryStatus = self.dataBase.execute(sql: insertQuery)
            let isDataSavedInDBSuccessfully = (insertDataQueryStatus == 0) ? false : true
            
            if (isDataSavedInDBSuccessfully){
                //Change status to SAVED_BLOB_TO_DATABASE_SUCCESSFUL
                KeychainHelper.sharedInstance.changeStatusTo(status: .SAVED_BLOB_TO_DATABASE_SUCCESSFUL, forEntry: entry)
                let isconnectionAvailable = NetworkStatusHelper.sharedInstance.isConnectionAvailable()
                
                if(isconnectionAvailable){
                    
                    let pendingEnrollments = EnrollmentHelper.sharedInstance.getTotalPendingEnrollments()
                    if pendingEnrollments == 1
                    {
                        EnrollmentHelper.sharedInstance.startUploadingEnrollmentsFromDB()
                    }
                    onCompletion(nil,"Upload Added to Queue")
                    
                }else{
                    //TODO: Create Error that states the device is offline!
                    let error = NSError(domain:"", code:0, userInfo:[ NSLocalizedDescriptionKey: "No network available!"])
                    Logger.sharedInstance.logError(error: "No network available!")
                    onCompletion(error,"No network available!")
                }
                
            }else {
                //Change status to SAVED_BLOB_TO_DATABASE_FAILURE
                KeychainHelper.sharedInstance.changeStatusTo(status: .SAVED_BLOB_TO_DATABASE_FAILURE, forEntry: entry)
                let error = NSError(domain:"", code:0, userInfo:[ NSLocalizedDescriptionKey: "Error occured while saving data in DB"])
                onCompletion(error,nil)
            }
            
        }
        
    }
    
    public func getNextItemToUpload() -> (EnrollmentEntry,String)
    {
        let result : (EnrollmentEntry,String)!
        
        let query = QueryHelper.sharedInstance.getNextRecordToUploadQuery()
//        Logger.sharedInstance.logInfo(info:"Next Item Query :\n\(query)")
        
        let queryResponse = self.dataBase.query(sql: query)
        
//        Logger.sharedInstance.logInfo(info:"\(queryResponse)")
        
        let nextItem = queryResponse[0]
        let messageId = nextItem["messageID"] as! String
        let data = nextItem["data"] as! String
        let status = nextItem["status"] as! String
        let enrollmentIdentifier = nextItem["enrollmentIdentifier"] as! String
        let environment = EnrollmentHelper.sharedInstance.environment!
        let blobContainer = nextItem["container"] as! String
        
        let entry : EnrollmentEntry = ACPTModel(uniqueMessageID: messageId, data: data, status: status, environment: environment, enrollmentIdentifier: enrollmentIdentifier)
        
        result = (entry,blobContainer)
        
        return result
    }
    
    public func updateStatus(forEntry entry:EnrollmentEntry) -> Bool {
        let query = QueryHelper.sharedInstance.getUpdateStatusQueryForEnrollmentEntry(entry: entry)
        let queryExecutionStatus = self.dataBase.execute(sql: query)
        let result = (queryExecutionStatus == 0) ? false : true
        return result
    }
    
    public func getAllDetailsForMessageID(_ messageID : String) -> EnrollmentEntry{
        
        let query = QueryHelper.sharedInstance.getSelectAllDetailsQueryForMessageID(messageID: messageID)
        var queryRespone = self.dataBase.query(sql: query)[0]
        
        let data = queryRespone["data"] as! String
        let status = queryRespone["status"] as! String
        let enrollmentIdentifier = queryRespone["enrollmentIdentifier"] as! String
        
        let entry : EnrollmentEntry = ACPTModel(uniqueMessageID: messageID, data: data, status: status, environment: EnrollmentHelper.sharedInstance.environment, enrollmentIdentifier: enrollmentIdentifier)
        
        return entry
    }
    
    public func getAllPendingEnrollmentIDs () -> [String]
    {
        let query = QueryHelper.sharedInstance.getSelectAllPendingEnrollmentIDsQuery()
        let queryResponse = self.dataBase.query(sql: query)
        
        var result = Set<String>()
        
        for pendingEnrollmentObject in queryResponse
        {
            let enrollmentID = pendingEnrollmentObject["enrollmentIdentifier"] as! String
            result.insert(enrollmentID)
        }
        
        return Array(result)
        
    }
    
    public func startRemovingSuccessfulAzurePayloadsAndBlobsFromDB()
    {
        let query = QueryHelper.sharedInstance.getDeleteQueryForSuccessfulItems()
        _ = self.dataBase.execute(sql: query)
    }
    
    public func getPendingItemsFromDB() -> [String]
    {
        let pendingPayloadsQuery = QueryHelper.sharedInstance.getSelectAllPendingPayloadsQuery()
        let pendingPayloadsQueryResponse = self.dataBase.query(sql: pendingPayloadsQuery)
        
        var result = [String]()
        
        for pendingPayload in pendingPayloadsQueryResponse {
            let messageID = pendingPayload["messageID"] as! String
            result.append(messageID)
        }
        
        return result
    }
    
//    public func getAllPendingAzurePayloadItemsFromDB() -> [EnrollmentEntry]{
//
//        let query = QueryHelper.sharedInstance.getSelectAllPendingAzurePayloadsQuery()
//        let queryRespone = self.dataBase.query(sql: query)
//        var enteries = [EnrollmentEntry]()
//
//        for row in queryRespone {
//            let data = row["data"] as! String
//            let status = row["status"] as! String
//            let messageID = row["messageID"] as! String
//            let enrollmentIdentifier = row["enrollmentIdentifier"] as! String
//
//            let enrollmentEntry = ACPTModel(uniqueMessageID: messageID, data: data, status: status, environment: EnrollmentHelper.sharedInstance.environment, enrollmentIdentifier: enrollmentIdentifier)
//            enteries.append(enrollmentEntry)
//        }
//
//        return enteries
//    }
    
//    public func getAllPendingBlobItemsFromDB() -> [(EnrollmentEntry,String)]{
//        
//        let query = QueryHelper.sharedInstance.getSelectAllPendingBlobsQuery()
//        let queryRespone = self.dataBase.query(sql: query)
//        var enteries = [(EnrollmentEntry,String)]()
//        
//        for row in queryRespone {
//            let data = row["data"] as! String
//            let status = row["status"] as! String
//            let messageID = row["messageID"] as! String
//            let enrollmentIdentifier = row["enrollmentIdentifier"] as! String
//            
//            let enrollmentEntry : EnrollmentEntry = ACPTModel(uniqueMessageID: messageID, data: data, status: status, environment: EnrollmentHelper.sharedInstance.environment, enrollmentIdentifier: enrollmentIdentifier)
//            
//            let container = row["container"] as! String
//            let tupleEntry = (enrollmentEntry,container)
//            
//            enteries.append(tupleEntry)
//        }
//        
//        return enteries
//    }
    
    public func deleteRowForMessageID(_ messageID: String) -> Bool{
        
        let query = QueryHelper.sharedInstance.getDeleteRowQueryForMessageID(messageID: messageID)
        
        let queryExecutionStatus = self.dataBase.execute(sql: query)
        
        let result = (queryExecutionStatus == 0) ? false : true
        
        return result
    }
    
}
