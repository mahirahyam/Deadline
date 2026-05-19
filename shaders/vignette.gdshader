shader_type canvas_item;

uniform float intensity : hint_range(0.0, 5.0) = 0.5; 
uniform float softness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    float dist = distance(UV, vec2(0.5));

    float vignette = smoothstep(0.5, 0.5 - softness, dist * intensity);
    
    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
    COLOR = vec4(color.rgb, (1.0 - vignette));
}