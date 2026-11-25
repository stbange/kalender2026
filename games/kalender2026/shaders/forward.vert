#include "shaders/common.glsl"

layout(location = 0) in vec3 a_pos;
layout(location = 1) in vec3 a_norm;
layout(location = 2) in vec2 a_uv;
layout(location = 3) in vec4 a_color;
layout(location = 4) in vec4 a_inst0;
layout(location = 5) in vec4 a_inst1;
layout(location = 6) in vec4 a_inst2;
layout(location = 7) in vec4 a_inst3;
layout(location = 8) in vec4 a_joints;
layout(location = 9) in vec4 a_weights;

uniform mat4 u_vp;
uniform mat4 u_light_vp;
uniform float u_vertex_snap;
uniform int u_skinned;
uniform vec3 u_mat_mr;
uniform int u_light_count;
uniform vec4 u_light_pos_type[8];
uniform vec4 u_light_dir_range[8];
flat out int v_cast_lamp;
/* 48 skinning matrices and the light bank fit the WebGL 2 minimum. */
uniform mat4 u_bones[48];

out vec3 v_world_pos;
out vec3 v_norm;
out vec2 v_uv;
out vec4 v_color;
out vec4 v_shadow_coord;

void main() {
    mat4 model = mat4(a_inst0, a_inst1, a_inst2, a_inst3);
    vec4 local_pos = vec4(a_pos, 1.0);
    vec3 local_nrm = a_norm;
    if (u_skinned != 0) {
        ivec4 j = clamp(ivec4(a_joints + 0.5), 0, 47);
        mat4 skin = a_weights.x * u_bones[j.x]
                  + a_weights.y * u_bones[j.y]
                  + a_weights.z * u_bones[j.z]
                  + a_weights.w * u_bones[j.w];
        local_pos = skin * local_pos;
        local_nrm = mat3(skin) * local_nrm;
    }
    vec4 wp = model * local_pos;
    v_norm = normalize(mat3(model) * local_nrm);
    v_uv = a_uv;
    v_color = a_color;
    v_cast_lamp = -1;
    // A shadow child inherits the body or joint's complete animated transform.
    if (u_mat_mr.x < -2.5) {
        if (model[3].y < -3.0 || u_light_count < 2 || u_light_pos_type[0].w < 0.5) {
            gl_Position = vec4(0.0, 0.0, 2.0, 1.0);
            return;
        }
        vec2 center = model[3].xz;
        float fire = 1.0 - distance(center, u_light_pos_type[0].xz) / u_light_dir_range[0].w;
        float candles = 1.0 - distance(center, u_light_pos_type[1].xz) / u_light_dir_range[1].w;
        if (max(fire, candles) <= 0.0) {
            gl_Position = vec4(0.0, 0.0, 2.0, 1.0);
            return;
        }
        v_cast_lamp = fire > candles ? 0 : 1;
        vec3 lamp = u_light_pos_type[v_cast_lamp].xyz;
        vec2 ray = wp.xz - lamp.xz;
        float scale = lamp.y / max(0.04, lamp.y - max(wp.y, 0.0));
        float reach = u_light_dir_range[v_cast_lamp].w / max(length(ray), 0.001);
        vec2 floor_position = lamp.xz + ray * min(scale, reach);
        wp = vec4(floor_position.x, 0.0, floor_position.y, 1.0);
        v_uv = wp.xz / 48.0 + 0.5;
        v_norm = vec3(0.0, 1.0, 0.0);
        v_color = vec4(1.0);
    }
    v_world_pos = wp.xyz;
    v_shadow_coord = u_light_vp * wp;
    gl_Position = eng_snap_vertex(u_vp * wp, u_vertex_snap);
    if (v_cast_lamp >= 0) gl_Position.z -= 0.000012 * gl_Position.w;
}
