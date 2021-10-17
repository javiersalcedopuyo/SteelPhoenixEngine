import Foundation
import MetalKit
import SLA
import SimpleLogs

let VERTEX_BUFFER_INDEX  = 0
let UNIFORM_BUFFER_INDEX = 1

let WORLD_UP = Vector3(x:0, y:1, z:0)

let TEST_MODEL_NAME = "bunny"
let TEST_MODEL_EXTENSION = "obj"

public class Renderer : NSObject
{
    public  var mView:          MTKView

    private let mCommandQueue:  MTLCommandQueue
    private let mPipelineState: MTLRenderPipelineState

    private var mModel:         Model?
    // TODO: Load textures on demand
    private var mTexture:       MTLTexture?
    // TODO: Pre-built collection?
    private var mSamplerState:  MTLSamplerState?

    private var mDepthStencilState: MTLDepthStencilState?

    public init(mtkView: MTKView)
    {
        if mtkView.device == nil
        {
            fatalError("NO GPU!")
        }

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

        if let modelURL = Bundle.module.url(forResource: TEST_MODEL_NAME,
                                            withExtension: TEST_MODEL_EXTENSION)
        {
            mModel = Model(device: mtkView.device!, url: modelURL)
        }
        else
        {
            SimpleLogs.ERROR("Couldn't load model '" + TEST_MODEL_NAME + "." + TEST_MODEL_EXTENSION + "'")
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.vertexFunction                  = vertexFunction
        pipelineDescriptor.fragmentFunction                = fragmentFunction
        pipelineDescriptor.vertexDescriptor                = mModel?.mVertexDescriptor
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
        let vertexBuffer = mModel?.mMeshes[0].vertexBuffers[0].buffer

        // TODO: Use Constant Buffer?
        var ubo   = UniformBufferObject()
        ubo.model = Matrix4x4.identity()
        ubo.view  = Matrix4x4.lookAtLH(eye: Vector3(x:0, y:0.25, z:0.5),
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
        commandEncoder?.setFrontFacing(.clockwise) // TODO: According to model?
        commandEncoder?.setCullMode(.back)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: VERTEX_BUFFER_INDEX)
        commandEncoder?.setVertexBuffer(uniformBuffer, offset: 0, index: UNIFORM_BUFFER_INDEX)
        commandEncoder?.setFragmentTexture(mTexture, index: 0)
        commandEncoder?.setFragmentSamplerState(mSamplerState, index: 0)

        if (mModel != nil)
        {
            for submesh in mModel!.mMeshes[0].submeshes
            {
                commandEncoder?.drawIndexedPrimitives(type: submesh.primitiveType,
                                                      indexCount: submesh.indexCount,
                                                      indexType: submesh.indexType,
                                                      indexBuffer: submesh.indexBuffer.buffer,
                                                      indexBufferOffset: submesh.indexBuffer.offset)
            }
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
