//
//  Project: GameKitDemo
//  File: ContentView.swift
//  Created by Noah Carpenter
//  🐱 Follow me on YouTube! 🎥
//  https://www.youtube.com/@NoahDoesCoding97
//  Like and Subscribe for coding tutorials and fun! 💻✨
//  Fun Fact: Cats have five toes on their front paws, but only four on their back paws! 🐾
//  Dream Big, Code Bigger

import SwiftUI

struct ContentView: View {
    @AppStorage("cookieCount") private var cookieCount: Int = 0
    private let achievementManager = AchievementManager()

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height) * 0.6

            VStack(spacing: 24) {
                Text("Total Clicks: \(cookieCount)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 16)

                Button(action: { cookieCount += 1 }) {
                    Image(systemName: "gamecontroller.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .foregroundStyle(Color.indigo)
                        .shadow(radius: 8)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                HStack(spacing: 16) {
                    Button {
                        GameCenterManager.shared.showLeaderboards()
                    } label: {
                        Label("Leaderboards", systemImage: "list.number")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        GameCenterManager.shared.showAchievements()
                    } label: {
                        Label("Achievements", systemImage: "rosette")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: cookieCount) {
                achievementManager.evaluate(count: cookieCount)
            }
        }
        .ignoresSafeArea(edges: [])
        .padding()
        .onAppear { GameCenterManager.shared.authenticate() }
    }
}

#Preview {
    ContentView()
}
