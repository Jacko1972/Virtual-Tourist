//
//  VirtualTouristClient.swift
//  VirtualTourist
//
//  Created by Andrew Jackson on 29/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class VirtualTouristClient {
    
    static let instance = VirtualTouristClient()
    
    var pin: Pin? = nil
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    func getLocalSearchLocationFromCoordinates(_ location: CLLocationCoordinate2D, handler: @escaping (_ placeMark: CLPlacemark?, _ error: Error?) -> Void) {
        func sendError(_ error: String) {
            let userInfo = [NSLocalizedDescriptionKey : error]
            handler(nil, NSError(domain: "Place Name from Coords Request", code: 1, userInfo: userInfo))
        }
        let location = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let geoCoder = CLGeocoder()
        
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
            if error != nil {
                sendError("Error from Geocode Location LookUp: \(error?.localizedDescription ?? "No Description")")
                return
            }
            let count = placemarks?.count ?? 0
            if count > 0 {
                handler(placemarks?[0], error)
            } else {
                sendError("No Place Names returned from Search!")
                return
            }
        })
    }
    
    func fetchPhotoInfoInTheBackground() {
        
        let params = getDefaultParameters()
        let url = flickrURLFromParameters(params)
        let request = URLRequest(url: url)
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { data, response, error2 in
            if error2 != nil {
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                return
            }
            guard let myData = data else {
                return
            }
            do {
                let pagedPhotos = try JSONDecoder().decode(PagedPhotos.self, from: myData)
                if pagedPhotos.stat == Constants.FlickrResponseValues.OKStatus {
                    if pagedPhotos.photos.pages == 0 {
                        return
                    }
                    self.fetchPhotosInTheBackground(Int(arc4random_uniform(UInt32(pagedPhotos.photos.pages))) + 1)
                }
            } catch {
                return
            }
        }
        task.resume()
    }
    
    private func fetchPhotosInTheBackground(_ pages: Int) {
        print("fetchPhotos In the background: \(pages)")
        var params = getDefaultParameters()
        params[Constants.FlickrParameterKeys.Page] = pages as Any
        let url = flickrURLFromParameters(params)
        let request = URLRequest(url: url)
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { data, response, error in
            if error != nil {
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                return
            }
            guard let data = data else {
                return
            }
            do {
                let pagedPhotos = try JSONDecoder().decode(PagedPhotos.self, from: data)
                if pagedPhotos.stat == Constants.FlickrResponseValues.OKStatus {
                    var photoInfos = [PhotoInfo]()
                    for photo: Photo in pagedPhotos.photos.photo {
                        let photoInfo = PhotoInfo(photo: photo, pin: self.pin!, context: self.delegate.stack.context)
                        photoInfos.append(photoInfo)
                    }
                    self.downloadImageData(photoInfos: photoInfos)
                }
                self.delegate.stack.save()
            } catch let error2 {
                print("error 4 \(error2)")
                return
            }
        }
        task.resume()
    }
    
    func downloadImageData(photoInfos: [PhotoInfo]) {
        print("downloadImageData In the background")
        for photoInfo in photoInfos {
            let url = URL(string: photoInfo.url!)
            let request = URLRequest(url: url!)
            let session = URLSession.shared
            
            let task = session.dataTask(with: request) { data, response, error in
                if error != nil {
                    return
                }
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                    return
                }
                guard let data = data else {
                    return
                }
                photoInfo.imageData = data as NSData
                self.delegate.stack.save()
                if photoInfo == photoInfos.last {
                    NotificationCenter.default.post(name: Notification.Name(Constants.AppStrings.DownloadComplete), object: nil)
                }
            }
            task.resume()
        }
    }
    
    func downloadImageData(photoInfo: PhotoInfo, handler: @escaping (_ downloaded: Bool, _ error: Error?) -> Void) {
        let url = URL(string: photoInfo.url!)
        let request = URLRequest(url: url!)
        let session = URLSession.shared
        
        if photoInfo.imageData != nil {
            print("not null")
            handler(true, nil)
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                handler(false, NSError(domain: "Image Data Download", code: 1, userInfo: userInfo))
            }
            if error != nil {
                sendError("Download Task returned with: \(String(describing: error?.localizedDescription))")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Download Status Code: \(String(describing: error?.localizedDescription))")
                return
            }
            guard let data = data else {
                sendError("Download returned no Data!")
                return
            }
            photoInfo.imageData = data as NSData
            self.delegate.stack.save()
            handler(true, nil)
        }
        task.resume()
    }
    
    func fetchPhotoInfo(handler: @escaping (_ pages: Int, _ error: Error?) -> Void) {
        let params = getDefaultParameters()
        let url = flickrURLFromParameters(params)
        let request = URLRequest(url: url)
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { data, response, error in
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                handler(0, NSError(domain: "Image Info Download", code: 1, userInfo: userInfo))
            }
            if error != nil {
                sendError("Could not fetch Photo Info: \(String(describing: error?.localizedDescription))")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Download Status Code: \(String(describing: error?.localizedDescription))")
                return
            }
            guard let myData = data else {
                sendError("Download returned no Data!")
                return
            }
            do {
                let pagedPhotos = try JSONDecoder().decode(PagedPhotos.self, from: myData)
                if pagedPhotos.stat == Constants.FlickrResponseValues.OKStatus {
                    if pagedPhotos.photos.pages == 0 {
                        sendError("No Photos for the chosen location!")
                        return
                    }
                    let pageLimit = min(pagedPhotos.photos.pages, 175) // For some reason any page number above 190 (approx) returns the default first page!!!!
                    let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                    handler(randomPage, nil)
                }
            } catch {
                return
            }
        }
        task.resume()
    }
    
    func fetchPhotos(_ pages: Int, handler: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        print("fetchPhotos: \(pages)")
        var params = getDefaultParameters()
        params[Constants.FlickrParameterKeys.Page] = pages as Any
        let url = flickrURLFromParameters(params)
        print("\(url)")
        let request = URLRequest(url: url)
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { data, response, error in
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                handler(false, NSError(domain: "Photo Download", code: 1, userInfo: userInfo))
            }
            if error != nil {
                sendError("Could not fetch Photos: \(String(describing: error?.localizedDescription))")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Photo Download Status Code: \(String(describing: error?.localizedDescription))")
                return
            }
            guard let data = data else {
                sendError("Photo Download returned no Data!")
                return
            }
            do {
                let pagedPhotos = try JSONDecoder().decode(PagedPhotos.self, from: data)
                if pagedPhotos.stat == Constants.FlickrResponseValues.OKStatus {
                    var photoInfos = [PhotoInfo]()
                    for photo: Photo in pagedPhotos.photos.photo {
                        let photoInfo = PhotoInfo(photo: photo, pin: self.pin!, context: self.delegate.stack.context)
                        photoInfos.append(photoInfo)
                    }
                    self.downloadImageData(photoInfos: photoInfos)
                    handler(true, nil)
                } else {
                    sendError("Flickr Response was not OK: \(pagedPhotos.stat)")
                    return
                }
            } catch {
                return
            }
        }
        task.resume()
    }
    
    private func getDefaultParameters() -> [String: Any]{
        let parameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.ImageURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PerPage,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            ] as [String : Any]
        return parameters
    }
    
    // Helper for creating a URL from parameters
    private func flickrURLFromParameters(_ parameters: [String: Any]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.ApiScheme
        components.host = Constants.Flickr.ApiHost
        components.path = Constants.Flickr.ApiPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    // Helper for creating Flickr bbox parameter
    private func bboxString() -> String {
        // ensure bbox is bounded by minimum and maximums
        guard let pin = pin else {
            return "0,0,0,0"
        }
        let minimumLon = max(pin.longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(pin.latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(pin.longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(pin.latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
}
