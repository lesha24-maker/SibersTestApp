//
//  Player.swift
//  SibersTest
//
//  Created by Alexey Lim on 12/6/25.
//

import Foundation

class Player {
    var currentRoom: (x: Int, y: Int)
    var inventory: [Item]
    var maxSteps: Int
    var currentSteps: Int
    var gold: Int
    
    init(startRoom: (x: Int, y: Int), maxSteps: Int) {
        self.currentRoom = startRoom
        self.inventory = []
        self.maxSteps = maxSteps
        self.currentSteps = 0
        self.gold = 0
    }
    
    var hasKey: Bool {
        return inventory.contains { $0.type == .key }
    }
    
    var hasTorchlight: Bool {
        return inventory.contains { $0.type == .torchlight }
    }
    
    var hasSword: Bool {
        return inventory.contains { $0.type == .sword }
    }
    
    var remainingSteps: Int {
        return maxSteps - currentSteps
    }
    
    var healthPercentage: Double {
        return Double(remainingSteps) / Double(maxSteps)
    }
    
    func addItem(_ item: Item) {
        inventory.append(item)
    }
    
    func removeItem(_ item: Item) {
        inventory.removeAll { $0.id == item.id }
    }
    
    func increaseHealth(by amount: Int) {
        maxSteps += amount
    }
    
    func decreaseHealth(by percentage: Double) {
        let decrease = Int(Double(maxSteps) * percentage)
        maxSteps = max(0, maxSteps - decrease)
    }
    
    func addGold(_ amount: Int) {
        gold += amount
    }
}

