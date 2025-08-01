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
                            let gradient = LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
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
        let rippleDuration: TimeInterval = 2.0
        let progress = min(age / rippleDuration, 1.0)
        
        let maxRadius: CGFloat = 120
        let currentRadius = CGFloat(progress) * maxRadius
        
        let center = CGPoint(
            x: ripple.normalizedLocation.x * size.width,
            y: ripple.normalizedLocation.y * size.height
        )
        
        // Simple expanding circle ripple
        let opacity = (1.0 - CGFloat(progress)) * 0.6
        
        for i in 0..<2 {
            let ringRadius = currentRadius - CGFloat(i) * 15
            if ringRadius > 0 {
                let circle = Path { path in
                    path.addEllipse(in: CGRect(
                        x: center.x - ringRadius,
                        y: center.y - ringRadius,
                        width: ringRadius * 2,
                        height: ringRadius * 2
                    ))
                }
                
                context.stroke(
                    circle,
                    with: .color(.white.opacity(opacity * (1.0 - CGFloat(i) * 0.5))),
                    lineWidth: 2.0
                )
            }
        }
    }
}

#Preview {
    HomeScreenView()
}
