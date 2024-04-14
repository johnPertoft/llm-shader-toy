#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

vec2 rotate(vec2 uv, float rotation) {
    float c = cos(rotation);
    float s = sin(rotation);
    mat2 rotMat = mat2(c, -s, s, c);
    return uv * rotMat;
}

float repeatAngle(float a, float times) {
    return mod(a * times, 2.0 * 3.14159) / times;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;
    uv *= 2.0; // Increase scale for a more zoom-in effect

    // Rotates a bit faster and more based on the zoom
    uv = rotate(uv, u_time * 0.3 + length(uv) * 0.2);

    // Use a complex mirroring and repetition system to create more intricate patterns
    uv.x = abs(mod(uv.x, 1.0) - 0.5);
    uv.y = abs(mod(uv.y, 1.0) - 0.5);
    uv = rotate(uv, u_time * 0.2);  // Additional rotation tied to time at pixel level

    // Compute angle and radius for polar coordinates
    float numPetals = 12.0;
    float angle = atan(uv.y, uv.x);
    float twistedAngle = repeatAngle(angle, numPetals);
    float radius = length(uv) * 5.0; // Zoom out a bit for more visibility of complexity

    // Radius modulation and detail enhancement
    radius = exp(-radius * sin(twistedAngle * radius));
    float furtherDetail = sin(uv.x * 40.0 + u_time) * cos(uv.y * 40.0 + u_time) * 0.5;

    // Distort the base color components for complexity
    float r = 0.5 + 0.5 * cos(u_time + twistedAngle * 5.0 + furtherDetail);
    float g = 0.5 + 0.5 * sin(u_time / 3.0 + twistedAngle * radius * 5.0 + furtherDetail);
    float b = 0.5 + 0.5 * cos(u_time / 2.0 + radius * 7.5 + furtherDetail);

    out_color = vec4(r, g, b, 1.0);
}
