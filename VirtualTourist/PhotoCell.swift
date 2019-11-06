//
//  PhotoCell.swift
//  VirtualTourist
//
//  Created by Noha on 31.10.19.
//  Copyright © 2019 udacity. All rights reserved.
//

import Foundation
import UIKit

class PhotoCell : UICollectionViewCell{

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var photoSpinner: UIActivityIndicatorView!
    var task: URLSessionDataTask?
    

    func loadImage(for photo: Photo) {
        if let data = photo.image {
            imageView.image = UIImage(data: data)
        } else {
            photoSpinner.startAnimating()
            task = URLSession.shared.dataTask(with: URL(string: photo.url!)!) { data, _, _ in
                guard let data = data else {
                    return
                }
                DispatchQueue.main.async {
                    self.photoSpinner.stopAnimating()
                    
                    self.imageView.image = UIImage(data: data)


                    photo.image = data
                    try? photo.managedObjectContext?.save()
                }
            }
            task?.resume()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        task?.cancel()
    }
}
