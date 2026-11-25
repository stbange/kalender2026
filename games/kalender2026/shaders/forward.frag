#include "shaders/common.glsl"

in vec3 v_world_pos;
in vec3 v_norm;
in vec2 v_uv;
in vec4 v_color;
in vec4 v_shadow_coord;
flat in int v_cast_lamp;

uniform sampler2D u_albedo_tex;
uniform sampler2D u_shadow_tex;
uniform vec4 u_tint;
uniform vec3 u_mat_mr;    /* x = metallic, y = roughness, z = mode (0=opaque, 1=translucent Fresnel, -1=unlit/additive FX) */
uniform vec3 u_emissive;  /* linear HDR emissive RGB */
uniform vec3 u_cam_pos;
uniform vec3 u_ambient;
uniform vec3 u_sky_zenith;
uniform vec3 u_sky_horizon;
uniform vec3 u_sky_ground;
uniform vec4 u_fog;       /* rgb = color, w = density */
uniform float u_fog_height;

/* Up to 8 active lights per pocket: pos_type.w: 0=dir, 1=point, 2=spot */
uniform int u_light_count;
uniform vec4 u_light_pos_type[8];
uniform vec4 u_light_dir_range[8];
uniform vec4 u_light_color_cone[8];
uniform int u_has_shadow;

layout(location = 0) out vec4 o_color;

float sample_shadow(vec4 sc) {
    if (u_has_shadow == 0) return 1.0;
    vec3 proj = sc.xyz / max(sc.w, 0.0001);
    proj = proj * 0.5 + 0.5;
    if (proj.x < 0.0 || proj.x > 1.0 || proj.y < 0.0 || proj.y > 1.0 || proj.z > 1.0) {
        return 1.0;
    }
    float closest = texture(u_shadow_tex, proj.xy).r;
    return (proj.z - 0.003 > closest) ? 0.30 : 1.0;
}

void main() {
    vec4 tex = texture(u_albedo_tex, v_uv) * v_color * u_tint;
    // The floor's alpha byte stores separate four-bit visibility masks for lights 0 and 1.
    bool floor_receiver = u_mat_mr.x < -1.5;
    vec2 blocked = vec2(0.0);
    if (floor_receiver) {
        if (any(lessThan(v_uv, vec2(0.0))) || any(greaterThan(v_uv, vec2(1.0)))) discard;
        // The receiver and silhouette both use this nearest-filtered, untinted floor texture.
        float masks = floor(tex.a * 255.0 + 0.5);
        blocked = vec2(mod(masks, 16.0), floor(masks / 16.0)) / 15.0;
        tex.a = 1.0;
    }
    float alpha_cut = (abs(u_mat_mr.z) > 0.1) ? 0.01 : 0.1;
    if (tex.a < alpha_cut) discard;

    float fog_f = eng_fog_factor(u_cam_pos, v_world_pos, u_fog.w, u_fog_height);
    if (u_mat_mr.y < 0.0) {
        // The moonlit outdoor meshes sit beyond the hall fixtures' range.
        o_color = vec4(mix(u_emissive, u_fog.rgb, fog_f), 1.0);
        return;
    }
    if (u_mat_mr.z < -0.5) {
        /* Self-emissive / additive particle (fire, sparks, magic glow) */
        vec3 fx_col = tex.rgb * (1.0 + u_emissive.r) * (1.0 - fog_f);
        o_color = vec4(fx_col, tex.a);
        return;
    }

    vec3 N = normalize(v_norm);
    vec3 V = normalize(u_cam_pos - v_world_pos);
    vec3 albedo = tex.rgb;
    float metallic = max(0.0, u_mat_mr.x);
    float roughness = u_mat_mr.y;

    vec3 Lo = u_emissive;
    if (any(greaterThan(u_ambient, vec3(0.0)))) {
        Lo += eng_env_ibl(N, V, albedo, metallic, roughness, u_sky_zenith, u_sky_horizon, u_sky_ground, u_ambient);
    }
    float sh = sample_shadow(v_shadow_coord);

    for (int i = 0; i < 8; i++) {
        if (i >= u_light_count) break;
        float ltype = u_light_pos_type[i].w;
        vec3 L;
        float atten = 1.0;
        if (ltype < 0.5) {
            L = normalize(-u_light_dir_range[i].xyz);
            atten = sh;
        } else {
            vec3 to_l = u_light_pos_type[i].xyz - v_world_pos;
            float dist = length(to_l);
            float range = max(u_light_dir_range[i].w, 0.1);
            if (dist >= range) continue;
            L = to_l / max(dist, 0.0001);
            float fall = clamp(1.0 - (dist / range), 0.0, 1.0);
            atten = fall * fall;
            if (floor_receiver && i < 2) {
                float occlusion = v_cast_lamp == i ? 1.0 : (i == 0 ? blocked.x : blocked.y);
                atten *= 1.0 - 0.95 * occlusion;
            }
            // The projecting mantel interrupts rays from the log basket to the chimney breast.
            bool hearth_material = i == 0 && u_mat_mr.x < -0.5 && v_world_pos.x < -19.0;
            if (hearth_material && v_world_pos.y > 2.65) {
                vec3 fire = u_light_pos_type[0].xyz;
                vec2 at_shelf = mix(fire.xz, v_world_pos.xz, (2.29 - fire.y) / (v_world_pos.y - fire.y));
                float inside = smoothstep(-23.89, -23.71, at_shelf.x) * (1.0 - smoothstep(-22.03, -21.84, at_shelf.x));
                inside *= 1.0 - smoothstep(1.93, 2.12, abs(at_shelf.y));
                atten *= 1.0 - 0.68 * inside;
            }
            if (hearth_material) {
                // Warm diffuse return from the firebrick and hearthstone reaches the fronts of the stockings.
                float bounce = 0.14 * (1.0 - smoothstep(1.5, 4.8, dist));
                Lo += albedo * u_light_color_cone[i].rgb * bounce * atten;
            }
            if (ltype > 1.5) {
                float cos_ang = dot(-L, normalize(u_light_dir_range[i].xyz));
                atten *= smoothstep(u_light_color_cone[i].w, u_light_color_cone[i].w + 0.1, cos_ang);
            }
        }
        if (dot(N, L) <= 0.0) continue;
        Lo += eng_pbr_eval(N, V, L, albedo, metallic, roughness, u_light_color_cone[i].rgb * atten);
    }

    float out_a = tex.a;
    if (u_mat_mr.z > 0.5) {
        /* Translucent crystal/glass Fresnel rim & sky-glint */
        float rim = pow(max(1.0 - max(dot(N, V), 0.0), 0.0001), 2.8);
        Lo += mix(u_sky_horizon, vec3(1.0), 0.45) * rim * max(0.70 - 0.40 * roughness, 0.10);
        out_a = clamp(tex.a + rim * 0.45, 0.0, 1.0);
    }

    vec3 col = mix(Lo, u_fog.rgb, fog_f);
    o_color = vec4(col, out_a);
}
