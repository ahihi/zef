uniform float iBeats;
uniform float iGlobalTime;
uniform vec2 iResolution;
uniform bool iRotate;

#define TAU 6.283185307179586

float scale(float l0, float r0, float l1, float r1, float x) {
	return (x - l0) / (r0 - l0) * (r1 - l1) + l1;
}

vec2 rect2polar(vec2 p) {
    return vec2(atan(p.y, p.x), length(p));
}

vec2 polar2rect(vec2 p) {
    return vec2(cos(p.x) * p.y, sin(p.x) * p.y);
}

#define NO_MATERIAL 0
#define HEAD_MATERIAL 1
#define EYE_MATERIAL 2
#define TOOTH_MATERIAL 3
#define GROUND_MATERIAL 4

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

ObjectDistance cylinder(vec2 h, int material, vec3 p)
{
  vec2 d = abs(vec2(length(p.xy), p.z)) - h;
  return ObjectDistance(
      min(max(d.x, d.y), 0.0) + length(max(d, 0.0)),
      material
  );
}

ObjectDistance ground(float y, int material, vec3 p) {
     return ObjectDistance(p.y - y, material);   
}

vec3 focus() {
    return vec3(0.0, 0.0, -4.0*iGlobalTime);
}

#define N_TEETH 6.0
ObjectDistance head(vec3 p) {
    ObjectDistance od = box(vec3(1.0), HEAD_MATERIAL, p);
    
    float pad = 0.3;
    float r_eye = 0.25;
    
    vec2 h_eye = vec2(r_eye, r_eye);
    float d_eye = 1.0 - r_eye - pad;
    vec3 p_eye = vec3(d_eye, d_eye, -(1.0 - h_eye.y + 0.01));
    od = distanceDifference(
    	od,
        cylinder(h_eye, EYE_MATERIAL, p - p_eye)
    );
    od = distanceDifference(
      	od,
        cylinder(h_eye, EYE_MATERIAL, p - p_eye * vec3(-1.0, 1.0, 1.0))
    );
    
    vec3 b_mouth = vec3(1.0 - pad, 0.3, 0.5);
    vec3 p_mouth = vec3(0.0, -(1.0 - b_mouth.y - pad), -(1.0 - b_mouth.z + 0.01));
    od = distanceDifference(
        od,
        box(b_mouth, HEAD_MATERIAL, p - p_mouth)
    );
    
    
    float pad_tooth = 0.01;
    float l_mouth = -(b_mouth.x - pad_tooth);
    float r_mouth = -l_mouth;
    for(float i = 0.0; i < N_TEETH; i++) {
        float t_tooth = abs(mod(iGlobalTime - 0.2*i, 2.0) - 1.0);
        vec3 b_tooth = vec3(
            b_mouth.x / N_TEETH - pad_tooth,
            scale(0.0, 1.0, 0.2*b_mouth.y, 0.5*b_mouth.y, t_tooth),
            0.08
        );
        vec3 p_tooth = vec3(
            scale(0.0, 1.0, l_mouth, r_mouth, i/N_TEETH) + b_mouth.x / N_TEETH / 1.0,
            p_mouth.y + b_mouth.y - b_tooth.y,
            -0.9
        );
        od = distanceUnion(
        	od,
            box(b_tooth, TOOTH_MATERIAL, p - p_tooth)
        );
        vec3 p_tooth1 = vec3(
            p_tooth.x,
            p_mouth.y - b_mouth.y + b_tooth.y,
            p_tooth.z
        );
        od = distanceUnion(
            od,
            box(b_tooth, TOOTH_MATERIAL, p - p_tooth1)
        );
    }
    
    
    return od;
}

ObjectDistance robot(vec3 p) {
    return head(p);
}

ObjectDistance sceneDistance(vec3 p) {    
	ObjectDistance od;
    
    p -= focus();
    
    od = ground(-1.0, GROUND_MATERIAL, p);
    
    vec3 q = p;//vec3((mod(p.x, 2.0) - 1.0) * 1.05, p.yz);
    //float t = iGlobalTime - 0.2*floor(p.x/2.0);
    float jump = 1.5*abs(sin(0.25 * (iBeats + 1.0) * TAU));
    q.y -= jump;
    
    vec3 q2 = q;
    if(iRotate && fract(0.25 * (iBeats + 1.0)) < 0.5) {
        float rot_sign = -1.0;
        float beat8 = fract((iBeats + 5.0) / 8.0);
        
        if((0.5 <= beat8) && p.x < 0.0) {
            rot_sign = 1.0;
        }
        // do the rotation thing
        vec2 q_zy_p = rect2polar(q.zy);
        vec2 q2_zy_p = q_zy_p + vec2(rot_sign * 0.5 * (iBeats + 1.0) * TAU, 0.0);
        vec2 q2_zy = polar2rect(q2_zy_p);
        q2 = vec3(q.x, q2_zy.yx);
    }
    
    od = distanceUnion(
        od,
        robot(q2)
    );
            
    return od;
}

#define THRESHOLD 0.0001
#define MAX_STEP 0.5
#define SHADOW_THRESHOLD 0.01
#define MAX_ITERATIONS 256
#define MAX_SHADOW_ITERATIONS 32
#define NORMAL_DELTA 0.01
#define MAX_DEPTH 60.0

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
        
        //result.length += min(MAX_STEP, result.distance * (1.0 - 0.5*THRESHOLD));
        result.length += result.distance * (1.0 - 0.5*THRESHOLD) /* * 1.4; // lol */;
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

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 pxPos = 2.0*(0.5 * iResolution.xy - fragCoord.xy) / iResolution.xx;
    
    vec2 camXZ = polar2rect(vec2(-TAU/4.0 + 0.3 * iGlobalTime, 3.0));
  	vec3 camPos = vec3(camXZ.x, 1.0 + 0.7 * sin(1.0 * iGlobalTime), camXZ.y);
    camPos = focus() + vec3(2.0*sin(0.6*iGlobalTime), 2.0, -6.5);
    
    vec3 camLook = focus();
    
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
    
    if(mr.material == NO_MATERIAL) {
        vec3 sky_color = iRotate
                       ? vec3(0.14, 0.14, 0.26)
                       : vec3(0.35, 0.21, 0.26);
        float sky_mix = clamp(5.0*rayForward.y, 0.0, 1.0);
        color = mix(vec3(0.0), sky_color, sky_mix);
    } else {
        vec3 baseColor;
        
        if(mr.material == HEAD_MATERIAL) {
            baseColor = vec3(0.6);
        } else if(mr.material == EYE_MATERIAL) {
            float kick_wave = fract(-iBeats);
            vec3 eye_color = iRotate
                           ? vec3(0.35, 0.21, 0.26) * 1.5
                           : vec3(0.60, 0.57, 0.76);
            baseColor = mix(vec3(0.0), eye_color, kick_wave);
        } else if(mr.material == TOOTH_MATERIAL) {
            baseColor = vec3(1.0);
        } else if(mr.material == GROUND_MATERIAL) {
            float tile = mod(floor(rayEnd.x) + floor(rayEnd.z), 2.0);
            
            float snare_wave = fract(-0.5 * (iBeats + 1.0));
            
            if(tile < 1.0) {
	         	baseColor = mix(vec3(0.2), vec3(0.3), snare_wave);
            } else {
                baseColor = mix(vec3(0.3), vec3(0.9), snare_wave);
            }
        }
        
        float deltaTwice = 2.0 * NORMAL_DELTA;
        vec3 dx = vec3(NORMAL_DELTA, 0.0, 0.0);
        vec3 dy = vec3(0.0, NORMAL_DELTA, 0.0);
        vec3 dz = vec3(0.0, 0.0, NORMAL_DELTA);
        vec3 normal = normalize(vec3(
            (sceneDistance(rayEnd + dx).distance) / NORMAL_DELTA,
            (sceneDistance(rayEnd + dy).distance) / NORMAL_DELTA,
            (sceneDistance(rayEnd + dz).distance) / NORMAL_DELTA
        ));

       	vec2 lightXZ = polar2rect(vec2(-0.5 * iGlobalTime, 3.0));
        vec3 lightPos = camPos + vec3(0.0, 2.0, 0.0);
        
        float ambient = 0.2;
        float diffuse = max(0.0, dot(normal, normalize(lightPos - rayEnd)));
        float specular = pow(diffuse, 16.0);
		float shadow = 1.0;
        shadow = marchShadow(lightPos, rayEnd, 32.0);

        color = ((ambient + shadow * diffuse) * baseColor + specular) * (1.0 - mr.length * 0.01);
        //color = vec3(rayIterations / MAX_TRACE_ITERATIONS, 0.0, shadow);

    }
        
	//color = mix(vec3(0.0), vec3(0.0, 1.0, 0.0), float(mr.iterations)/float(MAX_ITERATIONS));
    
    fragColor = vec4(color, 1.0);
}

void main() {
    vec4 fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    vec2 fragCoord = gl_FragCoord.xy;
    mainImage(fragColor, fragCoord);
    gl_FragColor = fragColor;
}
