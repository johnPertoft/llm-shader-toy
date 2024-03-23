#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;


vec2 mandelbrot(vec2 z, vec2 c, float t) {
    return vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c * vec2(sin(0.2*t), cos(0.2*t));
}

vec2 julia(vec2 z, vec2 c) {
    return vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;
}

vec3 colorGradient(float t) {
    return vec3(0.5 * cos(t) + 0.5, 0.5 * sin(t*1.2) + 0.5, 0.8 + 0.2 * cos(1.5*t));
}

void main() {
    // Normalized pixel coordinates
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    // Time-dependent parameters
    float t = u_time * 0.5;

    // Bubble refraction effect
    float bubble = sin(5.0 * length(uv - vec2(sin(0.2*t), cos(0.2*t)))) - 0.5;
    uv += bubble * 0.1 * vec2(cos(t), sin(t));

    // Mandelbrot fractal
    vec2 c = vec2(uv.x*2.0-1.0, uv.y*2.0-1.0);
    vec2 z = c;
    int iterations = 0;
    for(int i = 0; i < 100; i++) {
        if(length(z) > 2.0) break;
        z = mandelbrot(z, c, t);
        iterations++;
    }

    // Julia set fractal
    c = vec2(0.8*sin(0.2*t), 0.8*cos(0.2*t));
    z = uv * 2.0 - 1.0;
    int jIterations = 0;
    for(int i = 0; i < 100; i++) {
        if(length(z) > 2.0) break;
        z = julia(z, c);
        jIterations++;
    }

    float color = (float(iterations) + float(jIterations)) / 200.0;
    out_color = vec4(colorGradient(color + t), 1.0);
}
