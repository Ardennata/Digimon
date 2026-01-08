//
//  ImageCacheManager.swift
//  NDSAssignment
//
//  Created by Ardennata Winarno on 06/01/26.
//

import Foundation
import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
