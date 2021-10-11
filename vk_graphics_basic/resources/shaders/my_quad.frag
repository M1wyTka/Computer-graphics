#version 450
#extension GL_ARB_separate_shader_objects : enable

layout(location = 0) out vec4 color;

layout (binding = 0) uniform sampler2D colorTex;

layout (location = 0 ) in VS_OUT
{
  vec2 texCoord;
} surf;

vec4 billateralFilter(vec2 coord, int filtSize, float sigD, float sigR)
{
	vec2 step = 1.0 / textureSize(colorTex, 0);

	vec4 filteredSum = vec4(0);
	float fullWeight = 0;

	for(int i = -filtSize; i <= filtSize; i++)
	{
		for(int j = -filtSize; j <= filtSize; j++)
		{
			vec4 Ikl = textureLod(colorTex, coord, 0);
			
			vec2 relCoord = coord + step*vec2(i, j);
			vec4 Iij = textureLod(colorTex, relCoord, 0);
			
			float w = exp(-((pow(length(Iij-Ikl),2)) / (2*pow(sigD,2))) - (pow(length(coord-relCoord),2))/(2*pow(sigR,2)));

			fullWeight += w; 
			filteredSum += Iij*w; 
		}
	}
	return filteredSum / fullWeight;
}


void main()
{
	color = billateralFilter(surf.texCoord, 2, 3, 4);
}
