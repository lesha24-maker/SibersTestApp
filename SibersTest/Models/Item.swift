//
//  Item.swift
//  SibersTest
//
//  Created by Alexey Lim on 12/6/25.
//

import Foundation

enum ItemType: String {
    case key
    case chest
    case torchlight
    case food
    case sword
    case gold
    
    var isCollectible: Bool {
        return self != .chest
    }
}

struct Item: Identifiable, Equatable {
    let id = UUID()
    let type: ItemType
    let goldAmount: Int? // Only for gold items
    
    init(type: ItemType, goldAmount: Int? = nil) {
        self.type = type
        self.goldAmount = goldAmount
    }
    
    var displayName: String {
        if type == .gold, let amount = goldAmount {
            return "gold (\(amount) coins)"
        }
        return type.rawValue
    }
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }
}

