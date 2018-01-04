//
//  PhotoInfo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Andrew Jackson on 04/01/2018.
//  Copyright © 2018 Jacko1972. All rights reserved.
//
//

import Foundation
import CoreData


extension PhotoInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PhotoInfo> {
        return NSFetchRequest<PhotoInfo>(entityName: "PhotoInfo")
    }

    @NSManaged public var url: String?
    @NSManaged public var imageData: NSData?
    @NSManaged public var pin: Pin?

}
