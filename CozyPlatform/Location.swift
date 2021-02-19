//
//  Location.swift
//  CozyPlatform
//
//  Created by DERİN SEZGİN on 19.10.2020.
//

import Foundation
import MapKit
import Firebase

// Location object for coredata, firebase
class Location: NSObject, MKAnnotation {
    
    public var coordinate: CLLocationCoordinate2D {
      return CLLocationCoordinate2DMake(latitude, longitude)
    }

    let ref: DatabaseReference?
    let key: String
    let locationName : String
    let locationDescription: String
    let locationImageName: String
    let latitude: Double
    let longitude: Double
    let userID: String
    
    init(locationName: String, locationDescription: String, locationImageName: String, latitude: Double, longitude: Double, userID: String, key: String = "") {
    self.ref = nil
    self.key = key
    self.locationName = locationName
    self.locationDescription = locationDescription
    self.locationImageName = locationImageName
    self.latitude = latitude
    self.longitude = longitude
    self.userID = userID
    }
    
    init?(snapshot: DataSnapshot) {
      guard
        let value = snapshot.value as? [String: AnyObject],
        let locationName = value["locationName"] as? String,
        let locationDescription = value["locationDescription"] as? String,
        let locationImageName = value["locationImageName"] as? String,
        let latitude = value["latitude"] as? Double,
        let longitude = value["longitude"] as? Double,
        let userID = value["userID"] as? String else {
        return nil
      }
      
      self.ref = snapshot.ref
      self.key = snapshot.key
      self.locationName = locationName
      self.locationDescription = locationDescription
      self.locationImageName = locationImageName
      self.latitude = latitude
      self.longitude = longitude
      self.userID = userID
    }
    
    func toAnyObject() -> Any {
      return [
        "locationName": locationName,
        "locationDescription": locationDescription,
        "locationImageName": locationImageName,
        "latitude": latitude,
        "longitude": longitude,
        "userID": userID,
      ]
    }
}
