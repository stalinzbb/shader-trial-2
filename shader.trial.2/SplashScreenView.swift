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
    
    var body: some View {
        ZStack {
            if showHomeScreen {
                HomeScreenView()
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
                    
                    // Centered splash logo
                    VStack {
                        Spacer()
                        Image("splash-s")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                        Spacer()
                    }
                }
                .offset(x: splashOffset)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            splashOffset = -UIScreen.main.bounds.width
                            showHomeScreen = true
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