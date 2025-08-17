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
    
    // Control parameters
    @State private var maxPitchAngle: Double = 8.0
    @State private var maxRollAngle: Double = 45.0
    @State private var pitchSensitivity: Double = 0.3
    @State private var rollSensitivity: Double = 1.0
    
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
                
                // Centered badge in header
                HStack {
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
                // Achievement Title Only
                Text(achievement.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "333333"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // Motion Controls Section (moved out of card container)
                VStack(spacing: 16) {
                    Text("Motion Controls")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "333333"))
                    
                    VStack(spacing: 12) {
                        // Pitch Angle Control
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Pitch Range")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "333333"))
                                Spacer()
                                Text("±\(String(format: "%.0f", maxPitchAngle))°")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "757575"))
                            }
                            
                            Slider(value: $maxPitchAngle, in: 5...30, step: 1)
                                .accentColor(.purple)
                        }
                        
                        // Roll Angle Control
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Roll Range")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "333333"))
                                Spacer()
                                Text("±\(String(format: "%.0f", maxRollAngle))°")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "757575"))
                            }
                            
                            Slider(value: $maxRollAngle, in: 15...90, step: 5)
                                .accentColor(.purple)
                        }
                        
                        // Animation Speed Controls
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Pitch Response")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "333333"))
                                Spacer()
                                Text("\(String(format: "%.1f", pitchSensitivity))s")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "757575"))
                            }
                            
                            Slider(value: $pitchSensitivity, in: 0.1...1.0, step: 0.1)
                                .accentColor(.purple)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Roll Response")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "333333"))
                                Spacer()
                                Text("\(String(format: "%.1f", rollSensitivity))s")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "757575"))
                            }
                            
                            Slider(value: $rollSensitivity, in: 0.1...2.0, step: 0.1)
                                .accentColor(.purple)
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 10)
                
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
            
            // Clamp values using control parameters
            let clampedPitch = max(-maxPitchAngle, min(maxPitchAngle, pitchInDegrees))
            let clampedRoll = max(-maxRollAngle, min(maxRollAngle, rollInDegrees))
            
            // Apply animation speeds using control parameters
            withAnimation(.spring(response: pitchSensitivity, dampingFraction: 0.6, blendDuration: 0)) {
                pitchRotation = clampedPitch  // X-axis rotation (tilt up/down)
            }
            
            withAnimation(.spring(response: rollSensitivity, dampingFraction: 0.7, blendDuration: 0)) {
                rollRotation = -clampedRoll    // Y-axis rotation (opposite to device tilt left/right)
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