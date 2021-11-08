#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_GOOGLE_include_directive : require

#include "unpack_attributes.h"


layout(location = 0) in vec4 vPosNorm;
layout(location = 1) in vec4 vTexCoordAndTang;

layout(push_constant) uniform params_t
{
    mat4 mProjView;
} params;

layout (location = 0) out VS_OUT
{
    vec3 wPos;
    vec3 wNorm;
    vec3 wTangent;
    vec2 texCoord;
    vec3 color;
} vOut;

layout(std430, binding = 1) buffer matr
{
    mat4x4 matrices[]; 
};

layout(std430, binding = 2) buffer instInd
{
    uint seenInstances[];
};

out gl_PerVertex { vec4 gl_Position; };

void main(void)
{
    const vec4 wNorm = vec4(DecodeNormal(floatBitsToInt(vPosNorm.w)),         0.0f);
    const vec4 wTang = vec4(DecodeNormal(floatBitsToInt(vTexCoordAndTang.z)), 0.0f);

    vOut.wPos     = (matrices[seenInstances[gl_InstanceIndex]] * vec4(vPosNorm.xyz, 1.0f)).xyz;
    vOut.wNorm    = mat3(transpose(inverse(matrices[seenInstances[gl_InstanceIndex]]))) * wNorm.xyz;
    vOut.wTangent = mat3(transpose(inverse(matrices[seenInstances[gl_InstanceIndex]]))) * wTang.xyz;
    vOut.texCoord = vTexCoordAndTang.xy;

    //vOut.color = ceil(log2((cosh(vOut.wNorm*2))/cos(vOut.wTangent)));
    
    gl_Position   = params.mProjView * vec4(vOut.wPos, 1.0);
}