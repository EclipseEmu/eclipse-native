#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 tex_coords [[user(tex_coords)]];
};

vertex VertexOut framebuffer_vertex_main(uint vertex_id [[vertex_id]]) {
    VertexOut result;
    result.tex_coords = {
        // NOTE: the right into a left shift is not useless here!
        (float)((vertex_id >> 1) << 1),
        (float)((vertex_id & 1) << 1)
    };

    result.position = float4(result.tex_coords.x * 2.0 - 1.0, 1.0 - result.tex_coords.y * 2.0, 0.0, 1.0);

    return result;
}

fragment half4 framebuffer_fragment_main(VertexOut v [[stage_in]], texture2d<half> diffuse [[texture(0)]], sampler sampler [[sampler(0)]]) {
    return diffuse.sample(sampler, v.tex_coords);
}
