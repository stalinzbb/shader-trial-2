//
//  AchievementFireworksView.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/10/25.
//

import SwiftUI

struct AchievementFireworksView: View {
    let achievement: Achievement
    @Environment(\.presentationMode) var presentationMode
    @State private var rotationAngle: Double = 0
    @State private var bounceOffset: CGFloat = 0
    @State private var badgeScale: CGFloat = 1.0
    @State private var badgeRotation: CGFloat = 0
    @State private var isDragging = false
    @State private var isPressed = false
    
    // Fireworks animation states
    @State private var fireworksActive = false
    @State private var fireworksStartTime: TimeInterval = 0
    @State private var fireworksIntensity: Float = 0.0
    @State private var fireworksParticles: [FireworkParticle] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Canvas fireworks background
            ZStack {
                // Dark background for fireworks visibility
                Rectangle()
                    .fill(Color.black.opacity(0.9))
                    .frame(height: 320)
                
                // Canvas fireworks background (behind badge)
                TimelineView(.animation) { context in
                    Canvas { canvasContext, size in
                        drawFireworks(
                            context: canvasContext,
                            size: size,
                            time: context.date.timeIntervalSince1970 - fireworksStartTime,
                            intensity: fireworksActive ? fireworksIntensity : 0.0,
                            particles: fireworksParticles
                        )
                    }
                    .frame(height: 320)
                    .clipped()
                }
                .allowsHitTesting(false) // Ensure fireworks don't block badge interactions
                
                VStack {
                    Spacer()
                    
                    // Interactive Animated Badge (on top of fireworks)
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
                        
                        // Badge with 3D animations
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
                        .foregroundColor(.white)
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
                                .foregroundColor(.white.opacity(0.7))
                            Text("Locked")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .fontWeight(.medium)
                        }
                    }
                }
                
                // Button to trigger fireworks
                Button(action: {
                    triggerFireworks()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Celebrate!")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [achievement.primaryColor, achievement.secondaryColor]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: achievement.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(fireworksActive)
                .opacity(fireworksActive ? 0.6 : 1.0)
                
                Spacer()
            }
            .padding(.top, 30)
            .background(Color.black.opacity(0.95))
        }
        .background(Color.black.opacity(0.95))
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
        withAnimation(
            .easeIn(duration: 0.3).speed(1.2)
            .delay(0.2)
        ) {
            rotationAngle = 120
        }
        
        withAnimation(
            .linear(duration: 0.25)
            .delay(0.5)
        ) {
            rotationAngle = 240
        }
        
        withAnimation(
            .easeOut(duration: 0.35).speed(1.2)
            .delay(0.75)
        ) {
            rotationAngle = 360
        }
    }
    
    private func triggerFireworks() {
        fireworksActive = true
        fireworksStartTime = Date().timeIntervalSince1970
        
        // Generate firework particles
        generateFireworkParticles()
        
        // Animate intensity for dramatic effect
        withAnimation(.easeIn(duration: 0.2)) {
            fireworksIntensity = 1.0
        }
        
        // Fade out intensity gradually
        withAnimation(.easeOut(duration: 2.5).delay(0.5)) {
            fireworksIntensity = 0.2
        }
        
        // Auto-disable after animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            fireworksActive = false
            fireworksIntensity = 0.0
            fireworksParticles.removeAll()
        }
    }
    
    private func generateFireworkParticles() {
        fireworksParticles.removeAll()
        
        // Generate multiple firework explosions
        for explosionIndex in 0..<5 {
            let centerX = Double.random(in: 0.2...0.8)
            let centerY = Double.random(in: 0.3...0.7)
            let explosionColor = [Color.red, Color.blue, Color.green, Color.yellow, Color.purple].randomElement() ?? Color.red
            let delay = Double(explosionIndex) * 0.3
            
            // Generate particles for this explosion
            for particleIndex in 0..<75 {
                let angle = Double.random(in: 0...(2 * Double.pi))
                let speed = Double.random(in: 0.3...0.8)
                let life = Double.random(in: 2.0...4.0)
                
                let particle = FireworkParticle(
                    id: explosionIndex * 100 + particleIndex,
                    startX: centerX,
                    startY: centerY,
                    velocityX: cos(angle) * speed,
                    velocityY: sin(angle) * speed,
                    color: explosionColor,
                    life: life,
                    delay: delay
                )
                
                fireworksParticles.append(particle)
            }
        }
    }
    
    private func drawFireworks(context: GraphicsContext, size: CGSize, time: Double, intensity: Float, particles: [FireworkParticle]) {
        // Always draw something for debugging - even when not active, show static particles
        if !fireworksActive || intensity <= 0 {
            // Draw debug indicator
            context.fill(
                Path(CGRect(x: 10, y: 10, width: 20, height: 20)),
                with: .color(.white.opacity(0.5))
            )
            return
        }
        
        // Draw debug info
        context.fill(
            Path(CGRect(x: size.width - 50, y: 10, width: 40, height: 20)),
            with: .color(.green)
        )
        
        for particle in particles {
            let particleTime = max(0, time - particle.delay)
            guard particleTime < particle.life else { continue }
            
            // Calculate particle position
            let progress = particleTime / particle.life
            let x = particle.startX + particle.velocityX * particleTime * 0.5 // slower movement
            let y = particle.startY + particle.velocityY * particleTime * 0.5 + 0.1 * particleTime * particleTime // less gravity
            
            // Ensure particles stay within bounds
            guard x >= 0 && x <= 1 && y >= 0 && y <= 1 else { continue }
            
            // Calculate opacity (fade out over time) - much brighter
            let opacity = min(1.0, (1.0 - progress * 0.8) * Double(intensity) * 3.0)
            guard opacity > 0.05 else { continue }
            
            // Draw particle
            let pixelX = x * size.width
            let pixelY = y * size.height
            
            let particleSize = (1.0 - progress * 0.3) * 6.0 // even larger particles
            let rect = CGRect(
                x: pixelX - particleSize / 2,
                y: pixelY - particleSize / 2,
                width: particleSize,
                height: particleSize
            )
            
            // Draw main particle with full opacity
            context.fill(
                Path(ellipseIn: rect),
                with: .color(particle.color.opacity(opacity))
            )
            
            // Add bright glow effect
            let glowSize = particleSize * 1.8
            let glowRect = CGRect(
                x: pixelX - glowSize / 2,
                y: pixelY - glowSize / 2,
                width: glowSize,
                height: glowSize
            )
            context.fill(
                Path(ellipseIn: glowRect),
                with: .color(particle.color.opacity(opacity * 0.4))
            )
        }
    }
}

// Firework particle data structure
struct FireworkParticle: Identifiable {
    let id: Int
    let startX: Double
    let startY: Double
    let velocityX: Double
    let velocityY: Double
    let color: Color
    let life: Double
    let delay: Double
}


#Preview {
    AchievementFireworksView(achievement: Achievement(
        title: "Achievement Fireworks",
        description: "Tap the button to celebrate with fireworks!",
        badgeImageName: "achievement-badge-1",
        isUnlocked: true,
        progress: 1.0,
        primaryColor: .blue,
        secondaryColor: .cyan
    ))
}