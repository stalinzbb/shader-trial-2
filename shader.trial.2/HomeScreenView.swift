//
//  HomeScreenView.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 7/23/25.
//

import SwiftUI

struct HomeScreenView: View {
    @State private var showAchievements = false
    @State private var showAccelerometer = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // White background
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 8) {
                        Text("Interaction Explorer")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                        
                        Text("Checkout our interactions")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 20)
                    
                    // Cards Section
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Achievements Card
                            InteractionCard(
                                title: "Achievements Ripple Effect",
                                thumbnailImageName: "achievement-badge-1"
                            ) {
                                showAchievements = true
                            }
                            
                            // Accelerometer Card
                            InteractionCard(
                                title: "Achievement Badge 3D Accelerometer",
                                thumbnailImageName: "achievement-badge-3"
                            ) {
                                showAccelerometer = true
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
        }
        .sheet(isPresented: $showAccelerometer) {
            AccelerometerView()
        }
    }
}

struct InteractionCard: View {
    let title: String
    let thumbnailImageName: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(thumbnailImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                }
                
                // Title
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Caret
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    HomeScreenView()
}
