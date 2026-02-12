#version 150

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>

uniform sampler2D Sampler0;

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
in vec4 vertexColor;
in vec4 lightMapColor;
in vec4 overlayColor;
in vec2 texCoord0;

out vec4 fragColor;

// stuff needed for the bobber
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:light.glsl>

const mat3 IViewRotMat = mat3(1);
#moj_import <minecraft:bobber.glsl>

void main() {
    vec4 color = vec4(0);
    gl_FragDepth = gl_FragCoord.z;
    if (isBobber > 0.5) {
        if (!doBobber(color)) {
            discard;
            return;
        }
    } else {
        color = texture(Sampler0, texCoord0);
    }
#ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) {
        discard;
    }
#endif
    color *= vertexColor * ColorModulator;
#ifndef NO_OVERLAY
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
#endif
#ifndef EMISSIVE
    color *= lightMapColor;
#endif
    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}