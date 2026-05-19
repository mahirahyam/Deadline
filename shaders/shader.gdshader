shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);

    // Dithering
    vec2 uv = SCREEN_UV * 400.0; // Ukuran bintik
    float dither = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
    color.rgb += (dither - 0.5) * 0.1; // Intensitas noise
    
    COLOR = color;
}