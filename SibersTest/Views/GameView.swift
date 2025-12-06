//
//  GameView.swift
//  SibersTest
//
//  Created by Alexey Lim on 12/6/25.
//

import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("⚔️ Crystals and Dragons")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.1))
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            Text(message.text)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(colorForMessageType(message.type))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .id(message.id)
                        }
                    }
                    .padding(.vertical)
                }
                .background(Color.black)
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            VStack(spacing: 12) {
                if viewModel.gameState == .notStarted {
                    VStack(spacing: 12) {
                        Text("Enter number of rooms:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            TextField("Number of rooms", text: $viewModel.roomCount)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .frame(width: 150)
                            
                            Button("Start Game") {
                                viewModel.startGame()
                                isInputFocused = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                } else if viewModel.gameState == .playing {
                    HStack {
                        TextField("Enter command (N/S/W/E, get, drop, open, eat, fight)", text: $viewModel.inputText)
                            .textFieldStyle(.roundedBorder)
                            .focused($isInputFocused)
                            .onSubmit {
                                viewModel.submitCommand()
                            }
                        
                        Button("Send") {
                            viewModel.submitCommand()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        if viewModel.gameState == .won {
                            Text("🎉 Victory! 🎉")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        } else {
                            Text("💀 Game Over 💀")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        
                        Button("Play Again") {
                            viewModel.resetGame()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .background(Color.black.opacity(0.05))
        }
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func colorForMessageType(_ type: GameMessageType) -> Color {
        switch type {
        case .normal:
            return .white
        case .success:
            return .green
        case .error:
            return .red
        case .warning:
            return .yellow
        case .info:
            return .cyan
        }
    }
}

#Preview {
    GameView()
}

