//
//  Monster.swift
//  SibersTest
//
//  Created by Alexey Lim on 12/6/25.
//

import Foundation

struct Monster: Identifiable {
    let id = UUID()
    let name: String
    
    static let possibleNames = ["dragon", "goblin", "orc", "troll", "skeleton"]
}

