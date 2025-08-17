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
    float thickness; // Extrusion thickness for this layer
    float4x4 modelViewProjectionMatrix; // 3D transformation matrix
};

struct FragmentUniforms {
    float metallic;           // 0.0 to 1.0
    float roughness;          // 0.0 to 1.0
    float3 keyLightDir;       // Main key light from grazing angle
    float3 rimLightDir;       // Faint rim light from opposite side
    float lightIntensity;     // Light intensity multiplier
    float keyLightStrength;   // Key light strength
    float fillLightStrength;  // Fill light strength
    float rimLightStrength;   // Rim light strength
    float envMapIntensity;    // HDR environment map contribution
    uint layerType;          // 0=fill, 1=stroke, 2=artwork
    float strokeThickness;    // Stroke layer thickness for shadow calc
    float artworkThickness;   // Artwork layer thickness for shadow calc
};

// Vertex shader with 3D transformation and Z-axis thickness extrusion
vertex VertexOut vertexShader(VertexIn in [[stage_in]],
                             constant VertexUniforms& uniforms [[buffer(1)]]) {
    VertexOut out;
    
    // Create 3D position from 2D input - preserve original XY, add Z depth
    float3 position3D = float3(in.position.x, in.position.y, uniforms.z);
    
    // Apply thickness scaling only in Z-axis (creates depth without deforming shape)
    position3D.z *= uniforms.thickness;
    
    // Transform with model-view-projection matrix for 3D rotation and perspective
    out.position = uniforms.modelViewProjectionMatrix * float4(position3D, 1.0);
    
    // Pass through texture coordinates unchanged
    out.texCoord = in.texCoord;
    
    // Calculate world position for lighting (before transformation)
    out.worldPosition = position3D;
    
    // Generate normal pointing towards camera for front face (can be improved for side faces)
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
    
    // Ambient light (increased for better visibility)
    float3 ambient = baseColor * 0.35;
    
    // Final color with enhanced brightness
    return ambient + (diffuse + specular) * NdotL;
}

// HDR Environment reflection sampling
float3 sampleEnvironmentHDR(texturecube<float> envMap, float3 direction, float roughness) {
    constexpr sampler envSampler(mag_filter::linear, min_filter::linear);
    
    // Sample environment map - simplified for compatibility
    float4 envColor = envMap.sample(envSampler, direction);
    
    // Apply roughness by blending with a dimmer sample
    if (roughness > 0.5) {
        envColor.rgb *= (1.0 - roughness * 0.5); // Dim for rough surfaces
    }
    
    return envColor.rgb;
}

// Calculate shadow cast by upper layers onto lower layers
float calculateLayerShadow(float2 texCoord, 
                          float3 lightDir, 
                          uint currentLayerType,
                          texture2d<float> strokeTexture,
                          texture2d<float> artworkTexture,
                          float strokeThickness,
                          float artworkThickness) {
    
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    // Only calculate shadows for the fill layer (layer 0)
    if (currentLayerType != 0) {
        return 1.0; // No shadows for stroke and artwork layers
    }
    
    // Calculate shadow offset based on light direction
    float2 lightOffset = -lightDir.xy * 0.02; // Small offset for shadow projection
    float2 shadowCoord = texCoord + lightOffset;
    
    float shadowFactor = 1.0;
    
    // Sample artwork layer (thickest, casts strongest shadows)
    float4 artworkSample = artworkTexture.sample(textureSampler, shadowCoord);
    if (artworkSample.a > 0.1) { // If artwork exists at this position
        float artworkShadow = 1.0 - (artworkThickness * 2.0); // Stronger shadow
        shadowFactor *= max(artworkShadow, 0.3); // Don't go completely black
    }
    
    // Sample stroke layer (medium thickness, medium shadows)
    float4 strokeSample = strokeTexture.sample(textureSampler, shadowCoord);
    if (strokeSample.a > 0.1) { // If stroke exists at this position
        float strokeShadow = 1.0 - (strokeThickness * 1.5); // Medium shadow
        shadowFactor *= max(strokeShadow, 0.5); // Lighter than artwork shadow
    }
    
    return shadowFactor;
}

// Advanced PBR fragment shader with HDR environment reflections and shadow casting
fragment float4 fragmentShader(VertexOut in [[stage_in]],
                              constant FragmentUniforms& uniforms [[buffer(2)]],
                              texture2d<float> diffuseTexture [[texture(0)]],
                              texturecube<float> envMap [[texture(1)]],
                              texture2d<float> strokeTexture [[texture(2)]],
                              texture2d<float> artworkTexture [[texture(3)]]) {
    
    constexpr sampler textureSampler(mag_filter::linear,
                                   min_filter::linear,
                                   address::clamp_to_edge);
    
    // Sample the base texture
    float4 textureColor = diffuseTexture.sample(textureSampler, in.texCoord);
    
    // Discard fully transparent pixels
    if (textureColor.a < 0.001) {
        discard_fragment();
    }
    
    // Surface properties
    float3 baseColor = textureColor.rgb;
    float metallic = uniforms.metallic;
    float roughness = uniforms.roughness;
    float alpha = textureColor.a;
    
    // Geometry vectors
    float3 normal = normalize(in.normal);
    float3 viewDir = normalize(float3(0.0, 0.0, 1.0)); // Camera looking down Z
    float3 keyLight = normalize(uniforms.keyLightDir);  // Grazing key light
    float3 rimLight = normalize(uniforms.rimLightDir);  // Opposite rim light
    
    // Calculate reflection vector for environment sampling
    float3 reflectDir = reflect(-viewDir, normal);
    
    // Sample HDR environment for reflections
    float3 envReflection = sampleEnvironmentHDR(envMap, reflectDir, roughness);
    float3 ambientEnv = sampleEnvironmentHDR(envMap, normal, 1.0) * 0.4 * baseColor; // Further increased ambient
    
    // Key light contribution (grazing angle)
    float NdotL_key = max(dot(normal, keyLight), 0.0);
    float3 keyLightContrib = calculateMetallicLighting(baseColor, metallic, roughness, normal, keyLight, viewDir) 
                            * uniforms.keyLightStrength * NdotL_key;
    
    // Fill light contribution (softer, from front for better base visibility)
    float3 fillLightDir = normalize(float3(0.2, 0.3, 0.8)); // More frontal fill light
    float NdotL_fill = max(dot(normal, fillLightDir), 0.0);
    float3 fillLightContrib = baseColor * 0.6 * uniforms.fillLightStrength * NdotL_fill; // Increased contribution
    
    // Rim light contribution (stronger for metallic edge highlights)
    float NdotL_rim = max(dot(normal, rimLight), 0.0);
    float rimFactor = 1.0 - max(dot(normal, viewDir), 0.0); // Stronger at grazing angles
    float3 rimLightContrib = float3(0.9, 0.95, 1.0) * uniforms.rimLightStrength * NdotL_rim * rimFactor;
    
    // Environment reflection contribution
    float3 F0 = mix(float3(0.04), baseColor, metallic);
    float NdotV = max(dot(normal, viewDir), 0.0);
    float3 F = F0 + (1.0 - F0) * pow(1.0 - NdotV, 5.0); // Fresnel
    
    float3 envContrib = envReflection * F * metallic * uniforms.envMapIntensity * 1.5; // Boost env reflections
    
    // Calculate shadows cast by upper layers
    float shadowFactor = calculateLayerShadow(in.texCoord, 
                                             keyLight, 
                                             uniforms.layerType,
                                             strokeTexture,
                                             artworkTexture,
                                             uniforms.strokeThickness,
                                             uniforms.artworkThickness);
    
    // Add base metallic highlight for better visibility
    float3 metallicBoost = float3(0.8, 0.85, 0.9) * metallic * NdotV * 0.3;
    
    // Combine all lighting contributions
    float3 finalColor = ambientEnv + 
                       keyLightContrib + 
                       fillLightContrib + 
                       rimLightContrib + 
                       envContrib + 
                       metallicBoost;
    
    // Apply shadow factor to simulate depth shadows
    finalColor *= shadowFactor;
    
    // Apply overall light intensity with minimum brightness
    finalColor *= uniforms.lightIntensity;
    finalColor = max(finalColor, baseColor * 0.1); // Ensure minimum visibility
    
    return float4(finalColor, alpha);
}
