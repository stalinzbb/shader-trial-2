#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 shimmer(float2 position, 
                               half4 currentColor,
                               float shimmerPosition,
                               float shimmerAngle,
                               float shimmerWidth,
                               float shimmerIntensity) {
    
    // If the pixel is transparent, don't apply any effect
    if (currentColor.a < 0.1) {
        return currentColor;
    }
    
    // Start with the original color - this preserves the badge
    half4 result = currentColor;
    
    // Convert position to normalized coordinates
    float2 uv = position / 140.0;
    
    // Create simple diagonal shimmer based on position
    float shimmerLine = uv.x * cos(shimmerAngle) + uv.y * sin(shimmerAngle) - shimmerPosition;
    
    // Calculate distance from shimmer line with smooth falloff
    float distanceFromLine = abs(shimmerLine);
    float shimmerStrength = 1.0 - smoothstep(0.0, shimmerWidth, distanceFromLine);
    
    // Make shimmer very subtle
    shimmerStrength = shimmerStrength * shimmerIntensity * 0.3;
    
    // Apply subtle white highlight additive to original color
    result.rgb = currentColor.rgb + half3(shimmerStrength);
    
    // Clamp to prevent overexposure
    result.rgb = clamp(result.rgb, half3(0.0), half3(1.0));
    
    // Keep original alpha
    result.a = currentColor.a;
    
    return result;
}