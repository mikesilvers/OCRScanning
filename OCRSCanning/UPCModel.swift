//
//  UPCModel.swift
//  OCRSCanning
//
//  Created by Mike Silvers on 6/22/19.
//  Copyright © 2019 Mike Silvers. All rights reserved.
//

import Foundation

struct UPCModel: Codable {
    
    var upcnumber: String?
    var newupc: String?
    var st0s: String?
    var name: String?
    var alias: String
    var type: String
    var title: String
    var description: String?
    var brand: String?
    var category: String?
    var size: String?
    var color: String?
    var gender: String?
    var age: String?
    var unit: String?
    var msrp: String?
    var rateup: String?
    var ratedown: String?
    var status: Int?
    var message: String?
    var error: Bool?
    
    enum CodingKeys: String, CodingKey {
        case upcnumber, newupc, st0s
        case name, alias, type, title, description
        case brand, category, size, color
        case age, unit, msrp, status, message
        case rateup = "rate/up"
        case ratedown = "rate/down"
    }
}
