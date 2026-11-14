shader_type canvas_item;

uniform vec2 player_screen_pos = vec2(640.0, 360.0);
uniform float inner_radius = 60.0;
uniform float outer_radius = 180.0;
uniform float darkness = 0.0;
uniform vec4 dark_color : source_color = vec4(0.04, 0.06, 0.12, 1.0);

void fragment() {
	float dist = distance(FRAGCOORD.xy, player_screen_pos);
	float alpha = smoothstep(inner_radius, outer_radius, dist) * darkness;
	COLOR = vec4(dark_color.rgb, alpha);
}
