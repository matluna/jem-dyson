import Foundation
public protocol EnrollmentEntry : class {
    var uniqueMessageID : String { get set }
    var data : String { get set }
    var status : String { get set }
    var enrollmentIdentifier : String { get set }
}
