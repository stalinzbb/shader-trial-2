//
//  HomeScreenView.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 7/23/25.
//

import SwiftUI

struct HomeScreenView: View {
    @State private var showAchievements = false
    @StateObject private var rippleManager = RippleManager()
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Interactive ripple background
                    TimelineView(.animation) { context in
                        Canvas { canvasContext, size in
                            let currentTime = CACurrentMediaTime()
                            
                            // Draw base gradient
                            let rect = CGRect(origin: .zero, size: size)
                            
                            canvasContext.fill(Path(rect), with: .linearGradient(
                                Gradient(colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.3)
                                ]),
                                startPoint: CGPoint(x: 0, y: 0),
                                endPoint: CGPoint(x: size.width, y: size.height)
                            ))
                            
                            // Draw ripples
                            let activeRipples = rippleManager.activeRipples(at: currentTime)
                            for (ripple, age) in activeRipples {
                                drawHomeRipple(context: canvasContext, size: size, ripple: ripple, age: age)
                            }
                        }
                    }
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        rippleManager.addRipple(at: location, in: geometry.frame(in: .local))
                    }
                
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
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
        }
    }
    
    private func drawHomeRipple(context: GraphicsContext, size: CGSize, ripple: TapRipple, age: TimeInterval) {
        let rippleDuration: TimeInterval = 2.5
        let progress = min(age / rippleDuration, 1.0)
        
        let maxRadius: CGFloat = 150
        let currentRadius = CGFloat(progress) * maxRadius
        
        let center = CGPoint(
            x: ripple.normalizedLocation.x * size.width,
            y: ripple.normalizedLocation.y * size.height
        )
        
        // Enhanced progressive fading with natural water decay
        let fadingCurve = pow(1.0 - CGFloat(progress), 2.2)
        
        // Organic wave distortions
        let waveFrequency: CGFloat = 5.0 + CGFloat(progress) * 1.5
        let waveAmplitude: CGFloat = 12.0 * fadingCurve
        let phase = CGFloat(age) * 3.0
        
        // Enhanced concentric ripples with organic flow
        for i in 0..<4 {
            let ringOffset = CGFloat(i) * (12.0 + CGFloat(progress) * 8.0)
            let ringRadius = currentRadius - ringOffset
            
            if ringRadius > 3 {
                let ringFade = fadingCurve * pow(1.0 - CGFloat(i) * 0.2, 1.8)
                
                let ripplePath = Path { path in
                    let segments = 100
                    let angleStep = 2 * CGFloat.pi / CGFloat(segments)
                    
                    for j in 0...segments {
                        let angle = CGFloat(j) * angleStep
                        
                        // Multi-layered wave distortions for natural water flow
                        let primaryWave = sin(angle * waveFrequency + phase) * waveAmplitude
                        let secondaryWave = sin(angle * (waveFrequency * 0.4) + phase * 1.5) * waveAmplitude * 0.3
                        let organicFlow = cos(angle * 2.0 + phase * 0.7) * waveAmplitude * 0.15
                        
                        let distortedRadius = ringRadius + primaryWave + secondaryWave + organicFlow
                        
                        let x = center.x + cos(angle) * distortedRadius
                        let y = center.y + sin(angle) * distortedRadius
                        
                        if j == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    path.closeSubpath()
                }
                
                // Variable stroke width for depth
                let strokeWidth = 2.2 - CGFloat(i) * 0.3
                
                context.stroke(
                    ripplePath,
                    with: .color(.white.opacity(ringFade * 0.7)),
                    lineWidth: max(strokeWidth, 0.5)
                )
                
                // Subtle fill for water depth effect
                context.fill(
                    ripplePath,
                    with: .color(.cyan.opacity(ringFade * 0.1))
                )
            }
        }
    }
}

#Preview {
    HomeScreenView()
}
