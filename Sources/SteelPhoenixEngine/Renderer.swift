import MetalKit

let SHADERS_DIR_LOCAL_PATH        = "/Sources/Shaders"
let DEFAULT_SHADER_LIB_LOCAL_PATH = SHADERS_DIR_LOCAL_PATH + "/default.metallib"

public class Renderer : NSObject
{
    public  var mView:          MTKView

    private let mCommandQueue:  MTLCommandQueue
    private let mPipelineState: MTLRenderPipelineState

    private let mIndexBuffer:   MTLBuffer?

    let vertexData: [SIMD3<Float>] =
    [
        // v0
        [-0.5, -0.5, 0.0 ], // position
        [ 1.0,  0.0, 0.0 ], // color
        // v1
        [ 0.5, -0.5, 0.0 ],
        [ 0.0,  1.0, 0.0 ],
        // v2
        [ 0.5,  0.5, 0.0 ],
        [ 0.0,  0.0, 1.0 ],
        // v3
        [-0.5,  0.5, 0.0 ],
        [ 1.0,  1.0, 1.0 ],
    ]

    let indices: [UInt16] = [ 0, 1, 2, 2, 3, 0 ]

    public init(mtkView: MTKView)
    {
        mView = mtkView

        guard let cq = mView.device?.makeCommandQueue() else
        {
            fatalError("Could not create command queue")
        }
        mCommandQueue = cq

        let shaderLibPath = FileManager.default
                                       .currentDirectoryPath +
                            DEFAULT_SHADER_LIB_LOCAL_PATH

        guard let library = try! mView.device?.makeLibrary(filepath: shaderLibPath) else
        {
            fatalError("No shader library!")
        }
        let vertexFunction   = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")

        let vertDesc = MTLVertexDescriptor()
        vertDesc.attributes[0].format      = .float3
        vertDesc.attributes[0].bufferIndex = 0
        vertDesc.attributes[0].offset      = 0
        vertDesc.attributes[1].format      = .float3
        vertDesc.attributes[1].bufferIndex = 0
        vertDesc.attributes[1].offset      = MemoryLayout<SIMD3<Float>>.stride
        vertDesc.layouts[0].stride         = MemoryLayout<SIMD3<Float>>.stride * 2

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.vertexFunction                  = vertexFunction
        pipelineDescriptor.fragmentFunction                = fragmentFunction
        pipelineDescriptor.vertexDescriptor                = vertDesc

        guard let ps = try! mView.device?.makeRenderPipelineState(descriptor: pipelineDescriptor) else
        {
            fatalError("Couldn't create pipeline state")
        }
        mPipelineState = ps

        mIndexBuffer = mView.device?.makeBuffer(bytes: indices,
                                                length: indices.count * MemoryLayout.size(ofValue: indices[0]),
                                                options: [])
        if mIndexBuffer == nil
        {
            print("WARNING: No index buffer!") // TODO: proper logging
        }

        super.init()
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
        let dataSize       = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        let vertexBuffer   = mView.device?.makeBuffer(bytes: vertexData, length: dataSize, options: [])

        let commandBuffer  = mCommandQueue.makeCommandBuffer()!

        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: mView.currentRenderPassDescriptor!)
        commandEncoder?.setRenderPipelineState(mPipelineState)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

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
            print("WARNING: No index buffer!") // TODO: proper logging
            commandEncoder?.drawPrimitives(type: .triangle,
                                           vertexStart: 0,
                                           vertexCount: vertexData.count / 2,
                                           instanceCount: 1)
        }
        commandEncoder?.endEncoding()

        commandBuffer.present(mView.currentDrawable!)
        commandBuffer.commit()
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