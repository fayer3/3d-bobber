#version 150

#moj_import <fog.glsl>
#moj_import <light.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

uniform mat4 ModelViewMat;
uniform mat3 IViewRotMat;
uniform mat4 ProjMat;
uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightMapColor;
in vec4 overlayColor;
in vec2 texCoord0;

out vec4 fragColor;

#moj_import <bobber.glsl>

bool doBobber2(out vec4 color) {
    #ifdef DEBUG
        // debug show outline
        if (any(greaterThan(abs(texCoord0-0.5), vec2(0.49)))) {
            color = vec4(1,1,0,1);
            return true;
        }
    #endif

    vec3 corner1 = Pos1.xyz / Pos1.w;
    vec3 corner2 = Pos2.xyz / Pos2.w;

    vec3 Pos = (corner1 + corner2) * 0.5;
    Pos.y += Yoffset;

    vec3 dir = normalize(-viewPos.xyz);

    vec3 worldDir;
    if (IViewRotMat[0].x > 0.999 && IViewRotMat[1].y > 0.999 && IViewRotMat[2].z > 0.999) {
        // 1.20.5+ removes IViewRotMat
        worldDir = dir * mat3(ModelViewMat);
    } else {
        worldDir = IViewRotMat*dir;
    }

    #if bobbermode == bobber3Dbasic
        vec3 stringNormal = vec3(0.0);
        #ifdef bobberString
            float stringIntersect = min(
                boxIntersection(Pos - vec3(0.00, -0.125, 0.0), worldDir, vec3(0.03125, 0.03125, 0.0), stringNormal),
                boxIntersection(Pos - vec3(0.00, -0.125, 0.0), worldDir, vec3(0.0, 0.03125, 0.03125), stringNormal));
        #else
            float stringIntersect = 10000.0;
        #endif
        vec4 stringColor = vec4(0.0, 0.0, 0.0, float(stringIntersect > 0.0));
        vec3 hookNormal = vec3(0.0);
        float hookIntersect = boxIntersection(Pos - vec3(-0.03125, 0.2, 0.0), worldDir, vec3(0.125, 0.125, 0.0), hookNormal);
        vec4 hookColor = vec4(0.0);
        if (hookIntersect < 9999.0) {
            vec2 txCoord = (Pos.xyz - vec3(-0.03125, 0.2, 0.0) + hookIntersect * worldDir).xy * 8.0;
            hookColor = texture(Sampler0, vec2(0.5, 0.75) + txCoord * vec2(0.25));
            hookIntersect = hookColor.a < 0.1 ? 10000 : hookIntersect;
        }

        vec3 bobberNormal = vec3(0);
        vec4 bobberColor = vec4(0);
        float bobberIntersect = boxIntersection(Pos, worldDir, vec3(0.09375), bobberNormal);
        if (bobberIntersect < 9999.0) {
            vec2 txCoord = (Pos.xyz + bobberNormal * 0.001  + bobberIntersect  * worldDir).xy * 10.66666666;
            bobberColor = texture(Sampler0, vec2(0.5625, 0.3125) + txCoord * vec2(0.1875));
            bobberColor = minecraft_mix_light(Light0_Direction, Light1_Direction, bobberNormal * IViewRotMat, bobberColor);
        }
        float depth = min(min(hookIntersect, bobberIntersect), stringIntersect);
        if (depth > 9999.0) {
            return false;
        }

        color = mix(mix(bobberColor, hookColor, float(hookIntersect < bobberIntersect)), stringColor, float(stringIntersect < min(hookIntersect, bobberIntersect)));
    #else
        float depth = 10000;
        vec2 pixelSize = 1.0 / vec2(textureSize(Sampler0, 0));
        vec3 hookNormal = vec3(0);

        #ifdef bobberString
            depth = boxIntersection(Pos+vec3((vec2(0,0.5-1.0/8.0))*0.5, 0), worldDir, vec3(1.0/16.0)*0.5, hookNormal);
            color.a = depth < 9999.0 ? 1 : 0;
        #endif

        #if bobbermode == bobber3Dflat
            flatIntersect(ivec2(0), textureSize(Sampler0, 0), pixelSize, Pos, worldDir, color, depth, hookNormal);
        #elif bobbermode == bobber3Dcomplex
            cubeIntersect(ivec2(0), ivec2(textureSize(Sampler0, 0)*vec2(1.0, 0.5)), pixelSize, Pos, worldDir, color, depth, hookNormal);
            flatIntersect(ivec2(0, textureSize(Sampler0, 0).y*0.5+0.5), textureSize(Sampler0, 0), pixelSize, Pos, worldDir, color, depth, hookNormal);
        #else
            // bobber3Dcomplexfast
            float bobberDepth = boxIntersection(Pos + vec3(0,0.0625,0), worldDir, vec3(0.09375), hookNormal);
            if (bobberDepth < depth) {
                depth = bobberDepth;
                vec2 txCoord = (Pos + vec3(0,0.0625,0) + hookNormal * 0.001  + depth * worldDir).xy * 10.66666666;
                color = texture(Sampler0, vec2(0.5625, 0.3125) + txCoord * vec2(0.1875));
            }
            flatIntersect(ivec2(0, textureSize(Sampler0, 0).y*0.5+0.5), textureSize(Sampler0, 0), pixelSize, Pos, worldDir, color, depth, hookNormal);
        #endif

        color = minecraft_mix_light(Light0_Direction, Light1_Direction, hookNormal * IViewRotMat, color);
    #endif
    if (color.a < 0.1) {
        return false;
    }
    vec4 clipPos = ProjMat * vec4(-dir * depth, 1);
    gl_FragDepth = clipPos.z / clipPos.w * 0.5 + 0.5;
    return true;
}

void main() {
    vec4 color = vec4(0);
    gl_FragDepth = gl_FragCoord.z;
    if (isBobber > 0) {
        if (!doBobber(color)) {
            discard;
            return;
        }
    } else {
        color = texture(Sampler0, texCoord0);
        if (color.a < 0.1) {
            discard;
        }
    }

    color *= vertexColor * ColorModulator;
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    color *= lightMapColor;
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
