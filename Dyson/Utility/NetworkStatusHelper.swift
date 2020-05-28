//import Foundation
//class NetworkStatusHelper {
//    
//    var reachability : Reachability!
//    public var isConnectionAvailable = false;
//    
//    private init (){
//        self.subscribeReachability()
//    }
//    
//    public static let sharedInstance = NetworkStatusHelper()
//    
//    public func subscribeReachability()
//    {
//        reachability = Reachability()
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
//        do{
//            try reachability.startNotifier()
//        }catch{
//            Logger.sharedInstance.logError(error: "could not start reachability notifier")
//        }
//    }
//    
//    public func unsubscribeReachability()
//    {
//        self.reachability.stopNotifier()
//        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
//    }
//    
//    @objc func reachabilityChanged(note: Notification) {
//        
//        let reachability = note.object as! Reachability
//        
//        switch reachability.connection {
//        case .wifi:
//            self.isConnectionAvailable = true
//        case .cellular:
//            self.isConnectionAvailable = true
//        case .none:
//            self.isConnectionAvailable = false
//        }
//    }
//    
//    deinit {
//        self.unsubscribeReachability()
//    }
//    
//}
