//
//  HomeScreenView.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 7/23/25.
//

import SwiftUI

struct HomeScreenView: View {
    @State private var showAchievements = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.3),
                        Color.purple.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Button(action: {
                        showAchievements = true
                    }) {
                        Text("View Achievements")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.purple,
                                                Color.blue
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                    }
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.1), value: showAchievements)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
        }
    }
}

#Preview {
    HomeScreenView()
}
