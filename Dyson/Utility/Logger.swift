import Foundation
import SwiftyBeaver

public class Logger {
    
    public static let sharedInstance = Logger()
    private let log = SwiftyBeaver.self
    
    private init() {
        
        let console = ConsoleDestination()
        
        console.useTerminalColors   = false
        console.format              = "$DHH:mm:ss.SSS$d $C$L$c - $M"
        console.levelColor.verbose  = "🤪"
        console.levelColor.debug    = "😜" //"👻"
        console.levelColor.info     = "🤔"
        console.levelColor.warning  = "😱"
        console.levelColor.error    = "👺"
        
        log.addDestination(console)
    }
    
    public var isLoggingEnabled : Bool!
    
    public func logInfo(info: String){
        log.info(info + " 🚀🚀🚀")
//        if isLoggingEnabled{
//
//        }
    }
    
    public func logError(error: String){
        log.error(error)
    }
    
    public func logDebug(debug: String){
        log.debug(debug + " 🚀🚀")
    }
    
    public func log(message:String) {
        log.verbose(message)
    }
    
    public func logWarning(message:String) {
        log.warning(message)
    }
    
}
