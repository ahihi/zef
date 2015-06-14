uniform float iBeats;
uniform float iGlobalTime;
uniform vec2 iResolution;
uniform float iSaturation;

#define PI 3.141592653589793
#define TAU 6.283185307179586

vec3 c0a = vec3(0.1, 0.1, 0.1);
vec3 c0b = vec3(0.2, 0.2, 0.2);
vec3 c1a = vec3(0.4, 0.4, 0.4);
vec3 c1b = vec3(0.7, 0.7, 0.7);

float scale(float l0, float r0, float l1, float r1, float x) {
	return (x - l0) / (r0 - l0) * (r1 - l1) + l1;
}

float rand(vec2 p){
	return fract(sin(dot(p.xy, vec2(232.1933929, 737.112))) * 9233.41);
}

float brightness_squared(vec3 color) {
    return 0.241*color.x*color.x + 0.691*color.y*color.y + 0.068*color.z*color.z;
}

vec2 window(float n, float b) {
	float l = b * (n - 1.0);
	float r = l + 1.0;
	return vec2(l, r);
}

vec3 get_color(float i) {
	if(i < 1.0) {
		return vec3(0.0, 0.0, 0.0);
	} else {
		return vec3(1.0, 0.0, 0.0);
	}
}

vec2 car2pol(vec2 cartesian) {
	return vec2(atan(cartesian.y, cartesian.x), distance(vec2(0.0, 0.0), cartesian));
}

vec2 pol2car(vec2 polar) {
	return vec2(polar.y * cos(polar.x), polar.y * sin(polar.x));
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float timestep(float fps) {
	return floor(fps * iGlobalTime) / fps;
}

vec3 dither(float n, vec3 color, vec2 coord) {
	vec2 w = window(n, sqrt(brightness_squared(color)));
	float b = ceil(w.x) - w.x;
	float r = rand(vec2(coord.x, coord.y + timestep(30.0)));
	return get_color(r < b ? w.y : w.x);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = 2.0*(0.5 * iResolution.xy - fragCoord.xy) / iResolution.xx;
	float angle = atan(p.y, p.x);
	float turn = (angle + PI) / TAU;
	float radius = sqrt(p.x*p.x + p.y*p.y);
	
	float step0 = iGlobalTime;
	float step0b = timestep(6.0);
	float sine_kf = 19.0;
	float ka_wave_rate = 0.94;
	float ka_wave = sin(ka_wave_rate*step0);
	float sine_ka = 0.35 * ka_wave;
	float sine2_ka = 0.47 * sin(0.87*step0);
	float turn_t = turn + -0.0*step0 + sine_ka*sin(sine_kf*radius) + sine2_ka*sin(8.0 * angle);
	float turn2 = 10.0*turn_t;
	float turn_mod = mod(turn2, 2.0);
	float turn_i = mod(turn2, 1.0);
	
	bool turn_bit = turn_mod < 1.0; 
	
	float blend_k0 = scale(-1.0, 1.0, 0.0, 1.0, sin(0.08 * step0b * TAU));
	float blend_k1 = scale(-1.0, 1.0, 0.0, 1.0, sin(0.143 * step0b * TAU));
	vec3 c;
	if(turn_bit) {
		c = blend_k0 * c0a + (1.0 - blend_k0) * c0b;
	} else {
		c = blend_k1 * c1a + (1.0 - blend_k1) * c1b;
		if(turn_mod < 1.1) {
			float l = 0.6;
			c += vec3(l, l, l);
		}
	}
		
	c = dither(2.0, c, fragCoord);
	c *= 0.5 + 0.5*radius;
	
	float turn_mod1 = fract(turn_mod);
	float turn_mod2;
	if(turn_mod < 0.5) {
		turn_mod2 = scale(0.0, 0.5, 0.0, 0.1, turn_mod1);	
	} else {
		turn_mod2 = scale(0.5, 1.0, 1.0, 0.0, turn_mod1);
	}
	float blend_k2 = 0.15;
	c = c * pow(turn_mod2, 3.0) * blend_k2 + c * (1.0 - blend_k2);
	
	float step1 = timestep(30.0);
	float step2 = timestep(32.21);
	float kr = 1.0 - 0.8*radius;
	vec2 q = pol2car(car2pol(fragCoord.xy) + vec2(0.00009, 0.0));
	
	float ry = rand(vec2(q.y, step1));
	float rx = rand(vec2(q.x, step2));
	
	vec3 hsv = rgb2hsv(c);
	hsv.x += 0.88 + 0.06*radius;
	c = hsv2rgb(hsv);
	float ml = 0.7;
	float mr = 1.0;
	float mp = 2.0;
	c = vec3(
		c.x * scale(0.0, 1.0, ml, mr, pow(c.x, mp)),
		c.y * scale(0.0, 1.0, ml, mr, pow(c.y, mp)),
		c.z * scale(0.0, 1.0, ml, mr, pow(c.z, mp))
	);
	
    c = hsv2rgb(rgb2hsv(c) * vec3(1.0, iSaturation, 1.0));
    
    c *= vec3(1.0-length(p));
    
	fragColor = vec4(c, 1.0);
}

void main() {
    vec4 fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    vec2 fragCoord = gl_FragCoord.xy;
    mainImage(fragColor, fragCoord);
    gl_FragColor = fragColor;
}
