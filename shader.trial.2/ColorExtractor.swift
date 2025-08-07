//
//  ColorExtractor.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/7/25.
//

import SwiftUI
import UIKit

class ColorExtractor {
    static func extractColors(from imageName: String) -> [Color] {
        guard let uiImage = UIImage(named: imageName) else {
            return defaultColors()
        }
        
        let dominantColors = extractDominantColors(from: uiImage)
        return createGradientVariations(from: dominantColors)
    }
    
    private static func extractDominantColors(from image: UIImage) -> [UIColor] {
        guard image.cgImage != nil else { return [] }
        
        // Resize image for faster processing
        let size = CGSize(width: 50, height: 50)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        
        guard let resizedCGImage = resizedImage.cgImage,
              let dataProvider = resizedCGImage.dataProvider,
              let pixelData = dataProvider.data else { return [] }
        
        let data = CFDataGetBytePtr(pixelData)
        let bytesPerPixel = 4
        let width = resizedCGImage.width
        let height = resizedCGImage.height
        
        var colorCounts: [String: Int] = [:]
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = ((width * y) + x) * bytesPerPixel
                let r = CGFloat(data?[pixelIndex] ?? 0) / 255.0
                let g = CGFloat(data?[pixelIndex + 1] ?? 0) / 255.0
                let b = CGFloat(data?[pixelIndex + 2] ?? 0) / 255.0
                let a = CGFloat(data?[pixelIndex + 3] ?? 0) / 255.0
                
                // Skip transparent or very dark/light pixels
                if a < 0.5 || (r + g + b) < 0.3 || (r + g + b) > 2.7 { continue }
                
                // Quantize colors to reduce noise
                let quantizedR = round(r * 8) / 8
                let quantizedG = round(g * 8) / 8
                let quantizedB = round(b * 8) / 8
                
                let colorKey = "\(quantizedR)-\(quantizedG)-\(quantizedB)"
                colorCounts[colorKey, default: 0] += 1
            }
        }
        
        // Get top 3-5 most frequent colors
        let sortedColors = colorCounts.sorted { $0.value > $1.value }.prefix(5)
        
        return sortedColors.compactMap { colorString, _ in
            let components = colorString.split(separator: "-").compactMap { Double($0) }
            guard components.count == 3 else { return nil }
            return UIColor(red: components[0], green: components[1], blue: components[2], alpha: 1.0)
        }
    }
    
    private static func createGradientVariations(from colors: [UIColor]) -> [Color] {
        guard !colors.isEmpty else { return defaultColors() }
        
        var gradientColors: [Color] = []
        
        for color in colors {
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0
            
            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            
            // Create variations with moderate opacity for visibility
            let baseOpacity: CGFloat = 0.25
            
            // Original color with low opacity
            gradientColors.append(Color(color).opacity(baseOpacity))
            
            // Lighter variation
            let lighterColor = UIColor(hue: hue,
                                     saturation: max(0, saturation - 0.2),
                                     brightness: min(1, brightness + 0.3),
                                     alpha: 1.0)
            gradientColors.append(Color(lighterColor).opacity(baseOpacity * 0.8))
            
            // Darker variation
            let darkerColor = UIColor(hue: hue,
                                    saturation: min(1, saturation + 0.1),
                                    brightness: max(0, brightness - 0.2),
                                    alpha: 1.0)
            gradientColors.append(Color(darkerColor).opacity(baseOpacity * 1.2))
            
            // Desaturated variation
            let desaturatedColor = UIColor(hue: hue,
                                         saturation: saturation * 0.5,
                                         brightness: brightness,
                                         alpha: 1.0)
            gradientColors.append(Color(desaturatedColor).opacity(baseOpacity * 0.9))
        }
        
        return Array(gradientColors.prefix(8)) // Limit to 8 colors
    }
    
    private static func defaultColors() -> [Color] {
        return [
            Color.blue.opacity(0.3),
            Color.purple.opacity(0.25),
            Color.cyan.opacity(0.35),
            Color.indigo.opacity(0.28),
            Color.teal.opacity(0.32)
        ]
    }
}