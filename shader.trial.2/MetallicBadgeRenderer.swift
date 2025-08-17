//
//  MetallicBadgeRenderer.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/15/25.
//

import Metal
import MetalKit
import SwiftUI
import simd

// MARK: - Uniform Structures
struct VertexUniforms {
    var z: Float
    var thickness: Float
    var modelViewProjectionMatrix: matrix_float4x4
}

struct FragmentUniforms {
    var metallic: Float
    var roughness: Float
    var keyLightDir: SIMD3<Float>      // Main key light from grazing angle
    var rimLightDir: SIMD3<Float>      // Faint rim light from opposite side
    var lightIntensity: Float
    var keyLightStrength: Float        // Renamed from topLightStrength
    var fillLightStrength: Float       // Renamed from rightLightStrength
    var rimLightStrength: Float
    var envMapIntensity: Float         // HDR environment map contribution
    var layerType: UInt32              // 0=fill, 1=stroke, 2=artwork
    var strokeThickness: Float         // Thickness of stroke layer
    var artworkThickness: Float        // Thickness of artwork layer
}

// MARK: - Vertex Data
struct Vertex {
    var position: SIMD2<Float>  // Keep 2D - extrusion handled in shader
    var texCoord: SIMD2<Float>
}

// MARK: - Metal Renderer
class MetallicBadgeRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var renderPipelineState: MTLRenderPipelineState!
    private var depthStencilState: MTLDepthStencilState!
    private var vertexBuffer: MTLBuffer!
    private var drawCount = 0
    
    // Textures
    private var strokeTexture: MTLTexture?
    private var fillTexture: MTLTexture?
    private var artworkTexture: MTLTexture?
    private var envMapTexture: MTLTexture?  // HDR environment cubemap
    
    // Uniform buffers
    private var vertexUniformBuffer: MTLBuffer!
    private var fragmentUniformBuffer: MTLBuffer!
    
    // Control parameters
    private var strokeMetallic: Float = 1.0
    private var fillMetallic: Float = 0.2
    private var artworkMetallic: Float = 0.1
    private var globalRoughness: Float = 0.3
    private var lightIntensity: Float = 1.0
    private var topLightStrength: Float = 0.8  // Will map to keyLightStrength
    private var rightLightStrength: Float = 0.6  // Will map to fillLightStrength
    private var rimLightStrength: Float = 0.4
    private var envMapIntensity: Float = 0.8   // HDR environment contribution
    
    // Rotation parameters
    private var rotationX: Float = 0.0
    private var rotationY: Float = 0.0
    
    init(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        
        super.init()
        
        setupRenderPipeline()
        setupDepthStencilState()
        setupVertexBuffer()
        setupUniformBuffers()
        loadTextures()
        createHDREnvironmentMap()
    }
    
    // Update parameters from UI controls
    func updateParameters(strokeMetallic: Float,
                         fillMetallic: Float,
                         artworkMetallic: Float,
                         globalRoughness: Float,
                         lightIntensity: Float,
                         topLightStrength: Float,
                         rightLightStrength: Float,
                         rimLightStrength: Float,
                         rotationX: Float,
                         rotationY: Float) {
        self.strokeMetallic = strokeMetallic
        self.fillMetallic = fillMetallic
        self.artworkMetallic = artworkMetallic
        self.globalRoughness = globalRoughness
        self.lightIntensity = lightIntensity
        self.topLightStrength = topLightStrength
        self.rightLightStrength = rightLightStrength
        self.rimLightStrength = rimLightStrength
        self.rotationX = rotationX
        self.rotationY = rotationY
    }
    
    private func setupRenderPipeline() {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not create Metal library")
        }
        
        print("Available functions in library: \(library.functionNames)")
        
        guard let vertexFunction = library.makeFunction(name: "vertexShader"),
              let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
            print("Failed to load shader functions - available: \(library.functionNames)")
            fatalError("Could not create Metal functions")
        }
        
        print("Successfully loaded shader functions: vertexShader, fragmentShader")
        
        // Vertex descriptor - back to 2D with shader-based extrusion
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2 // position
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        
        vertexDescriptor.attributes[1].format = .float2 // texCoord
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.size
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        // Pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        // Enable alpha blending
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create render pipeline state: \(error)")
        }
    }
    
    private func setupDepthStencilState() {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .lessEqual  // Changed from .less to .lessEqual
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
        print("Depth stencil configured: lessEqual comparison, depth write enabled")
    }
    
    private func setupVertexBuffer() {
        // Create a simple 2D quad - extrusion will happen in the shader
        let vertices: [Vertex] = [
            Vertex(position: SIMD2<Float>(-0.8,  0.8), texCoord: SIMD2<Float>(0.0, 0.0)), // Top-left
            Vertex(position: SIMD2<Float>( 0.8,  0.8), texCoord: SIMD2<Float>(1.0, 0.0)), // Top-right
            Vertex(position: SIMD2<Float>(-0.8, -0.8), texCoord: SIMD2<Float>(0.0, 1.0)), // Bottom-left
            Vertex(position: SIMD2<Float>( 0.8, -0.8), texCoord: SIMD2<Float>(1.0, 1.0))  // Bottom-right
        ]
        
        print("Created 2D vertex buffer with \(vertices.count) vertices for shader-based extrusion")
        
        vertexBuffer = device.makeBuffer(bytes: vertices, 
                                       length: vertices.count * MemoryLayout<Vertex>.stride, 
                                       options: [])
    }
    
    private func createPerspectiveMatrix(fovy: Float, aspect: Float, near: Float, far: Float) -> matrix_float4x4 {
        let yScale = 1 / tan(fovy * 0.5)
        let xScale = yScale / aspect
        let zRange = far - near
        let zScale = -(far + near) / zRange
        let wzScale = -2 * far * near / zRange
        
        let P = matrix_float4x4(
            SIMD4<Float>(xScale, 0, 0, 0),
            SIMD4<Float>(0, yScale, 0, 0),
            SIMD4<Float>(0, 0, zScale, -1),
            SIMD4<Float>(0, 0, wzScale, 0)
        )
        return P
    }
    
    private func createRotationMatrixX(_ angle: Float) -> matrix_float4x4 {
        let c = cos(angle)
        let s = sin(angle)
        return matrix_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, c, s, 0),
            SIMD4<Float>(0, -s, c, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
    
    private func createRotationMatrixY(_ angle: Float) -> matrix_float4x4 {
        let c = cos(angle)
        let s = sin(angle)
        return matrix_float4x4(
            SIMD4<Float>(c, 0, -s, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(s, 0, c, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
    
    private func createViewMatrix(eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> matrix_float4x4 {
        let zAxis = normalize(eye - target)
        let xAxis = normalize(cross(up, zAxis))
        let yAxis = cross(zAxis, xAxis)
        
        return matrix_float4x4(
            SIMD4<Float>(xAxis.x, yAxis.x, zAxis.x, 0),
            SIMD4<Float>(xAxis.y, yAxis.y, zAxis.y, 0),
            SIMD4<Float>(xAxis.z, yAxis.z, zAxis.z, 0),
            SIMD4<Float>(-dot(xAxis, eye), -dot(yAxis, eye), -dot(zAxis, eye), 1)
        )
    }
    
    private func setupUniformBuffers() {
        vertexUniformBuffer = device.makeBuffer(length: MemoryLayout<VertexUniforms>.stride * 3, options: [])
        fragmentUniformBuffer = device.makeBuffer(length: MemoryLayout<FragmentUniforms>.stride * 3, options: [])
    }
    
    private func loadTextures() {
        let textureLoader = MTKTextureLoader(device: device)
        let options: [MTKTextureLoader.Option: Any] = [
            .textureUsage: MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode: MTLStorageMode.private.rawValue
        ]
        
        // Load textures from assets with corrected naming
        do {
            // Try both naming conventions
            if let strokeImage = UIImage(named: "b1-strok") ?? UIImage(named: "b1-stroke") {
                strokeTexture = try textureLoader.newTexture(cgImage: strokeImage.cgImage!, options: options)
                print("Successfully loaded stroke texture")
            } else {
                print("Failed to load stroke texture - creating fallback")
                strokeTexture = createFallbackTexture(color: .red)
            }
            
            if let fillImage = UIImage(named: "b1-fill") {
                fillTexture = try textureLoader.newTexture(cgImage: fillImage.cgImage!, options: options)
                print("Successfully loaded fill texture")
            } else {
                print("Failed to load fill texture - creating fallback")
                fillTexture = createFallbackTexture(color: .green)
            }
            
            if let artworkImage = UIImage(named: "b1-artwork") {
                artworkTexture = try textureLoader.newTexture(cgImage: artworkImage.cgImage!, options: options)
                print("Successfully loaded artwork texture - size: \(artworkImage.size)")
            } else {
                print("Failed to load artwork texture 'b1-artwork' - creating bright fallback for debugging")
                artworkTexture = createFallbackTexture(color: .yellow)
            }
        } catch {
            print("Error loading textures: \(error)")
            // Create fallback textures
            strokeTexture = createFallbackTexture(color: .red)
            fillTexture = createFallbackTexture(color: .green)
            artworkTexture = createFallbackTexture(color: .blue)
        }
    }
    
    private func createFallbackTexture(color: UIColor) -> MTLTexture? {
        let size = CGSize(width: 256, height: 256)
        let rect = CGRect(origin: .zero, size: size)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        
        let textureLoader = MTKTextureLoader(device: device)
        let options: [MTKTextureLoader.Option: Any] = [
            .textureUsage: MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode: MTLStorageMode.private.rawValue
        ]
        
        do {
            return try textureLoader.newTexture(cgImage: cgImage, options: options)
        } catch {
            print("Failed to create fallback texture: \(error)")
            return nil
        }
    }
    
    private func createHDREnvironmentMap() {
        // Create a procedural HDR cubemap for realistic reflections
        let cubeSize = 256  // Reduced size for better compatibility
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .typeCube
        textureDescriptor.pixelFormat = MTLPixelFormat.rgba8Unorm
        textureDescriptor.width = cubeSize
        textureDescriptor.height = cubeSize
        textureDescriptor.depth = 1
        textureDescriptor.mipmapLevelCount = 1
        textureDescriptor.usage = MTLTextureUsage.shaderRead
        textureDescriptor.storageMode = MTLStorageMode.shared  // Use shared for easier data upload
        
        guard let envMap = device.makeTexture(descriptor: textureDescriptor) else {
            print("Failed to create HDR environment cubemap")
            return
        }
        
        // Generate and upload HDR environment data for each face
        for face in 0..<6 {
            fillCubeFaceWithHDRData(envMap: envMap, face: face, size: cubeSize)
        }
        
        envMapTexture = envMap
        print("Created HDR environment cubemap with size: \(cubeSize)x\(cubeSize)")
    }
    
    private func generateCubeFace(commandBuffer: MTLCommandBuffer, envMap: MTLTexture, face: Int, size: Int) {
        // Create a render pass for this cubemap face
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = envMap
        renderPassDescriptor.colorAttachments[0].slice = face
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        // For simplicity, we'll create a basic HDR environment with:
        // - Bright sky gradient on top faces
        // - Horizon glow on side faces  
        // - Darker ground on bottom face
        // This gives realistic metallic reflections without external HDR files
        
        renderEncoder.endEncoding()
        
        // Fill the texture with procedural HDR data using a compute shader would be better,
        // but for now we'll create it procedurally in CPU and upload
        fillCubeFaceWithHDRData(envMap: envMap, face: face, size: size)
    }
    
    private func generateHDREnvironmentData(face: Int, size: Int) -> [UInt8] {
        var data: [UInt8] = []
        data.reserveCapacity(size * size * 4) // RGBA
        
        for y in 0..<size {
            for x in 0..<size {
                let u = (Float(x) + 0.5) / Float(size)
                let v = (Float(y) + 0.5) / Float(size)
                
                // Convert face UV to 3D direction
                let direction = cubemapUVToDirection(face: face, u: u, v: v)
                
                // Generate HDR color based on direction
                let hdrColor = generateHDRColorForDirection(direction)
                
                // Convert HDR to LDR and pack as UInt8
                data.append(UInt8(min(255, max(0, hdrColor.x * 255))))  // R
                data.append(UInt8(min(255, max(0, hdrColor.y * 255))))  // G
                data.append(UInt8(min(255, max(0, hdrColor.z * 255))))  // B
                data.append(255)  // A
            }
        }
        
        return data
    }
    
    private func cubemapUVToDirection(face: Int, u: Float, v: Float) -> SIMD3<Float> {
        let uc = 2.0 * u - 1.0
        let vc = 2.0 * v - 1.0
        
        switch face {
        case 0: return normalize(SIMD3<Float>(1.0, -vc, -uc))   // +X
        case 1: return normalize(SIMD3<Float>(-1.0, -vc, uc))   // -X
        case 2: return normalize(SIMD3<Float>(uc, 1.0, vc))     // +Y
        case 3: return normalize(SIMD3<Float>(uc, -1.0, -vc))   // -Y
        case 4: return normalize(SIMD3<Float>(uc, -vc, 1.0))    // +Z
        case 5: return normalize(SIMD3<Float>(-uc, -vc, -1.0))  // -Z
        default: return SIMD3<Float>(0, 1, 0)
        }
    }
    
    private func generateHDRColorForDirection(_ direction: SIMD3<Float>) -> SIMD3<Float> {
        let y = direction.y
        
        // Sky gradient (much brighter for better metallic reflections)
        if y > 0.1 {
            let skyIntensity = 3.0 + y * 4.0  // HDR range 3-7 (brighter)
            let skyColor = SIMD3<Float>(0.6, 0.8, 1.0) // Brighter blue sky
            return skyColor * skyIntensity
        }
        // Horizon glow (enhanced for metallic highlights)
        else if y > -0.1 {
            let horizonIntensity = 2.5 + abs(y) * 3.0  // Much brighter horizon
            let horizonColor = SIMD3<Float>(1.0, 0.9, 0.7) // Warmer, brighter horizon
            return horizonColor * horizonIntensity
        }
        // Ground/bottom (less dark for better base lighting)
        else {
            let groundIntensity = 0.8 + abs(y) * 0.4  // Brighter ground
            let groundColor = SIMD3<Float>(0.4, 0.45, 0.5) // Lighter ground
            return groundColor * groundIntensity
        }
    }
    
    private func fillCubeFaceWithHDRData(envMap: MTLTexture, face: Int, size: Int) {
        let data = generateHDREnvironmentData(face: face, size: size)
        let bytesPerRow = size * 4 * MemoryLayout<UInt8>.size
        
        data.withUnsafeBytes { bytes in
            let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), 
                                  size: MTLSize(width: size, height: size, depth: 1))
            envMap.replace(region: region,
                          mipmapLevel: 0,
                          slice: face,
                          withBytes: bytes.baseAddress!,
                          bytesPerRow: bytesPerRow,
                          bytesPerImage: 0)
        }
    }
    
    // MARK: - MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle resize if needed
    }
    
    func draw(in view: MTKView) {
        // Reduce debug spam - only print occasionally
        drawCount += 1
        let shouldLog = drawCount % 60 == 1 // Log every 60 frames
        
        if shouldLog {
            print("Draw called - view size: \(view.bounds)")
        }
        
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            if shouldLog {
                print("Failed to get drawable or render pass descriptor")
            }
            return
        }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Key light positioned for optimal metallic highlights (45-degree angle from top-left)
        let keyLightDir = normalize(SIMD3<Float>(-0.5, 0.7, 0.5))  // Better angle for metallic reflections
        
        // Rim light from opposite side for edge definition
        let rimLightDir = normalize(SIMD3<Float>(0.4, -0.3, -0.6))
        
        // Render THREE textures with controllable parameters (back to front)
        
        // Layer 1: Fill (background layer at z = -0.3)
        if let fill = fillTexture {
            if shouldLog {
                print("Drawing fill texture - size: \(fill.width)x\(fill.height), metallic: \(fillMetallic)")
            }
            drawPass(renderEncoder: renderEncoder, 
                    texture: fill, 
                    z: -0.3, 
                    thickness: 0.05,  // Thinnest layer
                    layerType: 0,     // Fill layer
                    metallic: fillMetallic, 
                    roughness: globalRoughness, 
                    keyLightDir: keyLightDir,
                    rimLightDir: rimLightDir)
        } else {
            if shouldLog {
                print("No fill texture available")
            }
        }
        
        // Layer 2: Stroke (middle layer at z = -0.2)
        if let stroke = strokeTexture {
            if shouldLog {
                print("Drawing stroke texture - size: \(stroke.width)x\(stroke.height), metallic: \(strokeMetallic)")
            }
            drawPass(renderEncoder: renderEncoder, 
                    texture: stroke, 
                    z: -0.2, 
                    thickness: 0.1,  // Medium thickness
                    layerType: 1,    // Stroke layer
                    metallic: strokeMetallic, 
                    roughness: globalRoughness, 
                    keyLightDir: keyLightDir,
                    rimLightDir: rimLightDir)
        } else {
            if shouldLog {
                print("No stroke texture available")
            }
        }
        
        // Layer 3: Artwork (FRONT layer at z = 0.0)
        if let artwork = artworkTexture {
            if shouldLog {
                print("ARTWORK DEBUG: Drawing artwork texture - size: \(artwork.width)x\(artwork.height), z: 0.0, metallic: \(artworkMetallic)")
            }
            drawPass(renderEncoder: renderEncoder, 
                    texture: artwork, 
                    z: 0.0, 
                    thickness: 0.15,  // Thickest layer
                    layerType: 2,     // Artwork layer
                    metallic: artworkMetallic, 
                    roughness: globalRoughness, 
                    keyLightDir: keyLightDir,
                    rimLightDir: rimLightDir)
        } else {
            if shouldLog {
                print("ARTWORK DEBUG: No artwork texture available - this should not happen!")
            }
        }
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        if shouldLog {
            print("Render passes completed and committed")
        }
    }
    
    private func drawPass(renderEncoder: MTLRenderCommandEncoder, 
                         texture: MTLTexture?, 
                         z: Float, 
                         thickness: Float,
                         layerType: UInt32,
                         metallic: Float, 
                         roughness: Float, 
                         keyLightDir: SIMD3<Float>,
                         rimLightDir: SIMD3<Float>) {
        
        guard let texture = texture else { 
            return 
        }
        
        // Create rotation matrices for 3D viewing
        let rotationXMatrix = createRotationMatrixX(rotationX)
        let rotationYMatrix = createRotationMatrixY(rotationY)
        let rotationMatrix = matrix_multiply(rotationYMatrix, rotationXMatrix)
        
        // Create view matrix (camera slightly back to see the 3D effect)
        let viewMatrix = createViewMatrix(eye: SIMD3<Float>(0, 0, 2), target: SIMD3<Float>(0, 0, 0), up: SIMD3<Float>(0, 1, 0))
        
        // Create perspective projection
        let projectionMatrix = createPerspectiveMatrix(fovy: Float.pi / 4, aspect: 1.0, near: 0.1, far: 10.0)
        
        // Combine matrices: Projection * View * Rotation
        let mvpMatrix = matrix_multiply(projectionMatrix, matrix_multiply(viewMatrix, rotationMatrix))
        
        // Update vertex uniforms
        let vertexUniformsPointer = vertexUniformBuffer.contents().bindMemory(to: VertexUniforms.self, capacity: 1)
        vertexUniformsPointer.pointee = VertexUniforms(
            z: z,
            thickness: thickness,
            modelViewProjectionMatrix: mvpMatrix
        )
        
        // Update fragment uniforms with shadow casting information
        let fragmentUniformsPointer = fragmentUniformBuffer.contents().bindMemory(to: FragmentUniforms.self, capacity: 1)
        fragmentUniformsPointer.pointee = FragmentUniforms(
            metallic: metallic, 
            roughness: roughness, 
            keyLightDir: keyLightDir,           // Grazing key light
            rimLightDir: rimLightDir,           // Opposite rim light
            lightIntensity: lightIntensity,
            keyLightStrength: topLightStrength,    // Map to key light
            fillLightStrength: rightLightStrength, // Map to fill light
            rimLightStrength: rimLightStrength,
            envMapIntensity: envMapIntensity,      // HDR environment contribution
            layerType: layerType,                  // Current layer being rendered
            strokeThickness: 0.1,                  // Stroke layer thickness for shadow calc
            artworkThickness: 0.15                 // Artwork layer thickness for shadow calc
        )
        
        renderEncoder.setVertexBuffer(vertexUniformBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(fragmentUniformBuffer, offset: 0, index: 2)
        renderEncoder.setFragmentTexture(texture, index: 0)
        
        // Bind HDR environment cubemap for reflections
        if let envMap = envMapTexture {
            renderEncoder.setFragmentTexture(envMap, index: 1)
        }
        
        // Bind stroke and artwork textures for shadow calculation
        if let stroke = strokeTexture {
            renderEncoder.setFragmentTexture(stroke, index: 2)
        }
        if let artwork = artworkTexture {
            renderEncoder.setFragmentTexture(artwork, index: 3)
        }
        
        // Draw simple triangle strip (4 vertices)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    }
}

// MARK: - SwiftUI Wrapper
struct MetallicBadgeMetalView: UIViewRepresentable {
    let strokeMetallic: Float
    let fillMetallic: Float
    let artworkMetallic: Float
    let globalRoughness: Float
    let lightIntensity: Float
    let topLightStrength: Float
    let rightLightStrength: Float
    let rimLightStrength: Float
    let rotationX: Float
    let rotationY: Float
    
    func makeUIView(context: Context) -> MTKView {
        let metalView = MTKView()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        
        metalView.device = device
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) // White background
        
        // Configure drawing behavior - Fix memory issues
        metalView.isPaused = false
        metalView.enableSetNeedsDisplay = true // Use explicit drawing instead of continuous
        metalView.framebufferOnly = true // Reduce memory usage
        metalView.preferredFramesPerSecond = 60
        
        let renderer = MetallicBadgeRenderer(device: device)
        metalView.delegate = renderer
        
        // Store renderer to prevent deallocation
        context.coordinator.renderer = renderer
        
        print("MTKView configured with device: \(device.name)")
        
        // Trigger initial draw after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            metalView.setNeedsDisplay()
        }
        
        return metalView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Update renderer parameters including rotation
        if let renderer = context.coordinator.renderer {
            renderer.updateParameters(
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
        }
        // Trigger redraw when view updates
        uiView.setNeedsDisplay()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var renderer: MetallicBadgeRenderer?
    }
}
