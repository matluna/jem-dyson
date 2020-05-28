//
//  CoreDataManager.swift
//  Dyson
//
//  Created by Singh on 2018-08-19.
//  Copyright © 2018 Syn. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataManager {
    
    //MARK: Init methods
    
    private init() {}
    public static let sharedInstance = CoreDataManager()
    
    // MARK: - Core Data stack
    
    @available(iOS 10.0, *)
    public lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let objectModelName = (UIApplication.shared.delegate?.getDataStoreCoordinator().objectModelName)!
        let container = NSPersistentContainer(name: objectModelName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                Logger.sharedInstance.logError(error: "Unresolved error \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    @available(iOS 10.0, *)
    public func saveContext () {
        
        if let mainManagedContext = UIApplication.shared.delegate?.getDataStoreCoordinator().mainManagedObjectContextInstance
        {
            mainManagedContext.perform {
                if mainManagedContext.hasChanges {
                    do {
                        try mainManagedContext.save()
                    } catch {
                        // Replace this implementation with code to handle the error appropriately.
                        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                        let nserror = error as NSError
                        Logger.sharedInstance.logError(error: "Unresolved error \(nserror), \(nserror.userInfo)")
                        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                    }
                }
            }
        }
        
        
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                Logger.sharedInstance.logError(error: "Unresolved error \(nserror), \(nserror.userInfo)")
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}
