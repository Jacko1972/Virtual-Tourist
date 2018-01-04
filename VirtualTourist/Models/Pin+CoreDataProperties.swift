//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Andrew Jackson on 04/01/2018.
//  Copyright © 2018 Jacko1972. All rights reserved.
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
    @NSManaged public var name: String?
    @NSManaged public var pinDate: String?
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
