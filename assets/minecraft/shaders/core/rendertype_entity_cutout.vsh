#version 150

#moj_import <light.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;
uniform int FogShape;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightMapColor;
out vec4 overlayColor;
out vec2 texCoord0;

out float isBobber;
out vec3 viewPos;

out vec4 Pos1;
out vec4 Pos2;

float fog_distance(mat4 modelViewMat, vec3 pos, int shape) {
    if (shape == 0) {
        return length((modelViewMat * vec4(pos, 1.0)).xyz);
    } else {
        float distXZ = length((modelViewMat * vec4(pos.x, 0.0, pos.z, 1.0)).xyz);
        float distY = length((modelViewMat * vec4(0.0, pos.y, 0.0, 1.0)).xyz);
        return max(distXZ, distY);
    }
}

void main() {
    isBobber = 0.0;
    
    // check top left and top right corner pixel for markers, that allows higher res packs to also work
    if (texelFetch(Sampler0, ivec2(0, 0), 0) == vec4(1.0, 0.0, 1.0, 0.0) 
      && texelFetch(Sampler0, ivec2(textureSize(Sampler0,0).x-1, 0), 0) == vec4(0.0, 1.0, 1.0, 0.0)) {
      isBobber = 1.0;
      
      // the position of the two opposing corner vertices, which cross the middle
      Pos1 = vec4(0.0);
      Pos2 = vec4(0.0);
      if (gl_VertexID % 4 == 0) Pos1 = vec4(IViewRotMat*Position, 1.0);
      if (gl_VertexID % 4 == 2) Pos2 = vec4(IViewRotMat*Position, 1.0);
      
      const vec2[4] corners = vec2[4](vec2(0.25), vec2(-0.25, 0.25), vec2(-0.25), vec2(0.25, -0.25));
      
      vec3 offset = vec3(corners[gl_VertexID % 4], 0);
      
      if (Normal.y < 0.99) {
        // vivecraft has a non vec3(0,1,0) Normal
        offset = vec3(0);
      }
      
      viewPos = (ModelViewMat * vec4(Position, 1.0)).xyz - offset;
      gl_Position = ProjMat * vec4(viewPos, 1.0);
      vertexColor = Color;
    } else {
      gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
      vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
    }
    
    vertexDistance = fog_distance(ModelViewMat, IViewRotMat * Position, FogShape);
    lightMapColor = texelFetch(Sampler2, UV2 / 16, 0);
    overlayColor = texelFetch(Sampler1, UV1, 0);
    texCoord0 = UV0;
}
