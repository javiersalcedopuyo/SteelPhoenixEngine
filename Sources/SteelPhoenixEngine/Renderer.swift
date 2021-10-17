import Foundation
import MetalKit
import SLA
import SimpleLogs

let VERTEX_BUFFER_INDEX  = 0
let UNIFORM_BUFFER_INDEX = 1

let WORLD_UP = Vector3(x:0, y:1, z:0)

public class Renderer : NSObject
{
    public  var mView:          MTKView

    private let mCommandQueue:  MTLCommandQueue
    private let mPipelineState: MTLRenderPipelineState

    private let mIndexBuffer:   MTLBuffer?

    // TODO: Load textures on demand
    private var mTexture:       MTLTexture?
    // TODO: Pre-built collection?
    private var mSamplerState:  MTLSamplerState?

    private var mDepthStencilState: MTLDepthStencilState?

    // TODO: use an array of Vertex
    // TODO: Load from file
    // TODO: Load models on demand
    let indices: [UInt16] = [ 0, 1, 2, 2, 3, 0 ]
    let vertexData: [SIMD3<Float>] =
    [
        // v0
        [-0.5, -0.5, 0.0 ], // position
        [ 1.0,  0.0, 0.0 ], // color
        [ 0.0,  1.0, 0.0 ], // UVs TODO: use just 2 floats
        // v1
        [ 0.5, -0.5, 0.0 ],
        [ 0.0,  1.0, 0.0 ],
        [ 1.0,  1.0, 0.0 ],
        // v2
        [ 0.5,  0.5, 0.0 ],
        [ 0.0,  0.0, 1.0 ],
        [ 1.0,  0.0, 0.0 ],
        // v3
        [-0.5,  0.5, 0.0 ],
        [ 1.0,  1.0, 1.0 ],
        [ 0.0,  0.0, 0.0 ]
    ]
    let vertexData2: [SIMD3<Float>] =
    [
        // v0
        [-0.5, -0.5, 0.5 ], // position
        [ 1.0,  0.0, 0.0 ], // color
        [ 0.0,  1.0, 0.0 ], // UVs TODO: use just 2 floats
        // v1
        [ 0.5, -0.5, 0.5 ],
        [ 0.0,  1.0, 0.0 ],
        [ 1.0,  1.0, 0.0 ],
        // v2
        [ 0.5,  0.5, 0.5 ],
        [ 0.0,  0.0, 1.0 ],
        [ 1.0,  0.0, 0.0 ],
        // v3
        [-0.5,  0.5, 0.5 ],
        [ 1.0,  1.0, 1.0 ],
        [ 0.0,  0.0, 0.0 ]
    ]

    public init(mtkView: MTKView)
    {
        mView = mtkView
        mView.depthStencilPixelFormat = MTLPixelFormat.depth16Unorm
        mView.clearDepth              = 1.0

        guard let cq = mView.device?.makeCommandQueue() else
        {
            fatalError("Could not create command queue")
        }
        mCommandQueue = cq

        guard let shaderLibURL = Bundle.module.url(forResource:   "test",
                                                   withExtension: "metallib")
        else
        {
            fatalError("Couldn't find shader metallib!")
        }

        guard let library = try! mView.device?.makeLibrary(URL: shaderLibURL) else
        {
            fatalError("Couldn't create shader library!")
        }
        let vertexFunction   = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")

        let vertDesc = MTLVertexDescriptor()
        // Position
        vertDesc.attributes[0].format      = .float3
        vertDesc.attributes[0].bufferIndex = VERTEX_BUFFER_INDEX
        vertDesc.attributes[0].offset      = 0
        // Color
        vertDesc.attributes[1].format      = .float3
        vertDesc.attributes[1].bufferIndex = VERTEX_BUFFER_INDEX
        vertDesc.attributes[1].offset      = MemoryLayout<SIMD3<Float>>.stride
        // TODO: Normals
        vertDesc.attributes[2].format      = .float3
        vertDesc.attributes[2].bufferIndex = VERTEX_BUFFER_INDEX
        vertDesc.attributes[2].offset      = 0 // TODO: MemoryLayout<SIMD3<Float>>.stride
        // UVs
        vertDesc.attributes[3].format      = .float2
        vertDesc.attributes[3].bufferIndex = VERTEX_BUFFER_INDEX
        vertDesc.attributes[3].offset      = MemoryLayout<SIMD3<Float>>.stride * 2

        vertDesc.layouts[0].stride         = MemoryLayout<SIMD3<Float>>.stride * 3

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.vertexFunction                  = vertexFunction
        pipelineDescriptor.fragmentFunction                = fragmentFunction
        pipelineDescriptor.vertexDescriptor                = vertDesc
        pipelineDescriptor.depthAttachmentPixelFormat      = mView.depthStencilPixelFormat

        guard let ps = try! mView.device?.makeRenderPipelineState(descriptor: pipelineDescriptor) else
        {
            fatalError("Couldn't create pipeline state")
        }
        mPipelineState = ps

        let depthStencilDesc = MTLDepthStencilDescriptor()
        depthStencilDesc.depthCompareFunction = .less
        depthStencilDesc.isDepthWriteEnabled  = true

        mDepthStencilState = mView.device?.makeDepthStencilState(descriptor: depthStencilDesc)

        mIndexBuffer = mView.device?.makeBuffer(bytes: indices,
                                                length: indices.count * MemoryLayout.size(ofValue: indices[0]),
                                                options: [])
        if mIndexBuffer == nil
        {
            SimpleLogs.ERROR("Failed creating index buffer!")
        }

        super.init()

        self.loadTextures()
        self.buildSamplerState()

        mView.delegate = self
    }

    public func update()
    {
        struct Wrapper { static var i = 0.0 }
        Wrapper.i = (Wrapper.i + 0.01).truncatingRemainder(dividingBy: 1.0)

        self.render()
    }

    func render()
    {
        let dataSize     = vertexData.count * MemoryLayout<SIMD3<Float>>.size
        let vertexBuffer = mView.device?.makeBuffer(bytes: vertexData,
                                                    length: dataSize,
                                                    options: [])
        let vertexBuffer2 = mView.device?.makeBuffer(bytes: vertexData2,
                                                    length: dataSize,
                                                    options: [])

        // TODO: Use Constant Buffer?
        var ubo   = UniformBufferObject()
        ubo.model = Matrix4x4.identity()
        ubo.view  = Matrix4x4.lookAtLH(eye: Vector3(x:1, y:1, z:-1),
                                       target: Vector3.zero(),
                                       upAxis: WORLD_UP)
        ubo.proj  = Matrix4x4.perspectiveLH(fovy: SLA.deg2rad(45.0),
                                            aspectRatio: Float(mView.frame.width / mView.frame.height),
                                            near: 0.1,
                                            far: 10.0)

        let uniformsSize  = ubo.size()
        let uniformBuffer = mView.device?.makeBuffer(bytes: ubo.asArray(),
                                                     length: uniformsSize,
                                                     options: [])

        let commandBuffer  = mCommandQueue.makeCommandBuffer()!

        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: mView.currentRenderPassDescriptor!)
        commandEncoder?.setRenderPipelineState(mPipelineState)
        commandEncoder?.setDepthStencilState(mDepthStencilState)
        commandEncoder?.setFrontFacing(.counterClockwise)
        commandEncoder?.setCullMode(.back)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: VERTEX_BUFFER_INDEX)
        commandEncoder?.setVertexBuffer(uniformBuffer, offset: 0, index: UNIFORM_BUFFER_INDEX)
        commandEncoder?.setFragmentTexture(mTexture, index: 0)
        commandEncoder?.setFragmentSamplerState(mSamplerState, index: 0)

        if mIndexBuffer != nil
        {
            commandEncoder?.drawIndexedPrimitives(type: .triangle,
                                                  indexCount: 6,
                                                  indexType: .uint16,
                                                  indexBuffer: mIndexBuffer!,
                                                  indexBufferOffset: 0)
        }
        else
        {
            SimpleLogs.WARNING("No index buffer!")
            commandEncoder?.drawPrimitives(type: .triangle,
                                           vertexStart: 0,
                                           vertexCount: vertexData.count / 2,
                                           instanceCount: 1)
        }

        commandEncoder?.setVertexBuffer(vertexBuffer2, offset: 0, index: VERTEX_BUFFER_INDEX)

        if mIndexBuffer != nil
        {
            commandEncoder?.drawIndexedPrimitives(type: .triangle,
                                                  indexCount: 6,
                                                  indexType: .uint16,
                                                  indexBuffer: mIndexBuffer!,
                                                  indexBufferOffset: 0)
        }
        else
        {
            SimpleLogs.WARNING("No index buffer!")
            commandEncoder?.drawPrimitives(type: .triangle,
                                           vertexStart: 0,
                                           vertexCount: vertexData.count / 2,
                                           instanceCount: 1)
        }
        commandEncoder?.endEncoding()

        commandBuffer.present(mView.currentDrawable!)
        commandBuffer.commit()
    }

    private func loadTextures()
    {
        // TODO: Async?
        let textureURL = Bundle.module.url(forResource:   "TestTexture1",
                                           withExtension: "png")

        if textureURL != nil
        {
            let texLoader = MTKTextureLoader(device: mView.device!)
            do
            {
                mTexture = try texLoader.newTexture(URL: textureURL!)
            }
            catch
            {
                mTexture = nil
            }
        }
        else
        {
            SimpleLogs.ERROR("Couldn't load texture!")
            mTexture = nil
        }
    }

    private func buildSamplerState()
    {
        // TODO: Read sampler descriptors from file?
        let texSamplerDesc          = MTLSamplerDescriptor()
        texSamplerDesc.minFilter    = .nearest
        texSamplerDesc.magFilter    = .linear
        texSamplerDesc.sAddressMode = .mirrorRepeat
        texSamplerDesc.tAddressMode = .mirrorRepeat

        mSamplerState = mView.device?.makeSamplerState(descriptor: texSamplerDesc)
    }
}

extension Renderer: MTKViewDelegate
{
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        // TODO
    }

    public func draw(in view: MTKView)
    {
        self.update()
    }
}
