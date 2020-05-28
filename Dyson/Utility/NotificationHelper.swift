import Foundation

public enum NetworkStatusColor : String{
    case YELLOW
    case ORANGE
    case RED
    case BLUE
}

@available(iOS 10.0, *)
public class NotificationHelper {
    
    private var notificationCenter : NotificationCenter!
    
    public static let sharedInstance = NotificationHelper()
    
    public let reachability = Reachability()!
  
    private init()
    {
        notificationCenter = NotificationCenter.default
        
        //Register On Terminate and Enter background events
        self.notificationCenter.addObserver(self, selector: #selector(onEnterBackgroundOrTerminate), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(onEnterBackgroundOrTerminate), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        //Register On Finish launching and did become active events
        self.notificationCenter.addObserver(self, selector: #selector(onApplicationDidFinishedLaunchingOrEnterForeground), name: NSNotification.Name.UIApplicationDidFinishLaunching, object: nil)
        self.notificationCenter.addObserver(self, selector: #selector(onApplicationDidFinishedLaunchingOrEnterForeground), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    public func startMonitoring()
    {
        self.notificationCenter.addObserver(self, selector: #selector(self.reachabilityChanged(notification:)), name: .reachabilityChanged, object: reachability)
        
        do{
            try reachability.startNotifier()
        } catch {
            Logger.sharedInstance.logError(error: "Could not start reachability notifier")
        }
    }
    
    public func stopMonitoring()
    {
        self.reachability.stopNotifier()
        self.notificationCenter.removeObserver(self, name: .reachabilityChanged, object: reachability)
    }
    
    public func subscribeToPendingUploadsEvent(observer: Any, selector: Selector)
    {
        notificationCenter.addObserver(observer, selector: selector, name: NSNotification.Name("UpdatePendingUploads"), object: nil)
    }
    
    public func postPendingUploadsEvent()
    {
        let userInfo = ["pendingUploads" : UploadManager.sharedInstance.pendingUploads]
        self.notificationCenter.post(name: Notification.Name("UpdatePendingUploads"), object: nil, userInfo: userInfo)
    }
    
    public func subscribeToChangeStatusEvent(observer: Any, selector: Selector)
    {
        notificationCenter.addObserver(observer, selector: selector, name: NSNotification.Name("ChangeStatus"), object: nil)
    }
    
    public func postChangeStatusEvent(status : Int)
    {
        let userInfo = ["status" : status]
        self.notificationCenter.post(name: Notification.Name("ChangeStatus"), object: nil, userInfo: userInfo)
    }
    
    public func subscribeToUploadCompletedEvent(observer: Any, selector: Selector)
    {
        notificationCenter.addObserver(observer, selector: selector, name: NSNotification.Name("UploadCompleted"), object: nil)
    }
    
    public func postUploadCompletedEvent(messageId : String)
    {
        let userInfo = ["messageId" : messageId]
        self.notificationCenter.post(name: Notification.Name("UploadCompleted"), object: nil, userInfo: userInfo)
    }
    
    
    public func getNetworkFlag() -> String
    {
        return "None"
    }
    
    
    @objc public func reachabilityChanged(notification: Notification)
    {
//        let reachability = notification.object as! Reachability
        var userInfo = ["ColorStatus" : NetworkStatusColor.BLUE.rawValue]
        
        if NetworkManager.sharedInstance.isConnectionAvailable
        {
            Logger.sharedInstance.logInfo(info: "Network is reachable.")
            
            //TODO: Check for API status
            userInfo = ["ColorStatus" : NetworkStatusColor.BLUE.rawValue]
        }
        else
        {
            Logger.sharedInstance.logWarning(message:"Network became unreachable")
            userInfo = ["ColorStatus" : NetworkStatusColor.YELLOW.rawValue]
        }
        self.notificationCenter.post(name: Notification.Name("ReachabilityChanged"), object: nil, userInfo: userInfo)
    }
    
    @objc func onEnterBackgroundOrTerminate (notification : NSNotification)
    {
        Logger.sharedInstance.logInfo(info: "Saving CD Context [Dyson]!")
        CoreDataManager.sharedInstance.saveContext()
//        NetworkStatusHelper.sharedInstance.unsubscribeReachability()
        NetworkManager.sharedInstance.stopNetworkReachabilityObserver()
    }
    
    @objc func onApplicationDidFinishedLaunchingOrEnterForeground()
    {
//        NetworkStatusHelper.sharedInstance.subscribeReachability()
        NetworkManager.sharedInstance.startNetworkReachabilityObserver()
    }
    
}
