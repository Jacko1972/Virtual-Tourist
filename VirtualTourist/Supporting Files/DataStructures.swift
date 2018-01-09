//
//  DataStructures.swift
//  VirtualTourist
//
//  Created by Andrew Jackson on 26/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.

struct PagedPhotos: Codable {
    let photos: Photos
    let stat: String
}

struct Photos: Codable {
    
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [Photo]
}

struct Photo: Codable {
    
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
    let url_q: String
}
