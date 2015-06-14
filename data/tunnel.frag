uniform float iBeats;
uniform float iGlobalTime;
uniform vec2 iResolution;

#define TAU 6.283185307179586
#define TAU6TH 1.0471975511965976

#define THRESHOLD 0.00001
#define SHADOW_THRESHOLD 0.001
#define MAX_ITERATIONS 256
#define MAX_SHADOW_ITERATIONS 128
#define NORMAL_DELTA 0.01
#define MAX_DEPTH 60.0

#define N_SPIKES 8.0

#define NO_MATERIAL 0
#define TUNNEL_MATERIAL1 1
#define TUNNEL_MATERIAL2 2
#define SPIKE_MATERIAL 3
// ...

vec2 rect2polar(vec2 p) {
    if(p.x == 0.0 && p.y == 0.0) {
        return vec2(0.0, 0.0);
    } else {
        return vec2(atan(p.y, p.x), length(p));            
    }
}

vec2 polar2rect(vec2 p) {
    return vec2(cos(p.x) * p.y, sin(p.x) * p.y);
}

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 getCamPos() {
    return vec3(0.0, 0.0, 0.5*iBeats);
}

struct ObjectDistance {
    float distance;
    int material;
};

ObjectDistance distanceUnion(ObjectDistance a, ObjectDistance b) {
    if(a.distance < b.distance) {
        return a;
    } else {
     	return b;
    }
}

float smin(float a, float b, float k) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

ObjectDistance distanceSmoothUnion(ObjectDistance a, ObjectDistance b) {
    return ObjectDistance(smin(a.distance, b.distance, 0.1), distanceUnion(a, b).material);
}

ObjectDistance distanceDifference(ObjectDistance b, ObjectDistance a) {
    if(-a.distance > b.distance) {
        a.distance *= -1.0;
        return a;
    } else {
        return b;
    }        
}

ObjectDistance sphere(float radius, int material, vec3 p) {
  	return ObjectDistance(length(p) - radius, material);
}

ObjectDistance box(vec3 b, int material, vec3 p)
{
  vec3 d = abs(p) - b;
  return ObjectDistance(
      min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0)),
      material
  );
}

ObjectDistance cylinder(vec2 h, int material, vec3 p) {
  vec2 d = abs(vec2(length(p.xy), p.z)) - h;
  return ObjectDistance(
      min(max(d.x, d.y), 0.0) + length(max(d, 0.0)),
      material
  );
}

ObjectDistance cone(int material, vec2 c, vec3 p) {
    // c must be normalized
    vec2 p1_yz = polar2rect(rect2polar(p.yz) + vec2(0.25/TAU, 0.0));
    vec3 p1 = p;//vec3(p.x, p1_yz);
    float q = length(p1.xz);
    return ObjectDistance(
        dot(c, vec2(q, p1.y)),
        material
    );
}

vec3 get_spikes_p(vec3 p, float phase, float protrusion) {
    float beat_phased = 0.5*iBeats - phase;
    float power = 1.0;//beat_phased < 0.5 ? 1.2 : 1.2;
    float wave = pow(abs(fract(beat_phased) * 2.0 - 1.0), power);
    
    float y = mix(-1.0, -0.1, wave * protrusion);
    return p - (getCamPos() + vec3(0.0, y, 1.0));
}

ObjectDistance spikes(vec3 p, float protrusion) {
    vec2 p1_xy = polar2rect(rect2polar(p.xy) - vec2(iBeats * TAU / 32.0, 0.0));
    vec3 p1 = vec3(p1_xy, p.z);
    
    vec2 c = normalize(vec2(6.0, 1.0));
    ObjectDistance od = cone(TUNNEL_MATERIAL2, c, get_spikes_p(p1, 0.0, protrusion));
    for(float i = 1.0; i < N_SPIKES; i++) {
        float phase_i = i / N_SPIKES;
        vec2 q_xy = polar2rect(rect2polar(p1.xy) + vec2(phase_i * TAU, 0.0));
        vec3 q = vec3(q_xy, p.z);
        od = distanceUnion(od, cone(TUNNEL_MATERIAL2, c, get_spikes_p(q, phase_i, protrusion)));
    }
    
    return od;
}

ObjectDistance tunnel(int n, float radius, vec3 p) {
    float segment_angle = TAU / float(n);
    
    vec2 polar = rect2polar(p.xy);
    float segment = floor(polar.x / segment_angle);
    
    vec2 p_rot = polar2rect(polar - vec2((segment + 0.5)*segment_angle, 0.0));
    float dist = radius - p_rot.x;
    
    int material = (mod(segment, 2.0) < 1.0 ? TUNNEL_MATERIAL1 : TUNNEL_MATERIAL2);
    
    return ObjectDistance(dist, material);
}

ObjectDistance sceneDistance(vec3 p) {    
	ObjectDistance od;

    vec2 q_xy = polar2rect(
        rect2polar(p.xy)
        - vec2(1.0/16.0 * TAU * sin(1.0 * TAU * p.z), 0.0)
    ) + vec2(0.2 * sin(0.128 * TAU * p.z), 0.2 * sin(0.137 * TAU * p.z));
    vec3 q = vec3(q_xy.xy, p.z);
    float radius = 0.5;
    od = tunnel(16, radius, q);
    
    float protrusion = 0.0;
    if(16.0 <= iBeats) {
        protrusion = min(1.0, (iBeats - 16.0) / 16.0);
    }
    od = distanceSmoothUnion(od, spikes(p, protrusion));
    
    return od;
}

struct MarchResult {
    float length;
    float distance;
    int material;
    int iterations;
};
    
MarchResult march(vec3 origin, vec3 direction) {
    MarchResult result = MarchResult(0.0, 0.0, NO_MATERIAL, 0);
    for(int i = 0; i < MAX_ITERATIONS; i++) {
	    ObjectDistance sd = sceneDistance(origin + direction * result.length);
        result.distance = sd.distance;
        result.material = sd.material;
        result.iterations++;
        
        if(result.distance < THRESHOLD || result.length > MAX_DEPTH) {
            break;
        }
        
        result.length += result.distance * (1.0 - 0.5*THRESHOLD);
    }

    if(result.length > MAX_DEPTH) {
        result.material = NO_MATERIAL;
    }
    
    return result;
}

float marchShadow(vec3 lightPos, vec3 surfacePos, float k) {
    vec3 origin = lightPos;
    vec3 target = surfacePos;
    
    vec3 travel = target - origin;
    vec3 forward = normalize(travel);
    float maxLength = length(travel) * 0.9;
    
    float length = 0.0;
    float distance = 0.0;
    float light = 1.0;
    int iterations = 0;
    for(int i = 0; i < MAX_SHADOW_ITERATIONS; i++) {
        if(length >= maxLength - SHADOW_THRESHOLD) {
         	break;
        }
        
        ObjectDistance od = sceneDistance(origin + forward * length);
        distance = od.distance;
        
        if(distance < SHADOW_THRESHOLD) {
            return 0.0;
        }
        
        light = min(light, k * distance / length);
        length += distance * 0.999;
        
        iterations++;
    }

    //return 1.0 - float(iterations) / float(MAX_SHADOW_ITERATIONS);
    return light;
}

bool shifty(vec2 fragCoord) {
	vec2 p0 = 2.0*(0.5 * iResolution.xy - fragCoord.xy) / iResolution.xx;
	float angle0 = atan(p0.y, p0.x);
	float turn0 = (angle0 + 0.5 * TAU) / TAU;
	float radius0 = sqrt(p0.x*p0.x + p0.y*p0.y);
	
    float section = floor(pow(radius0*500.0, 0.6) + 2.0*iBeats);
    float turn = turn0 + 0.05 * sin(0.25 * TAU * iBeats + 0.3*section) - iBeats / 16.0;
    
    float segments = 6.0;
    float segment_angle = 1.0/segments;
    return mod(turn, 2.0*segment_angle) < segment_angle ? true : false;
}

float rand(vec2 p){
	return fract(sin(dot(p.xy, vec2(1.3295, 4.12))) * 493022.1);
}

float brightness_squared(vec3 color) {
    return 0.241*color.x*color.x + 0.691*color.y*color.y + 0.068*color.z*color.z;
}

bool dither(vec3 color, vec2 coord) {
	float b2 = brightness_squared(color);
	float r = rand(vec2(coord.x, coord.y + iGlobalTime));
	return r*r < b2;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	vec2 pxPos = 2.0*(0.5 * iResolution.xy - fragCoord.xy) / iResolution.xx;
    
    bool shifty = shifty(fragCoord);

    vec3 camPos = getCamPos();    
    if(shifty) {
        camPos += vec3(0.0, 0.0, 1.0);
    }
    vec3 camLook = camPos + vec3(0.0, 0.0, 1.0);
        
    /*vec2 camPos_xz_polar = vec2(iGlobalTime, 2.0);
    vec2 camPos_xz = polar2rect(camPos_xz_polar);
  	vec3 camPos = vec3(0.2 * sin(iGlobalTime), 0.1 * sin(iGlobalTime*0.98), iGlobalTime);//vec3(camPos_xz.x, 0.0, camPos_xz.y);
    
    vec3 camLook = camPos;
    camLook.z += 1.0;*/
    
    /*vec3 camPos = vec3(0.0, 0.0, -5.0);
    vec3 camLook = vec3(0.0);*/
    
    /*float camR = 0.5;
    vec2 camPosXY = polar2rect(vec2(0.125 * iBeats * TAU, camR));
    vec3 camPos = vec3(camPosXY.x, 0.0, camPosXY.y);
    vec3 camLook = vec3(0.0, 0.0, 0.0);*/
    
    vec3 camUp = vec3(0.0, 1.0, 0.0); 
    vec3 camForward = normalize(camLook - camPos);
    vec3 camLeft = normalize(cross(camUp, camForward));
    vec3 camUp2 = cross(camForward, camLeft);
    vec3 camPosForward = camPos + camForward;
    vec3 screenPos = camPosForward - pxPos.x * camLeft - pxPos.y * camUp2;
    vec3 rayForward = normalize(screenPos - camPos);
    
    MarchResult mr = march(camPos, rayForward);
    	
    vec3 rayEnd = camPos + mr.length * rayForward;
    vec3 color;
    vec3 bgColor = vec3(0.0);
    
    float kick_wave = fract(-iBeats);
            
    float crash_wave = 0.0;
    if(32.0 <= iBeats && iBeats < 34.0) {
        crash_wave = fract(-iBeats / 2.0);
    }
    
    float ohh_wave = 0.0;
    if(32.0 <= iBeats) {
        ohh_wave = fract(-iBeats + 0.5);
    }
    
    float reverse_wave = 0.0;
    if(56.0 <= iBeats) {
        reverse_wave = pow((iBeats - 56.0) / 8.0, 1.2);
    }
    
    if(mr.material == NO_MATERIAL) {
        color = bgColor;
    } else {
        vec3 baseColor;
                                
        float beats_mod2 = mod(iBeats, 2.0);
        
        if(mr.material == TUNNEL_MATERIAL1) {
            baseColor = vec3(mix(vec3(0.05), vec3(0.3), kick_wave));
        } else if(mr.material == TUNNEL_MATERIAL2) {
            vec3 color0;
            bool in_snare_roll = 31.0 <= iBeats && iBeats < 32.0;
            
            if(in_snare_roll) {
                color0 = vec3(0.6, 0.57, 0.76);
            } else {
                color0 = vec3(0.35, 0.21, 0.26);
            }
            
            float snare_wave = 0.0;
            if(in_snare_roll) {
                float sixteenth = mod(4.0 * iBeats, 4.0);
                float sixteenth_wave = fract(-sixteenth);
                if(sixteenth < 2.0 || sixteenth >= 3.0) {
                    snare_wave = sixteenth_wave;
                }
            } else if(mod(iBeats, 2.0) >= 1.0) {
                snare_wave = kick_wave;
            }
            
            vec3 snare_color = shifty
                             ? hsv2rgb(rgb2hsv(color0) * vec3(1.0, 1.0, 0.8))
                             : hsv2rgb(rgb2hsv(color0) * vec3(1.0, 1.0, 1.5));
            vec3 ohh_color = vec3(0.14, 0.14, 0.26);	
            baseColor = mix(vec3(0.1), snare_color, snare_wave);
            baseColor = mix(baseColor, ohh_color, ohh_wave);
        } else if(mr.material == SPIKE_MATERIAL) {
            baseColor = vec3(1.0);
        }
        
        if(mr.material == TUNNEL_MATERIAL1 || mr.material == TUNNEL_MATERIAL2) {
            if(fract(8.0 * rayEnd.z) < 0.5 != fract(polar2rect(8.0 * rayEnd.xy).x) < 0.5) {
                baseColor *= 0.9;
            }
        }
        
        float deltaTwice = 2.0 * NORMAL_DELTA;
        vec3 dx = vec3(NORMAL_DELTA, 0.0, 0.0);
        vec3 dy = vec3(0.0, NORMAL_DELTA, 0.0);
        vec3 dz = vec3(0.0, 0.0, NORMAL_DELTA);
        vec3 normal = normalize(vec3(
            (sceneDistance(rayEnd + dx).distance - sceneDistance(rayEnd - dx).distance) / deltaTwice,
            (sceneDistance(rayEnd + dy).distance - sceneDistance(rayEnd - dy).distance) / deltaTwice,
            (sceneDistance(rayEnd + dz).distance - sceneDistance(rayEnd - dz).distance) / deltaTwice
        ));

       	vec2 lightXZ = polar2rect(vec2(-0.5 * iGlobalTime, 3.0));
        vec3 lightPos = camPos;
		lightPos.y += 0.1;
        
        float ambient = 0.0;
        float diffuse = max(0.0, dot(normal, normalize(lightPos - rayEnd)));
        float specular = pow(diffuse, 16.0);
		float shadow = 1.0;
        shadow = marchShadow(lightPos, rayEnd, 32.0);

        color = ((ambient + shadow * diffuse) * baseColor + specular) * (1.0 - pow(mr.length, 1.5) * 0.01);
    }
        
    color *= dither(color, fragCoord) ? 0.8 : mix(1.0, 4.0, pow(crash_wave, 2.0));
    color *= dither(color, fragCoord)
           ? mix(1.0, 0.0, reverse_wave)
           : mix(1.0, 16.0, reverse_wave);
    
    fragColor = vec4(color, 1.0);
}

void main() {
    vec4 fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    vec2 fragCoord = gl_FragCoord.xy;
    mainImage(fragColor, fragCoord);
    gl_FragColor = fragColor;
}
