//
//  AccelerometerBadgeDetailView.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/7/25.
//

import SwiftUI
import CoreMotion

struct AccelerometerBadgeDetailView: View {
    let achievement: Achievement
    @Environment(\.presentationMode) var presentationMode
    @State private var pitchRotation: Double = 0
    @State private var rollRotation: Double = 0
    @State private var gradientOffset: Double = -350 // Start off-screen (further back for larger rectangle)
    private let motionManager = CMMotionManager()
    
    // Check if this badge should have gradient shimmer effect (badges 7-12)
    private var shouldShowGradientShimmer: Bool {
        let badgeNumber = Int(achievement.badgeImageName.replacingOccurrences(of: "achievement-badge-", with: "")) ?? 0
        return badgeNumber >= 7 && badgeNumber <= 12
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with badge area - always white background
            ZStack {
                Color.white
                    .frame(height: 320)
                    .clipped()
                
                VStack {
                    Spacer()
                    
                    // Accelerometer-controlled Badge with optional gradient shimmer
                    ZStack {
                        Image(achievement.badgeImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: shouldShowGradientShimmer ? 160 : 140, 
                                   height: shouldShowGradientShimmer ? 160 : 140)
                        
                        // Gradient shimmer overlay for badges 7-12
                        if shouldShowGradientShimmer {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.0),
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.7),
                                            Color.white.opacity(1.0),
                                            Color.white.opacity(0.7),
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.0)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 120, height: 500) // Even larger rectangle to cover entire badge
                                .offset(x: gradientOffset, y: 0) // Move horizontally first
                                .rotationEffect(.degrees(45)) // Then rotate 45 degrees - this creates diagonal movement
                                .blendMode(.overlay)
                                .opacity(0.7)
                                .clipShape(RoundedRectangle(cornerRadius: 80))
                                .frame(width: 160, height: 160)
                        }
                    }
                    .rotation3DEffect(
                        .degrees(pitchRotation),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.3
                    )
                    .rotation3DEffect(
                        .degrees(rollRotation),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.3
                    )
                    
                    Spacer()
                }
            }
            
            // Content Section
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(achievement.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "333333"))
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
                    .foregroundColor(Color(hex: "757575"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                if !achievement.isUnlocked && achievement.progress > 0 {
                    VStack(spacing: 8) {
                        Text("Progress")
                            .font(.headline)
                            .foregroundColor(Color(hex: "757575"))
                        
                        ProgressView(value: achievement.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .tint(.purple)
                            .scaleEffect(y: 2)
                        
                        Text("\(Int(achievement.progress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(Color(hex: "757575"))
                    }
                    .padding(.horizontal, 30)
                }
                
                Spacer()
            }
            .padding(.top, 30)
            .background(Color(hex: "f8f8fa"))
        }
        .background(Color.white)
        .onAppear {
            startAccelerometerUpdates()
        }
        .onDisappear {
            stopAccelerometerUpdates()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
        .ignoresSafeArea()
    }
    
    private func startAccelerometerUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 Hz updates
        
        motionManager.startDeviceMotionUpdates(to: .main) { [self] (motion, error) in
            guard let motion = motion, error == nil else {
                print("Error getting device motion: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Convert pitch and roll from radians to degrees
            let pitchInDegrees = motion.attitude.pitch * 180.0 / .pi
            let rollInDegrees = motion.attitude.roll * 180.0 / .pi
            
            // Clamp values for optimal motion feel
            let clampedPitch = max(-8.0, min(8.0, pitchInDegrees))    // Further reduced pitch movement
            let clampedRoll = max(-45.0, min(45.0, rollInDegrees))    // Increased roll angle by 10°
            
            // Apply different animation speeds for pitch and roll
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                pitchRotation = clampedPitch  // X-axis rotation (tilt up/down)
            }
            
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5, blendDuration: 0)) {
                rollRotation = clampedRoll    // Y-axis rotation (tilt left/right) - faster animation
            }
            
            // Update gradient shimmer effect based on accelerometer data (only for shimmer badges)
            if shouldShowGradientShimmer {
                // Convert combined motion to trigger shimmer flash
                let motionMagnitude = sqrt(clampedPitch * clampedPitch + clampedRoll * clampedRoll)
                
                // Trigger shimmer flash on significant motion (threshold ~15 degrees)
                if motionMagnitude > 15.0 {
                    // Slower diagonal flash across badge at 45°
                    withAnimation(.spring(response: 1.0, dampingFraction: 0.8, blendDuration: 0)) {
                        gradientOffset = 350 // Flash across to opposite corner
                    }
                    
                    // Reset position after flash completes (longer duration)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            gradientOffset = -350 // Reset to starting corner off-screen
                        }
                    }
                } else {
                    // Keep gradient off-screen during subtle movements
                    if gradientOffset > -300 {
                        withAnimation(.easeOut(duration: 0.4)) {
                            gradientOffset = -350
                        }
                    }
                }
            }
        }
    }
    
    private func stopAccelerometerUpdates() {
        motionManager.stopDeviceMotionUpdates()
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