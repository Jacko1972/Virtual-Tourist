//
//  Extensions.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 28/11/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
////

import UIKit

extension UIViewController {
    func displayAlert(title : String?, msg : String, style: UIAlertControllerStyle = .alert) {
        let alert = UIAlertController.init(title: title, message: msg, preferredStyle: style)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension UserDefaults {
    
    enum Keys {
        
        static let HasRun = "hasRun"
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let LatitudeDelta = "latitudeDelta"
        static let LongitudeDelta = "longitudeDelta"
        
    }
    
}
