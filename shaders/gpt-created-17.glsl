#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

// Creating a rotation matrix for the x-axis
mat3 rotationMatrixX(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        1.0, 0.0, 0.0,
        0.0, c, -s,
        0.0, s, c
    );
}

// Creating a rotation matrix for the y-axis
mat3 rotationMatrixY(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        c, 0.0, s,
        0.0, 1.0, 0.0,
        -s, 0.0, c
    );
}

// Creating a rotation matrix for the z-axis
mat3 rotationMatrixZ(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        c, -s, 0.0,
        s, c, 0.0,
        0.0, 0.0, 1.0
    );
}

// Union operation for SDFs (returns the minimum distance)
float opUnion(float d1, float d2) {
    return min(d1, d2);
}

// Function to create a raymarched scene with simple lighting
float mapTheScene(vec3 p) {
    float dist = 1000.0;

    // Placement and rotation for multiple cubes
    vec3 positions[3] = vec3[](vec3(-1.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));
    for (int i = 0; i < 3; i++) {
        vec3 pos = p - positions[i];
        pos = rotationMatrixX(u_time + float(i)) * pos;
        pos = rotationMatrixY(u_time * 0.5 + float(i)) * pos;
        pos = rotationMatrixZ(u_time * 0.25 + float(i)) * pos;

        // Simple cube SDF (signed distance field)
        float cubeSize = 0.3;
        vec3 d = abs(pos) - cubeSize;
        float maxLength = max(d.x, max(d.y, d.z));
        float cubeDist = min(maxLength, length(max(d, 0.0)));
        dist = opUnion(dist, cubeDist);
    }

    return dist;
}

// Raymarch function
float rayMarch(vec3 ro, vec3 rd, float minDist, float maxDist) {
    float depth = minDist;
    for (int i = 0; i < 64; i++) {
        float dist = mapTheScene(ro + rd * depth);
        if (dist < 0.001 || depth > maxDist) break;
        depth += dist;
    }
    return depth;
}

// Simple phong lighting calculation
vec3 calculateLighting(vec3 p, vec3 rd, vec3 lightPos) {
    vec3 n = normalize(vec3(
        mapTheScene(p + vec3(0.001, 0.0, 0.0)) - mapTheScene(p - vec3(0.001, 0.0, 0.0)),
        mapTheScene(p + vec3(0.0, 0.001, 0.0)) - mapTheScene(p - vec3(0.0, 0.001, 0.0)),
        mapTheScene(p + vec3(0.0, 0.0, 0.001)) - mapTheScene(p - vec3(0.0, 0.0, 0.001))
    ));
    vec3 l = normalize(lightPos - p);
    float diff = max(dot(n, l), 0.0);
    vec3 r = reflect(-l, n);
    float spec = pow(max(dot(r, -rd), 0.0), 32.0);
    vec3 color = vec3(0.2) + 0.8 * diff * vec3(1.0, 0.8, 0.6) + 0.5 * spec * vec3(1.0);
    return color;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;

    // Camera setup
    vec3 camPos = vec3(0.0, 0.0, 3.0);
    vec3 camTarget = vec3(0.0, 0.0, 0.0);
    vec3 camDir = normalize(camTarget - camPos);
    vec3 camRight = normalize(cross(vec3(0.0, 1.0, 0.0), camDir));
    vec3 camUp = cross(camDir, camRight);

    // Generate ray
    vec3 rd = normalize(uv.x * camRight + uv.y * camUp + camDir);

    // Rotating light source
    vec3 lightPos = rotationMatrixY(u_time) * vec3(2.0, 1.0, 0.0);

    float dist = rayMarch(camPos, rd, 0.0, 10.0);

    if (dist > 9.5) {
        out_color = vec4(0.0, 0.0, 0.0, 1.0); // Background color
    } else {
        vec3 p = camPos + dist * rd;
        vec3 color = calculateLighting(p, rd, lightPos);
        out_color = vec4(color, 1.0);
    }
}
