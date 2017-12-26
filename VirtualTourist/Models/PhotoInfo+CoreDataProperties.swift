//
//  PhotoInfo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Andrew Jackson on 26/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//
//

import Foundation
import CoreData


extension PhotoInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PhotoInfo> {
        return NSFetchRequest<PhotoInfo>(entityName: "PhotoInfo")
    }

    @NSManaged public var id: String?
    @NSManaged public var owner: String?
    @NSManaged public var secret: String?
    @NSManaged public var server: String?
    @NSManaged public var farm: Int16
    @NSManaged public var title: String?
    @NSManaged public var pin: Pin?

}
