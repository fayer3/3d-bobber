
out float isBobber;
out vec3 viewPos;

out vec4 Pos1;
out vec4 Pos2;

bool checkForBobber(inout vec3 viewPosition, in vec3 worldPosition) {
    // check top left and top right corner pixel for markers, that allows higher res packs to also work
    if (texelFetch(Sampler0, ivec2(0, 0), 0) == vec4(1.0, 0.0, 1.0, 0.0) &&
        texelFetch(Sampler0, ivec2(textureSize(Sampler0,0).x - 1, 0), 0) == vec4(0.0, 1.0, 1.0, 0.0)) {
        
        // the position of the two opposing corner vertices, which cross the middle
        Pos1 = vec4(0.0);
        Pos2 = vec4(0.0); 
        if (gl_VertexID % 4 == 0) Pos1 = vec4(worldPosition, 1.0);
        if (gl_VertexID % 4 == 2) Pos2 = vec4(worldPosition, 1.0);
        
        const vec2[4] corners = vec2[4](vec2(0.25), vec2(-0.25, 0.25), vec2(-0.25), vec2(0.25, -0.25));
        
        vec3 offset = vec3(corners[gl_VertexID % 4], 0);
        
        if ((mat3(ModelViewMat) * Normal).y < 0.99) {
            // vivecraft has a non vec3(0,1,0) Normal
            // because vivecraft has camera roll, the offset doesn't work right, so remove it
            offset = vec3(0);
        }
        viewPosition -= offset;
        return true;
    } else {
        return false;
    }
}