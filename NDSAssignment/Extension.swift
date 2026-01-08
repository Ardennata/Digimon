//
//  Extension.swift
//  NDSAssignment
//
//  Created by Ardennata Winarno on 06/01/26.
//

import Foundation
import UIKit

extension UIImageView {
    func loadImage(from url: URL?, placeholder: UIImage? = UIImage(systemName: "photo")) {
        self.image = placeholder
        
        guard let url = url else { return }
        
        let urlString = url.absoluteString
        
        if let cachedImage = ImageCacheManager.shared.image(forKey: urlString) {
            self.image = cachedImage
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data) else { return }
            
            ImageCacheManager.shared.setImage(image, forKey: urlString)
            
            DispatchQueue.main.async {
                self.image = image
            }
        }.resume()
    }
}
