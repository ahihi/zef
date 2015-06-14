uniform float iBeats;
uniform float iGlobalTime;
uniform vec2 iResolution;
uniform float iFade;

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

void main()
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
	
	vec3 color = vec3(0.0);
	
	for (int i = 1; i < 5; i++) {
		vec2 p=uv.xy*10.0*float(i*i) + iGlobalTime;
		float a=smoothNoise(float(int(p.x)), float(int(p.y)));
		float b=smoothNoise(float(int(p.x)+1), float(int(p.y)));
		float c=smoothNoise(float(int(p.x)), float(int(p.y)+1));
		float d=smoothNoise(float(int(p.x)+1), float(int(p.y)+1));	
		float fx=1.0-fract(p.x);
		float fy=1.0-fract(p.y);
		color += ((fx*a+(1.0-fx)*b)*fy + (fx*c+(1.0-fx)*d)*(1.0-fy))/float(i*i);
	
	}
	
	uv-=vec2(0.5);
	color = color*(1.0-length(uv)*length(uv));
	color = (color + vec3(0.0, 0.0, 0.0))/2.0;
        
	gl_FragColor = vec4(color,(1.0-iFade)*0.5);
}