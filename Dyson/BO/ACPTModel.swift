import Foundation
public class ACPTModel : EnrollmentEntry {
    public var uniqueMessageID: String
    public var data: String
    public var status: String
    public var enrollmentIdentifier: String
    
    public init (uniqueMessageID : String, data : String, status : String, enrollmentIdentifier : String){
        
        self.uniqueMessageID = uniqueMessageID
        self.data = data
        self.status = status
        self.enrollmentIdentifier = enrollmentIdentifier
    }
}
