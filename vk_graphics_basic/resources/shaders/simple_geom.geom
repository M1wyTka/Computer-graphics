#version 450
layout (triangles) in;
layout (line_strip, max_vertices = 3) out;

layout(push_constant) uniform params_t
{
    mat4 mProjView;
} params;

layout (location = 0 ) in VS_IN
{
    vec3 wPos;
    vec3 wNorm;
    vec3 wTangent;
    vec2 texCoord;
} vIn[];

vec4 GetNorm()
{
   return vec4(normalize(cross((vIn[1].wPos -  vIn[0].wPos), (vIn[2].wPos -  vIn[0].wPos))), 0.0);
}  

vec4 GetMiddlePoint()
{
    return  vec4((vIn[0].wPos + vIn[1].wPos + vIn[2].wPos) / 3, 1.0);
}

vec4 GetOffsetPoint()
{
    float offsetMagnitude = 0.2;
    return GetMiddlePoint() + GetNorm() * offsetMagnitude;
}

// definetly not random
float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 GetRandInSphere(vec4 middle, float radius)
{
    float n = rand(vec2(middle.x, middle.y))*radius;
    return vec4(n, n, n, 0);
}


void main()
{
    vec4 start = GetMiddlePoint();
    vec4 end = GetOffsetPoint();
    vec4 mid =  (start + end) / 2;

    gl_Position = params.mProjView * (start);
    EmitVertex();

    gl_Position = params.mProjView * (mid + GetRandInSphere(mid, 0.015));
    EmitVertex();

    gl_Position = params.mProjView * (end + GetRandInSphere(end, 0.015));
    EmitVertex();

    EndPrimitive();
}  