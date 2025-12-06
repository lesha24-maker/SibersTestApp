//
//  GameViewModel.swift
//  SibersTest
//
//  Created by Alexey Lim on 12/6/25.
//

import Foundation
import SwiftUI
import Combine

enum GameState {
    case notStarted
    case playing
    case won
    case lost
}

enum GameMessageType {
    case normal
    case success
    case error
    case warning
    case info
}

struct GameMessage: Identifiable {
    let id = UUID()
    let text: String
    let type: GameMessageType
}

@MainActor
class GameViewModel: ObservableObject {
    @Published var gameState: GameState = .notStarted
    @Published var messages: [GameMessage] = []
    @Published var inputText: String = ""
    @Published var roomCount: String = "20"
    
    private var maze: Maze?
    private var player: Player?
    private var previousRoom: (x: Int, y: Int)?
    private var monsterTimer: Timer?
    private var isWaitingForMonsterAction = false
    
    func startGame() {
        guard let count = Int(roomCount), count > 0 else {
            addMessage("Please enter a valid number of rooms", type: .error)
            return
        }
        
        let side = Int(sqrt(Double(count)))
        let width = side
        let height = (count + side - 1) / side
        
        maze = Maze(width: width, height: height)
        maze?.generateMaze()
        
        let startX = Int.random(in: 0..<width)
        let startY = Int.random(in: 0..<height)
        player = Player(startRoom: (startX, startY), maxSteps: 100)
        
        placeKeyAndChest()
        
        placeAdditionalItems()
        
        placeMonsters()
        
        if !verifyTraversability() {
            startGame()
            return
        }
        
        gameState = .playing
        previousRoom = nil
        describeCurrentRoom()
    }
    
    private func placeKeyAndChest() {
        guard let maze = maze, let player = player else { return }
        
        let allRooms = maze.getAllRooms()
        let availableRooms = allRooms.filter { $0.x != player.currentRoom.x || $0.y != player.currentRoom.y }
        
        guard availableRooms.count >= 2 else { return }
        
        if let keyRoom = availableRooms.randomElement() {
            var room = keyRoom
            room.items.append(Item(type: .key))
            maze.setRoom(room)
        }
        
        let remainingRooms = maze.getAllRooms().filter { room in
            room.x != player.currentRoom.x || room.y != player.currentRoom.y
        }
        if let chestRoom = remainingRooms.randomElement() {
            var room = chestRoom
            room.items.append(Item(type: .chest))
            maze.setRoom(room)
        }
    }
    
    private func placeAdditionalItems() {
        guard let maze = maze else { return }
        
        let allRooms = maze.getAllRooms()
        let itemCount = min(5, allRooms.count / 3)
        
        for _ in 0..<itemCount {
            if let room = allRooms.randomElement() {
                var updatedRoom = room
                let itemType: ItemType
                
                switch Int.random(in: 0..<5) {
                case 0:
                    itemType = .torchlight
                case 1:
                    itemType = .food
                case 2:
                    itemType = .sword
                case 3:
                    itemType = .gold
                default:
                    itemType = .gold
                }
                
                if itemType == .gold {
                    let amount = Int.random(in: 50...500)
                    updatedRoom.items.append(Item(type: .gold, goldAmount: amount))
                } else {
                    updatedRoom.items.append(Item(type: itemType))
                }
                
                if Int.random(in: 0..<10) < 3 {
                    updatedRoom.isDark = true
                }
                
                maze.setRoom(updatedRoom)
            }
        }
    }
    
    private func placeMonsters() {
        guard let maze = maze, let player = player else { return }
        
        let allRooms = maze.getAllRooms()
        let monsterCount = min(3, allRooms.count / 4)
        
        for _ in 0..<monsterCount {
            if let room = allRooms.randomElement() {
                var updatedRoom = room
                if updatedRoom.x != player.currentRoom.x || updatedRoom.y != player.currentRoom.y {
                    let monsterName = Monster.possibleNames.randomElement() ?? "dragon"
                    updatedRoom.monster = Monster(name: monsterName)
                    maze.setRoom(updatedRoom)
                }
            }
        }
    }
    
    private func verifyTraversability() -> Bool {
        guard let maze = maze, let player = player else { return false }
        
        let allRooms = maze.getAllRooms()
        let keyRoom = allRooms.first { $0.items.contains { $0.type == .key } }
        let chestRoom = allRooms.first { $0.items.contains { $0.type == .chest } }
        
        guard let key = keyRoom, let chest = chestRoom else { return false }
        
        let start = player.currentRoom
        let pathToKey = maze.findPath(from: start, to: (key.x, key.y)) ?? Int.max
        _ = maze.findPath(from: start, to: (chest.x, chest.y)) ?? Int.max
        let pathFromKeyToChest = maze.findPath(from: (key.x, key.y), to: (chest.x, chest.y)) ?? Int.max
        
        let totalPath = pathToKey + pathFromKeyToChest
        
        return totalPath < player.maxSteps
    }
    
    func processCommand(_ command: String) {
        guard gameState == .playing, let player = player, let maze = maze else { return }
        
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if trimmed.isEmpty {
            return
        }
        
        if isWaitingForMonsterAction {
            handleMonsterAction(command: trimmed)
            return
        }
        
        executeCommand(trimmed)
    }
    
    private func executeCommand(_ command: String) {
        let parts = command.components(separatedBy: " ")
        let mainCommand = parts[0]
        
        switch mainCommand {
        case "N", "S", "W", "E":
            move(direction: mainCommand)
        case "GET":
            if parts.count > 1 {
                getItem(name: parts.dropFirst().joined(separator: " ").lowercased())
            } else {
                addMessage("Get what? Usage: get [item]", type: .error)
            }
        case "DROP":
            if parts.count > 1 {
                dropItem(name: parts.dropFirst().joined(separator: " ").lowercased())
            } else {
                addMessage("Drop what? Usage: drop [item]", type: .error)
            }
        case "OPEN":
            openChest()
        case "EAT":
            if parts.count > 1 {
                eatItem(name: parts.dropFirst().joined(separator: " ").lowercased())
            } else {
                addMessage("Eat what? Usage: eat [item]", type: .error)
            }
        case "FIGHT":
            fightMonster()
        default:
            addMessage("Unknown command. Available: N/S/W/E, get [item], drop [item], open, eat [item], fight", type: .error)
        }
    }
    
    private func move(direction: String) {
        guard let player = player, let maze = maze else { return }
        
        guard let dir = Direction.allCases.first(where: { $0.rawValue == direction }) else {
            addMessage("Invalid direction", type: .error)
            return
        }
        
        guard let currentRoom = maze.getRoom(x: player.currentRoom.x, y: player.currentRoom.y),
              currentRoom.doors.contains(dir) else {
            addMessage("There is no door in that direction!", type: .error)
            return
        }
        
        let offset = dir.coordinateOffset
        let newX = player.currentRoom.x + offset.x
        let newY = player.currentRoom.y + offset.y
        
        guard let newRoom = maze.getRoom(x: newX, y: newY) else {
            addMessage("Cannot move there!", type: .error)
            return
        }
        
        if player.currentSteps >= player.maxSteps {
            gameState = .lost
            addMessage("You have run out of steps and died of hunger in the dark dragon cave!", type: .error)
            return
        }
        
        previousRoom = player.currentRoom
        player.currentRoom = (newX, newY)
        player.currentSteps += 1
        
        if newRoom.monster != nil {
            handleMonsterEncounter()
            return
        }
        
        describeCurrentRoom()
        checkGameOver()
    }
    
    private func describeCurrentRoom() {
        guard let player = player, let maze = maze,
              let room = maze.getRoom(x: player.currentRoom.x, y: player.currentRoom.y) else { return }
        
        let canSee = room.canSee(playerHasTorchlight: player.hasTorchlight)
        
        if !canSee {
            addMessage("Can't see anything in this dark place!", type: .warning)
            return
        }
        
        let doors = room.doors.sorted { $0.rawValue < $1.rawValue }
        let doorNames = doors.map { $0.rawValue }.joined(separator: ", ")
        let itemList = room.items.isEmpty ? "none" : room.items.map { $0.displayName }.joined(separator: ", ")
        
        var description = "You are in the room [\(room.x),\(room.y)]. There are \(room.doors.count) doors: [\(doorNames)]. Items in the room: [\(itemList)]."
        
        if let monster = room.monster {
            description += "\nThere is an evil \(monster.name) in the room!"
        }
        
        addMessage(description, type: .normal)
        addMessage("Steps remaining: \(player.remainingSteps) | Health: \(Int(player.healthPercentage * 100))% | Gold: \(player.gold)", type: .info)
    }
    
    private func getItem(name: String) {
        guard let player = player, let maze = maze,
              var room = maze.getRoom(x: player.currentRoom.x, y: player.currentRoom.y) else { return }
        
        let canSee = room.canSee(playerHasTorchlight: player.hasTorchlight)
        if !canSee {
            addMessage("Can't see anything in this dark place!", type: .warning)
            return
        }
        
        let itemName = name.lowercased()
        var itemToGet: Item?
        
        if itemName.hasPrefix("gold") {
            itemToGet = room.items.first { $0.type == .gold }
        } else {
            itemToGet = room.items.first { $0.type.rawValue == itemName }
        }
        
        guard let item = itemToGet else {
            addMessage("There is no such item in the room!", type: .error)
            return
        }
        
        guard item.type.isCollectible else {
            addMessage("You cannot pick up \(item.type.rawValue)!", type: .error)
            return
        }
        
        if item.type == .gold {
            player.addGold(item.goldAmount ?? 0)
            addMessage("You collected \(item.goldAmount ?? 0) gold coins!", type: .success)
        } else {
            player.addItem(item)
            addMessage("You picked up \(item.type.rawValue)!", type: .success)
        }
        
        room.items.removeAll { $0.id == item.id }
        maze.setRoom(room)
    }
    
    private func dropItem(name: String) {
        guard let player = player, let maze = maze,
              var room = maze.getRoom(x: player.currentRoom.x, y: player.currentRoom.y) else { return }
        
        let itemName = name.lowercased()
        guard let item = player.inventory.first(where: { $0.type.rawValue == itemName }) else {
            addMessage("You don't have that item!", type: .error)
            return
        }
        
        player.removeItem(item)
        room.items.append(item)
        
        if item.type == .torchlight && room.isDark {
            room.isIlluminated = true
            addMessage("You dropped the torchlight. The room is now illuminated!", type: .success)
        } else {
            addMessage("You dropped \(item.type.rawValue)!", type: .success)
        }
        
        maze.setRoom(room)
    }
    
    private func openChest() {
        guard let player = player, let maze = maze,
              let room = maze.getRoom(x: player.currentRoom.x, y: player.currentRoom.y) else { return }
        
        let canSee = room.canSee(playerHasTorchlight: player.hasTorchlight)
        if !canSee {
            addMessage("Can't see anything in this dark place!", type: .warning)
            return
        }
        
        guard room.items.contains(where: { $0.type == .chest }) else {
            addMessage("There is no chest in this room!", type: .error)
            return
        }
        
        guard player.hasKey else {
            addMessage("You need a key to open the chest!", type: .error)
            return
        }
        
        gameState = .won
        addMessage("You opened the chest and found the Holy Grail! You win!", type: .success)
    }
    
    private func eatItem(name: String) {
        guard let player = player else { return }
        
        let itemName = name.lowercased()
        guard let item = player.inventory.first(where: { $0.type.rawValue == itemName && $0.type == .food }) else {
            addMessage("You don't have any food to eat!", type: .error)
            return
        }
        
        player.removeItem(item)
        let healthIncrease = 20
        player.increaseHealth(by: healthIncrease)
        addMessage("You ate the food and restored \(healthIncrease) health points!", type: .success)
    }
    
    private func handleMonsterEncounter() {
        guard let maze = maze,
              let room = maze.getRoom(x: player?.currentRoom.x ?? 0, y: player?.currentRoom.y ?? 0),
              room.monster != nil else { return }
        
        isWaitingForMonsterAction = true
        addMessage("You have 5 seconds to act! Enter any command...", type: .warning)
        
        monsterTimer?.invalidate()
        monsterTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleMonsterTimeout()
            }
        }
    }
    
    private func handleMonsterAction(command: String) {
        monsterTimer?.invalidate()
        isWaitingForMonsterAction = false
        
        guard let player = player, let maze = maze,
              var room = maze.getRoom(x: player.currentRoom.x, y: player.currentRoom.y),
              let monster = room.monster else { return }
        
        let random = Int.random(in: 0..<3)
        var commandExecuted = false
        var monsterDefeated = false
        
        if command == "FIGHT" && player.hasSword {
            switch random {
            case 0:
                player.decreaseHealth(by: 0.1)
                if let prev = previousRoom {
                    player.currentRoom = prev
                }
                addMessage("The \(monster.name) was too strong! You lost 10% health and were pushed back!", type: .error)
                describeCurrentRoom()
            case 1:
                player.decreaseHealth(by: 0.1)
                room.monster = nil
                maze.setRoom(room)
                monsterDefeated = true
                addMessage("You defeated the \(monster.name), but took some damage! You lost 10% health.", type: .warning)
            case 2:
                room.monster = nil
                maze.setRoom(room)
                monsterDefeated = true
                addMessage("You defeated the \(monster.name) with your sword!", type: .success)
            default:
                break
            }
        } else {
            switch random {
            case 0:
                player.decreaseHealth(by: 0.1)
                if let prev = previousRoom {
                    player.currentRoom = prev
                }
                addMessage("The \(monster.name) attacked you! You lost 10% health and were pushed back!", type: .error)
                describeCurrentRoom()
            case 1:
                player.decreaseHealth(by: 0.1)
                addMessage("You managed to act, but the \(monster.name) still hurt you! You lost 10% health.", type: .warning)
                executeCommand(command)
                commandExecuted = true
            case 2:
                addMessage("You successfully avoided the \(monster.name)'s attack!", type: .success)
                executeCommand(command)
                commandExecuted = true
            default:
                break
            }
        }
        
        if commandExecuted && command == "FIGHT" && player.hasSword {
            if let updatedRoom = maze.getRoom(x: player.currentRoom.x, y: player.currentRoom.y),
               updatedRoom.monster != nil {
                var newRoom = updatedRoom
                newRoom.monster = nil
                maze.setRoom(newRoom)
                addMessage("You defeated the \(monster.name) with your sword!", type: .success)
            }
        }
        
        checkGameOver()
    }
    
    private func handleMonsterTimeout() {
        guard let player = player, let maze = maze,
              var room = maze.getRoom(x: player.currentRoom.x, y: player.currentRoom.y),
              let monster = room.monster else { return }
        
        isWaitingForMonsterAction = false
        
        player.decreaseHealth(by: 0.1)
        if let prev = previousRoom {
            player.currentRoom = prev
        }
        
        addMessage("The \(monster.name) attacked you! You lost 10% health and were pushed back!", type: .error)
        describeCurrentRoom()
        checkGameOver()
    }
    
    private func fightMonster() {
        guard let player = player, let maze = maze,
              var room = maze.getRoom(x: player.currentRoom.x, y: player.currentRoom.y),
              let monster = room.monster else {
            addMessage("There is no monster to fight!", type: .error)
            return
        }
        
        guard player.hasSword else {
            addMessage("You need a sword to fight!", type: .error)
            return
        }
        
        let random = Int.random(in: 0..<3)
        
        switch random {
        case 0:
            player.decreaseHealth(by: 0.1)
            if let prev = previousRoom {
                player.currentRoom = prev
            }
            addMessage("The \(monster.name) was too strong! You lost 10% health and were pushed back!", type: .error)
            describeCurrentRoom()
        case 1:
            player.decreaseHealth(by: 0.1)
            room.monster = nil
            maze.setRoom(room)
            addMessage("You defeated the \(monster.name), but took some damage! You lost 10% health.", type: .warning)
        case 2:
            room.monster = nil
            maze.setRoom(room)
            addMessage("You defeated the \(monster.name) with your sword!", type: .success)
        default:
            break
        }
        
        checkGameOver()
    }
    
    private func checkGameOver() {
        guard let player = player else { return }
        
        if player.currentSteps >= player.maxSteps {
            gameState = .lost
            addMessage("You have run out of steps and died of hunger in the dark dragon cave!", type: .error)
        }
    }
    
    private func addMessage(_ text: String, type: GameMessageType) {
        messages.append(GameMessage(text: text, type: type))
        if messages.count > 50 {
            messages.removeFirst()
        }
    }
    
    func submitCommand() {
        processCommand(inputText)
        inputText = ""
    }
    
    func resetGame() {
        gameState = .notStarted
        messages.removeAll()
        inputText = ""
        maze = nil
        player = nil
        previousRoom = nil
        monsterTimer?.invalidate()
        isWaitingForMonsterAction = false
    }
}

