varying vec3 vViewDirection;

// direction towards sun 
uniform vec3 uLightDirection;

// henyey-greenstein parameter, aerosol scattering (sun disk size)
//uniform float g;
const float g = -0.990;

// air, aerosol density scale (turbidity)
//uniform vec2 RayleighMieScaleHeight;// = {0.25, 0.1};
const vec2 RayleighMieScaleHeight = vec2(0.25, 0.1);

// rgb wavelength(rayleigh and mie)
//const vec3 WaveLength = vec3(0.65, 0.57, 0.475);
const vec3 InvWavelength = vec3(5.602, 9.473, 19.644); // pow(WaveLength, -4.0);
const vec3 WavelengthMie = vec3(1.435, 1.603, 1.869); // pow(WaveLength, -0.84);

const float PI = 3.14159265;
const float InnerRadius = 6356.7523142;
const float OuterRadius = 6356.7523142 * 1.0157313;
const float Scale = 1.0 / (6356.7523142 * 1.0157313 - 6356.7523142);

//const float ESun = 20.0;
//const float Kr = 0.0025;
//const float Km = 0.0010;
const float KrESun = 0.0025 * 20.0;
const float KmESun = 0.0010 * 20.0;
const float Kr4PI = 0.0025 * 4.0 * 3.1415159;
const float Km4PI = 0.0010 * 4.0 * 3.1415159;

#define NumSamples 4

float MiePhase(float ViewSunCos, float ViewSunCos2)
{
   vec3 HG = vec3(1.5 * ((1.0 - g * g) / (2.0 + g * g)), 1.0 + g * g, 2.0 * g);
   return HG.x * (1.0 + ViewSunCos2) / pow(HG.y - HG.z * ViewSunCos, 1.5);
}

float RayleighPhase(float ViewSunCos2)
{
   return 0.75 * (1.0 + ViewSunCos2);
}

float HitOuterSphere(vec3 Pos, vec3 Dir) 
{
   vec3 L = -Pos;
   float B = dot(L, Dir);
   float C = dot(L, L);
   float D = C - B * B; 
   float q = sqrt(OuterRadius * OuterRadius - D);
   float t = B;
   return t + q;
}

vec2 DensityRatio(float Height)
{
   float Altitude = (Height - InnerRadius) * Scale;
   return exp(-Altitude / RayleighMieScaleHeight);
}

vec2 OpticalDepth(vec3 Pos, vec3 Dir, float Length)
{
   float SampleLength = Length / NumSamples;
   float ScaledLength = SampleLength * Scale;
   vec3 SampleRay = Dir * SampleLength;
   Pos += SampleRay * 0.5;
   
   vec2 OpticalDepth = vec2(0);
   for(int i = 0; i < NumSamples; i++)
   {
      float Height = length(Pos);
      OpticalDepth += DensityRatio(Height);
      Pos += SampleRay;
   }
   
   return OpticalDepth * ScaledLength;
}

vec3 Scatter(vec3 ViewPos, vec3 ViewDir, vec3 SunDir)
{
   float ViewLength = HitOuterSphere(ViewPos , ViewDir);
   float SampleLength = ViewLength / NumSamples;
   float ScaledLength = SampleLength * Scale;
   vec3 SampleRay = ViewDir * SampleLength;
   vec3 SamplePos = ViewPos + SampleRay * 0.5;
   ViewLength -= SampleLength * 0.5;
   
   vec3 Rayleigh = vec3(0);
   vec3 Mie = vec3(0);
   for(int i = 0; i < NumSamples; i++)
   {
      float SunLength = HitOuterSphere(SamplePos, SunDir);
      vec2 SunOpticalDepth = OpticalDepth(SamplePos, SunDir, SunLength);
      vec2 ViewOpticalDepth = OpticalDepth(SamplePos, ViewDir, ViewLength);
      
      vec2 OpticalDepth = SunOpticalDepth + ViewOpticalDepth;
      vec3 Attenuation = exp(-Kr4PI * InvWavelength * OpticalDepth.x - Km4PI * OpticalDepth.y);
      
      float SampleHeight = length(SamplePos);
      vec2 DensityRatio = DensityRatio(SampleHeight) * ScaledLength;
      
      Rayleigh += DensityRatio.x * Attenuation;
      Mie += DensityRatio.y * Attenuation;
      
      SamplePos += SampleRay;
      ViewLength -= SampleLength;
   }
   
   float ViewSunCos = -dot(ViewDir, SunDir);
   float ViewSunCos2 = ViewSunCos * ViewSunCos;
   
   Rayleigh = Rayleigh * KrESun * InvWavelength;
   Mie = Mie * KmESun * WavelengthMie;
   
   return Rayleigh * RayleighPhase(ViewSunCos2) + Mie * MiePhase(ViewSunCos, ViewSunCos2);
}

void main(void)
{
   vec3 ViewPos = vec3(0, 0, InnerRadius + 1e-3);
   vec3 ViewDir = normalize(vViewDirection);
   vec3 SunDir = normalize(uLightDirection);
   vec3 Color = Scatter(ViewPos, ViewDir, SunDir);
   gl_FragColor = vec4(Color, 1.0f);
}
