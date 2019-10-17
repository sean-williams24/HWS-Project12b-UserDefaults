//
//  Person.swift
//  Project 10 - Names To Faces
//
//  Created by Sean Williams on 16/10/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit

class Person: NSObject, Codable {
    var name: String
    var image: String
    
    init(name: String, image: String) {
        self.name = name
        self.image = image
    }

}
