
#define bobber3Dbasic 0       // basic box, with flat hook/string                       1 box intersection + 3 planes
#define bobber3Dcomplex 1     // complex 3D voxel raytraced bobber/hook/string        513 box intersections
#define bobber3Dflat 2        // complex flat 3D voxel raytraced bobber/hook/string    65 box intersections
#define bobber3DcomplexFast 3 // basic box with flat 3D voxel raytraced hook/string    34 box intersections
#define bobbermode bobber3Dbasic

//#define bobberString          // show black string

//#define DEBUG

in float isBobber;
in vec3 viewPos;

in vec4 Pos1;
in vec4 Pos2;

#if bobbermode == bobber3Dbasic
const float Yoffset = 0.0925;
#else
const float Yoffset = 0.03;
#endif

// intersections by Inigo Quilez
// The MIT License
// Copyright © 2014 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/
// https://iquilezles.org/articles/intersectors/
float boxIntersection(in vec3 ro, in vec3 rd, vec3 boxSize, out vec3 outNormal) {
    vec3 m = 1.0 / rd; // can precompute if traversing a set of aligned boxes
    vec3 n = m * ro;   // can precompute if traversing a set of aligned boxes
    vec3 k = abs(m) * boxSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    if(tN > tF || tF < 0.0) return 10000.0; // no intersection
    outNormal = sign(rd) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);
    return tN;
}

void flatIntersect(in ivec2 from, in ivec2 to, in vec2 pixelSize, in vec3 middle, in vec3 direction, inout vec4 outColor, inout float outDepth, inout vec3 outNormal) {
    vec2 size = vec2(textureSize(Sampler0, 0));
    vec3 boxSize = vec3(pixelSize * 0.25, 0.5/16.0);
    vec3 boxOffset = boxSize*2.0;
    middle -= boxOffset * (vec3(size * 0.5 + (size.x / 8.0 - 1.0) * vec2(-0.5, 0.5), 0));

    for (int x = from.x; x < to.x; x++) {
        for (int y = from.y; y < to.y; y++) {
            vec4 currentColor = texelFetch(Sampler0, ivec2(x,y),0);
            if (currentColor.a > 0.1) {
                vec3 currentNormal = vec3(0);
                float currentDepth = boxIntersection(middle + vec3(size.x - x, size.y - y - 1, 0) * boxOffset, direction, boxSize, currentNormal);
                if (currentDepth < outDepth) {
                    outDepth = currentDepth;
                    outColor = currentColor;
                    outNormal = currentNormal;
                }
            }
        }
    }
}

void cubeIntersect(in ivec2 from, in ivec2 to, in vec2 pixelSize, in vec3 middle, in vec3 direction, inout vec4 outColor, inout float outDepth, inout vec3 outNormal) {
    vec2 size = vec2(textureSize(Sampler0, 0));
    vec3 boxSize = pixelSize.xyx * 0.25;
    vec3 boxOffset = boxSize * 2.0;
    middle -= boxOffset * vec3(size.xyx * 0.5 + (size.x / 8.0 - 1.0) * vec3(-0.5, 0.5, 0.5));

    for (int x = from.x; x < to.x; x++) {
        for (int y = from.y; y < to.y; y++) {
            vec4 xColor = texelFetch(Sampler0, ivec2(x,y),0);
            if (xColor.a < 0.1)
            continue;
            for (int z = from.x; z < to.x; z++) {
                vec4 currentColor = texelFetch(Sampler0, ivec2(z,y),0);
                if (currentColor.a > 0.1) {
                    vec3 currentNormal = vec3(0);
                    float currentDepth = boxIntersection(middle + (vec3(to.x - z, to.y * 2.0 - (y+1), x) * boxOffset), direction, boxSize, currentNormal);
                    if (currentDepth < outDepth) {
                        outDepth = currentDepth;
                        outColor = currentColor;
                        outNormal = currentNormal;
                    }
                }
            }
        }
    }
}

bool doBobber(inout vec4 color) {
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