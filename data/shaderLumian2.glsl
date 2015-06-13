uniform float iGlobalTime;
uniform vec2 iResolution;

void main()
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
	uv.x*=iResolution.x/iResolution.y;
	
	uv *= uv*sin(iGlobalTime) + uv*cos(iGlobalTime) + 3.0*uv*uv;
	
	float t = iGlobalTime + 800.0;
	vec2 origin = vec2(0.5*sin(t) + 5.0, 0.5*sin(t) + 0.5);
	float distanceFromOrigin = 0.6*sin(distance(uv, origin)) - t*.1;
	
	gl_FragColor = vec4(0.5*sin(distanceFromOrigin*0.005*t),0.0,0.7*sin(distanceFromOrigin*0.0003*t),1.0);
}