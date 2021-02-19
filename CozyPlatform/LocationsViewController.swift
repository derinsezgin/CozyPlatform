//
//  LocationsViewController.swift
//  CozyPlatform
//
//  Created by DERİN SEZGİN on 19.10.2020.
//


import UIKit
import Firebase
import CoreLocation


class LocationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var locations: [Location] = []
    var locationManager = CLLocationManager()
    var lastLocation: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ask for location permission
        self.locationManager.requestAlwaysAuthorization()

            // For use in foreground
            self.locationManager.requestWhenInUseAuthorization()

            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.startUpdatingLocation()
            }
        
        // remove empty table view cells
        tableView.tableFooterView = UIView()
        
        // get user id and database reference
        let userID = Auth.auth().currentUser?.uid
        let ref = Database.database().reference(withPath: "locations")
        
        //load locations and populate table view
        ref.observe(.value, with: { snapshot in
            var newLocations: [Location] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let location = Location(snapshot: snapshot) {
                    if location.userID == userID {
                    newLocations.append(location)
                    }
                }
            }
            
            self.locations = newLocations
            self.tableView.reloadData()
        })
        
    }
    
    // calculate distance (on kilometer) between users current point and other locations
    func calculateDistance(destinationCoordinate: CLLocationCoordinate2D) -> Double {
        let currentlat = self.lastLocation?.coordinate.latitude
        let correntLong = self.lastLocation?.coordinate.longitude
        
        let pickLock = CLLocation(latitude: currentlat!, longitude: correntLong!)
        let destLoc = CLLocation(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude)
        let distance = pickLock.distance(from: destLoc) / 1000
        let distanceKM = Double(round(1000*distance)/1000)
        
        return distanceKM
    }
    
    // update user's location when change
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            self.lastLocation = locations.last
    }
        
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        locations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as! LocationTableViewCell
        
        // set cell corner radius, border color and width
        cell.locationImage.layer.cornerRadius = cell.locationImage.frame.width / 2
        cell.locationImage.clipsToBounds = true
        cell.locationImage.layer.borderColor = UIColor.black.cgColor
        cell.locationImage.layer.borderWidth = 0.5

        let location = locations[indexPath.row]

        // calculate distance
        let dist = calculateDistance(destinationCoordinate: location.coordinate)
        cell.locationName?.text = location.locationName + " (\(dist) KM)"
        cell.locationDescription?.text = location.locationDescription
 
        // call function to load images
        self.downloadImages(folderPath: location.locationImageName, success: { (img) in
            cell.locationImage?.image = img
                }) { (error) in
                    print(error)
                }
        
        return cell
        
    }
    
    // firebase: download images
    func downloadImages(folderPath:String,success:@escaping (_ image:UIImage)->(),failure:@escaping (_ error:Error)->()){

                // Create a reference with an initial file path and name
                let reference = Storage.storage().reference(withPath: folderPath)
                reference.getData(maxSize: (1 * 10240 * 10240)) { (data, error) in
                    if let _error = error{
                        print(_error)
                        failure(_error)
                    } else {
                        if let _data  = data {
                            let myImage:UIImage! = UIImage(data: _data)
                            success(myImage)
                        }
                    }
                }
    }
    
    // delete both post and image file from firebase
    func deletePost(imageName:String) {

        let rootRef = Database.database().reference()
        let locationsRef = rootRef.child("locations")
        let folderPath = stripFileExtension(imageName)

          // Remove the post from the DB
        locationsRef.child(folderPath).removeValue { error, success  in
            if error != nil {
                print("error \(error!)")
            }
          }
        
      // Remove the image from storage
      let imageRef = Storage.storage().reference(withPath: imageName)
      imageRef.delete { error in
        if error != nil {
          // An error occurred!
        } else {
         // Image deleted successfully
        }
      }
    }
    
    // strip the extension from filename
    func stripFileExtension ( _ filename: String ) -> String {
        var components = filename.components(separatedBy: ".")
        guard components.count > 1 else { return filename }
        components.removeLast()
        return components.joined(separator: ".")
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        cell.contentView.layer.masksToBounds = true
        let radius = cell.contentView.layer.cornerRadius
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: radius).cgPath
    }

    
    // set as table view cell can edit
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    // delete tableview cells and call regarding firebase func
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCell.EditingStyle.delete) {
            let location = locations[indexPath.row]
            deletePost(imageName: location.locationImageName)
        }
    }

    // go to regarding location when clicking on cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)

        self.performSegue(withIdentifier: "showLocation", sender: indexPath.row)
        
        }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        // pass values before go to show location screen
            if  segue.identifier == "showLocation",
                let destinationVC = segue.destination as? ShowLocationsViewController
            {
                let selectedRow = sender as! Int
                
                destinationVC.locationTitle = locations[selectedRow].locationName
                destinationVC.locationSubtitle = locations[selectedRow].locationDescription
                destinationVC.locationLatitude = locations[selectedRow].latitude
                destinationVC.locationLongitude = locations[selectedRow].longitude
            }
        }
}
