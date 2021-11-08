#version 450
layout (triangles) in;
layout (line_strip, max_vertices = 2) out;

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

void main()
{
    gl_Position = params.mProjView * GetMiddlePoint();
    EmitVertex();

    gl_Position = params.mProjView * GetOffsetPoint();
    EmitVertex();

    EndPrimitive();
}  