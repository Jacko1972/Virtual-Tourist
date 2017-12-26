//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Andrew Jackson on 26/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//
//

import Foundation
import CoreData


extension Pin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var photoInfos: NSSet?

}

// MARK: Generated accessors for photoInfos
extension Pin {

    @objc(addPhotoInfosObject:)
    @NSManaged public func addToPhotoInfos(_ value: PhotoInfo)

    @objc(removePhotoInfosObject:)
    @NSManaged public func removeFromPhotoInfos(_ value: PhotoInfo)

    @objc(addPhotoInfos:)
    @NSManaged public func addToPhotoInfos(_ values: NSSet)

    @objc(removePhotoInfos:)
    @NSManaged public func removeFromPhotoInfos(_ values: NSSet)

}
