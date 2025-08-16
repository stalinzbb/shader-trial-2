//
//  MetallicBadgeRenderer.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/15/25.
//

import Metal
import MetalKit
import SwiftUI

// MARK: - Uniform Structures
struct VertexUniforms {
    var z: Float
}

struct FragmentUniforms {
    var metallic: Float
    var roughness: Float
    var lightDir: SIMD3<Float>
    var lightIntensity: Float
    var topLightStrength: Float
    var rightLightStrength: Float
    var rimLightStrength: Float
}

// MARK: - Vertex Data
struct Vertex {
    var position: SIMD2<Float>
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
    
    // Uniform buffers
    private var vertexUniformBuffer: MTLBuffer!
    private var fragmentUniformBuffer: MTLBuffer!
    
    // Control parameters
    private var strokeMetallic: Float = 1.0
    private var fillMetallic: Float = 0.2
    private var artworkMetallic: Float = 0.1
    private var globalRoughness: Float = 0.3
    private var lightIntensity: Float = 1.0
    private var topLightStrength: Float = 0.8
    private var rightLightStrength: Float = 0.6
    private var rimLightStrength: Float = 0.4
    
    init(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        
        super.init()
        
        setupRenderPipeline()
        setupDepthStencilState()
        setupVertexBuffer()
        setupUniformBuffers()
        loadTextures()
    }
    
    // Update parameters from UI controls
    func updateParameters(strokeMetallic: Float,
                         fillMetallic: Float,
                         artworkMetallic: Float,
                         globalRoughness: Float,
                         lightIntensity: Float,
                         topLightStrength: Float,
                         rightLightStrength: Float,
                         rimLightStrength: Float) {
        self.strokeMetallic = strokeMetallic
        self.fillMetallic = fillMetallic
        self.artworkMetallic = artworkMetallic
        self.globalRoughness = globalRoughness
        self.lightIntensity = lightIntensity
        self.topLightStrength = topLightStrength
        self.rightLightStrength = rightLightStrength
        self.rimLightStrength = rimLightStrength
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
        
        // Vertex descriptor
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
        // Create a larger quad for bigger badge appearance
        let vertices: [Vertex] = [
            Vertex(position: SIMD2<Float>(-0.8,  0.8), texCoord: SIMD2<Float>(0.0, 0.0)), // Top-left
            Vertex(position: SIMD2<Float>( 0.8,  0.8), texCoord: SIMD2<Float>(1.0, 0.0)), // Top-right
            Vertex(position: SIMD2<Float>(-0.8, -0.8), texCoord: SIMD2<Float>(0.0, 1.0)), // Bottom-left
            Vertex(position: SIMD2<Float>( 0.8, -0.8), texCoord: SIMD2<Float>(1.0, 1.0))  // Bottom-right
        ]
        
        print("Created vertex buffer with vertices:")
        for (i, vertex) in vertices.enumerated() {
            print("  Vertex \(i): pos=\(vertex.position), uv=\(vertex.texCoord)")
        }
        
        vertexBuffer = device.makeBuffer(bytes: vertices, 
                                       length: vertices.count * MemoryLayout<Vertex>.stride, 
                                       options: [])
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
        
        // Light direction (from top-left)
        let lightDir = normalize(SIMD3<Float>(-0.5, 0.5, 0.8))
        
        // Render THREE textures with controllable parameters (back to front)
        
        // Layer 1: Fill (background layer at z = -0.3)
        if let fill = fillTexture {
            if shouldLog {
                print("Drawing fill texture - size: \(fill.width)x\(fill.height), metallic: \(fillMetallic)")
            }
            drawPass(renderEncoder: renderEncoder, 
                    texture: fill, 
                    z: -0.3, 
                    metallic: fillMetallic, 
                    roughness: globalRoughness, 
                    lightDir: lightDir)
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
                    metallic: strokeMetallic, 
                    roughness: globalRoughness, 
                    lightDir: lightDir)
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
                    metallic: artworkMetallic, 
                    roughness: globalRoughness, 
                    lightDir: lightDir)
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
                         metallic: Float, 
                         roughness: Float, 
                         lightDir: SIMD3<Float>) {
        
        guard let texture = texture else { 
            return 
        }
        
        // Update vertex uniforms
        let vertexUniformsPointer = vertexUniformBuffer.contents().bindMemory(to: VertexUniforms.self, capacity: 1)
        vertexUniformsPointer.pointee = VertexUniforms(z: z)
        
        // Update fragment uniforms
        let fragmentUniformsPointer = fragmentUniformBuffer.contents().bindMemory(to: FragmentUniforms.self, capacity: 1)
        fragmentUniformsPointer.pointee = FragmentUniforms(
            metallic: metallic, 
            roughness: roughness, 
            lightDir: lightDir,
            lightIntensity: lightIntensity,
            topLightStrength: topLightStrength,
            rightLightStrength: rightLightStrength,
            rimLightStrength: rimLightStrength
        )
        
        renderEncoder.setVertexBuffer(vertexUniformBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(fragmentUniformBuffer, offset: 0, index: 2)
        renderEncoder.setFragmentTexture(texture, index: 0)
        
        // Draw triangle strip (4 vertices)
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
        // Update renderer parameters
        if let renderer = context.coordinator.renderer {
            renderer.updateParameters(
                strokeMetallic: strokeMetallic,
                fillMetallic: fillMetallic,
                artworkMetallic: artworkMetallic,
                globalRoughness: globalRoughness,
                lightIntensity: lightIntensity,
                topLightStrength: topLightStrength,
                rightLightStrength: rightLightStrength,
                rimLightStrength: rimLightStrength
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
