//
//  DataStoreCoordinator.swift
//  SampleCoreData
//
//  Created by Administrator on 2018-08-20.
//  Copyright © 2018 synivision. All rights reserved.
//

import Foundation
import CoreData



@available(iOS 10.0, *)
public class DatastoreCoordinator: NSObject {
    
    public let objectModelName = "Enrollment"
    fileprivate let objectModelExtension = "momd"
    fileprivate let dbFilename = "Enrollment.sqlite"
    fileprivate let appDomain : String = (UIApplication.shared.delegate?.getBundle().bundleIdentifier)!
    
    public static let sharedInstance = DatastoreCoordinator()
    
    private override init()
    {
        /*let environment = EnrollmentHelper.sharedInstance.environment
        switch (environment)
        {
        case Environment.TESTSYS.rawValue:
            appDomain = "com.justenergy.enterprise.testsys"
            break
        case Environment.TESTPROD.rawValue:
            appDomain = "com.justenergy.enterprise.testprod"
            break
        case Environment.PROD.rawValue:
            appDomain = "com.justenergy.enterprise.prod"
            break
        case Environment.DEVPROD.rawValue:
            appDomain = "com.justenergy.enterprise.devsys"
            break
        case Environment.DEVSYS.rawValue:
            appDomain = "com.justenergy.enterprise.devprod"
            break
        case Environment.DEVDEV.rawValue:
            appDomain = "com.justenergy.enterprise.devdev"
            break
        default :
            appDomain = "com.justenergy.enterprise.prod"
        }*/
        
        Logger.sharedInstance.logDebug(debug: objectModelName)
        Logger.sharedInstance.logDebug(debug: appDomain)
        
        super.init()
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file.
        // This code uses a directory named "com.srmds.<dbName>" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        return urls[urls.count-1]
    }()
    
    
    // Create master context reference, with PrivateQueueConcurrency Type.
    lazy var masterManagedObjectContextInstance: NSManagedObjectContext = {
        var masterManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        masterManagedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        return masterManagedObjectContext
    }()
    
    //Create main context reference, with MainQueueuConcurrency Type.
    lazy var mainManagedObjectContextInstance: NSManagedObjectContext = {
        var mainManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainManagedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        Logger.sharedInstance.logDebug(debug: "mainManagedObjectContextInstance : \(mainManagedObjectContext)")
        Logger.sharedInstance.logDebug(debug: "mainManagedObjectContextInstance : \((mainManagedObjectContext.persistentStoreCoordinator)!)")
        return mainManagedObjectContext
    }()
    
    func saveContext() {
        defer {
            do {
                try masterManagedObjectContextInstance.save()
            } catch let masterMocSaveError as NSError {
                print("Master Managed Object Context save error: \(masterMocSaveError.localizedDescription)")
            } catch {
                print("Master Managed Object Context save error.")
            }
        }
        
        if mainManagedObjectContextInstance.hasChanges {
            mergeChangesFromMainContext()
        }
    }
    
    /**
     Merge Changes on the Main Context to the Master Context.
     
     - Returns: Void
     */
    fileprivate func mergeChangesFromMainContext() {
        DispatchQueue.main.async(execute: {
            do {
                try self.mainManagedObjectContextInstance.save()
            } catch let mocSaveError as NSError {
                print("Master Managed Object Context error: \(mocSaveError.localizedDescription)")
            }
        })
    }
    
    //
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional.
        // It is a fatal error for the application not to be able to find and load its model.
        let bundle = Bundle(identifier: self.appDomain) //UIApplication.shared.delegate?.getBundle()
//        Logger.sharedInstance.logDebug(debug: "\(bundle)")
        let modelPath = bundle?.path(forResource: self.objectModelName, ofType: self.objectModelExtension)
        let modelURL = URL(string: modelPath!)
//        let modelURL = bundle?.url(forResource: self.objectModelName, withExtension: self.objectModelName)
//        Logger.sharedInstance.logDebug(debug: "managedObjectModel : \((modelURL))")
        return NSManagedObjectModel(contentsOf: modelURL!)!
    }()
    
    //
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        // The persistent store coordinator for the application. This implementation creates and return a coordinator,
        // having added the store for the application to it. This property is optional since there are legitimate error
        // conditions that could cause the creation of the store to fail.
        
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent(self.dbFilename)
        Logger.sharedInstance.logDebug(debug: "persistentStoreCoordinator : \(url.absoluteString)")
        var failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: self.appDomain, code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            
            abort()
        }
        
        return coordinator
    }()
    
    
}

