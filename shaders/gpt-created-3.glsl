#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

const int MAX_STEPS = 50;
const float EPSILON = 0.0001;

vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

float sceneSDF(vec3 p) {
    return length(p) - 0.5; // Sphere SDF: sphere of radius 0.5 at the origin
}

float rayMarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        float dist = sceneSDF(ro + rd * t);
        if (dist < EPSILON) return t;
        t += dist;
    }
    return -1.0;
}

vec3 calculateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(p + vec3(EPSILON, 0.0, 0.0)) - sceneSDF(p - vec3(EPSILON, 0.0, 0.0)),
        sceneSDF(p + vec3(0.0, EPSILON, 0.0)) - sceneSDF(p - vec3(0.0, EPSILON, 0.0)),
        sceneSDF(p + vec3(0.0, 0.0, EPSILON)) - sceneSDF(p - vec3(0.0, 0.0, EPSILON))
    ));
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 size = u_resolution;
    vec3 ro = vec3(0.0, 0.0, 3.0); // Sphere position
    vec3 rd = rayDirection(45.0, size / 2.0, fragCoord); // Adjusted size for smaller view
    vec3 lightPos = vec3(0.0, sin(u_time) * 2.0, 3.0); // Moving light source

    float t = rayMarch(ro, rd);
    if (t > 0.0) {
        vec3 p = ro + rd * t;
        vec3 normal = calculateNormal(p);
        vec3 lightDir = normalize(lightPos - p);
        float intensity = max(dot(normalize(normal), lightDir), 0.0);
        float gray = intensity; // Use intensity for shading
        out_color = vec4(gray, gray, gray, 1.0);
    } else {
        out_color = vec4(0.0, 0.0, 0.0, 1.0);
    }
}
