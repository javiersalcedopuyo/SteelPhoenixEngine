#include <metal_stdlib>
using namespace metal;

struct UniformBufferObject
{
    float4x4 model;
    float4x4 view;
    float4x4 proj;
};

struct VertexIn
{
    float3 position [[ attribute(0) ]];
    float3 color    [[ attribute(1) ]];
};

struct VertexOut
{
    float4 position [[ position ]];
    float3 color;
};

vertex
VertexOut vertex_main(VertexIn vert [[ stage_in ]],
                      constant UniformBufferObject& ubo [[ buffer(1) ]])
{
    VertexOut out;
    out.position = ubo.proj * ubo.view * ubo.model * float4(vert.position, 1.0f);
    out.color    = vert.color;
    return out;
}

fragment
float4 fragment_main(VertexOut frag [[ stage_in ]])
{
    return sqrt(float4(frag.color, 1.0));
}