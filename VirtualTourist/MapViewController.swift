//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Noha on 25.10.19.
//  Copyright © 2019 udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData
enum PinError : Error {
    case failedSave
    case failedFetch
}

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var pins : [Pin]!
    var pin : Pin!
    var dataController = DataController(modelName: "VirtualTourist")
    @IBOutlet weak var editOk: UIBarButtonItem!
    @IBOutlet weak var tapToDeleteLabel: UILabel!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchPinLocations()
        let longPressrecogniser = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressrecogniser)
        mapView.delegate = self
        tapToDeleteLabel.isHidden = true

        // Do any additional setup after loading the view.
    }
    func showError(_ error: PinError){

        let controller = UIAlertController()
        controller.title = "Alert!"
        controller.message = "\(error)"

        let okAction = UIAlertAction(title: "ok", style: UIAlertAction.Style.default) { action in self.dismiss(animated: true, completion: nil)
        }

        controller.addAction(okAction)
        self.present(controller, animated: true, completion: nil)

    }

    @IBAction func editButton(_ sender: Any) {

        if editOk.title == "Edit"{
            tapToDeleteLabel.isHidden = false
            editOk.title = "Done"

        } else{
            tapToDeleteLabel.isHidden = true
            editOk.title = "Edit"
            
        }


    }


    func fetchPinLocations(){
        let fetchRequest : NSFetchRequest<Pin> = Pin.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            pins = result
            for location in result {

                let annotation = PinAnnotation(pin: location)
                mapView.addAnnotation(annotation)
            }
            mapView.reloadInputViews()

        } else{
            showError(.failedFetch)
        }
    }

    @objc func handleLongPress(_ gestureRecognizer : UIGestureRecognizer){
        if  gestureRecognizer.state != .began {return }
        let touchPoint = gestureRecognizer.location(in: mapView)
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

        if let savedPin = try? savePin(at: touchMapCoordinate){
        pins.insert(savedPin, at: 0)
        showOnMap(savedPin)
        } else{
            showError(.failedSave)
        }
    }

    private func savePin(at coordinate: CLLocationCoordinate2D) throws -> Pin {
        let pin = Pin(context: dataController.viewContext)
        pin.longitude = coordinate.longitude
        pin.latitude = coordinate.latitude

        try dataController.viewContext.save()
        return pin
    }

    private func showOnMap(_ pin: Pin) {
        let annotatin = PinAnnotation(pin: pin)
        mapView.addAnnotation(annotatin)
        mapView.reloadInputViews()
    }

    func pinToDelete(_ annotationToDelete: MKAnnotation){
        for pin in pins{
            if  pin.longitude == annotationToDelete.coordinate.longitude, pin.latitude == annotationToDelete.coordinate.latitude{
                let pinToDelete = pin
                dataController.viewContext.delete(pinToDelete)
                do{
                    try dataController.viewContext.save()
                } catch{
                    showError(.failedSave)
                }


            }
        }


    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

           let reuseId = "pin"

           var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

           if pinView == nil {
               pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
               pinView!.pinTintColor = .red
           }
           else {
               pinView!.annotation = annotation
           }


           return pinView
       }

     func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        if editOk.title == "Done" {
            if let annotation = view.annotation {
                pinToDelete(annotation)
                mapView.removeAnnotation(view.annotation!)

            }

        } else {
            guard let pinAnnotation = view.annotation as? PinAnnotation else { return }
            self.performSegue(withIdentifier: "lonLatSegue", sender: pinAnnotation.pin)
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "lonLatSegue"{
            let controller = segue.destination as! PhotoAlbumViewController

            controller.dataController = dataController
            controller.pin = sender as! Pin
        }
    }
   
}
