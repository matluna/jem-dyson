//
//  UIApplicationDelegate+CoreData.swift
//  Dyson
//
//  Created by Singh on 2018-08-21.
//  Copyright © 2018 Syn. All rights reserved.
//

import Foundation
@available(iOS 10.0, *)
public extension UIApplicationDelegate
{
//    lazy var datastoreCoordinator: DatastoreCoordinator = {
//        return DatastoreCoordinator()
//    }()
    
    public func getDataStoreCoordinator() -> DatastoreCoordinator
    {
        return DatastoreCoordinator.sharedInstance;
    }
    
    public func getBundle() -> Bundle
    {
        let bundle = Bundle(for: type(of: self))
        return bundle
    }
}
