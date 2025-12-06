//
//  Direction.swift
//  SibersTest
//
//  Created by Alexey Lim on 12/6/25.
//

import Foundation

enum Direction: String, CaseIterable {
    case north = "N"
    case south = "S"
    case west = "W"
    case east = "E"
    
    var opposite: Direction {
        switch self {
        case .north: return .south
        case .south: return .north
        case .west: return .east
        case .east: return .west
        }
    }
    
    var coordinateOffset: (x: Int, y: Int) {
        switch self {
        case .north: return (0, -1)
        case .south: return (0, 1)
        case .west: return (-1, 0)
        case .east: return (1, 0)
        }
    }
}

