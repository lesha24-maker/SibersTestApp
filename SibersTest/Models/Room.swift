//
//  Room.swift
//  SibersTest
//
//  Created by Alexey Lim on 12/6/25.
//

import Foundation

struct Room: Identifiable {
    let id = UUID()
    let x: Int
    let y: Int
    var doors: Set<Direction>
    var items: [Item]
    var isDark: Bool
    var monster: Monster?
    var isIlluminated: Bool
    
    init(x: Int, y: Int, doors: Set<Direction> = [], items: [Item] = [], isDark: Bool = false, monster: Monster? = nil, isIlluminated: Bool = false) {
        self.x = x
        self.y = y
        self.doors = doors
        self.items = items
        self.isDark = isDark
        self.monster = monster
        self.isIlluminated = isIlluminated
    }
    
    func canSee(playerHasTorchlight: Bool) -> Bool {
        if isDark && !isIlluminated {
            return playerHasTorchlight
        }
        return true
    }
}

