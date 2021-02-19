//
//  LocationTableViewCell.swift
//  CozyPlatform
//
//  Created by DERİN SEZGİN on 19.10.2020.
//

import UIKit

class LocationTableViewCell: UITableViewCell {

    @IBOutlet weak var locationName: UILabel!
    @IBOutlet weak var locationDescription: UILabel!
    @IBOutlet weak var locationImage: UIImageView!
    @IBOutlet weak var cellBackgroundView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear

        cellBackgroundView.backgroundColor = .white
        cellBackgroundView.layer.cornerRadius = 20
//
    }
 
    
}



