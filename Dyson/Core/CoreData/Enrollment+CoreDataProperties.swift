//
//  Enrollment+CoreDataProperties.swift
//  Dyson
//
//  Created by Singh on 2018-08-21.
//  Copyright © 2018 Syn. All rights reserved.
//
//

import Foundation
import CoreData


extension Enrollment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Enrollment> {
        return NSFetchRequest<Enrollment>(entityName: "Enrollment")
    }

    override public func awakeFromInsert() {
        setPrimitiveValue(NSDate(), forKey: "createdAt")
    }
    
    @NSManaged public var containerData: String?
    @NSManaged public var createdAt: NSDate?
    @NSManaged public var enrollmentData: String?
    @NSManaged public var enrollmentKey: String?
    @NSManaged public var enrollmentType: String?
    @NSManaged public var messageId: String?
    @NSManaged public var status: String?

}
