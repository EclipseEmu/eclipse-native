#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 textureCoordinates [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinates [[user(tex_coords)]];
};

vertex VertexOut framebuffer_vertex_main(uint vertexID [[vertex_id]], const device VertexIn* vertexArray [[buffer(0)]]) {
    VertexOut outVertex;
    outVertex.position = float4(vertexArray[vertexID].position, 0.0, 1.0);
    outVertex.textureCoordinates = vertexArray[vertexID].textureCoordinates;
    return outVertex;
}

fragment half4 framebuffer_fragment_main(VertexOut in [[stage_in]], texture2d<half> diffuseMap [[texture(0)]], sampler textureSampler [[sampler(0)]]) {
    return diffuseMap.sample(textureSampler, in.textureCoordinates);
}
