//
//  DynamicGradient.metal
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/7/25.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// Noise function for organic movement
float noise(float2 position, float time) {
    float2 p = position + time * 0.3;
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453) * 2.0 - 1.0;
}

// Smooth noise with multiple octaves
float smoothNoise(float2 position, float time) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 0.02;
    
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(position * frequency, time);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

[[ stitchable ]]
half4 DynamicGradient(
    float2 position,
    SwiftUI::Layer layer,
    float time,
    float4 color1,
    float4 color2,
    float4 color3,
    float4 color4,
    float4 color5,
    float2 size
) {
    // Normalize position
    float2 uv = position / size;
    
    // Create multiple moving gradient flows
    float2 flow1 = float2(cos(time * 0.4) * 0.3, sin(time * 0.6) * 0.4);
    float2 flow2 = float2(sin(time * 0.5) * 0.4, cos(time * 0.3) * 0.3);
    float2 flow3 = float2(cos(time * 0.7) * 0.2, sin(time * 0.8) * 0.5);
    
    // Add noise for organic movement
    float noise1 = smoothNoise(uv * 3.0, time);
    float noise2 = smoothNoise(uv * 2.0 + float2(100.0, 100.0), time * 1.2);
    float noise3 = smoothNoise(uv * 4.0 + float2(200.0, 200.0), time * 0.8);
    
    // Create flowing gradient influences
    float influence1 = 0.5 + 0.3 * sin(length(uv + flow1) * 6.0 + time * 2.0) + noise1 * 0.2;
    float influence2 = 0.5 + 0.3 * cos(length(uv + flow2) * 5.0 + time * 1.5) + noise2 * 0.2;
    float influence3 = 0.5 + 0.3 * sin(length(uv + flow3) * 7.0 + time * 2.5) + noise3 * 0.2;
    
    // Radial gradients from different points
    float2 center1 = float2(0.3 + flow1.x, 0.7 + flow1.y);
    float2 center2 = float2(0.7 + flow2.x, 0.3 + flow2.y);
    float2 center3 = float2(0.5 + flow3.x, 0.5 + flow3.y);
    
    float dist1 = 1.0 - smoothstep(0.0, 0.8, length(uv - center1));
    float dist2 = 1.0 - smoothstep(0.0, 0.9, length(uv - center2));
    float dist3 = 1.0 - smoothstep(0.0, 0.7, length(uv - center3));
    
    // Blend multiple colors based on influences
    half4 finalColor = half4(0.0);
    
    finalColor += half4(color1) * influence1 * dist1;
    finalColor += half4(color2) * influence2 * dist2;
    finalColor += half4(color3) * influence3 * dist3;
    
    // Add some directional flow
    float flowPattern = sin(uv.x * 8.0 + time * 3.0) * cos(uv.y * 6.0 + time * 2.0);
    finalColor += half4(color4) * flowPattern * 0.3;
    
    // Add subtle sparkle effect
    float sparkle = smoothNoise(uv * 20.0, time * 4.0);
    if (sparkle > 0.7) {
        finalColor += half4(color5) * (sparkle - 0.7) * 2.0;
    }
    
    // Ensure smooth blending and prevent over-saturation
    finalColor = clamp(finalColor, 0.0, 1.0);
    
    // Add slight blur effect by sampling nearby pixels
    half4 blurred = finalColor;
    float blurRadius = 1.5;
    
    for (float x = -blurRadius; x <= blurRadius; x += blurRadius) {
        for (float y = -blurRadius; y <= blurRadius; y += blurRadius) {
            if (x == 0.0 && y == 0.0) continue;
            
            // Simple color blending for blur effect
            blurred += finalColor * 0.1;
        }
    }
    
    return mix(finalColor, blurred, 0.3);
}