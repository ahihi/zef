uniform float iBeats;
uniform float iGlobalTime;
uniform vec2 iResolution;

#define TAU 6.283185307179586
#define TAU6TH 1.0471975511965976

#define THRESHOLD 0.001
#define SHADOW_THRESHOLD 0.01
#define MAX_ITERATIONS 256
#define MAX_SHADOW_ITERATIONS 256
#define NORMAL_DELTA 0.001
#define MAX_DEPTH 60.0

#define NO_MATERIAL 0
#define TUNNEL_MATERIAL 1
// ...
#define GROUND_MATERIAL 5


vec2 rect2polar(vec2 p) {
    return vec2(atan(p.y, p.x), length(p));
}

vec2 polar2rect(vec2 p) {
    return vec2(cos(p.x) * p.y, sin(p.x) * p.y);
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

ObjectDistance hexPrism(int material, vec3 p) {
    float tau6th = TAU / 6.0;
    float tau3rd = 2.0 * tau6th;
    
    float r = 0.5;
    float h = r * sin(tau6th); 
    float w = r * cos(tau6th);
    vec3 b = vec3(w, r, h);

    ObjectDistance od = box(b, material, p);
   	for(float i = 1.0; i < 3.0; i++) {
        vec2 p_xz_polar = rect2polar(p.xz);
        vec2 q_xz_polar = p_xz_polar + vec2(i * tau3rd, 0.0);
    	vec2 q_xz = polar2rect(q_xz_polar);
        vec3 q = vec3(q_xz.x, p.y, q_xz.y);
        od = distanceUnion(od, box(b, material, q));
    }
                            
	return od;
}

ObjectDistance hexTunnel1(int material, float scale, vec3 p) {
    float scale_inv = 1.0/scale;
    vec3 q = p;
    q.xz *= scale_inv;
    float q_y_abs = abs(q.y);
    float q_y_sign = q.y / q_y_abs;
    q.y = q_y_sign * (q_y_abs - 2.0*THRESHOLD); 
    return distanceDifference(
        hexPrism(material, p),
        hexPrism(material, q)
    );
}

ObjectDistance hexWall(int material, float width, vec3 p) {
    float r1 = 0.5;
    float w = r1 * cos(TAU6TH);
    float h1 = r1 * sin(TAU6TH);
    float h0 = h1 - width;
    float z = 0.5 * (h0 + h1);
	
    vec3 q = p;
    q.z += z;
    return box(vec3(w, 0.5, 0.5*width), material, q);
}

ObjectDistance hexTunnel(int material, float width, vec3 p) {
    ObjectDistance od = hexWall(material, width, p);
    vec2 p_xz_polar = rect2polar(p.xz);
    for(float i = 1.0; i < 6.0; i++) {
        vec2 q_xz_polar = p_xz_polar;
        q_xz_polar.x += i * TAU6TH;
        vec2 q_xz = polar2rect(q_xz_polar);
        vec3 q = p;
        q.xz = q_xz;
        od = distanceUnion(od, hexWall(material, width, q));
    }
    
    return od;
}

ObjectDistance hexTunnelSegment(int material, float width1, float width2, vec3 p) {
    vec3 q1 = p;
    q1.y -= 0.5;
    //q1.y *= 2.0;
    //q1.y += 0.25;
    //q1.y -= 0.0;
    
    
    ObjectDistance od = hexTunnel(material, width1, q1);
	
    vec3 q2 = p;
    q2.y += 0.5;
    //od = distanceUnion(od, hexTunnel(material, width2, q2))-;
    
    return od;
}

// scene
ObjectDistance sceneDistance(vec3 p) {    
	ObjectDistance od;
    
    od = ground(-1.0, GROUND_MATERIAL, p);
    
    vec3 p1 = p;
    //p1.z *= 2.0;
    vec2 p1_zy = p1.zy;
    p1_zy.x = mod(p1_zy.x, 1.0) - 0.5;
    vec2 p1_zy_polar = rect2polar(p1_zy);
    vec2 q_zy_polar = p1_zy_polar + vec2(TAU/4.0, 0.0);
    vec2 q_zy = polar2rect(q_zy_polar);
    vec3 q = vec3(p1.x, q_zy.yx);
    od = distanceUnion(od, hexTunnelSegment(TUNNEL_MATERIAL, 0.1, 0.2, q));
    
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

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 pxPos = 2.0*(0.5 * iResolution.xy - fragCoord.xy) / iResolution.xx;
    
    vec2 camPos_xz_polar = vec2(iGlobalTime, 2.0);
    vec2 camPos_xz = polar2rect(camPos_xz_polar);
  	vec3 camPos = vec3(0.2 * sin(iGlobalTime), 0.1 * sin(iGlobalTime*0.98), iGlobalTime);//vec3(camPos_xz.x, 0.0, camPos_xz.y);
    
    vec3 camLook = camPos;
    camLook.z += 1.0;
    
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
    vec3 bgColor = vec3(0.1);
    
    /*if(mr.distance < 0.0) {
       	color = vec3(0.0, 1.0, 1.0);
    } else */if(mr.material == NO_MATERIAL) {
        color = bgColor;
    } else {
        vec3 baseColor;
        
        if(mr.material == TUNNEL_MATERIAL) {
            baseColor = vec3(0.7);
        } else if(mr.material == GROUND_MATERIAL) {
            float tile = mod(floor(rayEnd.x) + floor(rayEnd.z), 2.0);
            
            if(tile < 1.0) {
	         	baseColor = vec3(0.2);
            } else {
                baseColor = vec3(0.3);
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
        
        float ambient = 0.2;
        float diffuse = max(0.0, dot(normal, normalize(lightPos - rayEnd)));
        float specular = pow(diffuse, 16.0);
		float shadow = 1.0;
        shadow = marchShadow(lightPos, rayEnd, 32.0);
        //shadow = marchGlitchyShadow(lightPos, rayEnd, 8.0);

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