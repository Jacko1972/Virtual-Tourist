//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Andrew Jackson on 26/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    let locationManager = CLLocationManager()
    
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            
        }
    }
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult> {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        let _fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        do {
            _fetchedResultsController.performFetch()
        } catch {
            displayAlert(title: "Pin Fetch Failed", msg: "Unable to search for Pins in data source")
        }
        return _fetchedResultsController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationAction(gestureRecognizer:)))
        longPress.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(longPress)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkLocationAuthorizationStatus()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        var onTheMapPin = mapView.dequeueReusableAnnotationView(withIdentifier: "VirtualTouristPin") as? MKPinAnnotationView
        if onTheMapPin == nil {
            onTheMapPin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "VirtualTouristPin")
            onTheMapPin!.canShowCallout = false
            onTheMapPin!.pinTintColor = UIColor.red
        }
        return onTheMapPin
    }

    @objc func addAnnotationAction(gestureRecognizer:UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        mapView.addAnnotation(annotation)
    }
    
    func loadAnnotations() {
        if fetchedResultsController.fetchedObjects?.count > 0 {
            for record in fetchedResultsController.fetchedObjects {
                let location = CLLocationCoordinate2D(latitude: record.latitude!, longitude: record.longitude!)
                let annotation = MKPointAnnotation()
                annotation.coordinate = location
                annotation.title = record.getFullName()
                annotation.subtitle = record.mediaURL
                pointAnnotations.append(annotation)
            }
        } else {
            displayAlert(title: "No Data!", msg: "No locations have been retrieved from the app to display!")
        }
        if pointAnnotations.count > 0 {
            mapView.addAnnotations(pointAnnotations)
        }
        if mapView.userLocation.location == nil {
            setRegion(center: CLLocationCoordinate2D(latitude: pointAnnotations[0].coordinate.latitude, longitude: pointAnnotations[0].coordinate.longitude))
        } else {
            setRegion(center: CLLocationCoordinate2D(latitude: mapView.userLocation.coordinate.latitude, longitude: mapView.userLocation.coordinate.longitude))
        }
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
