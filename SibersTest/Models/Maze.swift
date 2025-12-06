//
//  Maze.swift
//  SibersTest
//
//  Created by Alexey Lim on 12/6/25.
//

import Foundation

class Maze {
    private var rooms: [[Room?]]
    private let width: Int
    private let height: Int
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.rooms = Array(repeating: Array(repeating: nil as Room?, count: height), count: width)
    }
    
    func generateMaze() {
        var visited = Set<String>()
        var stack: [(x: Int, y: Int)] = []
        
        let startX = Int.random(in: 0..<width)
        let startY = Int.random(in: 0..<height)
        stack.append((startX, startY))
        visited.insert("\(startX),\(startY)")
        
        while !stack.isEmpty {
            let current = stack.last!
            let neighbors = getUnvisitedNeighbors(current, visited: visited)
            
            if let neighbor = neighbors.randomElement() {
                let direction = getDirection(from: current, to: neighbor)
                let oppositeDirection = direction.opposite
                
                if rooms[current.x][current.y] == nil {
                    rooms[current.x][current.y] = Room(x: current.x, y: current.y, doors: [direction])
                } else {
                    var room = rooms[current.x][current.y]!
                    room.doors.insert(direction)
                    rooms[current.x][current.y] = room
                }
                
                if rooms[neighbor.x][neighbor.y] == nil {
                    rooms[neighbor.x][neighbor.y] = Room(x: neighbor.x, y: neighbor.y, doors: [oppositeDirection])
                } else {
                    var room = rooms[neighbor.x][neighbor.y]!
                    room.doors.insert(oppositeDirection)
                    rooms[neighbor.x][neighbor.y] = room
                }
                
                visited.insert("\(neighbor.x),\(neighbor.y)")
                stack.append(neighbor)
            } else {
                stack.removeLast()
            }
        }
        
        for x in 0..<width {
            for y in 0..<height {
                if rooms[x][y] == nil {
                    var doors: Set<Direction> = []
                    for direction in Direction.allCases {
                        let offset = direction.coordinateOffset
                        let newX = x + offset.x
                        let newY = y + offset.y
                        if isValidCoordinate(x: newX, y: newY) {
                            if var neighbor = rooms[newX][newY] {
                                doors.insert(direction)
                                neighbor.doors.insert(direction.opposite)
                                rooms[newX][newY] = neighbor
                            }
                        }
                    }
                    rooms[x][y] = Room(x: x, y: y, doors: doors.isEmpty ? [.north] : doors)
                }
            }
        }
    }
    
    private func getUnvisitedNeighbors(_ room: (x: Int, y: Int), visited: Set<String>) -> [(x: Int, y: Int)] {
        var neighbors: [(x: Int, y: Int)] = []
        
        for direction in Direction.allCases {
            let offset = direction.coordinateOffset
            let newX = room.x + offset.x
            let newY = room.y + offset.y
            let key = "\(newX),\(newY)"
            
            if isValidCoordinate(x: newX, y: newY) && !visited.contains(key) {
                neighbors.append((newX, newY))
            }
        }
        
        return neighbors
    }
    
    private func getDirection(from: (x: Int, y: Int), to: (x: Int, y: Int)) -> Direction {
        let dx = to.x - from.x
        let dy = to.y - from.y
        
        if dx == 1 { return .east }
        if dx == -1 { return .west }
        if dy == 1 { return .south }
        if dy == -1 { return .north }
        
        return .north
    }
    
    private func isValidCoordinate(x: Int, y: Int) -> Bool {
        return x >= 0 && x < width && y >= 0 && y < height
    }
    
    func getRoom(x: Int, y: Int) -> Room? {
        guard isValidCoordinate(x: x, y: y) else { return nil }
        return rooms[x][y]
    }
    
    func setRoom(_ room: Room) {
        guard isValidCoordinate(x: room.x, y: room.y) else { return }
        rooms[room.x][room.y] = room
    }
    
    func getAllRooms() -> [Room] {
        var allRooms: [Room] = []
        for x in 0..<width {
            for y in 0..<height {
                if let room = rooms[x][y] {
                    allRooms.append(room)
                }
            }
        }
        return allRooms
    }
    
    func findPath(from: (x: Int, y: Int), to: (x: Int, y: Int)) -> Int? {
        var queue: [((x: Int, y: Int), steps: Int)] = [(from, 0)]
        var visited = Set<String>()
        visited.insert("\(from.x),\(from.y)")
        
        while !queue.isEmpty {
            let (current, steps) = queue.removeFirst()
            
            if current.x == to.x && current.y == to.y {
                return steps
            }
            
            guard let room = getRoom(x: current.x, y: current.y) else { continue }
            
            for direction in room.doors {
                let offset = direction.coordinateOffset
                let newX = current.x + offset.x
                let newY = current.y + offset.y
                let key = "\(newX),\(newY)"
                
                if !visited.contains(key) && isValidCoordinate(x: newX, y: newY) {
                    visited.insert(key)
                    queue.append(((newX, newY), steps + 1))
                }
            }
        }
        
        return nil
    }
}

