#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

// Signed distance function for a sphere
float sphereSDF(vec3 p, float r) {
    return length(p) - r;
}

// Map the scene to the geometry we want to visualize
float mapTheScene(vec3 p) {
    float d = sphereSDF(p, 1.0);
    d += 0.2 * sin(6.0 * p.x + u_time) * sin(6.0 * p.y + u_time) * sin(6.0 * p.z + u_time);
    return d;
}

// Calculate normal by approximating derivatives
vec3 calculateNormal(vec3 p) {
    const float eps = 0.001;
    vec3 n = vec3(
        mapTheScene(p + vec3(eps, 0.0, 0.0)) - mapTheScene(p - vec3(eps, 0.0, 0.0)),
        mapTheScene(p + vec3(0.0, eps, 0.0)) - mapTheScene(p - vec3(0.0, eps, 0.0)),
        mapTheScene(p + vec3(0.0, 0.0, eps)) - mapTheScene(p - vec3(0.0, 0.0, eps))
    );
    return normalize(n);
}

// Perform ray marching to determine the closest distance from the camera to the scene surface
float rayMarch(vec3 ro, vec3 rd, float start, float end, float precis) {
    float depth = start;
    for (int i = 0; i < 100; i++) {
        float dist = mapTheScene(ro + rd * depth);
        if (dist < precis || depth > end) break;
        depth += dist;
    }
    return depth;
}

// Camera ray function
vec3 calculateRayDir(vec2 uv, float fov, vec3 camPos, vec3 target) {
    vec3 forward = normalize(target - camPos);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = cross(forward, right);

    float aspectRatio = u_resolution.x / u_resolution.y;
    vec3 rayDir = normalize(forward + uv.x * right * aspectRatio + uv.y * up);
    rayDir *= tan(radians(fov / 2.0));

    return rayDir;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - u_resolution * 0.5) / u_resolution.y;
    vec3 camPos = vec3(0.0, 0.0, 3.0);
    vec3 target = vec3(0.0, 0.0, 0.0);
    vec3 lightPos1 = vec3(2.0 * sin(u_time), 1.0, 2.0 * cos(u_time));
    vec3 lightPos2 = vec3(2.0 * cos(u_time * 1.5), 2.0 * sin(u_time * 0.5), 2.0 * sin(u_time * 1.25)); // Added erratic movement

    vec3 rayDir = calculateRayDir(uv, 75.0, camPos, target);
    float t = rayMarch(camPos, rayDir, 0.0, 100.0, 0.001);
    if (t > 99.0) {
        out_color = vec4(0.0, 0.0, 0.0, 1.0); // Background color
        return;
    }
    vec3 p = camPos + t * rayDir;
    vec3 normal = calculateNormal(p);

    // Lighting calculations for two light sources
    vec3 lightDir1 = normalize(lightPos1 - p);
    float diff1 = max(dot(normal, lightDir1), 0.0);
    vec3 lightDir2 = normalize(lightPos2 - p);
    float diff2 = max(dot(normal, lightDir2), 0.0);

    vec3 ambient = 0.1 * vec3(0.5, 0.5, 0.5);
    vec3 color = vec3(0.5 + 0.5 * sin(u_time), 0.5 + 0.5 * cos(u_time), 0.7 + 0.3 * sin(u_time));
    vec3 diffuse = 0.9 * (diff1 + diff2) * color;

    vec3 finalColor = ambient + diffuse;
    out_color = vec4(finalColor, 1.0);
}
