//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Andrew Jackson on 26/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate {
    @IBOutlet var deleteButton: UIBarButtonItem!
    @IBOutlet var displayBannerLabel: UILabel!
    @IBOutlet var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    let delegate = UIApplication.shared.delegate as! AppDelegate
    let reachability = Reachability()!
    let defaults = UserDefaults.standard
    var seguePin: Pin!
    
    @objc func networkStatusChanged(_ notification: Notification) {
        let reachability = notification.object as! Reachability
        switch reachability.connection {
        case .none:
            allowInternetActions(false)
        default:
            allowInternetActions(true)
        }
    }
    
    func allowInternetActions(_ available: Bool) -> Void {
        if available {
            displayBannerLabel.isHidden = true
        } else {
            displayBannerLabel.isHidden = false
            displayBannerLabel.text = "No Internet! No New Pins Allowed!"
            displayBannerLabel.backgroundColor = UIColor.red
            displayBannerLabel.textColor = UIColor.white
        }
    }
    
    @objc func updateUIFromSelector() {
        DispatchQueue.main.async {
            self.showDownloadBanner(false)
        }
    }
    
    func subscribeToNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateUIFromSelector), name: Notification.Name(rawValue: Constants.AppStrings.DownloadComplete), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(networkStatusChanged(_:)), name: .reachabilityChanged, object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            print("could not start reachability notifier")
        }
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: Constants.AppStrings.DownloadComplete), object: nil)
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
    }
    
    @IBAction func deletePinAction(_ sender: UIBarButtonItem) {
        let ann = mapView.selectedAnnotations[0]
        guard let title = ann.title, let pinDate = ann.subtitle else {
            displayAlert(title: "Missing Information", msg: "Unable to find Pin in Data Source!")
            return
        }
        let pin = pinFromAnnotation(name: title!, pinDate: pinDate!, latitude: ann.coordinate.latitude, longitude: ann.coordinate.longitude)
        if pin != nil {
            delegate.stack.context.delete(pin!)
            delegate.stack.save()
        }
        mapView.removeAnnotation(ann)
        displayAlert(title: "Pin Removed", msg: "Pin along with its associated images have been removed!")
        deleteButton.isEnabled = false
    }
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
            loadAnnotations()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            loadAnnotations()
        }
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
        mapView.removeAnnotations(mapView.annotations)
        checkLocationAuthorizationStatus()
        setMapFromUserDefaults()
        subscribeToNotifications()
        displayBannerLabel.isHidden = true
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        var pin = mapView.dequeueReusableAnnotationView(withIdentifier: "VirtualTouristPin") as? MKPinAnnotationView
        if pin == nil {
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "VirtualTouristPin")
            pin!.canShowCallout = true
            pin!.pinTintColor = UIColor.red
            pin!.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure)
        }
        return pin
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        deleteButton.isEnabled = true
    }
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        deleteButton.isEnabled = false
    }
    
    func showDownloadBanner(_ show: Bool) {
        displayBannerLabel.text = "Downloading..."
        displayBannerLabel.textColor = UIColor.white
        displayBannerLabel.backgroundColor = UIColor.green
        displayBannerLabel.isHidden = !show
    }
    
    @objc func addAnnotationAction(gestureRecognizer:UIGestureRecognizer) {
        if reachability.connection == .none {
            return
        }
        if gestureRecognizer.state == .began {
            showDownloadBanner(true)
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoords = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            VirtualTouristClient.instance.getLocalSearchLocationFromCoordinates(newCoords) { (response, error) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if error != nil {
                    self.showDownloadBanner(false)
                    self.displayAlert(title: "Could Not Find Name", msg: "Geocoder could not find a name for dropped pin location.")
                    return
                }
                guard let resp = response else {
                    self.showDownloadBanner(false)
                    self.displayAlert(title: "Missing Locations", msg: "We were unable to find a location name.")
                    return
                }
                var name = "Collection"
                if resp.name != nil {
                    name = resp.name!
                }
                let annotation = MKPointAnnotation()
                annotation.coordinate = newCoords
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                formatter.dateStyle = .medium
                formatter.locale = Locale.current
                let pinDate = formatter.string(from: Date())
                annotation.title = name
                annotation.subtitle = pinDate
                self.mapView.addAnnotation(annotation)
                let pin = Pin(latitude: newCoords.latitude, longitude: newCoords.longitude, name: name, pinDate: pinDate, context: self.delegate.stack.context)
                self.delegate.stack.save()
                VirtualTouristClient.instance.pin = pin
                VirtualTouristClient.instance.fetchPhotoInfoInTheBackground()
            }
        }
    }
    
    func setMapFromUserDefaults() {
        let hasRun = defaults.bool(forKey: UserDefaults.Keys.HasRun)
        let latitude = hasRun ? defaults.double(forKey: UserDefaults.Keys.Latitude) : 54.5
        let longitude = hasRun ? defaults.double(forKey: UserDefaults.Keys.Longitude) : -3.5
        let latitudeDelta = hasRun ? defaults.double(forKey: UserDefaults.Keys.LatitudeDelta) : 10
        let longitudeDelta = hasRun ? defaults.double(forKey: UserDefaults.Keys.LongitudeDelta) : 10
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        defaults.set(true, forKey: UserDefaults.Keys.HasRun)
        defaults.set(mapView.centerCoordinate.latitude, forKey: UserDefaults.Keys.Latitude)
        defaults.set(mapView.centerCoordinate.longitude, forKey: UserDefaults.Keys.Longitude)
        defaults.set(mapView.region.span.latitudeDelta, forKey: UserDefaults.Keys.LatitudeDelta)
        defaults.set(mapView.region.span.longitudeDelta, forKey: UserDefaults.Keys.LongitudeDelta)
    }
    
    func loadAnnotations() {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            if let mapPins = try? delegate.stack.context.fetch(fr) as! [Pin] {
                for pin in mapPins {
                    let location = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = location
                    annotation.title = pin.name
                    annotation.subtitle = pin.pinDate
                    mapView.addAnnotation(annotation)
                }
            } else {
                displayAlert(title: "No Pins Stored!", msg: "No Pins to display, long click on Map to create a Pin.")
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let pin = view.annotation as? MKPointAnnotation else {
            return
        }
        seguePin = pinFromAnnotation(name: pin.title!, pinDate: pin.subtitle!, latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
        performSegue(withIdentifier: "ShowCollectionView", sender: seguePin)
    }
    
    func pinFromAnnotation(name: String, pinDate: String, latitude: Double, longitude: Double) -> Pin?{
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        let latPredicate = NSPredicate(format: "latitude == %lf", latitude)
        let longPredicate = NSPredicate(format: "longitude == %lf", longitude)
        let titlePredicate = NSPredicate(format: "name == %@", name)
        let pinDatePredicate = NSPredicate(format: "pinDate == %@", pinDate)
        
        fr.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [latPredicate, longPredicate, titlePredicate, pinDatePredicate])
        fr.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            if let mapPins = try? delegate.stack.context.fetch(fr) as! [Pin] {
                return mapPins[0]
            }
        }
        return nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowCollectionView", seguePin != nil {
            if let controller = segue.destination as? CollectionViewController {
                controller.pin = seguePin
                controller.title = seguePin.name
            }
        }
    }
    
    
}
