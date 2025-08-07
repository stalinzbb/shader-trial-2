//
//  BadgeDetailView.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 7/23/25.
//

import SwiftUI

struct BadgeDetailView: View {
    let achievement: Achievement
    @Environment(\.presentationMode) var presentationMode
    @State private var rotationAngle: Double = 0
    @State private var bounceOffset: CGFloat = 0
    @State private var badgeScale: CGFloat = 1.0
    @State private var badgeRotation: CGFloat = 0
    @State private var isDragging = false
    @State private var isPressed = false
    
    // Metal ripple shader states
    @State private var rippleOrigin: CGPoint = CGPoint(x: 70, y: 70)
    @State private var rippleStartTime: TimeInterval = 0
    @State private var rippleActive = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with animated noisy gradient background and ripple effects
            ZStack {
                DynamicGradientBackground(achievement: achievement)
                .frame(height: 320)
                .clipped()
                
                VStack {
                    Spacer()
                    
                    // Interactive Animated Badge
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
                            .opacity(isPressed ? 0.8 : 0.4)
                        
                        TimelineView(.animation) { context in
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
                                .layerEffect(
                                    ShaderLibrary.Ripple(
                                        .float2(rippleOrigin),
                                        .float(context.date.timeIntervalSince1970 - rippleStartTime),
                                        .float(8.0),      // amplitude
                                        .float(15.0),     // frequency
                                        .float(5.0),      // decay
                                        .float(400.0)     // speed
                                    ),
                                    maxSampleOffset: CGSize(width: 20, height: 20),
                                    isEnabled: rippleActive
                                )
                                .onChange(of: context.date) { _, newDate in
                                    let currentTime = newDate.timeIntervalSince1970
                                    let elapsedTime = currentTime - rippleStartTime
                                    
                                    if rippleActive && elapsedTime < 2.0 {
                                        // Continue ripple animation
                                    } else if elapsedTime >= 2.0 {
                                        rippleActive = false
                                    }
                                }
                        }
                            .onTapGesture { location in
                                triggerRippleEffect(at: location)
                            }
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
        // Faster, more energetic bounce with spring effects
        withAnimation(
            .interpolatingSpring(stiffness: 150, damping: 12, initialVelocity: 4)
            .delay(0.2)
        ) {
            bounceOffset = -44  // Even higher bounce
            badgeScale = 1.08   // More scale
        }
        
        // Faster settle back to natural position with bouncy spring
        withAnimation(
            .interpolatingSpring(stiffness: 180, damping: 16, initialVelocity: 0)
            .delay(0.7)
        ) {
            bounceOffset = 0
            badgeScale = 1.0
        }
        
        // Faster rotation with smooth speed variations
        // Phase 1: Moderately slow start (bottom of bounce)
        withAnimation(
            .easeIn(duration: 0.3).speed(1.2)
            .delay(0.2)
        ) {
            rotationAngle = 120  // First third - moderately slow but faster
        }
        
        // Phase 2: Faster speed (middle to top of bounce)  
        withAnimation(
            .linear(duration: 0.25)
            .delay(0.5)
        ) {
            rotationAngle = 240  // Fast middle section
        }
        
        // Phase 3: Moderately slow finish (back to bottom)
        withAnimation(
            .easeOut(duration: 0.35).speed(1.2)
            .delay(0.75)
        ) {
            rotationAngle = 360  // Moderately slow finish but faster
        }
    }
    
    private func handleNaturalRotation(value: DragGesture.Value) {
        let dragDistance = value.translation.width
        let dragVelocity = value.velocity.width
        
        // Reduced sensitivity to prevent excessive rotation
        let baseSensitivity: CGFloat = 0.6 // Reduced from 1.2
        let maxVelocityInfluence: CGFloat = 1.5 // Cap to prevent super fast rotations
        let velocityFactor = min(abs(dragVelocity) / 800.0, maxVelocityInfluence)
        let dynamicSensitivity = baseSensitivity * (0.4 + velocityFactor * 0.3)
        
        // Calculate rotation with natural feel and speed limiting
        let rawRotation = dragDistance * dynamicSensitivity
        
        // Limit maximum rotation to prevent multiple spins during drag
        let maxRotationDuringDrag: CGFloat = 180 // Max half rotation during drag
        let targetRotation = max(-maxRotationDuringDrag, min(maxRotationDuringDrag, rawRotation))
        
        // Natural springy animation that responds to drag characteristics
        let dragIntensity = min(abs(dragVelocity) / 400.0, 1.0)
        let springResponse = 0.3 + (dragIntensity * 0.2) // More responsive for faster drags
        let springDamping = 0.65 + (dragIntensity * 0.15) // Less bouncy for faster drags
        
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
        let velocityInfluence = velocity / 25.0 // Increased from 15.0
        let rotationThreshold: CGFloat = 60 // Degrees needed to trigger full rotation
        let velocityThreshold: CGFloat = 12 // Increased threshold for full rotation
        
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
        let springStiffness = shouldCompleteRotation ? 200.0 : 180.0 // Softer for direct snap
        let springDamping = shouldCompleteRotation ? 22.0 : 18.0 // More bounce for direct snap
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
    
    private func triggerRippleEffect(at location: CGPoint) {
        // Set ripple origin to tap location relative to badge center
        rippleOrigin = location
        
        // Start ripple animation
        rippleStartTime = Date().timeIntervalSince1970
        rippleActive = true
    }
}

struct NoisyGradientHeader: View {
    let noisePhase: CGFloat
    let wavePhase: CGFloat
    let achievement: Achievement
    let turbulenceIntensity: CGFloat
    
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            
            // Use badge-specific colors
            let primaryColor = achievement.primaryColor
            let secondaryColor = achievement.secondaryColor
            
            // Create subtle gradient variations
            let gradientColors = [
                primaryColor.opacity(0.08),
                secondaryColor.opacity(0.12),
                primaryColor.opacity(0.06),
                secondaryColor.opacity(0.10),
                primaryColor.opacity(0.09)
            ]
            
            let gradient = Gradient(colors: gradientColors)
            
            // Base flowing gradient
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = max(size.width, size.height) * 1.5
            
            let startAngle = wavePhase * 0.6
            let endAngle = wavePhase * 0.6 + .pi * 1.8
            
            let startPoint = CGPoint(
                x: center.x + cos(startAngle) * radius * 0.7,
                y: center.y + sin(startAngle) * radius * 0.5
            )
            
            let endPoint = CGPoint(
                x: center.x + cos(endAngle) * radius * 0.7,
                y: center.y + sin(endAngle) * radius * 0.5
            )
            
            context.fill(
                Path(rect),
                with: .linearGradient(
                    gradient,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
            
            // Add Perlin-like noise layers
            addNoiseLayer(
                context: context,
                size: size,
                color: primaryColor,
                phase: noisePhase,
                frequency: 0.8,
                amplitude: 0.05,
                turbulence: turbulenceIntensity
            )
            
            addNoiseLayer(
                context: context,
                size: size,
                color: secondaryColor,
                phase: noisePhase + .pi / 3,
                frequency: 1.2,
                amplitude: 0.03,
                turbulence: turbulenceIntensity * 0.7
            )
            
            // Flowing wave layers with noise
            let wave1 = createNoisyWavePath(
                size: size,
                amplitude: 25,
                frequency: 1.2,
                phase: wavePhase,
                noisePhase: noisePhase,
                verticalOffset: size.height * 0.25,
                turbulence: turbulenceIntensity
            )
            
            let wave2 = createNoisyWavePath(
                size: size,
                amplitude: 35,
                frequency: 1.8,
                phase: wavePhase + .pi / 2,
                noisePhase: noisePhase + .pi / 4,
                verticalOffset: size.height * 0.65,
                turbulence: turbulenceIntensity * 0.8
            )
            
            context.addFilter(.blur(radius: 8))
            context.fill(wave1, with: .color(primaryColor.opacity(0.06)))
            context.fill(wave2, with: .color(secondaryColor.opacity(0.04)))
        }
        .drawingGroup()
    }
    
    private func addNoiseLayer(context: GraphicsContext, size: CGSize, color: Color, phase: CGFloat, frequency: CGFloat, amplitude: CGFloat, turbulence: CGFloat) {
        let width = size.width
        let height = size.height
        let steps = 40
        
        for i in 0..<steps {
            for j in 0..<steps {
                let x = (CGFloat(i) / CGFloat(steps)) * width
                let y = (CGFloat(j) / CGFloat(steps)) * height
                
                // Generate pseudo-Perlin noise
                let noise1 = sin(x * frequency * 0.02 + phase) * cos(y * frequency * 0.02 + phase)
                let noise2 = sin(x * frequency * 0.04 + phase * 1.3) * cos(y * frequency * 0.04 + phase * 1.3)
                let noise3 = sin(x * frequency * 0.08 + phase * 0.7) * cos(y * frequency * 0.08 + phase * 0.7)
                
                let combinedNoise = (noise1 * 0.5 + noise2 * 0.3 + noise3 * 0.2) * amplitude
                let turbulentNoise = combinedNoise * (1.0 + turbulence * 2.0)
                
                let opacity = abs(turbulentNoise) * 0.8
                
                if opacity > 0.01 {
                    let rect = CGRect(x: x, y: y, width: width / CGFloat(steps), height: height / CGFloat(steps))
                    context.fill(Path(rect), with: .color(color.opacity(opacity)))
                }
            }
        }
    }
    
    private func createNoisyWavePath(size: CGSize, amplitude: CGFloat, frequency: CGFloat, phase: CGFloat, noisePhase: CGFloat, verticalOffset: CGFloat, turbulence: CGFloat) -> Path {
        Path { path in
            let width = size.width
            let height = size.height
            
            path.move(to: CGPoint(x: 0, y: verticalOffset))
            
            for x in stride(from: 0, through: width, by: 1.0) {
                let relativeX = x / width
                
                // Base wave
                let sine = sin((relativeX * frequency * 2 * .pi) + phase)
                let cosine = cos((relativeX * frequency * 1.5 * .pi) + phase * 0.8)
                
                // Add noise to wave
                let noise = sin(relativeX * 8 * .pi + noisePhase) * 0.3
                let turbulentNoise = noise * turbulence * 10
                
                let y = verticalOffset + (sine * amplitude) + (cosine * amplitude * 0.4) + turbulentNoise
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
        }
    }
}

#Preview {
    BadgeDetailView(achievement: Achievement(
        title: "First Steps",
        description: "Complete your first task to begin your journey",
        badgeImageName: "achievement-badge-1",
        isUnlocked: true,
        progress: 1.0,
        primaryColor: .blue,
        secondaryColor: .cyan
    ))
}