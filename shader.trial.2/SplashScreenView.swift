//
//  SplashScreenView.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 7/23/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var showHomeScreen = false
    @State private var splashOffset: CGFloat = 0
    @State private var logoOffset: CGFloat = 0
    @State private var homeScreenOffset: CGFloat = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            // HomeScreen with slide-in animation from right
            if showHomeScreen {
                HomeScreenView()
                    .offset(x: homeScreenOffset)
            }
            
            // Splash screen with slide-out animation
            if !showHomeScreen || splashOffset <= UIScreen.main.bounds.width {
                ZStack {
                    // Purple gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "3d079a"),
                            Color(hex: "7308ff")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    .offset(x: splashOffset)
                    
                    // Centered splash logo with parallax effect
                    VStack {
                        Spacer()
                        Image("splash-s")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                        Spacer()
                    }
                    .offset(x: logoOffset)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        // Start logo parallax animation first - smoother spring animation
                        withAnimation(.interpolatingSpring(stiffness: 100, damping: 20, initialVelocity: 0)) {
                            logoOffset = -UIScreen.main.bounds.width * 0.2
                        }
                        
                        // Start main transition after logo begins moving
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showHomeScreen = true
                            
                            // Splash screen slides out with quicker, smoother easing
                            withAnimation(.easeInOut(duration: 0.6).speed(1.2)) {
                                splashOffset = -UIScreen.main.bounds.width
                                logoOffset = -UIScreen.main.bounds.width
                            }
                            
                            // HomeScreen slides in from right - starts immediately (no delay)
                            withAnimation(.easeOut(duration: 0.6)) {
                                homeScreenOffset = 0
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}