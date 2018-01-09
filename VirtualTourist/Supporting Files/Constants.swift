//
//  Constants.swift
//  VirtualTourist
//
//  Created by Andrew Jackson on 24/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import Foundation

class Constants {
    
    struct AppStrings {
        static let EmptyCollectionView = "No Images Available!\nClick Back to select another Location!"
        static let BlankString = "Blank Message"
        static let DownloadComplete = "Download Complete"
        static let CurrentlyDownloading = "Download In Progress...\nPlease Wait For New Collection."
    }
    
    // MARK: Flickr Data
    struct Flickr {
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest"
        static let SearchBBoxHalfWidth = 0.5
        static let SearchBBoxHalfHeight = 0.5
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
    }
    
    // MARK: Flickr Parameter Keys
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let Page = "page"
        static let PerPage = "per_page"
    }
    
    // MARK: Flickr Parameter Values
    struct FlickrParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "a355ab30f692957dbdfbfcfbbb889d1f"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = 1        /* 1 means "yes" */
        static let ImageURL = "url_q"
        static let UseSafeSearch = 1
        static let PerPage = 21
    }
    
    // MARK: Flickr Response Values
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
}
