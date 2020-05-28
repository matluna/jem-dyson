import Foundation

public class CDVPluginHelper {
    
    private init() {}
    public static let sharedInstance = CDVPluginHelper()
    
    public func getJavascriptChangeStatusCommandFor(status : Int) -> String{
        let result = "window.changeStatus(\(status));"
        return result
    }
    
    public func getJavascriptChangeUpdateCurrentUploadedItemsCommandFor(uploadsLeft : Int) -> String{
        let result = "window.updateUploadsLeft(\(uploadsLeft));"
        return result
    }
    
    public func getJavascriptUploadCompleteCommandFor(messageId : String) -> String{
        let result = "window.uploadCompleted(\(messageId);"
        return result
    }
    
}
