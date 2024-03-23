#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

void main() {
    // Calculate UV coordinates
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // Create a Scottish tartan pattern based on UV coordinates
    float lines = 12.0;
    float lineThickness = 0.01;

    float tartanX = mod(uv.x * lines, 1.0);
    float tartanY = mod(uv.y * lines, 1.0);

    // Create a spinning movement based on time
    float spinAngle = u_time * 0.5;
    float centerU = 0.5 * cos(spinAngle) + 0.5;
    float centerV = 0.5 * sin(spinAngle) + 0.5;

    float xOffset = uv.x - centerU;
    float yOffset = uv.y - centerV;

    float rotatedX = cos(spinAngle) * xOffset + sin(spinAngle) * yOffset + centerU;
    float rotatedY = -sin(spinAngle) * xOffset + cos(spinAngle) * yOffset + centerV;

    float movementX = mod(rotatedX * lines, 1.0);
    float movementY = mod(rotatedY * lines, 1.0);

    // Apply bubble distortion effect as if grid was on a stretched cloth
    vec2 bubbleCenter = vec2(0.5, 0.5);
    float bubbleSize = 0.1;
    float bubbleStrength = 0.5;
    float distToBubble = length(uv - bubbleCenter);
    float distortion = clamp((bubbleSize - distToBubble) * bubbleStrength, 0.0, 1.0);

    // Color the tartan pattern with dark green, red, brown and apply distortion
    float darkGreen = smoothstep(0.5 - lineThickness, 0.5, movementX) * step(fract(movementY * lines), 0.5);
    float red = smoothstep(0.5 - lineThickness, 0.5, movementY) * step(fract(movementX * lines), 0.5);
    float brown = mix(darkGreen, red, 0.5);

    // Apply distortion to the tartan pattern simulating a heavy ball effect
    darkGreen = mix(darkGreen, darkGreen + distortion, 0.5);
    red = mix(red, red + distortion, 0.5);
    brown = mix(brown, brown + distortion, 0.5);

    // Set color based on tartan pattern with bubble distortion effect
    out_color = vec4(darkGreen, red * 0.5, brown * 0.3, 1.0);
}
