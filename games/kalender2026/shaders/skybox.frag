// World-space stars stay at infinity as the player moves between the windows.
in vec3 v_ray_dir;
layout(location = 0) out vec4 o_color;

float hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

float stars(vec2 uv, vec2 grid, float density) {
    vec2 pos = uv * grid;
    vec2 cell = floor(pos);
    cell.x = mod(cell.x, grid.x);
    float seed = hash(cell);
    vec2 center = .16 + .68 * vec2(hash(cell + 41.7), hash(cell + 19.2));
    vec2 d = abs(fract(pos) - center);
    float size = .045 + .07 * seed;
    float aa = clamp(length(fwidth(pos)) * .42, .025, .14);
    float core = 1.0 - smoothstep(size - aa, size + aa, length(d));
    float rays = max(0.0, 1.0 - (max(d.x,d.y)*3.7 + min(d.x,d.y)*21.0));
    return step(1.0-density, seed) * (core + step(.985,seed)*.65*rays);
}

void main() {
    vec3 d = normalize(v_ray_dir);
    vec2 uv = vec2(atan(d.z,d.x)/6.2831853 + .5, asin(clamp(d.y,-1.0,1.0))/3.1415927 + .5);
    vec3 night = mix(vec3(.027,.062,.126), vec3(.003,.007,.028), smoothstep(.0,.67,d.y));
    float veil = .046 * exp(-8.0 * abs(d.y - .24 - .21*sin(uv.x*6.2831853)));
    night += vec3(.19,.34,.60) * veil;
    float fine = stars(uv,vec2(410,174),.20);
    float bright = stars(uv+vec2(.217,.07),vec2(197,82),.145);
    night += smoothstep(-.04,.09,d.y) * (vec3(.43,.62,.92)*fine + vec3(1.19,1.30,1.48)*bright);
    o_color = vec4(night,1.0);
}
