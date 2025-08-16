//
//  MetallicBadgeShader.metal
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/15/25.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    float3 worldPosition;
    float3 normal;
};

struct VertexUniforms {
    float z; // Layer depth for multi-pass rendering
};

struct FragmentUniforms {
    float metallic;           // 0.0 to 1.0
    float roughness;          // 0.0 to 1.0
    float3 lightDir;          // Normalized light direction
    float lightIntensity;     // Light intensity multiplier
    float topLightStrength;   // Top light strength
    float rightLightStrength; // Right light strength
    float rimLightStrength;   // Rim light strength
};

// Vertex shader
vertex VertexOut vertexShader(VertexIn in [[stage_in]],
                             constant VertexUniforms& uniforms [[buffer(1)]]) {
    VertexOut out;
    
    // Convert 2D position to 3D with provided z depth
    // Make sure Z is properly clamped for clip space
    float clampedZ = clamp(uniforms.z, -1.0, 1.0);
    out.position = float4(in.position.x, in.position.y, clampedZ, 1.0);
    
    // DEBUG: Log z values for artwork layer
    if (uniforms.z >= -0.01 && uniforms.z <= 0.01) {
        // This is likely the artwork layer at z=0.0
    }
    out.texCoord = in.texCoord;
    
    // Calculate world position for lighting (assuming quad is in XY plane)
    out.worldPosition = float3(in.position.x, in.position.y, uniforms.z);
    
    // Normal pointing towards camera (positive Z)
    out.normal = float3(0.0, 0.0, 1.0);
    
    return out;
}

// PBR-inspired lighting calculation
float3 calculateMetallicLighting(float3 baseColor,
                                float metallic,
                                float roughness,
                                float3 normal,
                                float3 lightDir,
                                float3 viewDir) {
    // Normalize inputs
    normal = normalize(normal);
    lightDir = normalize(lightDir);
    viewDir = normalize(viewDir);
    
    // Calculate half vector
    float3 halfDir = normalize(lightDir + viewDir);
    
    // Dot products
    float NdotL = max(dot(normal, lightDir), 0.0);
    float NdotV = max(dot(normal, viewDir), 0.0);
    float NdotH = max(dot(normal, halfDir), 0.0);
    float VdotH = max(dot(viewDir, halfDir), 0.0);
    
    // Fresnel (Schlick approximation)
    float3 F0 = mix(float3(0.04), baseColor, metallic);
    float3 F = F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
    
    // Distribution (GGX/Trowbridge-Reitz)
    float alpha = roughness * roughness;
    float alpha2 = alpha * alpha;
    float denom = NdotH * NdotH * (alpha2 - 1.0) + 1.0;
    float D = alpha2 / (M_PI_F * denom * denom);
    
    // Geometry (Smith model)
    float k = (roughness + 1.0) * (roughness + 1.0) / 8.0;
    float G1L = NdotL / (NdotL * (1.0 - k) + k);
    float G1V = NdotV / (NdotV * (1.0 - k) + k);
    float G = G1L * G1V;
    
    // BRDF
    float3 numerator = D * G * F;
    float denominator = 4.0 * NdotV * NdotL + 0.001; // Add small value to prevent division by zero
    float3 specular = numerator / denominator;
    
    // Diffuse
    float3 kS = F;
    float3 kD = float3(1.0) - kS;
    kD *= 1.0 - metallic; // Metallic surfaces don't have diffuse
    float3 diffuse = kD * baseColor / M_PI_F;
    
    // Ambient light
    float3 ambient = baseColor * 0.15;
    
    // Final color
    return ambient + (diffuse + specular) * NdotL * 0.85;
}

// Fragment shader - STEP 4: Basic metallic effects
fragment float4 fragmentShader(VertexOut in [[stage_in]],
                              constant FragmentUniforms& uniforms [[buffer(2)]],
                              texture2d<float> diffuseTexture [[texture(0)]]) {
    
    constexpr sampler textureSampler(mag_filter::linear,
                                   min_filter::linear,
                                   address::clamp_to_edge);
    
    // Sample the texture
    float4 textureColor = diffuseTexture.sample(textureSampler, in.texCoord);
    
    // Skip transparent pixels - but be more lenient for artwork
    if (textureColor.a < 0.001) {
        discard_fragment();
    }
    
    // DEBUG: If this is artwork layer (z=0), force visibility if alpha is very low
    if (uniforms.metallic < 0.2 && textureColor.a < 0.1 && textureColor.a > 0.001) {
        // Force artwork to be visible with bright test color
        return float4(1.0, 1.0, 0.0, 1.0); // Bright yellow for debugging
    }
    
    // Volumetric lighting effect from top and right
    float3 normal = normalize(in.normal);
    float3 viewDir = normalize(float3(0.0, 0.0, 1.0)); // Camera looks down Z axis
    
    // Multiple light sources for volumetric effect
    float3 topLight = normalize(float3(0.0, 1.0, 0.8));     // Light from top
    float3 rightLight = normalize(float3(1.0, 0.0, 0.6));   // Light from right
    float3 mainLight = normalize(uniforms.lightDir);        // Main directional light
    
    // Calculate lighting contributions
    float NdotV = max(dot(normal, viewDir), 0.0);
    float NdotMain = max(dot(normal, mainLight), 0.0);
    float NdotTop = max(dot(normal, topLight), 0.0);
    float NdotRight = max(dot(normal, rightLight), 0.0);
    
    // Volumetric lighting: stronger at edges (rim lighting effect)
    float2 screenPos = in.texCoord * 2.0 - 1.0; // Convert to [-1,1] range
    float distFromCenter = length(screenPos);
    float rimFactor = smoothstep(0.3, 0.8, distFromCenter); // Stronger at edges
    
    // Combine lighting with controllable volumetric rim effect
    float topRim = NdotTop * rimFactor * uniforms.topLightStrength;
    float rightRim = NdotRight * rimFactor * uniforms.rightLightStrength;
    float combinedLighting = (NdotMain + topRim + rightRim) * uniforms.lightIntensity;
    
    // Metallic enhancement with volumetric highlights
    float metallic = uniforms.metallic;
    float3 baseColor = textureColor.rgb;
    
    // Enhanced metallic effect with controllable volumetric highlights
    float3 reflectColor = float3(1.0, 0.95, 0.8); // Warm metallic reflection
    float3 volumetricHighlight = float3(1.0, 1.0, 0.9) * (topRim + rightRim) * uniforms.rimLightStrength;
    float3 metalColor = baseColor * (1.0 - metallic * 0.4) + 
                       reflectColor * metallic * NdotV * 0.5 + 
                       volumetricHighlight * metallic;
    
    // Final lighting with volumetric enhancement
    float3 finalColor = metalColor * (0.7 + 0.3 * combinedLighting);
    
    return float4(finalColor, textureColor.a);
}
