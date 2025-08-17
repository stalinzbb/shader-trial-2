//
//  MetallicBadgeView.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/15/25.
//

import SwiftUI

struct MetallicBadgeView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Material control parameters
    @State private var strokeMetallic: Float = 1.0
    @State private var fillMetallic: Float = 0.2
    @State private var artworkMetallic: Float = 0.1
    @State private var globalRoughness: Float = 0.3
    
    // Lighting control parameters - increased for better visibility
    @State private var lightIntensity: Float = 1.4
    @State private var topLightStrength: Float = 1.0
    @State private var rightLightStrength: Float = 0.8
    @State private var rimLightStrength: Float = 0.6
    
    // Rotation control parameters
    @State private var rotationX: Float = 0.0
    @State private var rotationY: Float = 0.0
    @State private var lastDragValue: CGSize = .zero
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header - Fixed height
                    VStack(spacing: 16) {
                        Text("Metallic Badge")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.top, 40)
                        
                        Text("Real-time Metal shader rendering with PBR lighting and multi-layer compositing")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .frame(height: 140) // Fixed height for header
                    
                    // Spacer to center badge
                    Spacer()
                    
                    // Metal View Container - Centered
                    HStack {
                        Spacer()
                        MetallicBadgeMetalView(
                            strokeMetallic: strokeMetallic,
                            fillMetallic: fillMetallic,
                            artworkMetallic: artworkMetallic,
                            globalRoughness: globalRoughness,
                            lightIntensity: lightIntensity,
                            topLightStrength: topLightStrength,
                            rightLightStrength: rightLightStrength,
                            rimLightStrength: rimLightStrength,
                            rotationX: rotationX,
                            rotationY: rotationY
                        )
                        .frame(width: 300, height: 300)
                        .background(Color.white)
                        // Remove clipping to allow 3D badge to extend outside bounds
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let deltaX = value.translation.width - lastDragValue.width
                                    let deltaY = value.translation.height - lastDragValue.height
                                    
                                    // Convert drag to rotation with restricted limits
                                    rotationY += Float(deltaX) * 0.01  // Roll rotation (full range)
                                    rotationX += Float(deltaY) * 0.005 // Pitch rotation (very limited)
                                    
                                    // Clamp rotations: roll allows full rotation, pitch is very limited
                                    rotationX = max(-0.15, min(0.15, rotationX)) // ~±8.5 degrees pitch
                                    rotationY = max(-Float.pi, min(Float.pi, rotationY)) // Full roll rotation
                                    
                                    lastDragValue = value.translation
                                }
                                .onEnded { _ in
                                    lastDragValue = .zero
                                }
                        )
                        Spacer()
                    }
                    
                    // Spacer to center badge
                    Spacer()
                    
                    // Controls Panel - Fixed height
                    ScrollView {
                        VStack(spacing: 20) {
                            // Material Controls
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Material Properties")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                
                                // Stroke Metallic
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Stroke Metallic")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Text(String(format: "%.2f", strokeMetallic))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Slider(value: Binding(
                                        get: { Double(strokeMetallic) },
                                        set: { strokeMetallic = Float($0) }
                                    ), in: 0.0...1.0, step: 0.05)
                                    .accentColor(.purple)
                                }
                                
                                // Fill Metallic
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Fill Metallic")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Text(String(format: "%.2f", fillMetallic))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Slider(value: Binding(
                                        get: { Double(fillMetallic) },
                                        set: { fillMetallic = Float($0) }
                                    ), in: 0.0...1.0, step: 0.05)
                                    .accentColor(.purple)
                                }
                                
                                // Artwork Metallic
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Artwork Metallic")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Text(String(format: "%.2f", artworkMetallic))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Slider(value: Binding(
                                        get: { Double(artworkMetallic) },
                                        set: { artworkMetallic = Float($0) }
                                    ), in: 0.0...1.0, step: 0.05)
                                    .accentColor(.purple)
                                }
                                
                                // Global Roughness
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Global Roughness")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Text(String(format: "%.2f", globalRoughness))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Slider(value: Binding(
                                        get: { Double(globalRoughness) },
                                        set: { globalRoughness = Float($0) }
                                    ), in: 0.0...1.0, step: 0.05)
                                    .accentColor(.purple)
                                }
                            }
                            
                            Divider()
                            
                            // Lighting Controls
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Lighting Controls")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                
                                // Light Intensity
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Light Intensity")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Text(String(format: "%.2f", lightIntensity))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Slider(value: Binding(
                                        get: { Double(lightIntensity) },
                                        set: { lightIntensity = Float($0) }
                                    ), in: 0.1...2.0, step: 0.1)
                                    .accentColor(.orange)
                                }
                                
                                // Top Light Strength
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Top Light")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Text(String(format: "%.2f", topLightStrength))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Slider(value: Binding(
                                        get: { Double(topLightStrength) },
                                        set: { topLightStrength = Float($0) }
                                    ), in: 0.0...2.0, step: 0.1)
                                    .accentColor(.orange)
                                }
                                
                                // Right Light Strength
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Right Light")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Text(String(format: "%.2f", rightLightStrength))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Slider(value: Binding(
                                        get: { Double(rightLightStrength) },
                                        set: { rightLightStrength = Float($0) }
                                    ), in: 0.0...2.0, step: 0.1)
                                    .accentColor(.orange)
                                }
                                
                                // Rim Light Strength
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Rim Light")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Text(String(format: "%.2f", rimLightStrength))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Slider(value: Binding(
                                        get: { Double(rimLightStrength) },
                                        set: { rimLightStrength = Float($0) }
                                    ), in: 0.0...1.0, step: 0.05)
                                    .accentColor(.orange)
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 20)
                    }
                    .frame(height: 300) // Fixed height for controls
                    .background(Color.gray.opacity(0.05))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
}

#Preview {
    MetallicBadgeView()
}
