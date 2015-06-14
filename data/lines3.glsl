uniform float iGlobalTime;
uniform vec2 iResolution;

void main()
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
    uv *= cos(iGlobalTime*0.0001) + 10.0;
	float color = cos(uv.y*3500.0);
	gl_FragColor = vec4(vec3(color), 0.1);
}