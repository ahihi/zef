uniform float iGlobalTime;
uniform vec2 iResolution;

void main()
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
    uv *= cos(iGlobalTime*0.001) + sin(iGlobalTime * 0.005) + 10.0;
	float color = cos(uv.y*3500.0) * 0.2;
	gl_FragColor = vec4(vec3(color), 0.1);
}