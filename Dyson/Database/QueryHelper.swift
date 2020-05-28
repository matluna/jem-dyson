import Foundation
@available(iOS 10.0, *)
class QueryHelper {
    
    public var tableName : String!
    private init() {}
    public static let sharedInstance = QueryHelper()
    
    public func getCreateTableQueryForTableName(tableName:String) -> String{
        self.tableName = tableName
        let result = "CREATE TABLE \(tableName) ( messageID text , data text NOT NULL, status text NOT NULL,type text, container text, enrollmentIdentifier text, date text);"
        return result
    }
    
    public func getInsertQueryForEnrollmentEntry(entry:EnrollmentEntry) -> String{
        
        let date = Date()
        let dateString = ISO8601DateFormatter.string(from: date, timeZone: TimeZone.current)
        let result = "INSERT INTO \(self.tableName!) (messageID, data, status, type, container, enrollmentIdentifier, date) VALUES ('\(entry.uniqueMessageID)', '\(entry.data)', '\(entry.status)', 'azure_payload', 'none', '\(entry.enrollmentIdentifier)', '\(dateString)');"
        
//        Logger.sharedInstance.logInfo(info: result);
        
        return result
    }
    
    public func getInsertQueryForBlobEntry(entry:EnrollmentEntry, blobContainer: String) -> String{
        
        let date = Date()
        let dateString = ISO8601DateFormatter.string(from: date, timeZone: TimeZone.current)
        let result = "INSERT INTO \(self.tableName!) (messageID, data, status, type, container, enrollmentIdentifier, date) VALUES ('\(entry.uniqueMessageID)', '\(entry.data)','\(entry.status)','blob', '\(blobContainer)', '\(entry.enrollmentIdentifier)', '\(dateString)');"
        return result
    }
    
    public func getUpdateStatusQueryForEnrollmentEntry(entry:EnrollmentEntry) -> String {
        let sendToAzureFunctionSuccessfulStatus = EnrollmentStatusType.SENT_TO_AZURE_FUNCTION_SUCCESSFUL
        let sendToBlobSuccesfulStatus = EnrollmentStatusType.SENT_TO_BLOB_FUNCTION_SUCCESSFUL
        
        let result = "UPDATE \(self.tableName!) SET status ='\(entry.status)' WHERE (messageID = '\(entry.uniqueMessageID)') AND ( status != '\(sendToBlobSuccesfulStatus)' AND status != '\(sendToAzureFunctionSuccessfulStatus)' );"
        return result
    }
    
    public func getSelectAllDetailsQueryForMessageID(messageID : String) -> String{
        let result = "SELECT * FROM \(self.tableName!) WHERE messageID = '\(messageID)';"
        return result
    }
    
    public func getNextRecordToUploadQuery() -> String{
        let sendToAzureFunctionSuccessfulStatus = EnrollmentStatusType.SENT_TO_AZURE_FUNCTION_SUCCESSFUL
        let sendToBlobSuccesfulStatus = EnrollmentStatusType.SENT_TO_BLOB_FUNCTION_SUCCESSFUL
        
        let result = "SELECT * FROM \(self.tableName!) WHERE ( status != '\(sendToAzureFunctionSuccessfulStatus)' AND status != '\(sendToBlobSuccesfulStatus)' ) ORDER BY date DESC;"
        return result
    }
    
    public func getSelectAllPendingPayloadsQuery() -> String{
        let sendToAzureFunctionSuccessfulStatus = EnrollmentStatusType.SENT_TO_AZURE_FUNCTION_SUCCESSFUL
        let sendToBlobSuccesfulStatus = EnrollmentStatusType.SENT_TO_BLOB_FUNCTION_SUCCESSFUL
        
        let result = "SELECT messageID FROM \(self.tableName!) WHERE ( status != '\(sendToAzureFunctionSuccessfulStatus)' AND status != '\(sendToBlobSuccesfulStatus)' );"
        return result
    }
    
//    public func getSelectAllPendingBlobsQuery() -> String{
//        let blobFunctionFailureStatus = EnrollmentStatusType.SENT_TO_AZURE_FUNCTION_FAILURE
//        let saveToDBSuccesStatus = EnrollmentStatusType.SAVED_BLOB_TO_DATABASE_SUCCESSFUL
//        let result = "SELECT * FROM \(self.tableName!) WHERE type = 'blob' AND ( status = '\(blobFunctionFailureStatus)' OR status = '\(saveToDBSuccesStatus)' );"
//        return result
//    }
    
    public func getSelectAllPendingEnrollmentIDsQuery() -> String{
        let blobFunctionFailureStatus = EnrollmentStatusType.SENT_TO_AZURE_FUNCTION_FAILURE
        let saveBlobToDBSuccesStatus = EnrollmentStatusType.SAVED_BLOB_TO_DATABASE_SUCCESSFUL
        let azureFunctionFailureStatus = EnrollmentStatusType.SENT_TO_AZURE_FUNCTION_FAILURE
        let saveAzureToDBSuccesStatus = EnrollmentStatusType.SAVED_AZURE_PAYLOAD_TO_DATABASE_SUCCESSFUL
        let result = "SELECT enrollmentIdentifier FROM \(self.tableName!) WHERE ( status = '\(blobFunctionFailureStatus)' OR status = '\(saveBlobToDBSuccesStatus)' OR status = '\(azureFunctionFailureStatus)' OR status = '\(saveAzureToDBSuccesStatus)' );"
        return result
    }
    
    public func getDeleteQueryForSuccessfulItems() -> String{
        let azureFunctionSuccessStatus = EnrollmentStatusType.SENT_TO_AZURE_FUNCTION_SUCCESSFUL
        let blobFunctionSuccessStatus = EnrollmentStatusType.SENT_TO_BLOB_FUNCTION_SUCCESSFUL
        let result = "DELETE FROM \(self.tableName!) WHERE status = '\(azureFunctionSuccessStatus)' OR status = '\(blobFunctionSuccessStatus)';"
        return result
    }
    
    public func getDeleteRowQueryForMessageID(messageID : String) -> String{
        let result = "DELETE FROM \(self.tableName!) WHERE messageID = '\(messageID)';"
        return result
    }
    
}
