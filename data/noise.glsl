uniform float iGlobalTime;
uniform vec2 iResolution;

float random(vec2 co){
    return fract(sin(dot(co.xy ,vec2(sin(iGlobalTime)*12.9898,78.233))) * 43758.5453);
}

float noise(float x, float y) {
	return random(vec2(x, y));
}

float smoothNoise(float x, float y) {
    
    float corners = ( noise(x-1.0, y-1.0) + noise(x+1.0, y-1.0) + noise(x-1.0, y+1.0)+ noise(x+1.0, y+1.0) ) / 16.0;
    float sides   = ( noise(x-1.0, y) + noise(x+1.0, y) + noise(x, y-1.0) + noise(x, y+1.0) ) /  8.0;
    float center  =  noise(x, y) / 4.0;

    return corners + sides + center;
}

void main()
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
	
	vec3 color = vec3(smoothNoise(uv.x, uv.y));
	
	float aspect = iResolution.x/iResolution.y;
	float u = gl_FragCoord.x * 2.0 / iResolution.x - 1.0;
	float v = gl_FragCoord.y * 2.0 / iResolution.y - 1.0;
	u*=aspect;
	u/=10.0;
	v/=10.0;
	uv= vec2(u,v);
	
	float corners = min(length(uv), 0.25);
	
	gl_FragColor = vec4(color,0.4) - vec4(corners);
}