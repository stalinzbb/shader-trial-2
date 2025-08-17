//
//  MaterialBadgeShader.metal
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/16/25.
//

#include <metal_stdlib>
using namespace metal;

struct MaterialVertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texCoord [[attribute(2)]];
};

struct MaterialVertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 normal;
    float2 texCoord;
};

struct MaterialVertexUniforms {
    float z;
    float offsetX;
    float4x4 modelViewProjectionMatrix;
};

struct MaterialFragmentUniforms {
    float metallic;           // 0.0 to 1.0
    float roughness;          // 0.0 to 1.0
    float3 lightDir;          // Normalized light direction
    float lightIntensity;     // Light intensity multiplier
    float topLightStrength;   // Top light strength
    float rightLightStrength; // Right light strength
    float rimLightStrength;   // Rim light strength
    uint layerType;          // 0=fill, 1=stroke, 2=artwork
};

// Material Vertex shader - WITH OFFSET FOR DEBUGGING
vertex MaterialVertexOut materialVertexShader(MaterialVertexIn in [[stage_in]],
                                            constant MaterialVertexUniforms& uniforms [[buffer(1)]]) {
    MaterialVertexOut out;
    
    // Apply X offset to separate layers visually
    out.position = float4(in.position.x + uniforms.offsetX, in.position.y, uniforms.z, 1.0);
    out.worldPosition = float3(in.position.x + uniforms.offsetX, in.position.y, in.position.z);
    out.normal = normalize(in.normal);
    out.texCoord = in.texCoord;
    
    return out;
}

// Advanced PBR lighting calculation for tessellated geometry
float3 calculateAdvancedMetallicLighting(float3 baseColor,
                                        float metallic,
                                        float roughness,
                                        float3 normal,
                                        float3 lightDir,
                                        float3 viewDir,
                                        float3 topLight,
                                        float3 rightLight,
                                        float topStrength,
                                        float rightStrength,
                                        float rimStrength,
                                        float2 texCoord) {
    // Normalize inputs
    normal = normalize(normal);
    lightDir = normalize(lightDir);
    viewDir = normalize(viewDir);
    topLight = normalize(topLight);
    rightLight = normalize(rightLight);
    
    // Calculate lighting contributions
    float NdotL = max(dot(normal, lightDir), 0.0);
    float NdotV = max(dot(normal, viewDir), 0.0);
    float NdotTop = max(dot(normal, topLight), 0.0);
    float NdotRight = max(dot(normal, rightLight), 0.0);
    
    // Advanced rim lighting based on geometry edges
    float distFromCenter = length(texCoord * 2.0 - 1.0);
    float rimFactor = smoothstep(0.4, 0.9, distFromCenter);
    
    // Multiple light contributions
    float topRim = NdotTop * rimFactor * topStrength;
    float rightRim = NdotRight * rimFactor * rightStrength;
    
    // Fresnel effect for metallic surfaces
    float3 halfDir = normalize(lightDir + viewDir);
    float VdotH = max(dot(viewDir, halfDir), 0.0);
    float3 F0 = mix(float3(0.04), baseColor, metallic);
    float3 F = F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
    
    // Distribution term (GGX)
    float NdotH = max(dot(normal, halfDir), 0.0);
    float alpha = roughness * roughness;
    float alpha2 = alpha * alpha;
    float denom = NdotH * NdotH * (alpha2 - 1.0) + 1.0;
    float D = alpha2 / (M_PI_F * denom * denom);
    
    // Geometry term (Smith model)
    float k = (roughness + 1.0) * (roughness + 1.0) / 8.0;
    float G1L = NdotL / (NdotL * (1.0 - k) + k);
    float G1V = NdotV / (NdotV * (1.0 - k) + k);
    float G = G1L * G1V;
    
    // BRDF calculation
    float3 numerator = D * G * F;
    float denominator = 4.0 * NdotV * NdotL + 0.001;
    float3 specular = numerator / denominator;
    
    // Diffuse component
    float3 kS = F;
    float3 kD = float3(1.0) - kS;
    kD *= 1.0 - metallic;
    float3 diffuse = kD * baseColor / M_PI_F;
    
    // Volumetric highlights
    float3 volumetricHighlight = float3(1.0, 0.98, 0.85) * (topRim + rightRim) * rimStrength;
    
    // Ambient lighting
    float3 ambient = baseColor * 0.15;
    
    // Combine all lighting components
    float3 directLighting = (diffuse + specular) * NdotL;
    float3 additionalLighting = volumetricHighlight * metallic;
    
    return ambient + directLighting + additionalLighting;
}

// Material Fragment shader - SIMPLIFIED FOR DEBUGGING
fragment float4 materialFragmentShader(MaterialVertexOut in [[stage_in]],
                                     constant MaterialFragmentUniforms& uniforms [[buffer(2)]]) {
    
    // DEBUG: Return bright colors based on layer type to verify geometry
    switch(uniforms.layerType) {
        case 0: // Fill
            return float4(0.0, 1.0, 0.0, 1.0); // Bright green
        case 1: // Stroke  
            return float4(1.0, 0.0, 0.0, 1.0); // Bright red
        case 2: // Artwork
            return float4(0.0, 0.0, 1.0, 1.0); // Bright blue
        default:
            return float4(1.0, 1.0, 0.0, 1.0); // Bright yellow fallback
    }
}