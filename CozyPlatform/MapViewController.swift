//
//  MapViewController.swift
//  CozyPlatform
//
//  Created by DERİN SEZGİN on 19.10.2020.
//

import UIKit
import MapKit
import Firebase
import FirebaseStorage
import CoreLocation

class MapViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var locations: [Location] = []
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    @IBOutlet weak var takePictureBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var placeName: UITextField!
    @IBOutlet weak var placeDescription: UITextField!
    let locationManager = CLLocationManager()
    var lastLocation: CLLocation?
    var isImageLoaded = false
    var imageFileName = ""
    var randomName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //text field delegate
        placeName.delegate = self
        placeDescription.delegate = self
        
        // iboutlets border width, color and radius settings
        self.saveBtn.layer.borderWidth = 0.5
        self.saveBtn.layer.borderColor = UIColor.black.cgColor
        self.saveBtn.layer.cornerRadius = 15
        self.saveBtn.isEnabled = false
        self.saveBtn.backgroundColor = .lightGray
        
        self.takePictureBtn.layer.borderWidth = 0.5
        self.takePictureBtn.layer.borderColor = UIColor.black.cgColor
        self.takePictureBtn.layer.cornerRadius = 15
        
        self.placeName.layer.borderWidth = 0.5
        self.placeName.layer.borderColor = UIColor.black.cgColor
        self.placeName.layer.cornerRadius = 15
        
        self.placeDescription.layer.borderWidth = 0.5
        self.placeDescription.layer.borderColor = UIColor.black.cgColor
        self.placeDescription.layer.cornerRadius = 15

        //add gseture recognizer. set mininmum press duration as 1 second
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(action(longGesture:)))
        longGesture.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longGesture)
        
        // ask for authorization
        self.locationManager.requestAlwaysAuthorization()

            // For use in foreground
            self.locationManager.requestWhenInUseAuthorization()

            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.startUpdatingLocation()
            }

            // map view delegate and other settings
            mapView.delegate = self
            mapView.mapType = .standard
            mapView.isZoomEnabled = true
            mapView.isScrollEnabled = true

        //show users coordination center of the map view
            if let coor = mapView.userLocation.location?.coordinate{
                mapView.setCenter(coor, animated: true)
            }
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    

    override func viewDidAppear(_ animated: Bool) {
            if self.lastLocation != nil {
                // set center and region to current location
                let center = CLLocationCoordinate2D(latitude: self.lastLocation!.coordinate.latitude, longitude: self.lastLocation!.coordinate.longitude)
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))

                //set region on the map
                mapView.setRegion(region, animated: true)
            }
        }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            self.lastLocation = locations.last
    }

    @objc func action(longGesture:UIGestureRecognizer){
        
        if (self.self.mapView.annotations.last != nil) {
        mapView.removeAnnotation(self.mapView.annotations.last!)
        }
        
        let touchPoint = longGesture.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        latitude = newCoordinates.latitude
        longitude = newCoordinates.longitude
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        mapView.addAnnotation(annotation)
        checkIfCanSave()
    }
    
    // check if place name, description is not empty and also image is uploaded
    func checkIfCanSave() {
        
        if placeName.text!.count > 0 && placeDescription.text!.count > 0 && mapView.annotations.count > 0 && isImageLoaded {
  
            self.saveBtn.isEnabled = true
            self.saveBtn.backgroundColor = .systemTeal
        } else {
            self.saveBtn.isEnabled = false
            self.saveBtn.backgroundColor = .lightGray
        }
        
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        checkIfCanSave()
    }

    
    @objc func dismissKeyboard() {
           view.endEditing(true)
    }

    // add location to firebase
    @IBAction func addLocation(_ sender: UIButton) {
        
        let userID = (Auth.auth().currentUser?.uid)!
        let rootRef = Database.database().reference()
        let locationsRef = rootRef.child("locations")
        let locID = locationsRef.child(randomName)
        
        let newLocation: [String: Any] = ["userID":userID as Any, "locationName": self.placeName.text!, "locationDescription": self.placeDescription.text!, "locationImageName":self.imageFileName, "latitude": latitude, "longitude": longitude]
        
        locID.setValue(newLocation) {
          (error:Error?, ref:DatabaseReference) in
          if let error = error {
            print("Data could not be saved: \(error).")
          } else {
            print("Data saved successfully!")
            _ = self.navigationController?.popViewController(animated: true)
          }
        }
    }
    
    //open image picker
    @IBAction func uploadImageTapped(_ sender: UIButton) {
        view.endEditing(true)
        let picker = UIImagePickerController()
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    // upload image on firebase
    func uploadImage(image: UIImage) {
        randomName = randomStringWithLength(length: 10) as String
        let imageData = image.jpegData(compressionQuality: 1.0)
        let uploadRef = Storage.storage().reference().child("\(randomName).jpg")
        _ = uploadRef.putData(imageData!, metadata: nil) { [self] metadata,
            error in
            if error == nil {
                //success
                self.imageFileName = "\(randomName as String).jpg"
                self.isImageLoaded = true
                self.checkIfCanSave()
                
                self.showSingleAlert(withMessage: "The photo uploaded succesfully")
            } else {
                //error
                self.showSingleAlert(withMessage: "error uploading image")
            }
        }
    }
    
    func showSingleAlert(withMessage message: String) {
        let alertController = UIAlertController(title: "Cozy Platform", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    // generate random string for photo and also firebase post node
    func randomStringWithLength(length: Int) -> NSString {
        let characters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString: NSMutableString = NSMutableString(capacity: length)

        for _ in 0..<length {
            let len = UInt32(characters.length)
            let rand = arc4random_uniform(len)
            randomString.appendFormat("%C", characters.character(at: Int(rand)))
        }
        return randomString
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // will run if the user hits cancel
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.originalImage.rawValue)] as? UIImage {
            uploadImage(image: pickedImage)
            picker.dismiss(animated: true, completion: nil)
        }
    }    
}



