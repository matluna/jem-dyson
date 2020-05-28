import Foundation
import Alamofire
public class NetworkManager {
    
    //shared instance
    public static let sharedInstance = NetworkManager()
    let reachabilityManager : NetworkReachabilityManager!
    public var isConnectionAvailable : Bool!
    
    private init()
    {
        reachabilityManager = NetworkReachabilityManager(host: "www.google.com")
        isConnectionAvailable = reachabilityManager.isReachable
//        self.startNetworkReachabilityObserver()
    }
    
    public func startNetworkReachabilityObserver()
    {
        Logger.sharedInstance.logInfo(info: "Subscribing to reachablitiy status!")
        
        reachabilityManager?.listener =
        {
            status in
            
            Logger.sharedInstance.logInfo(info: "Listning to reachablitiy status!")
            
            switch status
            {
                
                case .notReachable:
                    self.isConnectionAvailable = false
                
                case .unknown :
                    self.isConnectionAvailable = false
                
                case .reachable(.ethernetOrWiFi):
                    self.isConnectionAvailable = true
                
                case .reachable(.wwan):
                    self.isConnectionAvailable = true
                
            }
        }
        
        // start listening
        reachabilityManager?.startListening()
    }
    
    public func stopNetworkReachabilityObserver()
    {
        // stop listening
        Logger.sharedInstance.logInfo(info: "Unsubscribing to reachablitiy status!")
        reachabilityManager?.stopListening()
    }
}
