uniform float iGlobalTime;
uniform vec2 iResolution;

void main()
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
    uv *= sin(iGlobalTime*0.0005) + 1.0;
	float color = sin(uv.y*35000.0);
	gl_FragColor = vec4(vec3(color), 0.1);
}