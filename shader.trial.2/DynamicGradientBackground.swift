//
//  DynamicGradientBackground.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/7/25.
//

import SwiftUI

struct DynamicGradientBackground: View {
    let achievement: Achievement
    @State private var extractedColors: [Color] = []
    @State private var animationTime: TimeInterval = 0
    
    var body: some View {
        TimelineView(.animation) { context in
            let currentTime = context.date.timeIntervalSince1970
            
            // Use extracted colors or defaults
            let colors = extractedColors.isEmpty ? defaultColors() : extractedColors
            
            // Ensure we have at least 3 colors for gradient
            let safeColors = Array((colors + defaultColors()).prefix(6))
            
            ZStack {
                // Base gradient background
                LinearGradient(
                    gradient: Gradient(colors: safeColors.prefix(3).map { $0 }),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Animated overlays for movement effect
                ForEach(0..<3, id: \.self) { index in
                    let timeOffset = currentTime * 0.3 + Double(index) * 0.8
                    
                    RadialGradient(
                        gradient: Gradient(colors: [
                            safeColors[index + 1].opacity(0.4),
                            Color.clear
                        ]),
                        center: UnitPoint(
                            x: 0.5 + 0.3 * cos(timeOffset),
                            y: 0.5 + 0.3 * sin(timeOffset * 1.2)
                        ),
                        startRadius: 0,
                        endRadius: 200
                    )
                }
                
                // Additional flowing gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        safeColors[4].opacity(0.2),
                        Color.clear,
                        safeColors[5].opacity(0.15),
                        Color.clear
                    ]),
                    startPoint: UnitPoint(
                        x: 0.5 + 0.4 * cos(currentTime * 0.4),
                        y: 0.5 + 0.4 * sin(currentTime * 0.6)
                    ),
                    endPoint: UnitPoint(
                        x: 0.5 - 0.4 * cos(currentTime * 0.4),
                        y: 0.5 - 0.4 * sin(currentTime * 0.6)
                    )
                )
            }
            .blur(radius: 8)
            .clipped()
        }
        .onAppear {
            extractColorsFromBadge()
        }
    }
    
    private func extractColorsFromBadge() {
        let colors = ColorExtractor.extractColors(from: achievement.badgeImageName)
        
        // Add some variation based on achievement properties for uniqueness
        let enhancedColors = colors.map { color in
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0
            
            UIColor(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            
            // Slightly adjust based on achievement title hash for uniqueness
            let titleHash = CGFloat(achievement.title.hash % 100) / 100.0
            let adjustedHue = hue + (titleHash - 0.5) * 0.1
            let adjustedSat = max(0, min(1, saturation + (titleHash - 0.5) * 0.2))
            let adjustedBrightness = max(0, min(1, brightness + (titleHash - 0.5) * 0.15))
            
            return Color(hue: adjustedHue, saturation: adjustedSat, brightness: adjustedBrightness, opacity: alpha)
        }
        
        extractedColors = enhancedColors
    }
    
    private func defaultColors() -> [Color] {
        return [
            Color.blue.opacity(0.3),
            Color.purple.opacity(0.25),
            Color.cyan.opacity(0.35),
            Color.indigo.opacity(0.28),
            Color.teal.opacity(0.32),
            Color.mint.opacity(0.26)
        ]
    }
}

#Preview {
    DynamicGradientBackground(achievement: Achievement(
        title: "First Steps",
        description: "Complete your first task",
        badgeImageName: "achievement-badge-1",
        isUnlocked: true,
        progress: 1.0,
        primaryColor: .blue,
        secondaryColor: .cyan
    ))
    .frame(height: 320)
}