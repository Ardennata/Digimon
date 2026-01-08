//
//  DigimonCollectionViewCell.swift
//  NDSAssignment
//
//  Created by Ardennata Winarno on 06/01/26.
//

import UIKit

class DigimonCell: UICollectionViewCell {
        
        @IBOutlet weak var imageView: UIImageView!
        @IBOutlet weak var nameLabel: UILabel!
        
        override func awakeFromNib() {
            super.awakeFromNib()
            setupUI()
        }
        
        private func setupUI() {
            imageView.layer.cornerRadius = 12
            imageView.clipsToBounds = true
        }
        
        func configure(with digimon: Digimon) {
            nameLabel.text = digimon.name
            imageView.loadImage(from: digimon.imageURL)
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            imageView.image = UIImage(systemName: "photo")
            nameLabel.text = nil
        }

}
