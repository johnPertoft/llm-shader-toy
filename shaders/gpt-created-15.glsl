#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

float sphereSDF(vec3 p, float r) {
    float displacement =
        0.3 * sin(6.0 * p.z + 0.5 * u_time) * cos(6.0 * p.x + 0.5 * u_time) +
        0.3 * sin(8.0 * p.y - 0.5 * u_time) * cos(8.0 * p.x - u_time);
    return length(p) - (r + displacement);
}

vec3 rayMarch(vec3 ro, vec3 rd, float start, float end, float step) {
    float depth = start;
    float d;
    for (int i = 0; i < 100; ++i) {
        vec3 p = ro + depth * rd;
        d = sphereSDF(p, 0.6 + 0.2 * sin(u_time + 0.5 * length(p)));
        if (d < 0.01 || depth > end) break;
        depth += d * step;
    }
    return ro + depth * rd;
}

vec3 phongLighting(vec3 rd, vec3 p, vec3 color, vec3 lightPos) {
    vec3 n = normalize(p);
    vec3 l = normalize(lightPos - p);
    float diff = max(dot(n, l), 0.0);
    vec3 v = normalize(-rd);
    vec3 r = reflect(-l, n);
    float spec = pow(max(dot(r, v), 0.0), 16.0);
    return color * 0.2 + color * diff * 0.8 + vec3(1.0) * spec * 0.5;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;
    vec3 ro = vec3(0.0, 0.0, 4.0);
    vec3 rd = normalize(vec3(uv, -2.0));
    vec3 lightPos = vec3(2.0 * sin(u_time), 2.0 * cos(u_time), 2.0);
    vec3 p = rayMarch(ro, rd, 0.0, 100.0, 0.1);
    vec3 color = vec3(0.65, 1.0, 0.0); // Slimy green color

    out_color = length(p - ro) < 100.0 ? vec4(phongLighting(rd, p, color, lightPos), 1.0) : vec4(0.0);
}
