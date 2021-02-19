//
//  ShowLocationsViewController.swift
//  CozyPlatform
//
//  Created by DERİN SEZGİN on 19.10.2020.
//

import UIKit
import MapKit
import Firebase
import CoreLocation

class ShowLocationsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var locations: [Location] = []
    var locationManager = CLLocationManager()
    var locationTitle = ""
    var locationSubtitle = ""
    var locationLatitude = 0.0
    var locationLongitude = 0.0
    var lastLocation: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create custom annotation for location
        let info = CustomPointAnnotation()
        info.coordinate = CLLocationCoordinate2DMake(Double(locationLatitude),Double(locationLongitude))
        info.title = locationTitle
        info.subtitle = locationSubtitle
        let coordinateRegion = MKCoordinateRegion(center: info.coordinate, latitudinalMeters: 800, longitudinalMeters: 800)
        mapView.setRegion(coordinateRegion, animated: true)
        self.mapView.addAnnotation(info)
        
        // ask for location permissions
        self.locationManager.requestAlwaysAuthorization()

            // For use in foreground
            self.locationManager.requestWhenInUseAuthorization()

            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.startUpdatingLocation()
            }
    }

    override func viewWillAppear(_ animated: Bool) {
        
        // load locations from firebase before view will appear
        let ref = Database.database().reference(withPath: "locations")

        ref.observe(.value, with: { snapshot in
            var allLocations: [Location] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let location = Location(snapshot: snapshot) {
                    allLocations.append(location)
                }
            }

            self.locations = allLocations

            self.updateLocations()
            if !self.locations.isEmpty {
                self.showLocations()
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            self.lastLocation = locations.last
    }
    
    // share location name and link etc.
    @IBAction func share(_ sender: Any) {
        //Set the default sharing message.
        let message = "I have just visited \(locationTitle)"
        //Set the link to share.
        if let link = NSURL(string: "https://cozyplatform")
        {
            let objectsToShare = [message,link] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    //draw route
    @IBAction func drawRoute(_ sender: Any) {
        
        let crd1lat = self.lastLocation?.coordinate.latitude
        let crd1lon = self.lastLocation?.coordinate.longitude
        
        let source:CLLocationCoordinate2D = CLLocationCoordinate2DMake(crd1lat!, crd1lon!)

        let crd2lat = locationLatitude
        let crd2lon = locationLongitude
        
        let crd2:CLLocationCoordinate2D = CLLocationCoordinate2DMake(crd2lat, crd2lon)
  
        
        showRouteOnMap(pickupCoordinate: source, destinationCoordinate: crd2)
    }
    
    // calculate distance between users's location and other point
    private func userDistance(from point: MKPointAnnotation) -> Double? {
        guard let userLocation = mapView.userLocation.location else {
            return nil // User location unknown!
        }
        let pointLocation = CLLocation(
            latitude:  point.coordinate.latitude,
            longitude: point.coordinate.longitude
        )
        return userLocation.distance(from: pointLocation)
    }
    
    @IBAction func showLocations() {
    }

    func updateLocations() {
     mapView.removeAnnotations(locations)
     mapView.addAnnotations(locations)
    }
    

    
    @objc func showLocationDetails(_ sender: UIButton) {
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if !(annotation is CustomPointAnnotation) {
                return nil
            }

            let reuseId = "Location"

        var anView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
            if anView == nil {
                anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                anView!.canShowCallout = true
            }
            else {
                anView!.annotation = annotation
            }
            let cpa = annotation as! CustomPointAnnotation
            anView!.image = cpa.imageName

            return anView
        }
    
    // draw route and calculate distance
    func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        
        self.mapView.delegate = self
        
        let pickLock = CLLocation(latitude: pickupCoordinate.latitude, longitude: pickupCoordinate.longitude)
        let destLoc = CLLocation(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude)
        let distance = pickLock.distance(from: destLoc) / 1000
        let distanceKM = Double(round(1000*distance)/1000)

        let sourcePlacemark = MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil)

        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)

        let sourceAnnotation = MKPointAnnotation()

        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }

        let destinationAnnotation = MKPointAnnotation()

        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }

        self.mapView.showAnnotations([sourceAnnotation,destinationAnnotation], animated: true )

        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile

        // Calculate the direction
        let directions = MKDirections(request: directionRequest)

        directions.calculate {
            (response, error) -> Void in

            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }

                return
            }

            let route = response.routes[0]

            self.mapView.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)

            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
            
            self.showSingleAlert(withMessage: "The distance between your location and \(self.locationTitle) is \(distanceKM) KM.")
            

            
        }
    }
    // renderer for overlay
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        let renderer = MKPolylineRenderer(overlay: overlay)

        renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)

        renderer.lineWidth = 5.0

        return renderer
    }
    
    func showSingleAlert(withMessage message: String) {
        let alertController = UIAlertController(title: "Cozy Platform", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
}
// regarding mapview extensions
extension MapViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard annotation is Location else {
      return nil
    }
    let identifier = "Location"
    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
    if annotationView == nil {
      let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
      
      pinView.isEnabled = true
      pinView.canShowCallout = true
      pinView.animatesDrop = false
      pinView.pinTintColor = UIColor(red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
      pinView.tintColor = UIColor(white: 0.0, alpha: 0.5)
      
      let rightButton = UIButton(type: .detailDisclosure)
      rightButton.addTarget(self, action: #selector(showLocationDetails(_:)), for: .touchUpInside)
      pinView.rightCalloutAccessoryView = rightButton

      annotationView = pinView
    }
    
    if let annotationView = annotationView {
      annotationView.annotation = annotation

      
      let button = annotationView.rightCalloutAccessoryView as! UIButton
      if let index = locations.firstIndex(of: annotation as! Location) {
        button.tag = index
      }
    }
    return annotationView
  }
    
    @objc func showLocationDetails(_ sender: UIButton) {
      //performSegue(withIdentifier: "EditLocation", sender: sender)
        print(sender.tag)
    }
}


class CustomPointAnnotation: MKPointAnnotation {
    var imageName: UIImage!
}




