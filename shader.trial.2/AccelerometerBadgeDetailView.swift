//
//  AccelerometerBadgeDetailView.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/7/25.
//

import SwiftUI

struct AccelerometerBadgeDetailView: View {
    let achievement: Achievement
    @Environment(\.presentationMode) var presentationMode
    @State private var rotationAngle: Double = 0
    @State private var bounceOffset: CGFloat = 0
    @State private var badgeScale: CGFloat = 1.0
    @State private var badgeRotation: CGFloat = 0
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with static background
            ZStack {
                Color(hex: "e9ebed")
                    .frame(height: 320)
                    .clipped()
                
                VStack {
                    Spacer()
                    
                    // Interactive Animated Badge (no ripple effects)
                    ZStack {
                        // Subtle glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        achievement.primaryColor.opacity(0.3),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .blur(radius: 20)
                            .opacity(0.4)
                        
                        Image(achievement.badgeImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 140, height: 140)
                            .opacity(1.0)
                            .saturation(1.0)
                            .scaleEffect(badgeScale)
                            .rotation3DEffect(
                                .degrees(rotationAngle + badgeRotation),
                                axis: (x: 0, y: 1, z: 0),
                                perspective: 0.3
                            )
                            .offset(y: bounceOffset)
                            .gesture(
                                DragGesture(minimumDistance: 5)
                                    .onChanged { value in
                                        if !isDragging {
                                            isDragging = true
                                        }
                                        handleNaturalRotation(value: value)
                                    }
                                    .onEnded { value in
                                        isDragging = false
                                        snapToNearestFace(value: value)
                                    }
                            )
                    }
                    
                    Spacer()
                }
            }
            
            // Content Section
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(achievement.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.appText)
                        .multilineTextAlignment(.center)
                    
                    if achievement.isUnlocked {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Unlocked")
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    } else {
                        HStack {
                            Image(systemName: "lock.circle.fill")
                                .foregroundColor(.gray)
                            Text("Locked")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Text(achievement.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                if !achievement.isUnlocked && achievement.progress > 0 {
                    VStack(spacing: 8) {
                        Text("Progress")
                            .font(.headline)
                            .foregroundColor(.appText)
                        
                        ProgressView(value: achievement.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .tint(.purple)
                            .scaleEffect(y: 2)
                        
                        Text("\(Int(achievement.progress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 30)
                }
                
                Spacer()
            }
            .padding(.top, 30)
            .background(Color.appBackground)
        }
        .background(Color.appBackground)
        .onAppear {
            startAnimations()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
        .ignoresSafeArea()
    }
    
    private func startAnimations() {
        // Smooth, natural rotation with easing
        withAnimation(
            .easeInOut(duration: 1.8)
            .delay(0.4)
        ) {
            rotationAngle = 360
        }
        
        // Synchronized natural bounce and scale
        withAnimation(
            .interpolatingSpring(stiffness: 120, damping: 15, initialVelocity: 2)
            .delay(0.4)
        ) {
            bounceOffset = -18
            badgeScale = 1.05
        }
        
        // Smooth settle back to natural position
        withAnimation(
            .interpolatingSpring(stiffness: 180, damping: 20, initialVelocity: 1)
            .delay(1.0)
        ) {
            bounceOffset = 0
            badgeScale = 1.0
        }
    }
    
    private func handleNaturalRotation(value: DragGesture.Value) {
        let dragDistance = value.translation.width
        let dragVelocity = value.velocity.width
        
        // Reduced sensitivity to prevent excessive rotation
        let baseSensitivity: CGFloat = 0.6
        let maxVelocityInfluence: CGFloat = 1.5
        let velocityFactor = min(abs(dragVelocity) / 800.0, maxVelocityInfluence)
        let dynamicSensitivity = baseSensitivity * (0.4 + velocityFactor * 0.3)
        
        // Calculate rotation with natural feel and speed limiting
        let rawRotation = dragDistance * dynamicSensitivity
        
        // Limit maximum rotation to prevent multiple spins during drag
        let maxRotationDuringDrag: CGFloat = 180
        let targetRotation = max(-maxRotationDuringDrag, min(maxRotationDuringDrag, rawRotation))
        
        // Natural springy animation that responds to drag characteristics
        let dragIntensity = min(abs(dragVelocity) / 400.0, 1.0)
        let springResponse = 0.3 + (dragIntensity * 0.2)
        let springDamping = 0.65 + (dragIntensity * 0.15)
        
        withAnimation(.interactiveSpring(
            response: springResponse,
            dampingFraction: springDamping,
            blendDuration: 0.08
        )) {
            badgeRotation = targetRotation
        }
    }
    
    private func snapToNearestFace(value: DragGesture.Value) {
        let currentRotation = badgeRotation
        let velocity = value.velocity.width
        
        // More conservative velocity threshold to prevent excessive spinning
        let velocityInfluence = velocity / 25.0
        let rotationThreshold: CGFloat = 60
        let velocityThreshold: CGFloat = 12
        
        let shouldCompleteRotation = abs(velocityInfluence) > velocityThreshold && abs(currentRotation) > rotationThreshold
        
        let finalTarget: CGFloat
        if shouldCompleteRotation {
            // Complete rotation in direction of momentum, but limit to single rotation
            finalTarget = currentRotation > 0 ? 360 : -360
        } else {
            // Gentle snap back to face-forward with natural spring
            finalTarget = 0
        }
        
        // Natural springy snap-back animation
        let springStiffness = shouldCompleteRotation ? 200.0 : 180.0
        let springDamping = shouldCompleteRotation ? 22.0 : 18.0
        let initialVel = shouldCompleteRotation ? Double(velocity / 150) : Double(velocity / 200)
        
        withAnimation(
            .interpolatingSpring(
                stiffness: springStiffness,
                damping: springDamping,
                initialVelocity: initialVel
            )
        ) {
            badgeRotation = finalTarget
        }
        
        // If completed full rotation, gentle spring back to face-forward
        if shouldCompleteRotation {
            withAnimation(
                .interpolatingSpring(
                    stiffness: 120,
                    damping: 15,
                    initialVelocity: 0
                ).delay(0.4)
            ) {
                badgeRotation = 0
            }
        }
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    AccelerometerBadgeDetailView(achievement: Achievement(
        title: "First Steps",
        description: "Complete your first task to begin your journey",
        badgeImageName: "achievement-badge-1",
        isUnlocked: true,
        progress: 1.0,
        primaryColor: .blue,
        secondaryColor: .cyan
    ))
}