//
//  RippleEffect.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/1/25.
//

import SwiftUI
import Foundation

struct TapRipple: Identifiable {
    let id = UUID()
    let location: CGPoint
    let timestamp: TimeInterval
    let normalizedLocation: CGPoint
    
    init(location: CGPoint, normalizedLocation: CGPoint) {
        self.location = location
        self.normalizedLocation = normalizedLocation
        self.timestamp = CACurrentMediaTime()
    }
}

class RippleManager: ObservableObject {
    @Published var ripples: [TapRipple] = []
    private let maxRipples = 5
    private let rippleDuration: TimeInterval = 2.0
    
    func addRipple(at location: CGPoint, in frame: CGRect) {
        let normalizedLocation = CGPoint(
            x: location.x / frame.width,
            y: location.y / frame.height
        )
        
        let ripple = TapRipple(location: location, normalizedLocation: normalizedLocation)
        
        DispatchQueue.main.async {
            self.ripples.append(ripple)
            
            if self.ripples.count > self.maxRipples {
                self.ripples.removeFirst()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + rippleDuration) {
            self.ripples.removeAll { $0.id == ripple.id }
        }
    }
    
    func activeRipples(at currentTime: TimeInterval) -> [(ripple: TapRipple, age: TimeInterval)] {
        return ripples.compactMap { ripple in
            let age = currentTime - ripple.timestamp
            return age <= rippleDuration ? (ripple, age) : nil
        }
    }
}

struct RippleHeaderView: View {
    let noisePhase: CGFloat
    let wavePhase: CGFloat
    let achievement: Achievement
    let turbulenceIntensity: CGFloat
    @StateObject private var rippleManager = RippleManager()
    
    var body: some View {
        GeometryReader { geometry in
            RippleCanvas(
                noisePhase: noisePhase,
                wavePhase: wavePhase,
                achievement: achievement,
                turbulenceIntensity: turbulenceIntensity,
                rippleManager: rippleManager,
                frameSize: geometry.size
            )
            .contentShape(Rectangle())
            .onTapGesture { location in
                rippleManager.addRipple(at: location, in: geometry.frame(in: .local))
            }
        }
    }
}

struct RippleCanvas: View {
    let noisePhase: CGFloat
    let wavePhase: CGFloat
    let achievement: Achievement
    let turbulenceIntensity: CGFloat
    let rippleManager: RippleManager
    let frameSize: CGSize
    
    @State private var animationTime: TimeInterval = 0
    
    var body: some View {
        TimelineView(.animation) { context in
            Canvas { canvasContext, size in
                let currentTime = CACurrentMediaTime()
                
                // Draw base gradient background
                drawBaseGradient(context: canvasContext, size: size)
                
                // Draw noise layers
                drawNoiseLayers(context: canvasContext, size: size)
                
                // Draw wave layers
                drawWaveLayers(context: canvasContext, size: size)
                
                // Draw ripple effects
                drawRipples(context: canvasContext, size: size, currentTime: currentTime)
            }
        }
        .drawingGroup()
    }
    
    private func drawBaseGradient(context: GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        
        let primaryColor = achievement.primaryColor
        let secondaryColor = achievement.secondaryColor
        
        let gradientColors = [
            primaryColor.opacity(0.08),
            secondaryColor.opacity(0.12),
            primaryColor.opacity(0.06),
            secondaryColor.opacity(0.10),
            primaryColor.opacity(0.09)
        ]
        
        let gradient = Gradient(colors: gradientColors)
        
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
    }
    
    private func drawNoiseLayers(context: GraphicsContext, size: CGSize) {
        let primaryColor = achievement.primaryColor
        let secondaryColor = achievement.secondaryColor
        
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
    }
    
    private func drawWaveLayers(context: GraphicsContext, size: CGSize) {
        let primaryColor = achievement.primaryColor
        let secondaryColor = achievement.secondaryColor
        
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
    
    private func drawRipples(context: GraphicsContext, size: CGSize, currentTime: TimeInterval) {
        let activeRipples = rippleManager.activeRipples(at: currentTime)
        
        for (ripple, age) in activeRipples {
            drawSingleRipple(context: context, size: size, ripple: ripple, age: age)
        }
    }
    
    private func drawSingleRipple(context: GraphicsContext, size: CGSize, ripple: TapRipple, age: TimeInterval) {
        let rippleDuration: TimeInterval = 2.0
        let progress = min(age / rippleDuration, 1.0)
        
        // Ripple parameters
        let maxRadius: CGFloat = 150
        let currentRadius = CGFloat(progress) * maxRadius
        
        // Ripple center in actual coordinates
        let center = CGPoint(
            x: ripple.normalizedLocation.x * size.width,
            y: ripple.normalizedLocation.y * size.height
        )
        
        // Create ripple effect using sine wave
        let waveFrequency: CGFloat = 8.0
        let waveAmplitude: CGFloat = 15.0 * (1.0 - CGFloat(progress))
        
        // Multiple concentric ripples
        for i in 0..<3 {
            let ringRadius = currentRadius - CGFloat(i) * 20
            if ringRadius > 0 {
                drawRippleRing(
                    context: context,
                    center: center,
                    radius: ringRadius,
                    waveAmplitude: waveAmplitude * (1.0 - CGFloat(i) * 0.3),
                    waveFrequency: waveFrequency,
                    opacity: (1.0 - CGFloat(progress)) * (1.0 - CGFloat(i) * 0.4),
                    phase: CGFloat(age) * 4.0
                )
            }
        }
    }
    
    private func drawRippleRing(context: GraphicsContext, center: CGPoint, radius: CGFloat, waveAmplitude: CGFloat, waveFrequency: CGFloat, opacity: CGFloat, phase: CGFloat) {
        let path = Path { path in
            let segments = 120
            let angleStep = 2 * CGFloat.pi / CGFloat(segments)
            
            for i in 0...segments {
                let angle = CGFloat(i) * angleStep
                
                // Create sine wave distortion
                let waveValue = sin(angle * waveFrequency + phase) * waveAmplitude
                let distortedRadius = radius + waveValue
                
                let x = center.x + cos(angle) * distortedRadius
                let y = center.y + sin(angle) * distortedRadius
                
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.closeSubpath()
        }
        
        // Create gradient effect for ripple
        let rippleColor = achievement.primaryColor.opacity(opacity * 0.3)
        
        context.stroke(
            path,
            with: .color(rippleColor),
            lineWidth: 2.0
        )
        
        // Add subtle fill for depth
        context.fill(
            path,
            with: .color(achievement.secondaryColor.opacity(opacity * 0.1))
        )
    }
    
    // Helper functions from original NoisyGradientHeader
    private func addNoiseLayer(context: GraphicsContext, size: CGSize, color: Color, phase: CGFloat, frequency: CGFloat, amplitude: CGFloat, turbulence: CGFloat) {
        let width = size.width
        let height = size.height
        let steps = 40
        
        for i in 0..<steps {
            for j in 0..<steps {
                let x = (CGFloat(i) / CGFloat(steps)) * width
                let y = (CGFloat(j) / CGFloat(steps)) * height
                
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
                
                let sine = sin((relativeX * frequency * 2 * .pi) + phase)
                let cosine = cos((relativeX * frequency * 1.5 * .pi) + phase * 0.8)
                
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