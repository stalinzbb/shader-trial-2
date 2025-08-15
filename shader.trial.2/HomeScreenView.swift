//
//  HomeScreenView.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 7/23/25.
//

import SwiftUI

struct HomeScreenView: View {
    @State private var showAchievements = false
    @State private var showAccelerometer = false
    @State private var showFireworks = false
    @State private var showChecklistProgress = false
    @State private var viewAppearanceID = UUID()
    
    var body: some View {
        NavigationView {
            ZStack {
                // White background
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 8) {
                        Text("Interaction Explorer")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                        
                        Text("Checkout our interactions")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 20)
                    
                    // Cards Section
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Ripple Effect Card
                            RippleEffectCard(
                                title: "Ripple Effect",
                                viewAppearanceID: viewAppearanceID
                            ) {
                                showAchievements = true
                            }
                            
                            // 3D Accelerometer Card
                            AccelerometerCard(
                                title: "3D Accelerometer",
                                viewAppearanceID: viewAppearanceID
                            ) {
                                showAccelerometer = true
                            }
                            
                            // Fireworks Effect Card
                            FireworksEffectCard(
                                title: "Fireworks Effect",
                                viewAppearanceID: viewAppearanceID
                            ) {
                                showFireworks = true
                            }
                            
                            // Checklist Progress Card
                            ChecklistProgressCard(
                                title: "Checklist Progress",
                                viewAppearanceID: viewAppearanceID
                            ) {
                                showChecklistProgress = true
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Regenerate viewAppearanceID to force animation replay
            viewAppearanceID = UUID()
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
        }
        .onChange(of: showAchievements) { _, newValue in
            if !newValue {
                // When sheet is dismissed, regenerate ID to replay animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewAppearanceID = UUID()
                }
            }
        }
        .sheet(isPresented: $showAccelerometer) {
            AccelerometerView()
        }
        .onChange(of: showAccelerometer) { _, newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewAppearanceID = UUID()
                }
            }
        }
        .sheet(isPresented: $showFireworks) {
            AchievementsFireworksView()
        }
        .onChange(of: showFireworks) { _, newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewAppearanceID = UUID()
                }
            }
        }
        .sheet(isPresented: $showChecklistProgress) {
            ChecklistProgressView()
        }
        .onChange(of: showChecklistProgress) { _, newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewAppearanceID = UUID()
                }
            }
        }
    }
}

struct ChecklistProgressCard: View {
    let title: String
    let viewAppearanceID: UUID
    let action: () -> Void
    @State private var isPressed = false
    @State private var progress: Double = 0.0
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Progress Indicator Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                            .frame(width: 40, height: 40)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: progress)
                        
                        Text("6/12")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                
                // Title
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Caret
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            // Reset animation state
            progress = 0.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                progress = 0.5 // 6/12 = 0.5
            }
        }
        .onChange(of: viewAppearanceID) { _, _ in
            // Reset and replay animation when viewAppearanceID changes
            progress = 0.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                progress = 0.5 // 6/12 = 0.5
            }
        }
    }
}

struct InteractionCard: View {
    let title: String
    let thumbnailImageName: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(thumbnailImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                }
                
                // Title
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Caret
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// Animated Card Components
struct AccelerometerCard: View {
    let title: String
    let viewAppearanceID: UUID
    let action: () -> Void
    @State private var isPressed = false
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 3D Wiggling Badge Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image("achievement-badge-3")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .rotation3DEffect(.degrees(rotationX), axis: (x: 1, y: 0, z: 0))
                        .rotation3DEffect(.degrees(rotationY), axis: (x: 0, y: 1, z: 0))
                }
                
                // Title
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Caret
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            // Reset animation state
            rotationX = 0
            rotationY = 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    rotationX = 15
                    rotationY = 15
                }
            }
        }
        .onChange(of: viewAppearanceID) { _, _ in
            // Reset and replay animation when viewAppearanceID changes
            rotationX = 0
            rotationY = 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    rotationX = 15
                    rotationY = 15
                }
            }
        }
    }
}

struct RippleEffectCard: View {
    let title: String
    let viewAppearanceID: UUID
    let action: () -> Void
    @State private var isPressed = false
    @State private var ripple1Scale: CGFloat = 0
    @State private var ripple1Opacity: Double = 0
    @State private var ripple2Scale: CGFloat = 0
    @State private var ripple2Opacity: Double = 0
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Ripple Badge Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    ZStack {
                        Image("achievement-badge-1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                        
                        // Ripple 1
                        Circle()
                            .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                            .frame(width: 35, height: 35)
                            .scaleEffect(ripple1Scale)
                            .opacity(ripple1Opacity)
                        
                        // Ripple 2
                        Circle()
                            .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                            .frame(width: 35, height: 35)
                            .scaleEffect(ripple2Scale)
                            .opacity(ripple2Opacity)
                    }
                }
                
                // Title
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Caret
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            // Reset animation state
            ripple1Scale = 0
            ripple1Opacity = 0
            ripple2Scale = 0
            ripple2Opacity = 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // First ripple
                withAnimation(.easeOut(duration: 1.0)) {
                    ripple1Scale = 1.5
                    ripple1Opacity = 1.0
                }
                withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                    ripple1Opacity = 0
                }
                
                // Second ripple with delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 1.0)) {
                        ripple2Scale = 1.5
                        ripple2Opacity = 1.0
                    }
                    withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                        ripple2Opacity = 0
                    }
                }
            }
        }
        .onChange(of: viewAppearanceID) { _, _ in
            // Reset and replay animation when viewAppearanceID changes
            ripple1Scale = 0
            ripple1Opacity = 0
            ripple2Scale = 0
            ripple2Opacity = 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // First ripple
                withAnimation(.easeOut(duration: 1.0)) {
                    ripple1Scale = 1.5
                    ripple1Opacity = 1.0
                }
                withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                    ripple1Opacity = 0
                }
                
                // Second ripple with delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 1.0)) {
                        ripple2Scale = 1.5
                        ripple2Opacity = 1.0
                    }
                    withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                        ripple2Opacity = 0
                    }
                }
            }
        }
    }
}

struct FireworksEffectCard: View {
    let title: String
    let viewAppearanceID: UUID
    let action: () -> Void
    @State private var isPressed = false
    @State private var showFireworks = false
    @State private var particleOffsets: [(CGFloat, CGFloat)] = []
    @State private var particleOpacities: [Double] = []
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Fireworks Badge Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    ZStack {
                        Image("achievement-badge-5")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                        
                        if showFireworks {
                            ForEach(0..<8, id: \.self) { index in
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 3, height: 3)
                                    .offset(x: particleOffsets.count > index ? particleOffsets[index].0 : 0,
                                           y: particleOffsets.count > index ? particleOffsets[index].1 : 0)
                                    .opacity(particleOpacities.count > index ? particleOpacities[index] : 0)
                            }
                        }
                    }
                }
                
                // Title
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Caret
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            // Reset animation state
            showFireworks = false
            particleOffsets = []
            particleOpacities = []
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showFireworks = true
                
                // Initialize particle positions and opacities
                particleOffsets = (0..<8).map { i in
                    let angle = Double(i) * 45 * .pi / 180
                    return (CGFloat(cos(angle) * 15), CGFloat(sin(angle) * 15))
                }
                particleOpacities = Array(repeating: 1.0, count: 8)
                
                // Animate particles
                withAnimation(.easeOut(duration: 1.0)) {
                    particleOffsets = (0..<8).map { i in
                        let angle = Double(i) * 45 * .pi / 180
                        return (CGFloat(cos(angle) * 25), CGFloat(sin(angle) * 25))
                    }
                }
                
                withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                    particleOpacities = Array(repeating: 0.0, count: 8)
                }
            }
        }
        .onChange(of: viewAppearanceID) { _, _ in
            // Reset and replay animation when viewAppearanceID changes
            showFireworks = false
            particleOffsets = []
            particleOpacities = []
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showFireworks = true
                
                // Initialize particle positions and opacities
                particleOffsets = (0..<8).map { i in
                    let angle = Double(i) * 45 * .pi / 180
                    return (CGFloat(cos(angle) * 15), CGFloat(sin(angle) * 15))
                }
                particleOpacities = Array(repeating: 1.0, count: 8)
                
                // Animate particles
                withAnimation(.easeOut(duration: 1.0)) {
                    particleOffsets = (0..<8).map { i in
                        let angle = Double(i) * 45 * .pi / 180
                        return (CGFloat(cos(angle) * 25), CGFloat(sin(angle) * 25))
                    }
                }
                
                withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                    particleOpacities = Array(repeating: 0.0, count: 8)
                }
            }
        }
    }
}

#Preview {
    HomeScreenView()
}
