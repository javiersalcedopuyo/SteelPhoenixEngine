import MetalKit

public class Renderer : NSObject
{
    public  var view:          MTKView
    private let commandQueue:  MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState

    let vertexData: [Float] =
    [
         0.0,  1.0, 0.0,
        -1.0, -1.0, 0.0,
         1.0, -1.0, 0.0
    ]

    let shader = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexIn {
    float4 position;
    };

    vertex float4 vertex_main(const device packed_float3* vertex_array [[ buffer(0) ]], unsigned int vid [[ vertex_id ]]) {
    return float4(vertex_array[vid], 1.0);
    }

    fragment float4 fragment_main() {
    return float4(1, 1, 1, 1);
    }
    """

    public init(mtkView: MTKView)
    {
        self.view = mtkView

        guard let cq = self.view.device?.makeCommandQueue() else
        {
            fatalError("Could not create command queue")
        }
        self.commandQueue = cq

        guard let library = try! self.view.device?.makeLibrary(source: shader, options: nil) else
        {
            fatalError("Shader compiling failed")
        }
        let vertexFunction   = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.vertexFunction                  = vertexFunction
        pipelineDescriptor.fragmentFunction                = fragmentFunction

        guard let ps = try! self.view.device?.makeRenderPipelineState(descriptor: pipelineDescriptor) else
        {
            fatalError("Couldn't create pipeline state")
        }
        self.pipelineState = ps
    }

    public func update()
    {
        struct Wrapper { static var i = 0.0 }
        Wrapper.i = (Wrapper.i + 0.01).truncatingRemainder(dividingBy: 1.0)

        self.view.clearColor = MTLClearColor(red: Wrapper.i, green: 0, blue: 0, alpha: 1)
        self.render()
    }

    func render()
    {
        let dataSize       = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        let vertexBuffer   = self.view.device?.makeBuffer(bytes: vertexData, length: dataSize, options: [])

        let commandBuffer  = self.commandQueue.makeCommandBuffer()!

        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: self.view.currentRenderPassDescriptor!)
        //commandEncoder?.setViewport(self.viewport)
        commandEncoder?.setRenderPipelineState(self.pipelineState)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder?.drawPrimitives(type: .triangle,
                                       vertexStart: 0,
                                       vertexCount: 3,
                                       instanceCount: 1)
        commandEncoder?.endEncoding()

        commandBuffer.present(self.view.currentDrawable!)
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