#ifdef linux
#include "dx_linux.h"
#define GL_FORCE_RADIANS
#include <glm/glm.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <glm/gtc/matrix_transform.hpp>

#define MAX_PATH 500

struct sound_buffer_t {
	ALuint id;
	char path[MAX_PATH];
};

struct sound_source_t {
	ALuint id;
	ALuint buffer;
	bool playing;
	char path[MAX_PATH];
};

sound_buffer_t * sound_load(char* file);
sound_source_t * sound_source( sound_buffer_t * buffer );
void sound_play( sound_source_t * s );
void sound_play_looping( sound_source_t * s );
bool sound_is_playing( sound_source_t * s );
void sound_stop( sound_source_t * s );
void sound_release_source( sound_source_t * s );
void sound_release_buffer( sound_buffer_t * s );
void sound_set_pitch( sound_source_t * s, float freq );
void sound_volume( sound_source_t * s, long decibels );
void sound_pan( sound_source_t * s, long pan );
void sound_position( sound_source_t * s, float x, float y, float z, float min_distance, float max_distance );

void sound_set_position( sound_source_t * s, long newpos );
long sound_get_position( sound_source_t * s );

IDirectSoundBuffer8::IDirectSoundBuffer8()
{
	source = NULL;
}

HRESULT IDirectSoundBuffer8::SetVolume(LONG lVolume)
{
	if (!source)
		return DSERR_GENERIC;
	sound_volume(source, lVolume); 
	return DS_OK;
}

HRESULT IDirectSoundBuffer8::Play(DWORD dwReserved1, DWORD dwPriority, DWORD dwFlags) 
{
	if (!source)
		return DSERR_GENERIC;
	if (dwFlags&DSBPLAY_LOOPING) 
		sound_play_looping(source); 
	else 
		sound_play(source); 
	return DS_OK;
}
  
HRESULT IDirectSoundBuffer8::SetFrequency(DWORD dwFrequency)
{
	if (!source)
		return DSERR_GENERIC;
	sound_set_pitch(source, dwFrequency); 
	return DS_OK;
}

HRESULT IDirectSoundBuffer8::SetCurrentPosition(DWORD dwNewPosition)
{
	if (!source)
		return DSERR_GENERIC;
	sound_set_pitch(source, dwNewPosition); 
	return DS_OK;
}

HRESULT IDirectSoundBuffer8::GetCurrentPosition(LPDWORD pdwCurrentPlayCursor, LPDWORD pdwCurrentWriteCursor)
{
	if (!source)
		return DSERR_GENERIC;
	if (pdwCurrentPlayCursor)
		*pdwCurrentPlayCursor = sound_get_position(source);
	return DS_OK;
}

HRESULT IDirectSoundBuffer8::Stop() 
{
	if (!source)
		return DSERR_GENERIC;
	sound_stop(source); 
	return DS_OK;
}

HRESULT IDirectSoundBuffer8::SetPan(LONG lPan)
{
	if (!source)
		return DSERR_GENERIC;
#warning TODO: conversion lPan to OpenAL panning
	sound_pan(source, lPan); 
	return DS_OK;
}

IDirectSoundBuffer8::~IDirectSoundBuffer8()
{
	if (source)
		Release();
}

HRESULT IDirectSoundBuffer8::Release()
{
	if (!source)
		return DSERR_GENERIC;
#warning TODO: free OpenAL buffer...
	free(source);
	source = NULL;
}

/*
 * Matrix
*/
// Try to keep everything column-major to make OpenGL happy...
D3DXMATRIX* D3DXMatrixPerspectiveFovLH(D3DXMATRIX *pOut, FLOAT fovy, FLOAT Aspect, FLOAT zn, FLOAT zf)
{
	float yScale = 1.0f / tanf(fovy/2.0f);
	float xScale = yScale / Aspect;
	float zfzn = zf/(zf-zn);
	*pOut = glm::mat4(
		xScale, 0.0f, 0.0f, 0.0f,
		0.0f, yScale, 0.0f, 0.0f,
		0.0f, 0.0f, zfzn, 1.0f,
		0.0f, 0.0f, -zn*zfzn, 0.0f);
	return pOut;
}

D3DXMATRIX* D3DXMatrixIdentity(D3DXMATRIX* pOut)
{
	*pOut=glm::mat4(1.0f);
	return pOut;
}

D3DXMATRIX* D3DXMatrixRotationX(D3DXMATRIX* pOut, FLOAT Angle)
{
	*pOut=glm::rotate(glm::mat4(1.0f), Angle, glm::vec3(1.0f, 0.0f, 0.0f));
	return pOut;
}
D3DXMATRIX* D3DXMatrixRotationY(D3DXMATRIX* pOut, FLOAT Angle)
{
	*pOut=glm::rotate(glm::mat4(1.0f), Angle, glm::vec3(0.0f, 1.0f, 0.0f));
	return pOut;
}

D3DXMATRIX* D3DXMatrixRotationZ(D3DXMATRIX* pOut, FLOAT Angle)
{
	*pOut=glm::rotate(glm::mat4(1.0f), Angle, glm::vec3(0.0f, 0.0f, 1.0f));
	return pOut;
}

D3DXMATRIX* D3DXMatrixTranslation(D3DXMATRIX* pOut, FLOAT x, FLOAT y, FLOAT z)
{
	*pOut=glm::translate(glm::mat4(1.0f), glm::vec3(x, y, z));
	return pOut;
}

D3DXMATRIX* D3DXMatrixMultiply(D3DXMATRIX* pOut, const D3DXMATRIX* pM1, const D3DXMATRIX* pM2)
{
	*pOut=(*pM1)*(*pM2);
	return pOut;
}

glm::vec3 FromVector(const D3DXVECTOR3* vec)
{
	glm::vec3 ret;
	ret[0]=vec->x;
	ret[1]=vec->y;
	ret[2]=vec->z;
	return ret;
}

D3DXMATRIX* D3DXMatrixLookAtLH(D3DXMATRIX* pOut, const D3DXVECTOR3* pEye, const D3DXVECTOR3* pAt, const D3DXVECTOR3* pUp)
{
	glm::vec3 eye=FromVector(pEye);
	glm::vec3 at=FromVector(pAt);
	glm::vec3 up=FromVector(pUp);
	*pOut=glm::lookAt(eye, at, up);
	return pOut;
}


// IDirect3DDevice9
IDirect3DDevice9::IDirect3DDevice9()
{
	for (int i=0; i<8; i++) {
		colorop[i] = 0;
		colorarg1[i] = 0;
		colorarg2[i] = 0;
		alphaop[i] = 0;
	}
}

IDirect3DDevice9::~IDirect3DDevice9()
{
}

HRESULT IDirect3DDevice9::SetTransform(D3DTRANSFORMSTATETYPE State, D3DXMATRIX* pMatrix)
{
	switch (State) 
	{
		case D3DTS_VIEW:
			glMatrixMode(GL_MODELVIEW);
			glLoadMatrixf(glm::value_ptr(*pMatrix));
			break;
		case D3DTS_PROJECTION:
			glMatrixMode(GL_PROJECTION);
			glLoadMatrixf(glm::value_ptr(*pMatrix));
			break;
		case D3DTS_TEXTURE0:
		case D3DTS_TEXTURE1:
		case D3DTS_TEXTURE2:
		case D3DTS_TEXTURE3:
		case D3DTS_TEXTURE4:
			#warning TODO change active texture...
			glMatrixMode(GL_TEXTURE);
			glLoadMatrixf(glm::value_ptr(*pMatrix));
			break;
		default:
			printf("Unhandled Matrix SetTransform(%X, %p)\n", State, pMatrix);
	}
	return S_OK;
}

HRESULT IDirect3DDevice9::SetRenderState(D3DRENDERSTATETYPE State, int Value)
{
	switch (State)
	{
		case D3DRS_ZENABLE:
			if(Value)
				glDepthMask(GL_TRUE);
			else
				glDepthMask(GL_FALSE);
			break;
		case D3DRS_CULLMODE:
			switch(Value)
			{
				case D3DCULL_NONE:
					glDisable(GL_CULL_FACE);
					break;
				case D3DCULL_CW:
					glFrontFace(GL_CW);
					glCullFace(GL_FRONT);
					glEnable(GL_CULL_FACE);
					break;
				case D3DCULL_CCW:
					glFrontFace(GL_CCW);
					glCullFace(GL_FRONT);
					glEnable(GL_CULL_FACE);
					break;
			}
			break;
		default:
			printf("Unhandled Render State %X=%d\n", State, Value);
	}
	return S_OK;
}

HRESULT IDirect3DDevice9::SetUTBuffer(UTBuffer& a)
{
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
	glVertexPointer(3, GL_FLOAT, sizeof(UTVERTEX), &a.buffer[0].pos);
	glColorPointer(4, GL_UNSIGNED_BYTE, sizeof(UTVERTEX), &a.buffer[0].color);
	glTexCoordPointer(2, GL_FLOAT, sizeof(UTVERTEX), &a.buffer[0].tu);
	return S_OK;
}

HRESULT IDirect3DDevice9::DrawPrimitive(D3DPRIMITIVETYPE PrimitiveType,UINT StartVertex,UINT PrimitiveCount)
{
	const GLenum primgl[] = {GL_POINTS, GL_LINES, GL_LINE_STRIP, GL_TRIANGLES, GL_TRIANGLE_STRIP, GL_TRIANGLE_FAN};
	if(PrimitiveType<D3DPT_POINTLIST || PrimitiveType>D3DPT_TRIANGLEFAN)
		return E_FAIL;
	GLenum mode = primgl[PrimitiveType-1];
	glDrawArrays(mode, StartVertex, PrimitiveCount);
	return S_OK;
}

HRESULT IDirect3DDevice9::SetTextureStageState(DWORD Stage, D3DTEXTURESTAGESTATETYPE Type, DWORD Value)
{
	if(Stage>0) {
		printf("Unhandled SetTextureStageState(%d, 0x%X, 0x%X)\n", Stage, Type, Value);
		return S_OK;
	}

	switch(Type)
	{
		case D3DTSS_COLOROP:
			colorop[Stage] = Value;
			switch(Value)
			{
				case D3DTOP_DISABLE:
					glDisable(GL_TEXTURE_2D);
					break;
				case D3DTOP_SELECTARG1:
					if(colorarg1[Stage]==D3DTA_TEXTURE)
						glEnable(GL_TEXTURE_2D);
				case D3DTOP_SELECTARG2:
					if(colorarg2[Stage]==D3DTA_TEXTURE)
						glEnable(GL_TEXTURE_2D);
					break;
				default:
					printf("Unhandled SetTextureStageState(%d, D3DTSS_COLOROP, %d)\n", Stage, Value);
			}
			break;
		case D3DTSS_COLORARG1:
			colorarg1[Stage] = Value;
			if(Value==D3DTA_TEXTURE && colorop[Stage]==D3DTOP_SELECTARG1)
				glEnable(GL_TEXTURE_2D);
			break;
		case D3DTSS_COLORARG2:
			colorarg2[Stage] = Value;
			if(Value==D3DTA_TEXTURE && colorop[Stage]==D3DTOP_SELECTARG2)
				glEnable(GL_TEXTURE_2D);
			break;
		default:
			printf("Unhandled SetTextureStageState(%d, 0x%X, 0x%X)\n", Stage, Type, Value);
	}

	return S_OK;
}

HRESULT IDirect3DDevice9::SetTexture(DWORD Sampler, IDirect3DTexture9 *pTexture)
{
	if(Sampler) {
		glActiveTexture(GL_TEXTURE0+Sampler);
		glClientActiveTexture(GL_TEXTURE0+Sampler);
	}

	pTexture->Bind();

	if(Sampler) {
		glActiveTexture(GL_TEXTURE0);
		glClientActiveTexture(GL_TEXTURE0);
	}
	return S_OK;
}

CDXUTTextHelper::CDXUTTextHelper(TTF_Font* font, GLuint sprite, int size) : 
	m_font(font), m_sprite(sprite), m_size(size)
{
	// nothing...
}

CDXUTTextHelper::~CDXUTTextHelper()
{
	// nothing
}


UTVERTEX* CheckUTBuffer(UTBuffer& a, uint32_t s)
{
	if (s>a.capacity) {
		#define FACTOR 	128
		a.capacity = ((s+(FACTOR-1))/FACTOR)*FACTOR;
		#undef FACTOR
		a.buffer = (UTVERTEX*)realloc(a.buffer, sizeof(UTVERTEX)*a.capacity);
	}
	return a.buffer;
}
void FreeUTBuffer(UTBuffer& a)
{
	if (a.capacity) {
		free(a.buffer);
		a.buffer = 0;
		a.capacity = 0;
	}
}


static IDirect3DDevice9* device = NULL;
IDirect3DDevice9 *DXUTGetD3DDevice()
{
	if (!device)
		device = new IDirect3DDevice9();
	return device;
}

#endif
