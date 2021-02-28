import MetalKit

public class Renderer
{
    public  var view:          MTKView

    private let device:        MTLDevice
    private let commandQueue:  MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState

    let shader = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexIn {
    float4 position [[ attribute(0) ]];
    };

    vertex float4 vertex_main(const VertexIn vertex_in [[ stage_in ]]) {
    return vertex_in.position;
    }

    fragment float4 fragment_main() {
    return float4(1, 0, 0, 1);
    }
    """

    public init(w: Int, h: Int)
    {
        guard let d = MTLCreateSystemDefaultDevice() else
        {
            fatalError("GPU is not supported")
        }

        self.device = d

        let rect = NSRect(x: 0, y: 0, width: w, height: h)

        self.view = MTKView(frame: rect, device: device)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.green.cgColor
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        guard let cq = self.device.makeCommandQueue() else
        {
            fatalError("Could not create command queue")
        }

        self.commandQueue = cq

        let allocator = MTKMeshBufferAllocator(device: device)
        let mdlMesh   = MDLMesh(sphereWithExtent: [0.75, 0.75, 0.75],
                                segments: [100, 100],
                                inwardNormals: false,
                                geometryType: .triangles,
                                allocator: allocator)
        let mesh: MTKMesh?
        do {
            mesh = try MTKMesh(mesh: mdlMesh, device: device)
        } catch {
            fatalError("Failed creating mesh")
        }
        if mesh == nil { fatalError("NO MESH") }

        guard let submesh = mesh!.submeshes.first else { fatalError() }

        do
        {
            let library          = try self.device.makeLibrary(source: shader, options: nil)
            let vertexFunction   = library.makeFunction(name: "vertex_main")
            let fragmentFunction = library.makeFunction(name: "fragment_main")

            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.vertexFunction                  = vertexFunction
            pipelineDescriptor.fragmentFunction                = fragmentFunction
            pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh!.vertexDescriptor)

            self.pipelineState = try self.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        catch
        {
            fatalError("Shader failed compiling")
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { fatalError() }

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(mesh!.vertexBuffers[0].buffer, offset: 0, index: 0)
        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: submesh.indexCount,
                                            indexType: submesh.indexType,
                                            indexBuffer: submesh.indexBuffer.buffer,
                                            indexBufferOffset: 0)
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else { fatalError() }
        commandBuffer.present(drawable)
        commandBuffer.commit()


    }

}