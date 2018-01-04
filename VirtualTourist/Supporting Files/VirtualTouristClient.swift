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
                let photos = try JSONDecoder().decode(Photos.self, from: data)
                if photos.stat == Constants.FlickrResponseValues.OKStatus {
                    guard let pages = UInt32(photos.pages) else {
                        return
                    }
                    self.fetchPhotosInTheBackground(Int(arc4random_uniform(pages)) + 1)
                }
            } catch {
                return
            }
        }
        task.resume()
    }
    
    private func fetchPhotosInTheBackground(_ pages: Int) {
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
                let photos = try JSONDecoder().decode(Photos.self, from: data)
                if photos.stat == Constants.FlickrResponseValues.OKStatus {
                    for photo: Photo in photos.photo {
                        let photoInfo = PhotoInfo(photo: photo, pin: self.pin!, context: self.delegate.stack.context)
                        self.downloadImageData(photoInfo: photoInfo)
                    }
                }
                self.delegate.stack.save()
            } catch {
                return
            }
        }
        task.resume()
    }
    
    func downloadImageData(photoInfo: PhotoInfo) {
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
