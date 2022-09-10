#version 450

/*
   TriggerExcited's MIPlateral.
   
   MIPlateral is a super fast bilateral with a very wide range of settings.
   Changing the effect radius or strength does not affect performance.
   Makes use of Fabrice Neyret's mipmap edge detection technique.

   Copyright (c) 2022 TriggerExcited - triggerexcited@gmail.com

   Permission is hereby granted, free of charge, to any person obtaining a
   copy of this software and associated documentation files (the
   "Software"), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to permit
   persons to whom the Software is furnished to do so, subject to the
   following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
   DEALINGS IN THE SOFTWARE.
*/

#pragma parameter QUALITY "Blur Radius:" 2.0 0.0 10.0 1.0
#pragma parameter STRENGTH "Bilateral Strength:" 0.15 0.0 1.0 0.01

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float QUALITY;
	float STRENGTH;
} params;

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
	vec3 original, lod0, lod1;
	vec3 edge3;
	float edge, floor_val;

	original = texture(Source, vTexCoord, 0.0).rgb;
	lod0 = texture(Source, vTexCoord, params.QUALITY).rgb;

	edge3 = abs(original - lod0);
	edge = (edge3.r + edge3.g + edge3.b) / 3.0;
	edge = clamp(edge, 0.0, params.STRENGTH);    // help, I need a curve here (might be partly responsible for edge artifacts)
	edge = 1.0 - (edge / params.STRENGTH);
	
	// 2 Tap Version (not accurate, fastest version, halo effect, less edge artifacts)
	//FragColor = vec4(mix(original, lod0, edge), 1.0);
	
	// 3 Tap Version (not accurate, interesting result, most edge artifacts)
	//FragColor = vec4(texture(Source, vTexCoord, params.QUALITY * edge).rgb, 1.0);
	
	// 4 Tap Version (accurate, no artifacts)
	edge *= params.QUALITY;
	floor_val = floor(edge);
	lod0 = texture(Source, vTexCoord, floor_val).rgb;
	lod1 = texture(Source, vTexCoord, ceil(edge)).rgb;
	FragColor = vec4(mix(lod0, lod1, edge - floor_val),1.0);
}
