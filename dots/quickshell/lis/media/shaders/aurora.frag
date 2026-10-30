#version 440

// The media panel's cover-coloured flow; `energy` is the bass
// Build: qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o aurora.frag.qsb aurora.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float energy;
    vec2 resolution;
    vec4 color1;
    vec4 color2;
    vec4 color3;
};

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 p = uv * vec2(resolution.x / max(resolution.y, 1.0), 1.0) * 1.6;
    float t = time * 0.06;

    vec2 q = vec2(fbm(p + vec2(0.0, t)), fbm(p + vec2(5.2, -t)));
    vec2 r = vec2(fbm(p + 3.0 * q + vec2(1.7, 9.2) + 1.5 * t),
                  fbm(p + 3.0 * q + vec2(8.3, 2.8) - t));
    float f = fbm(p + 2.5 * r);

    vec3 col = mix(color1.rgb, color2.rgb, smoothstep(0.2, 0.8, f));
    col = mix(col, color3.rgb, smoothstep(0.45, 0.95, length(r) * 0.8));

    // Brighter ribbons on the bass
    float glow = smoothstep(0.55, 0.9, f) * (0.5 + 0.9 * energy);
    col += glow * 0.35 * mix(color2.rgb, vec3(1.0), 0.3);

    float a = (0.55 + 0.25 * energy) * mix(1.0, 0.35, smoothstep(0.35, 1.0, uv.y));

    // Grain keeps the gradients from banding
    col += (hash(uv * resolution + fract(time)) - 0.5) * 0.035;

    fragColor = vec4(clamp(col, 0.0, 1.0) * a, a) * qt_Opacity;
}
