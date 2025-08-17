//
//  MaterialBadgeRenderer.swift
//  shader.trial.2
//
//  Created by Stalin Thomas on 8/16/25.
//

import Metal
import MetalKit
import SwiftUI
import CoreGraphics

// MARK: - Uniform Structures
struct MaterialVertexUniforms {
    var z: Float
    var offsetX: Float
    var modelViewProjectionMatrix: matrix_float4x4
}

struct MaterialFragmentUniforms {
    var metallic: Float
    var roughness: Float
    var lightDir: SIMD3<Float>
    var lightIntensity: Float
    var topLightStrength: Float
    var rightLightStrength: Float
    var rimLightStrength: Float
    var layerType: UInt32 // 0=fill, 1=stroke, 2=artwork
}

// MARK: - Vertex Data with Normals
struct MaterialVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
    var texCoord: SIMD2<Float>
}

// MARK: - SVG Path Parser and Tessellator
class SVGTessellator {
    
    static func tessellateHexagonFill() -> [MaterialVertex] {
        // Create a simple, large hexagon that's definitely visible
        let vertices: [SIMD2<Float>] = [
            SIMD2<Float>(-0.6, -0.3),  // Top-left
            SIMD2<Float>(0.0, -0.7),   // Top 
            SIMD2<Float>(0.6, -0.3),   // Top-right
            SIMD2<Float>(0.6, 0.3),    // Bottom-right
            SIMD2<Float>(0.0, 0.7),    // Bottom
            SIMD2<Float>(-0.6, 0.3)    // Bottom-left
        ]
        
        print("Fill vertices: \(vertices)")
        return tessellatePolygon(vertices: vertices, z: 0.0)
    }
    
    static func tessellateHexagonStroke() -> [MaterialVertex] {
        // Create a simple stroke outline - larger and more visible
        let strokeWidth: Float = 0.1
        
        let outerVertices: [SIMD2<Float>] = [
            SIMD2<Float>(-0.7, -0.4),
            SIMD2<Float>(0.0, -0.8),
            SIMD2<Float>(0.7, -0.4),
            SIMD2<Float>(0.7, 0.4),
            SIMD2<Float>(0.0, 0.8),
            SIMD2<Float>(-0.7, 0.4)
        ]
        
        let innerVertices: [SIMD2<Float>] = [
            SIMD2<Float>(-0.5, -0.3),
            SIMD2<Float>(0.0, -0.6),
            SIMD2<Float>(0.5, -0.3),
            SIMD2<Float>(0.5, 0.3),
            SIMD2<Float>(0.0, 0.6),
            SIMD2<Float>(-0.5, 0.3)
        ]
        
        print("Stroke outer vertices: \(outerVertices)")
        print("Stroke inner vertices: \(innerVertices)")
        return tessellateStroke(outerVertices: outerVertices, innerVertices: innerVertices, z: 0.0)
    }
    
    static func tessellatePlayButton() -> [MaterialVertex] {
        // Create a simple, large play triangle that's definitely visible
        let playVertices: [SIMD2<Float>] = [
            SIMD2<Float>(-0.3, -0.3),  // Left point
            SIMD2<Float>(0.4, 0.0),    // Right point  
            SIMD2<Float>(-0.3, 0.3)    // Left bottom
        ]
        
        print("Artwork (play) vertices: \(playVertices)")
        return tessellatePolygon(vertices: playVertices, z: 0.0)
    }
    
    static private func tessellatePolygon(vertices: [SIMD2<Float>], z: Float) -> [MaterialVertex] {
        var tessellatedVertices: [MaterialVertex] = []
        
        // Simple fan tessellation for convex polygons
        if vertices.count >= 3 {
            let center = SIMD2<Float>(0, 0) // Use origin as center
            let normal = SIMD3<Float>(0, 0, 1) // Normal pointing towards camera
            
            print("Tessellating polygon with \(vertices.count) vertices at z=\(z)")
            
            for i in 0..<vertices.count {
                let current = vertices[i]
                let next = vertices[(i + 1) % vertices.count]
                
                // Create triangle: center -> current -> next
                tessellatedVertices.append(MaterialVertex(
                    position: SIMD3<Float>(center.x, center.y, z),
                    normal: normal,
                    texCoord: SIMD2<Float>(0.5, 0.5)
                ))
                tessellatedVertices.append(MaterialVertex(
                    position: SIMD3<Float>(current.x, current.y, z),
                    normal: normal,
                    texCoord: SIMD2<Float>((current.x + 1.0) * 0.5, (current.y + 1.0) * 0.5)
                ))
                tessellatedVertices.append(MaterialVertex(
                    position: SIMD3<Float>(next.x, next.y, z),
                    normal: normal,
                    texCoord: SIMD2<Float>((next.x + 1.0) * 0.5, (next.y + 1.0) * 0.5)
                ))
                
                if i == 0 {
                    print("  Triangle \(i): center=\(center), current=\(current), next=\(next)")
                }
            }
            
            print("  Generated \(tessellatedVertices.count) vertices")
        } else {
            print("ERROR: Not enough vertices for tessellation: \(vertices.count)")
        }
        
        return tessellatedVertices
    }
    
    static private func tessellateStroke(outerVertices: [SIMD2<Float>], innerVertices: [SIMD2<Float>], z: Float) -> [MaterialVertex] {
        var tessellatedVertices: [MaterialVertex] = []
        let normal = SIMD3<Float>(0, 0, 1)
        
        print("Tessellating stroke with \(outerVertices.count) outer and \(innerVertices.count) inner vertices at z=\(z)")
        
        for i in 0..<outerVertices.count {
            let nextIndex = (i + 1) % outerVertices.count
            
            let outer1 = outerVertices[i]
            let outer2 = outerVertices[nextIndex]
            let inner1 = innerVertices[i]
            let inner2 = innerVertices[nextIndex]
            
            if i == 0 {
                print("  Stroke quad \(i): outer1=\(outer1), inner1=\(inner1), outer2=\(outer2), inner2=\(inner2)")
            }
            
            // Create quad between outer and inner edges
            // Triangle 1: outer1 -> inner1 -> outer2
            tessellatedVertices.append(MaterialVertex(
                position: SIMD3<Float>(outer1.x, outer1.y, z),
                normal: normal,
                texCoord: SIMD2<Float>((outer1.x + 1.0) * 0.5, (outer1.y + 1.0) * 0.5)
            ))
            tessellatedVertices.append(MaterialVertex(
                position: SIMD3<Float>(inner1.x, inner1.y, z),
                normal: normal,
                texCoord: SIMD2<Float>((inner1.x + 1.0) * 0.5, (inner1.y + 1.0) * 0.5)
            ))
            tessellatedVertices.append(MaterialVertex(
                position: SIMD3<Float>(outer2.x, outer2.y, z),
                normal: normal,
                texCoord: SIMD2<Float>((outer2.x + 1.0) * 0.5, (outer2.y + 1.0) * 0.5)
            ))
            
            // Triangle 2: inner1 -> inner2 -> outer2
            tessellatedVertices.append(MaterialVertex(
                position: SIMD3<Float>(inner1.x, inner1.y, z),
                normal: normal,
                texCoord: SIMD2<Float>((inner1.x + 1.0) * 0.5, (inner1.y + 1.0) * 0.5)
            ))
            tessellatedVertices.append(MaterialVertex(
                position: SIMD3<Float>(inner2.x, inner2.y, z),
                normal: normal,
                texCoord: SIMD2<Float>((inner2.x + 1.0) * 0.5, (inner2.y + 1.0) * 0.5)
            ))
            tessellatedVertices.append(MaterialVertex(
                position: SIMD3<Float>(outer2.x, outer2.y, z),
                normal: normal,
                texCoord: SIMD2<Float>((outer2.x + 1.0) * 0.5, (outer2.y + 1.0) * 0.5)
            ))
        }
        
        print("  Generated \(tessellatedVertices.count) stroke vertices")
        return tessellatedVertices
    }
}

// MARK: - Material Badge Renderer
class MaterialBadgeRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var renderPipelineState: MTLRenderPipelineState!
    private var depthStencilState: MTLDepthStencilState!
    private var drawCount = 0
    
    // Tessellated geometry buffers
    private var fillVertexBuffer: MTLBuffer!
    private var strokeVertexBuffer: MTLBuffer!
    private var artworkVertexBuffer: MTLBuffer!
    private var fillVertexCount: Int = 0
    private var strokeVertexCount: Int = 0
    private var artworkVertexCount: Int = 0
    
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
        setupGeometry()
        setupUniformBuffers()
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
        
        print("Available functions in Material library: \(library.functionNames)")
        
        guard let vertexFunction = library.makeFunction(name: "materialVertexShader"),
              let fragmentFunction = library.makeFunction(name: "materialFragmentShader") else {
            print("FAILED to load Material shader functions - available: \(library.functionNames)")
            fatalError("Could not create Material shader functions")
        }
        
        print("Successfully loaded Material shader functions: materialVertexShader, materialFragmentShader")
        
        // Vertex descriptor for MaterialVertex
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3 // position
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        
        vertexDescriptor.attributes[1].format = .float3 // normal
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.size
        
        vertexDescriptor.attributes[2].format = .float2 // texCoord
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD3<Float>>.size * 2
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<MaterialVertex>.stride
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
            print("Material render pipeline created successfully")
        } catch {
            fatalError("Could not create Material render pipeline state: \(error)")
        }
    }
    
    private func setupDepthStencilState() {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .lessEqual  // Enable proper depth testing
        depthStencilDescriptor.isDepthWriteEnabled = true        // Enable depth writing
        
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
        print("Material depth stencil configured: lessEqual comparison, depth write enabled")
    }
    
    private func setupGeometry() {
        // Tessellate SVG assets
        let fillVertices = SVGTessellator.tessellateHexagonFill()
        let strokeVertices = SVGTessellator.tessellateHexagonStroke()
        let artworkVertices = SVGTessellator.tessellatePlayButton()
        
        fillVertexCount = fillVertices.count
        strokeVertexCount = strokeVertices.count
        artworkVertexCount = artworkVertices.count
        
        print("Tessellated geometry: Fill=\(fillVertexCount), Stroke=\(strokeVertexCount), Artwork=\(artworkVertexCount)")
        
        // Create vertex buffers
        fillVertexBuffer = device.makeBuffer(bytes: fillVertices, 
                                           length: fillVertices.count * MemoryLayout<MaterialVertex>.stride, 
                                           options: [])
        strokeVertexBuffer = device.makeBuffer(bytes: strokeVertices, 
                                             length: strokeVertices.count * MemoryLayout<MaterialVertex>.stride, 
                                             options: [])
        artworkVertexBuffer = device.makeBuffer(bytes: artworkVertices, 
                                              length: artworkVertices.count * MemoryLayout<MaterialVertex>.stride, 
                                              options: [])
    }
    
    private func setupUniformBuffers() {
        vertexUniformBuffer = device.makeBuffer(length: MemoryLayout<MaterialVertexUniforms>.stride, options: [])
        fragmentUniformBuffer = device.makeBuffer(length: MemoryLayout<MaterialFragmentUniforms>.stride, options: [])
    }
    
    // MARK: - MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle resize if needed
    }
    
    func draw(in view: MTKView) {
        drawCount += 1
        let shouldLog = drawCount % 60 == 1 // Log every 60 frames
        
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
        
        // Light direction (from top-right)
        let lightDir = normalize(SIMD3<Float>(-0.3, 0.7, 0.8))
        
        // DEBUG: Render three tessellated layers (back to front) with extensive logging
        
        print("=== RENDER FRAME START ===")
        print("Fill vertices: \(fillVertexCount), Stroke vertices: \(strokeVertexCount), Artwork vertices: \(artworkVertexCount)")
        
        // Render all three tessellated layers overlapping at center (last rendered is visible)
        
        // Layer 1: Fill (background) - Should be GREEN
        if fillVertexCount > 0 {
            print("DRAWING FILL (GREEN) - vertices: \(fillVertexCount), layerType: 0, z: -0.1")
            drawMaterialPass(renderEncoder: renderEncoder, 
                           vertexBuffer: fillVertexBuffer, 
                           vertexCount: fillVertexCount,
                           z: -0.1, 
                           metallic: fillMetallic, 
                           roughness: globalRoughness, 
                           lightDir: lightDir,
                           layerType: 0)
        } else {
            print("SKIPPING FILL - no vertices")
        }
        
        // Layer 2: Stroke (middle) - Should be RED  
        if strokeVertexCount > 0 {
            print("DRAWING STROKE (RED) - vertices: \(strokeVertexCount), layerType: 1, z: 0.0")
            drawMaterialPass(renderEncoder: renderEncoder, 
                           vertexBuffer: strokeVertexBuffer, 
                           vertexCount: strokeVertexCount,
                           z: 0.0, 
                           metallic: strokeMetallic, 
                           roughness: globalRoughness, 
                           lightDir: lightDir,
                           layerType: 1)
        } else {
            print("SKIPPING STROKE - no vertices")
        }
        
        // Layer 3: Artwork (front) - Should be BLUE
        if artworkVertexCount > 0 {
            print("DRAWING ARTWORK (BLUE) - vertices: \(artworkVertexCount), layerType: 2, z: 0.1")
            drawMaterialPass(renderEncoder: renderEncoder, 
                           vertexBuffer: artworkVertexBuffer, 
                           vertexCount: artworkVertexCount,
                           z: 0.1, 
                           metallic: artworkMetallic, 
                           roughness: globalRoughness, 
                           lightDir: lightDir,
                           layerType: 2)
        } else {
            print("SKIPPING ARTWORK - no vertices")
        }
        
        print("=== RENDER FRAME END ===")
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        if shouldLog {
            print("Material render passes completed and committed")
        }
    }
    
    private func drawMaterialPass(renderEncoder: MTLRenderCommandEncoder, 
                                vertexBuffer: MTLBuffer,
                                vertexCount: Int,
                                z: Float, 
                                metallic: Float, 
                                roughness: Float, 
                                lightDir: SIMD3<Float>,
                                layerType: UInt32) {
        
        // Create identity matrix for now (could add rotation/scale later)
        let modelViewProjectionMatrix = matrix_identity_float4x4
        
        // Update vertex uniforms
        let vertexUniformsPointer = vertexUniformBuffer.contents().bindMemory(to: MaterialVertexUniforms.self, capacity: 1)
        vertexUniformsPointer.pointee = MaterialVertexUniforms(
            z: z,
            offsetX: 0.0, // No offset - centered
            modelViewProjectionMatrix: modelViewProjectionMatrix
        )
        
        // Update fragment uniforms
        let fragmentUniformsPointer = fragmentUniformBuffer.contents().bindMemory(to: MaterialFragmentUniforms.self, capacity: 1)
        fragmentUniformsPointer.pointee = MaterialFragmentUniforms(
            metallic: metallic, 
            roughness: roughness, 
            lightDir: lightDir,
            lightIntensity: lightIntensity,
            topLightStrength: topLightStrength,
            rightLightStrength: rightLightStrength,
            rimLightStrength: rimLightStrength,
            layerType: layerType
        )
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(vertexUniformBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(fragmentUniformBuffer, offset: 0, index: 2)
        
        // Draw triangles
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }
}

// MARK: - SwiftUI Wrapper
struct MaterialBadgeMetalView: UIViewRepresentable {
    let strokeMetallic: Float
    let fillMetallic: Float
    let artworkMetallic: Float
    let globalRoughness: Float
    let lightIntensity: Float
    let topLightStrength: Float
    let rightLightStrength: Float
    let rimLightStrength: Float
    
    func makeUIView(context: Context) -> MTKView {
        print("=== CREATING MATERIAL BADGE METAL VIEW ===")
        let metalView = MTKView()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        
        metalView.device = device
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) // White background
        
        // Configure drawing behavior
        metalView.isPaused = false
        metalView.enableSetNeedsDisplay = true
        metalView.framebufferOnly = true
        metalView.preferredFramesPerSecond = 60
        
        print("Creating MaterialBadgeRenderer...")
        let renderer = MaterialBadgeRenderer(device: device)
        metalView.delegate = renderer
        
        // Store renderer to prevent deallocation
        context.coordinator.renderer = renderer
        
        print("Material MTKView configured with device: \(device.name)")
        
        // Trigger initial draw
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
        var renderer: MaterialBadgeRenderer?
    }
}