//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Noha on 12.10.19.
//  Copyright © 2019 udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    @IBOutlet weak var photoAlbum: UICollectionView!
    @IBOutlet weak var detailedMapView: MKMapView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var selectButton: UIBarButtonItem!
    var photos : [Photo] = []
    var dataController = DataController(modelName: "VirtualTourist")
    var page = 1
    var pin : Pin!
    var photoCell = PhotoCell()
    var selectedCells = Set<IndexPath>()

    override func viewDidLoad() {
        super.viewDidLoad()
        photoAlbum.dataSource = self
        let annotation = PinAnnotation(pin: self.pin)
        detailedMapView.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: 0.15,longitudeDelta: 0.15)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude), span: span)
        detailedMapView.setRegion(region, animated: true)
        deleteButton.layer.borderWidth = 0.2
        deleteButton.layer.borderColor = UIColor.gray.cgColor
        loadPhotos()
    }
    func showError(){

        let controller = UIAlertController()
        controller.title = "Alert!"
        controller.message = "Couldn't fetch Photos"

        let okAction = UIAlertAction(title: "ok", style: UIAlertAction.Style.default) { action in self.dismiss(animated: true, completion: nil)
        }

        controller.addAction(okAction)
        self.present(controller, animated: true, completion: nil)

    }
    private func loadPhotos() {

        dataController.loadPhotos(from: pin, at: page) { result in
            guard case let .success(photos) = result else {
                DispatchQueue.main.async {
                    self.showError()
                    
                }
                return
            }
            self.photos = photos
            DispatchQueue.main.async {
                self.photoAlbum.reloadData()

            }
            self.page += 1
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sendImage"{
            let cell = sender as! PhotoCell
            let controller = segue.destination as! PhotoViewController
            controller.selectedPhoto = cell.imageView.image
            controller.pin = self.pin

        }

    }
    //TODO: Come up with better Solution
    @IBAction func selectPhotos(_ sender: Any) {
        if selectButton.title == "Select"{
        toolbar.isHidden = false
        selectButton.title = "Done"
        } else{
            toolbar.isHidden = true
            selectButton.title = "Select"
            for indexPath in selectedCells{
                let cell = photoAlbum.cellForItem(at: indexPath) as! PhotoCell
                cell.imageView.alpha = 1.0
            }
            selectedCells = []

        }
    }

    @IBAction func moveToTrash(_ sender: Any) {
        var toRemove: [Photo] = []
             for item in selectedCells.sorted().reversed() {

                 toRemove.append(photos.remove(at: item.row))

                 if let cell = photoAlbum.cellForItem(at: item) {

                     deselectCell(cell)

                 }
             }
             photoAlbum.deleteItems(at: Array(selectedCells))

             selectedCells = []

             dataController.delete(photos: toRemove)

    }
    @IBAction func newCollection(_ sender: UIButton) {
        loadPhotos()
    }
}

//MARK: - Collection View
//MARK: Data Source
extension PhotoAlbumViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCell
        let photo = photos[indexPath.row]
        cell.loadImage(for: photo)
        cell.photoSpinner.hidesWhenStopped = true
        cell.imageView.alpha = 1.0

        return cell
    }
}

//MARK: Delegate
extension PhotoAlbumViewController: UICollectionViewDelegate {
    private func deselectCell(_ cell: UICollectionViewCell) {
        cell.isSelected = false


    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell

        if selectButton.title! == "Done" {
            if selectedCells.contains(indexPath) {
                cell.imageView.alpha = 1.0
                deselectCell(cell)
                selectedCells.remove(indexPath)
            } else {
                cell.imageView.alpha = 0.5
                cell.isSelected = true
                selectedCells.insert(indexPath)

            }
        } else{
            performSegue(withIdentifier: "sendImage", sender: photoAlbum.cellForItem(at: indexPath))
        }
    }
}

//MARK: Flow Layout
extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let noOfCellsInRow = 3

        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout

        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))

        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))

        return CGSize(width: size, height: size)
    }
}
