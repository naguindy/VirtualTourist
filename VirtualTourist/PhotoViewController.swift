//
//  PhotoViewController.swift
//  VirtualTourist
//
//  Created by Noha on 13.11.19.
//  Copyright © 2019 udacity. All rights reserved.
//

import UIKit
import CoreData
enum FilterType : String, CaseIterable {

    case Chrome = "CIPhotoEffectChrome"
    case Fade = "CIPhotoEffectFade"
    case Instant = "CIPhotoEffectInstant"
    case Mono = "CIPhotoEffectMono"
    case Noir = "CIPhotoEffectNoir"
    case Process = "CIPhotoEffectProcess"
    case Tonal = "CIPhotoEffectTonal"
    case Transfer =  "CIPhotoEffectTransfer"
}

class PhotoViewController: UIViewController, UITextViewDelegate {
    var selectedPhoto : UIImage!
    let tintView = UIView()
    var currentFilter: FilterType = .Mono
    var pin: Pin!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var verticalSlider: UISlider!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var viewImage: UIImageView!
    @IBOutlet var colors: [UIButton]!
    @IBOutlet weak var textButton: UIButton!
    let textColorDic = [0: UIColor.red, 1:.green, 2: .blue, 3: .orange, 4: .purple, 5: .yellow, 6: .systemPink]
    override var prefersStatusBarHidden: Bool{
        get{
            return true
        }
    }
   /* override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
    }*/

    override func viewDidLoad() {
        super.viewDidLoad()
        viewImage.image = selectedPhoto
        viewImage.contentMode = .scaleAspectFit
        navigationController?.isNavigationBarHidden = true
        textView.delegate = self
        shareButton.layer.cornerRadius = 15
        verticalSlider.isHidden = true
        for color in colors{
            color.isHidden = true
        }
    }
   /* override func viewWillDisappear(_ animated: Bool) {
        unsubscribeFromKeyboardNotifications()
    }*/
    @IBAction func colorText(_ sender: UIButton) {
        textView.textColor = textColorDic[sender.tag]
    }
    @IBAction func backButton(_ sender: UIButton) {

        _ = navigationController?.popViewController(animated: true)
        navigationController?.isNavigationBarHidden = false
    }
   
    @IBAction func fontSliderAction(_ sender: UISlider) {
        textView.font = .systemFont(ofSize: CGFloat(sender.value))
    }

    @IBAction func shareImage(_ sender: UIButton) {
        let image = editedPhotogenerator()
        let items : [Any] = [URL(string:"maps.google.com/?q=\(self.pin.latitude),\(self.pin.longitude)") as Any, image as Any]
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(controller, animated: true, completion: nil)

    }
    @IBAction func handlePan(recognizer : UIPanGestureRecognizer){
        let translation = recognizer.translation(in: self.view)
        if let view = recognizer.view{
            view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
        }
        recognizer.setTranslation(CGPoint.zero, in: self.view)
    }
    @IBAction func handlePinch(recognizer: UIPinchGestureRecognizer){
        if let view = recognizer.view{
            view.transform = view.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
            recognizer.scale = 1
        }

    }
    
    @IBAction func textingButton(_ sender: UIButton) {
        if textButton.title(for: .normal) == nil{
            filterButton.isHidden = true
            textButton.setTitle("Done", for: .normal)
            textButton.setImage(nil, for: .normal)
            textButton.isSelected = true
            self.textView.becomeFirstResponder()
            verticalSlider.isHidden = false
            tintView.backgroundColor = UIColor(white: 0, alpha: 0.5) //change to your liking
            tintView.frame = CGRect(x: 0, y: 0, width: viewImage.frame.width, height: viewImage.frame.height)
            viewImage.addSubview(tintView)

            for color in colors{
                color.isHidden = false
                color.layer.cornerRadius = color.frame.width/2
            }

        } else{
            textButton.setTitle(nil, for: .normal)
            filterButton.isHidden = false
            self.textView.resignFirstResponder()
            textButton.setImage(#imageLiteral(resourceName: "Text"), for: .normal)
            tintView.removeFromSuperview()
            verticalSlider.isHidden = true
            for color in colors{
                color.isHidden = true
            }
        }


    }

    @IBAction func filter(_ sender: UIButton) {
        let originalImage = viewImage.image

        let index = FilterType.allCases.firstIndex(of: currentFilter)!
        if index + 1 == FilterType.allCases.count {
            viewImage.image = originalImage
            currentFilter = FilterType.allCases[0]
        } else {
            currentFilter = FilterType.allCases[index + 1]
        }
        if let filteredImage = viewImage.image?.addFilter(filter: currentFilter){
                viewImage.image = filteredImage
        }

    }
    
    func editedPhotogenerator()-> UIImage{
        closeButton.isHidden = true
        filterButton.isHidden = true
        textButton.isHidden = true
        shareButton.isHidden = true
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let editedPhoto: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        closeButton.isHidden = false
        filterButton.isHidden = false
        textButton.isHidden = false
        shareButton.isHidden = false
        return editedPhoto

    }

}
extension PhotoViewController: UITextFieldDelegate{
   }
extension UIImage {
    func addFilter(filter : FilterType) -> UIImage {
        let filter = CIFilter(name: filter.rawValue)
        // convert UIImage to CIImage and set as input
        let ciInput = CIImage(image: self)
        filter?.setValue(ciInput, forKey: "inputImage")
        // get output CIImage, render as CGImage first to retain proper UIImage scale
        let ciOutput = filter?.outputImage
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)
        //Return the image
        return UIImage(cgImage: cgImage!)
        }
    }
