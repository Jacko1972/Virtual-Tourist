//
//  Constants.swift
//  VirtualTourist
//
//  Created by Andrew Jackson on 24/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import Foundation

class Constants {
    
    class Flickr {
        
        let api = "a355ab30f692957dbdfbfcfbbb889d1f"
        let secret = "44cee23754c62664"
        let address = "https://api.flickr.com/services/rest/?"
        let api_key = "api_key=a355ab30f692957dbdfbfcfbbb889d1f&"
        let method = "method=flickr.photos.geo.photosForLocation&"
        let format = "format=json&nojsoncallback=1&"
        
        func requestUrl() -> URL {
            let url : URL = URL(string: "\(address)\(api_key)\(method)\(format)")!
            return url
        }
    }

}
