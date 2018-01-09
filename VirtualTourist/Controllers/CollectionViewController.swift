//
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by Andrew Jackson on 27/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class CollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var showCollection: UIButton!
    @IBOutlet var collectionView: UICollectionView!
    
    var pin: Pin!
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var insertIndexPath = [IndexPath]()
    var deleteIndexPath = [IndexPath]()
    var updateIndexPath = [IndexPath]()
    var messageToDisplay: String = Constants.AppStrings.EmptyCollectionView
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "PhotoInfo")
        fr.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
        if let pin = pin {
            let predicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
            fr.predicate = predicate
        }
        let frc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: delegate.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        return frc
    }()
    
    let reachability = Reachability()!
    
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
        showCollection.isHidden = !available
    }
    
    func subscribeToNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateUIFromSelector), name: Notification.Name(rawValue: Constants.AppStrings.DownloadComplete), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateAfterRotated(_:)), name: Notification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(networkStatusChanged(_:)), name: .reachabilityChanged, object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            print("could not start reachability notifier")
        }
    }
    
    func unsubscribeFromNotifications() {
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: Constants.AppStrings.DownloadComplete), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    @IBAction func showCollectionAction(_ sender: UIButton) {
        messageToDisplay = Constants.AppStrings.CurrentlyDownloading
        updateUIForNetworkAndShowCollectionActionButton(false)
        for photoInfo in (self.fetchedResultsController.fetchedObjects)! {
            self.delegate.stack.context.delete(photoInfo as! PhotoInfo)
        }
        self.delegate.stack.save()
        VirtualTouristClient.instance.pin = pin
        VirtualTouristClient.instance.fetchPhotoInfo() { ( pages, error ) in
            if error != nil {
                self.displayAlert(title: "Error", msg: (error?.localizedDescription)!)
                return
            }
            guard pages != 0 else {
                self.displayAlert(title: "No Pages", msg: "There are no pages to display!")
                return
            }
            VirtualTouristClient.instance.fetchPhotos(pages) { ( success, error) in
                if error != nil {
                    self.displayAlert(title: "Error", msg: (error?.localizedDescription)!)
                    return
                }
                if !success {
                    self.displayAlert(title: "Failed", msg: "Fetch Photos did not complete successfully!")
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchedResultsController.delegate = self
        performFetchForFRC()
        mapView.delegate = self
        plotPinOnMapView()
        setUpCollectionViewLayout(width: view.bounds.size.width)
        subscribeToNotifications()
        print("viewDidLoad")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToNotifications()
        showCollection.isHidden = reachability.connection != .none ? false : true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromNotifications()
    }
    
    func performFetchForFRC() {
        do {
            try fetchedResultsController.performFetch()
        } catch let err {
            displayAlert(title: "FRC Failed", msg: "Unable to create Fetch Results Controller: \(err)")
        }
    }
    
    @objc func updateAfterRotated(_ notification: Notification) {
        setUpCollectionViewLayout(width: view.bounds.size.width)
    }
    
    func setUpCollectionViewLayout(width: CGFloat) {
        let space: CGFloat = 1.0
        let numberAcross: CGFloat = UIDevice.current.orientation.isLandscape ? 6.0 : 3.0
        let dimension = floor((width - ((numberAcross - 1) * space)) / numberAcross)
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.collectionViewLayout = flowLayout
    }
    
    func plotPinOnMapView() {
        if pin == nil {
            displayAlert(title: "Pin Missing", msg: "Unable to find Pin from Map View!")
        } else {
            let location = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 3, longitudeDelta: 3)
            let region = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(region, animated: true)
            mapView.addAnnotation(annotation)
            mapView.isScrollEnabled = false
            mapView.isZoomEnabled = false
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let objects = fetchedResultsController.sections![section].numberOfObjects
        objects == 0 ? showEmptyView(true, message: messageToDisplay) : showEmptyView(false, message: Constants.AppStrings.BlankString)
        return objects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
        let photoInfo = fetchedResultsController.object(at: indexPath) as! PhotoInfo
        guard photoInfo.imageData != nil else {
            cell.imageView.image = nil
            cell.activityIndicator.startAnimating()
            cell.activityIndicator.isHidden = false
            return cell
        }
        cell.imageView.image = UIImage(data: photoInfo.imageData! as Data)
        cell.imageView.isHidden = false
        cell.activityIndicator.stopAnimating()
        cell.activityIndicator.isHidden = true
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let photoInfo = fetchedResultsController.object(at: indexPath) as! PhotoInfo
        delegate.stack.context.delete(photoInfo)
        delegate.stack.save()
        return true
    }
    
    func showEmptyView(_ show: Bool, message: String) {
        if show {
            let label: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: collectionView.frame.width, height: collectionView.frame.height))
            label.numberOfLines = 2
            label.textAlignment = .center
            label.text = message
            collectionView.backgroundView = label
        } else {
            collectionView.backgroundView = nil
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        var pin = mapView.dequeueReusableAnnotationView(withIdentifier: "VirtualTouristPin") as? MKPinAnnotationView
        if pin == nil {
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "VirtualTouristPin")
            pin!.canShowCallout = false
            pin!.pinTintColor = UIColor.red
        }
        return pin
    }
    
    @objc func updateUIFromSelector() {
        messageToDisplay = Constants.AppStrings.EmptyCollectionView
        updateUIForNetworkAndShowCollectionActionButton(true)
    }
    
    func updateUIForNetworkAndShowCollectionActionButton(_ show: Bool) {
        DispatchQueue.main.async {
            self.showCollection.isEnabled = show
            UIApplication.shared.isNetworkActivityIndicatorVisible = !show
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertIndexPath.removeAll()
        deleteIndexPath.removeAll()
        updateIndexPath.removeAll()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                insertIndexPath.append(newIndexPath)
            }
        case .delete:
            if let indexPath = indexPath {
                deleteIndexPath.append(indexPath)
            }
        case .update:
            if let indexPath = indexPath {
                updateIndexPath.append(indexPath)
            }
        case .move:
            break // No Moves allowed
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({
            self.collectionView.insertItems(at: insertIndexPath)
            self.collectionView.deleteItems(at: deleteIndexPath)
            self.collectionView.reloadItems(at: updateIndexPath)
        }, completion: nil)
    }
}
