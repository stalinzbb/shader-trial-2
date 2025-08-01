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
    @State private var noisePhase: CGFloat = 0
    @State private var wavePhase: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var bounceOffset: CGFloat = 0
    @State private var badgeScale: CGFloat = 1.0
    @State private var turbulenceIntensity: CGFloat = 0
    @State private var lightingOffset: CGFloat = 0
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with animated noisy gradient background and ripple effects
            ZStack {
                RippleHeaderView(
                    noisePhase: noisePhase,
                    wavePhase: wavePhase,
                    achievement: achievement,
                    turbulenceIntensity: turbulenceIntensity
                )
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
                        
                        Image(achievement.badgeImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 140, height: 140)
                            .opacity(1.0)
                            .saturation(1.0)
                            .scaleEffect(badgeScale)
                            .rotation3DEffect(
                                .degrees(rotationAngle),
                                axis: (x: 0, y: 1, z: 0),
                                perspective: 0.3
                            )
                            .offset(y: bounceOffset)
                            .offset(x: lightingOffset * 2, y: lightingOffset)
                            .brightness(isPressed ? 0.1 : 0)
                            .contrast(isPressed ? 1.1 : 1.0)
                            .onTapGesture {
                                triggerTurbulence()
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        if !isPressed {
                                            triggerTurbulence()
                                        }
                                    }
                                    .onEnded { _ in
                                        releaseTurbulence()
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
                        .foregroundColor(.black)
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
                            .foregroundColor(.black)
                        
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
            .background(Color.white)
        }
        .onAppear {
            startAnimations()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .ignoresSafeArea(edges: .top)
    }
    
    private func startAnimations() {
        // Continuous noise animation
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            noisePhase = 2 * .pi
        }
        
        // Continuous wave animation
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            wavePhase = 2 * .pi
        }
        
        // Smooth, natural rotation with easing
        withAnimation(
            .easeInOut(duration: 1.8)
            .delay(0.4)
        ) {
            rotationAngle = 360
        }
        
        // Synchronized natural bounce and scale (no delay, starts with rotation)
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
    
    private func triggerTurbulence() {
        guard !isPressed else { return }
        isPressed = true
        
        withAnimation(.easeOut(duration: 0.15)) {
            turbulenceIntensity = 1.0
            badgeScale = 0.95
            lightingOffset = 2.0
        }
    }
    
    private func releaseTurbulence() {
        guard isPressed else { return }
        isPressed = false
        
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 20, initialVelocity: 5)) {
            turbulenceIntensity = 0
            badgeScale = 1.0
            lightingOffset = 0
        }
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