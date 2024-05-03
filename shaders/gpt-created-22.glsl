#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

// Define basic Phong shading components
vec3 lightPosition = vec3(5.0, 5.0, 5.0);
vec3 ambientColor = vec3(0.1, 0.1, 0.1);
vec3 lightColor = vec3(0.9, 0.9, 0.9);

// Sphere signed distance function
float sphereSDF(vec3 p, float r) {
    // Enhanced chaotic displacement along the normal of the sphere
    float noise = sin(5.0 * p.x + u_time) * cos(5.0 * p.y - u_time) +
                  sin(7.0 * p.y + 2.0 * u_time) * cos(7.0 * p.z - 2.0 * u_time);
    noise += sin(10.0 * p.z + 3.0 * u_time) * cos(10.0 * p.x - 3.0 * u_time);
    float displacement = 0.2 * noise;
    return length(p) - (r + displacement);
}

// Phong shading model function
vec3 phongShading(vec3 color, vec3 normal, vec3 lightDir, vec3 viewDir) {
    float ambientStrength = 0.1;
    vec3 ambient = ambientStrength * ambientColor;

    float diff = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = diff * lightColor;

    float spec = pow(max(dot(viewDir, reflect(-lightDir, normal)), 0.0), 32.0);
    vec3 specular = vec3(0.3) * spec * lightColor;

    return (ambient + diffuse + specular) * color;
}

// Raymarching function
float rayMarch(vec3 ro, vec3 rd, float start, float end, float precis) {
    float depth = start;
    for (int i = 0; i < 100; i++) {
        vec3 pos = ro + rd * depth;
        float dist = sphereSDF(pos, 1.0); // Sphere radius 1.0
        if (dist < precis)
            break;
        depth += dist;
        if (depth >= end)
            break;
    }
    return depth;
}

// Normal estimation function
vec3 estimateNormal(vec3 p) {
    float dist = sphereSDF(p, 1.0);
    vec2 e = vec2(0.01, 0.0);
    vec3 n = dist - vec3(
        sphereSDF(p - e.xyy, 1.0),
        sphereSDF(p - e.yxy, 1.0),
        sphereSDF(p - e.yyx, 1.0));
    return normalize(n);
}

// Generate an oilslick-like color pattern on the sphere
vec3 spherePatternColor(vec3 p) {
    float longitude = atan(p.z, p.x) + u_time;      // Longitudinal angle
    float latitude = acos(p.y / length(p));         // Latitudinal angle
    float complexPattern = sin(10.0 * longitude) * cos(10.0 * latitude);
    float hueShift = 0.6 + 0.4 * sin(complexPattern + u_time);
    vec3 shiftedColor = vec3(0.75 + 0.25 * sin(hueShift),
                             0.5 + 0.5 * cos(longitude),
                             0.5 + 0.5 * sin(latitude));
    shiftedColor *= vec3(1.2 - 0.2 * cos(complexPattern + u_time));
    return shiftedColor;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;
    vec3 ro = vec3(0.0, 0.0, 3.0); // Camera at (0,0,3)
    vec3 rd = normalize(vec3(uv, -1.0)); // Ray direction

    float depth = rayMarch(ro, rd, 0.0, 100.0, 0.001);
    if (depth < 100.0) {
        vec3 p = ro + rd * depth;
        vec3 normal = estimateNormal(p);
        vec3 lightDir = normalize(lightPosition - p);
        vec3 viewDir = -rd;
        vec3 patternColor = spherePatternColor(p);
        vec3 color = phongShading(patternColor, normal, lightDir, viewDir);
        out_color = vec4(color, 1.0);
    } else {
        out_color = vec4(ambientColor, 1.0); // Background color
    }
}
