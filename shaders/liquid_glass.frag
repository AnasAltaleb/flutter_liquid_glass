#version 320 es

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;             // 0, 1: Texture size in physical pixels
uniform sampler2D u_texture;     // sampler 0: Backdrop texture

uniform vec4 u_rect;             // 2, 3, 4, 5: (left, top, width, height) in physical pixels
uniform float u_corner_radius;   // 6: Corner radius in physical pixels
uniform float u_rim_thickness;   // 7: Width of curved edge lens in physical pixels
uniform float u_refraction;      // 8: Refraction displacement in physical pixels
uniform float u_dispersion;      // 9: Chromatic dispersion
uniform float u_frost;           // 10: Frost blur sigma
uniform float u_specular;        // 11: Specular highlight intensity
uniform float u_tint;            // 12: Crystal glass tint factor
uniform vec2 u_velocity;         // 13, 14: Physical drag velocity vector (dx, dy)
uniform float u_fluid_wobble;    // 15: Fluid oscillation amplitude

out vec4 frag_color;

// 2D Signed Distance Function for a rounded box
float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

// Evaluates the SDF in deformed fluid space
// Volume-preserving: stretches in direction of motion, compresses perpendicularly
// Axis-aligned so a horizontal capsule never tilts diagonally into a skewed stick
float evalDeformedSDF(vec2 p, vec2 b, float r, vec2 scale) {
    vec2 q = p / scale;
    return sdRoundedBox(q, b, r);
}

// Numerical gradient for exact normal of the deformed liquid surface
vec2 calcDeformedNormal(vec2 p, vec2 b, float r, vec2 scale) {
    float eps = 1.0;
    float dX = evalDeformedSDF(p + vec2(eps, 0.0), b, r, scale) 
             - evalDeformedSDF(p - vec2(eps, 0.0), b, r, scale);
    float dY = evalDeformedSDF(p + vec2(0.0, eps), b, r, scale) 
             - evalDeformedSDF(p - vec2(0.0, eps), b, r, scale);
    float len = length(vec2(dX, dY));
    return len > 0.0001 ? vec2(dX, dY) / len : vec2(0.0, -1.0);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 unperturbedUV = fragCoord / u_size;
    
    vec2 widgetCenter = u_rect.xy + u_rect.zw * 0.5;
    vec2 localPos = fragCoord - widgetCenter;
    vec2 halfSize = u_rect.zw * 0.5;
    float maxRadius = min(halfSize.x, halfSize.y);
    float radius = min(u_corner_radius, maxRadius);
    
    // Subtle, realistic fluid elasticity:
    // Elongates in the direction of drag and gets pressed in the opposite axis
    float speedX = abs(u_velocity.x);
    float speedY = abs(u_velocity.y);
    
    // Controlled elasticity factor (clamped at max 5% subtle elongation)
    float ex = clamp(speedX * 0.00003, 0.0, 0.05);
    float ey = clamp(speedY * 0.00003, 0.0, 0.05);
    
    // Surface tension wobble (subtle capillary oscillation, max 3.5%)
    float wobble = clamp(u_fluid_wobble * 0.035, -0.035, 0.035);
    
    // Incompressible fluid: stretch in motion axis, compress in opposite axis
    float scaleX = clamp(1.0 + (ex - ey * 0.5) + wobble, 0.94, 1.06);
    float scaleY = clamp(1.0 + (ey - ex * 0.5) - wobble, 0.94, 1.06);
    vec2 fluidScale = vec2(scaleX, scaleY);
    
    // Evaluate Distance Field in the deformed fluid space
    float d = evalDeformedSDF(localPos, halfSize, radius, fluidScale);
    
    // Outside the liquid body: soft contact shadow
    if (d > 0.5) {
        vec4 bg = texture(u_texture, unperturbedUV);
        if (d < 26.0) {
            float shadow = (1.0 - smoothstep(0.0, 26.0, d)) * 0.24;
            bg.rgb *= (1.0 - shadow);
        }
        frag_color = bg;
        return;
    }
    
    float distToEdge = -d;
    float rimWidth = max(u_rim_thickness, 4.0);
    
    // Surface normal of the deformed liquid body
    vec2 outwardNormal = calcDeformedNormal(localPos, halfSize, radius, fluidScale);
    
    // Optical lens refraction calculation
    vec2 sampleCoord = fragCoord;
    float chromaticDisp = 0.0;
    float specularRim = 0.0;
    float edgeDarkening = 0.0;
    
    if (distToEdge < rimWidth) {
        // We are on the curved meniscus lens rim!
        float t = clamp(distToEdge / rimWidth, 0.0, 1.0);
        
        // Meniscus lens profile
        float curve = sin((1.0 - t) * 1.5707963);
        curve = pow(curve, 1.8);
        
        // Ray bending: incoming light bends inward toward the center of the lens
        vec2 refractDir = -outwardNormal;
        vec2 offsetPixels = refractDir * (curve * u_refraction);
        sampleCoord = fragCoord + offsetPixels;
        
        // Chromatic dispersion proportional to curvature
        chromaticDisp = u_dispersion * curve * u_refraction * 0.6;
        
        // 3D Surface normal for specular light reflection
        float edgeHeight = sqrt(max(0.01, 1.0 - pow(1.0 - t, 2.0)));
        vec3 normal3D = normalize(vec3(outwardNormal * (1.0 - t), edgeHeight));
        
        // Primary overhead light source
        vec3 lightDir = normalize(vec3(-0.35, -0.85, 0.45));
        vec3 viewDir = vec3(0.0, 0.0, 1.0);
        vec3 halfDir = normalize(lightDir + viewDir);
        float NdotH = max(dot(normal3D, halfDir), 0.0);
        specularRim = pow(NdotH, 20.0) * u_specular * (1.0 - t * 0.7);
        
        // Internal reflection darkening along bottom rim
        edgeDarkening = max(0.0, dot(outwardNormal, vec2(0.2, 0.8))) * (1.0 - t) * 0.28;
    }
    
    // Sample backdrop with chromatic dispersion
    vec2 uvG = clamp(sampleCoord / u_size, vec2(0.001), vec2(0.999));
    vec2 uvR = clamp((sampleCoord - outwardNormal * chromaticDisp) / u_size, vec2(0.001), vec2(0.999));
    vec2 uvB = clamp((sampleCoord + outwardNormal * chromaticDisp) / u_size, vec2(0.001), vec2(0.999));
    
    vec4 colR = texture(u_texture, uvR);
    vec4 colG = texture(u_texture, uvG);
    vec4 colB = texture(u_texture, uvB);
    
    // Optional center frost blur
    if (u_frost > 0.02) {
        float b = u_frost * 4.0;
        vec2 bUV = vec2(b) / u_size;
        colR = (colR + texture(u_texture, uvR + vec2(bUV.x, bUV.y)) + texture(u_texture, uvR - vec2(bUV.x, bUV.y))) / 3.0;
        colG = (colG + texture(u_texture, uvG + vec2(bUV.x, -bUV.y)) + texture(u_texture, uvG - vec2(bUV.x, -bUV.y))) / 3.0;
        colB = (colB + texture(u_texture, uvB + vec2(0.0, bUV.y)) + texture(u_texture, uvB - vec2(0.0, bUV.y))) / 3.0;
    }
    
    vec3 col = vec3(colR.r, colG.g, colB.b);
    
    // Internal rim attenuation
    col *= (1.0 - edgeDarkening);
    
    // Crystal glass tint
    vec3 tintColor = vec3(0.94, 0.97, 1.0);
    col = mix(col, tintColor, u_tint * 0.15);
    
    // Specular highlight
    col += vec3(1.0) * specularRim;
    
    // Caustic ring at base of meniscus
    if (distToEdge < rimWidth) {
        float t = distToEdge / rimWidth;
        float caustic = smoothstep(0.0, 0.25, t) * smoothstep(0.7, 0.25, t) * 0.22 * u_specular;
        col += vec3(0.9, 0.96, 1.0) * caustic;
    }
    
    // Anti-aliased outer boundary transition
    float edgeAlpha = clamp(0.5 - d, 0.0, 1.0);
    vec4 backdrop = texture(u_texture, unperturbedUV);
    if (d > 0.0 && d < 26.0) {
        float shadow = (1.0 - smoothstep(0.0, 26.0, d)) * 0.24;
        backdrop.rgb *= (1.0 - shadow);
    }
    frag_color = mix(backdrop, vec4(col, 1.0), edgeAlpha);
}
