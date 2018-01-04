//
//  PhotoInfo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Andrew Jackson on 26/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//
//

import Foundation
import CoreData


public class PhotoInfo: NSManagedObject {
    
    convenience init(photo: Photo, pin: Pin, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "PhotoInfo", in: context) {
            self.init(entity: entity, insertInto: context)
            self.url = photo.url_q
            self.pin = pin
        } else {
            fatalError("Unable to find Entity Name")
        }
    }

}
