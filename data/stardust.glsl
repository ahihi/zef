uniform vec2 iResolution;
uniform float iGlobalTime;

vec3 nrand3( vec2 co )
{
        vec3 a = fract( cos( co.x*8.3e-3 + co.y )*vec3(1.3e5, 4.7e5, 2.9e5) );
        vec3 b = fract( sin( co.x*0.3e-3 + co.y )*vec3(8.1e5, 1.0e5, 0.1e5) );
        vec3 c = mix(a, b, 0.5);
        return c;
}

vec4 colorWithStars(vec2 uv, float currentTransitionTime) {
	vec2 seed = uv;
	seed = floor(seed * iResolution.x);
	vec3 rnd = nrand3( seed );
	
	vec4 color = vec4(vec3(pow(rnd.y,30.0)), pow(rnd.y,30.0));

    color = color * (currentTransitionTime);
	
	return color;
}

float random(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
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

vec4 getCloudColor(vec2 uv) {
		
	
	vec3 cloudColor = vec3(0.0);
		
	for (int i = 1; i < 5; i++) {
		vec2 p=(uv.xy+vec2(100.0))*10.0*float(i*i) + 11. + iGlobalTime;
		float a=smoothNoise(float(int(p.x)), float(int(p.y)));
		float b=smoothNoise(float(int(p.x)+1), float(int(p.y)));
		float c=smoothNoise(float(int(p.x)), float(int(p.y)+1));
		float d=smoothNoise(float(int(p.x)+1), float(int(p.y)+1));	
		float fx=1.0-fract(p.x);
		float fy=1.0-fract(p.y);
		cloudColor += ((fx*a+(1.0-fx)*b)*fy + (fx*c+(1.0-fx)*d)*(1.0-fy))/float(i*i);
	
	}
	
	uv-=vec2(0.5);
	cloudColor = cloudColor*(1.0-length(uv)*length(uv));
	
	return vec4(cloudColor, 1.0);
}

void main()
{

	float aspect = iResolution.x/iResolution.y;
    float u = gl_FragCoord.x * 2.0 / iResolution.x - 1.0;
    float v = gl_FragCoord.y * 2.0 / iResolution.y - 1.0;
	u = u * aspect;
	
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
    
    vec4 stars = colorWithStars(uv, iGlobalTime);
    
	float green = u;//sin(u*5.0) + sin(v);
	green = min(green, 0.25);
    vec4 clouds = getCloudColor(uv) + vec4(0.0, green, 0.0, 0.0)*0.05;	
	
	uv = vec2(u, v);
	float darkening = min(length(uv), 0.25);
    
	gl_FragColor = stars + clouds - vec4(darkening);
}



