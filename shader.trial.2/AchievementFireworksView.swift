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
    @State private var fireworkParticles: [FireworkParticle] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with basic background color and fireworks effects
            ZStack {
                Color(hex: "e9ebed")
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
                        
                        // Badge with fireworks overlay
                        TimelineView(.animation) { context in
                            ZStack {
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
                                
                                // Canvas-based fireworks overlay
                                if fireworksActive {
                                    FireworksOverlay(
                                        particles: fireworkParticles,
                                        currentTime: context.date.timeIntervalSince1970,
                                        startTime: fireworksStartTime,
                                        achievement: achievement
                                    )
                                }
                            }
                        }
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
        createFireworkParticles()
        
        // Auto-disable after animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            fireworksActive = false
            fireworkParticles.removeAll()
        }
    }
    
    private func createFireworkParticles() {
        fireworkParticles.removeAll()
        
        // Create multiple firework bursts
        for burst in 0..<3 {
            let burstDelay = Double(burst) * 0.3
            let burstCenter = CGPoint(
                x: CGFloat.random(in: -30...30),
                y: CGFloat.random(in: -40...40)
            )
            
            // Create particles for this burst
            for _ in 0..<25 {
                let particle = FireworkParticle(
                    startPosition: burstCenter,
                    velocity: CGPoint(
                        x: CGFloat.random(in: -150...150),
                        y: CGFloat.random(in: (-200)...(-50))
                    ),
                    color: [achievement.primaryColor, achievement.secondaryColor, .yellow, .orange, .red].randomElement()!,
                    startDelay: burstDelay
                )
                fireworkParticles.append(particle)
            }
        }
    }
}

struct FireworkParticle: Identifiable {
    let id = UUID()
    let startPosition: CGPoint
    let velocity: CGPoint
    let color: Color
    let startDelay: TimeInterval
    let gravity: CGFloat = 300
    let lifetime: TimeInterval = 2.5
}

struct FireworksOverlay: View {
    let particles: [FireworkParticle]
    let currentTime: TimeInterval
    let startTime: TimeInterval
    let achievement: Achievement
    
    var body: some View {
        Canvas { context, size in
            let elapsedTime = currentTime - startTime
            
            for particle in particles {
                let particleAge = elapsedTime - particle.startDelay
                
                if particleAge > 0 && particleAge < particle.lifetime {
                    let progress = particleAge / particle.lifetime
                    
                    // Physics simulation
                    let x = particle.startPosition.x + particle.velocity.x * CGFloat(particleAge)
                    let y = particle.startPosition.y + particle.velocity.y * CGFloat(particleAge) + 0.5 * particle.gravity * CGFloat(particleAge * particleAge)
                    
                    let position = CGPoint(
                        x: size.width / 2 + x,
                        y: size.height / 2 + y
                    )
                    
                    // Fade out over time
                    let alpha = 1.0 - CGFloat(progress)
                    let particleSize = CGFloat(6 - progress * 4)
                    
                    // Draw particle
                    let rect = CGRect(
                        x: position.x - particleSize / 2,
                        y: position.y - particleSize / 2,
                        width: particleSize,
                        height: particleSize
                    )
                    
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(particle.color.opacity(alpha))
                    )
                    
                    // Add glow effect for the first half of lifetime
                    if progress < 0.5 {
                        let glowSize = particleSize * 2
                        let glowRect = CGRect(
                            x: position.x - glowSize / 2,
                            y: position.y - glowSize / 2,
                            width: glowSize,
                            height: glowSize
                        )
                        
                        context.fill(
                            Path(ellipseIn: glowRect),
                            with: .color(particle.color.opacity(alpha * 0.3))
                        )
                    }
                }
            }
        }
        .frame(width: 300, height: 300)
        .allowsHitTesting(false)
    }
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