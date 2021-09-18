const vec3 eye = vec3(0, 0, 3);
const vec3 light = vec3(0, 0, 5);
const int maxsteps = 30;
const float maxdist = 15.0;
const float eps = 0.01;

// Rotation matrix around the X axis.
mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

// Rotation matrix around the Y axis.
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

float dVibroSphere(vec3 p, in vec3 c, float size, bool side)
{
    if(side)
        return length(p-c) - size + 0.03 * cos(-20.0*p.x + 5.0* iTime);
    else
        return length(p-c) - size + 0.03 * sin(-20.0*p.z + 5.0* iTime);
}

float dSphere(vec3 p, in vec3 c, float size)
{
    return length(p-c) - size;
}

float dEllipsoid( vec3 p, vec3 offset, vec3 r )
{
  p += offset;
  float k0 = length(p/r);
  float k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}

float dVibroTorus ( vec3 p, vec3 offset, vec2 t, bool side)
{
    p -= offset;
	vec2 q = vec2(length(p.xz) - t.x, p.y);
    if(side)
        return length(q) - t.y + 0.03 * sin(20.0*p.x +iTime);
    else
        return length(q) - t.y + 0.03 * sin(20.0*p.z +iTime);
}

float dTorus ( vec3 p, vec3 offset, vec2 t)
{
    p -= offset;
	vec2 q = vec2(length(p.xz) - t.x, p.y);
    
	return length(q) - t.y;
}


float smin ( float a, float b, float k )
{
	float res = exp ( -k*a ) + exp ( -k*b );
	return -log ( res ) / k;
}


float sdf(in vec3 p, in mat3 m)
{
    vec3 q = m * p;
    //return dSphere(p, vec3(0, 0, 0));
    return
    max(
        min(
            max(
                max(
                    max(
                        min(
                           min(
                                min(
                                    min(
                                        max(
                                            smin(
                                                dVibroTorus(q, vec3(-1.5, 0, 1),  vec2(1.1, 0.4), true),
                                                dSphere(q, vec3(sin(iTime), 0, cos(iTime)), 0.5), 
                                                10.0),  
                                            -dSphere(q, vec3(-sin(iTime), 0, cos(iTime)), 0.5)
                                            ),
                                        dVibroTorus(q, vec3(1.5, 0, 1),  vec2(1.1, 0.4), false)
                                        ),
                                       dSphere(q, vec3(0, 0, -0.8), 1.5)
                                    ),
                                   dSphere(q, vec3(0.5, -0.7, 0.1), 0.5)),
                               dSphere(q, vec3(-0.5, -0.7, 0.1), 0.5)
                            ), -dSphere(q, vec3(-0.5, -1.1, 0.2), 0.2)
                       ), -dSphere(q, vec3(0.5, -1.1, 0.2), 0.2)
                    ), -dVibroSphere(q, vec3(0, -1.3, -0.3), 0.2, false)
                ), dVibroSphere(q, vec3(1.5*sin(iTime), 1.5*cos(iTime), 0.75), 0.3, false)
            ), -dEllipsoid(q, vec3(0, 1.5, 0.55), vec3(0.3, 0.1, 0.1))
        );
    }

vec3 generateNormal(vec3 z, float d, in mat3 m)
{
    float e = max(d * 0.5, eps);
    float dx1 = sdf(z + vec3(e, 0, 0), m);
    float dx2 = sdf(z - vec3(e, 0, 0), m);
    float dy1 = sdf(z + vec3(0, e, 0), m);
    float dy2 = sdf(z - vec3(0, e, 0), m);
    float dz1 = sdf(z + vec3(0, 0, e), m);
    float dz2 = sdf(z - vec3(0, 0, e), m);
    return normalize(vec3(dx1-dx2, dy1-dy2, dz1-dz2));
    
}

vec3 trace(in vec3 from, in vec3 dir, out bool hit, in mat3 m)
{
    vec3 p = from;
    float totalDist = 0.0;
    
    hit = false;
    
    for(int stp = 0; stp < maxsteps; stp++)
    {
        float dist = sdf(p, m);
        if(dist < eps)
        {
            hit = true;
            break;
        }
        
        totalDist += dist;
        
        if(totalDist > maxdist)
            break;
            
        p += dist * dir;
    }
    
    return p;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    bool hit;
    
    vec3 mouse = vec3((iMouse.xy/iResolution.xy) - 0.5, iMouse.z-0.5);
    mat3 m     = rotateX (6.0 * mouse.y) * rotateY (6.0 * mouse.x);
    
    vec2 scale = 9.0 * iResolution.xy / max(iResolution.x, iResolution.y);
    
    vec2 uv = scale * (fragCoord/iResolution.xy - vec2(0.5));
    vec3 dir = normalize(vec3(uv, 0) - eye);
    vec4 color = vec4(0, 0, 0, 1);
    
    vec3 p = trace(eye, dir, hit, m);
    
    if(hit)
    {
        vec3  l  = normalize( light - p );
        vec3  v  = normalize( eye - p );
		vec3  n  = generateNormal( p, 0.001, m );
		float nl = max (0.0, dot(n, l));
        vec3  h  = normalize(l + v);
        float hn = max (0.0, dot (h, n));
        float sp = pow (hn, 150.0);
		
		color = 0.5*vec4(nl) + 0.5*sp*vec4(1, 1, 0, 1);
        
    }
    
    
    // Output to screen
    fragColor = color;
}