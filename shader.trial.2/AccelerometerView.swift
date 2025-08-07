//
//  AccelerometerView.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/7/25.
//

import SwiftUI

struct AccelerometerView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedAchievement: Achievement?
    
    let achievements = [
        Achievement(title: "First Steps", description: "Complete your first task to begin your journey", badgeImageName: "achievement-badge-1", isUnlocked: true, progress: 1.0, primaryColor: .blue, secondaryColor: .cyan),
        Achievement(title: "Getting Started", description: "Use the app for 3 consecutive days", badgeImageName: "achievement-badge-2", isUnlocked: true, progress: 1.0, primaryColor: .green, secondaryColor: .mint),
        Achievement(title: "Dedicated User", description: "Use the app for 7 days straight without missing a day", badgeImageName: "achievement-badge-3", isUnlocked: false, progress: 0.6, primaryColor: .orange, secondaryColor: .yellow),
        Achievement(title: "Power User", description: "Complete 10 different tasks across various categories", badgeImageName: "achievement-badge-4", isUnlocked: false, progress: 0.3, primaryColor: .red, secondaryColor: .pink),
        Achievement(title: "Master", description: "Reach level 10 by earning experience points", badgeImageName: "achievement-badge-5", isUnlocked: false, progress: 0.0, primaryColor: .purple, secondaryColor: .indigo),
        Achievement(title: "Explorer", description: "Discover and try all available features in the app", badgeImageName: "achievement-badge-6", isUnlocked: false, progress: 0.8, primaryColor: .teal, secondaryColor: .cyan),
        Achievement(title: "Speedster", description: "Complete tasks in record time with efficiency", badgeImageName: "achievement-badge-7", isUnlocked: true, progress: 1.0, primaryColor: .yellow, secondaryColor: .orange),
        Achievement(title: "Collector", description: "Unlock at least 5 different achievements", badgeImageName: "achievement-badge-8", isUnlocked: false, progress: 0.8, primaryColor: .indigo, secondaryColor: .blue),
        Achievement(title: "Perfectionist", description: "Complete all daily tasks for a full week", badgeImageName: "achievement-badge-9", isUnlocked: false, progress: 0.2, primaryColor: .pink, secondaryColor: .red),
        Achievement(title: "Champion", description: "Reach the highest level available in the app", badgeImageName: "achievement-badge-10", isUnlocked: false, progress: 0.1, primaryColor: .mint, secondaryColor: .green),
        Achievement(title: "Legend", description: "Unlock every single achievement available", badgeImageName: "achievement-badge-11", isUnlocked: false, progress: 0.0, primaryColor: .brown, secondaryColor: .orange),
        Achievement(title: "Ultimate", description: "Master all features and become the ultimate user", badgeImageName: "achievement-badge-12", isUnlocked: false, progress: 0.0, primaryColor: .black, secondaryColor: .gray)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        Text("3D Accelerometer Badges")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.appText)
                            .padding(.top, 20)
                        
                        let columns = [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ]
                        
                        LazyVGrid(columns: columns, spacing: 30) {
                            ForEach(achievements, id: \.id) { achievement in
                                AccelerometerBadge(achievement: achievement) {
                                    selectedAchievement = achievement
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.appText)
                }
            }
        }
        .sheet(item: $selectedAchievement) { achievement in
            AccelerometerBadgeDetailView(achievement: achievement)
        }
    }
}

struct AccelerometerBadge: View {
    let achievement: Achievement
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(achievement.badgeImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .opacity(1.0)
                .saturation(1.0)
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.appText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                onTap()
            }
        }
    }
}

#Preview {
    AccelerometerView()
}