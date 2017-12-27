//
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by Andrew Jackson on 27/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit
import MapKit

class CollectionViewController: CoreDataCollectionViewController, MKMapViewDelegate {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var showCollection: UIButton!
    
    @IBAction func showCollectionAction(_ sender: UIButton) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        mapView.delegate = self

        // Do any additional setup after loading the view.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
