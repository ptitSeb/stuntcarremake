#ifndef _DX_LINUX_H_
#define _DX_LINUX_H_
#ifdef HAVE_GLES
#include <GLES/gl.h>
#else
#include <GL/gl.h>
#endif
#include <math.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <string.h>
#ifdef USE_SDL2
#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>
#include <SDL2/SDL_image.h>
#else
#include <SDL/SDL.h>
#include <SDL/SDL_ttf.h>
#include <SDL/SDL_image.h>
#endif
#include <AL/al.h>
#include <wchar.h>
#define USEGLM
#ifdef USEGLM
#define GL_FORCE_RADIANS
//#define GLM_LEFT_HANDED 
#include <glm/glm.hpp>		
#include <glm/gtc/type_ptr.hpp>		
#include <glm/gtc/matrix_transform.hpp>
#else
#include "matvec.h"
#endif

// DX -> OpenGL inspired by forsaken project
typedef u_int32_t DWORD;
typedef u_int8_t BYTE;
typedef u_int16_t WORD;
typedef u_int32_t BOOL;

typedef const wchar_t* LPCWSTR;

typedef void* HMODULE;

typedef int32_t LONG;
typedef float FLOAT;
typedef double DOUBLE;
typedef int32_t INT;

typedef BYTE *LPBYTE;

#define D3DX_PI PI
#define CALLBACK 

#define TRUE true
#define FALSE false

#define S_OK	0x00000000
#define E_ABORT	0x80004004
#define E_FAIL	0x80004005

#define ERROR_SUCCESS 0

#define	_FACDS 0x878
#define	MAKE_DSHRESULT(code)	MAKE_HRESULT(1,_FACDS,code)

#define DS_OK 			0
#define DSERR_ALLOCATED 	MAKE_DSHRESULT(10)
#define DSERR_CONTROLUNAVAIL 	MAKE_DSHRESULT(30)
#define DSERR_INVALIDPARAM 	E_INVALIDARG
#define DSERR_INVALIDCALL M	AKE_DSHRESULT(50)
#define DSERR_GENERIC 		E_FAIL
#define DSERR_PRIOLEVELNEEDED 	MAKE_DSHRESULT(70)
#define DSERR_OUTOFMEMORY 	E_OUTOFMEMORY
#define DSERR_BADFORMAT 	MAKE_DSHRESULT(100)
#define DSERR_UNSUPPORTED 	E_NOTIMPL
#define DSERR_NODRIVER 		MAKE_DSHRESULT(120)
#define DSERR_ALREADYINITIALIZED MAKE_DSHRESULT(130)
#define DSERR_NOAGGREGATION 	CLASS_E_NOAGGREGATION
#define DSERR_BUFFERLOST 	MAKE_DSHRESULT(150)
#define DSERR_OTHERAPPHASPRIO 	MAKE_DSHRESULT(160)
#define DSERR_UNINITIALIZED 	MAKE_DSHRESULT(170)

#define DSCAPS_PRIMARYMONO 	0x00000001
#define DSCAPS_PRIMARYSTEREO 	0x00000002
#define DSCAPS_PRIMARY8BIT 	0x00000004
#define DSCAPS_PRIMARY16BIT 	0x00000008
#define DSCAPS_CONTINUOUSRATE 	0x00000010
#define DSCAPS_EMULDRIVER 	0x00000020
#define DSCAPS_CERTIFIED 	0x00000040
#define DSCAPS_SECONDARYMONO 	0x00000100
#define DSCAPS_SECONDARYSTEREO 	0x00000200
#define DSCAPS_SECONDARY8BIT 	0x00000400
#define DSCAPS_SECONDARY16BIT 	0x00000800

#define	DSSCL_NORMAL 		1
#define	DSSCL_PRIORITY 		2
#define	DSSCL_EXCLUSIVE 	3
#define	DSSCL_WRITEPRIMARY 	4

#define DSBPLAY_LOOPING 	0x00000001
#define DSBSTATUS_PLAYING 	0x00000001
#define DSBSTATUS_BUFFERLOST 	0x00000002
#define DSBSTATUS_LOOPING 	0x00000004

#define DSBLOCK_FROMWRITECURSOR 0x00000001

#define DSBCAPS_PRIMARYBUFFER 	0x00000001
#define DSBCAPS_STATIC 		0x00000002
#define DSBCAPS_LOCHARDWARE 	0x00000004
#define DSBCAPS_LOCSOFTWARE 	0x00000008
#define DSBCAPS_CTRLFREQUENCY 	0x00000020
#define DSBCAPS_CTRLPAN 	0x00000040
#define DSBCAPS_CTRLVOLUME 	0x00000080
#define DSBCAPS_CTRLDEFAULT 	0x000000E0 /* Pan + volume + frequency. */
#define DSBCAPS_CTRLALL 	0x000000E0 /* All control capabilities */
#define DSBCAPS_STICKYFOCUS 	0x00004000
#define DSBCAPS_GETCURRENTPOSITION2 0x00010000 /* More accurate play cursor under emulation*/

#define DSBPAN_RIGHT		 10000
#define DSBPAN_LEFT		-10000
#define DSBPAN_CENTER		 0

// taken from d3d9.h
typedef DWORD COLOR; // bgra originaly, rgba for OpenGL

// bjd - taken from d3dtypes.h
//#define RGBA_MAKE(r, g, b, a) 	((COLOR) (((a) << 24) | ((r) << 16) | ((g) << 8) | (b)))
//#define	RGB_MAKE(r, g, b) 	((COLOR) (((r) << 16) | ((g) << 8) | (b)))
#define RGBA_MAKE(r, g, b, a) 	((COLOR) (((a) << 24) | ((b) << 16) | ((g) << 8) | (r)))
#define	RGB_MAKE(r, g, b) 	((COLOR) (((b) << 16) | ((g) << 8) | (r)))
// COLOR is packed bgra, but converted to rgba for OpenGL
#define RGBA_GETALPHA(rgb) 	((rgb) >> 24)
//#define RGBA_GETRED(rgb) 	(((rgb) >> 16) & 0xff)
#define RGBA_GETRED(rgb) 	((rgb) & 0xff)
#define RGBA_GETGREEN(rgb) 	(((rgb) >> 8) & 0xff)
//#define RGBA_GETBLUE(rgb) 	((rgb) & 0xff)
#define RGBA_GETBLUE(rgb) 	(((rgb) >> 16) & 0xff)

#define RENDERVAL(val) 		((float)val)

#define D3DCOLOR_XRGB(r, g, b) 	RGBA_MAKE(r, g, b, 255)

typedef struct tagPALETTEENTRY {
  BYTE peRed;
  BYTE peGreen;
  BYTE peBlue;
  BYTE peFlags;
} PALETTEENTRY;

/*
Pre-DX8 vertex formats
taken from http://www.mvps.org/directx/articles/definitions_for_dx7_vertex_types.htm
*/
typedef struct {
	union {
		float x;
		float dvX;
	};
	union {
		float y;
		float dvY;
	};
	union {
		float z;
		float dvZ;
	};
	union {
		COLOR color;
		COLOR dcColor;
	};
	union {
		float tu;
		float dvTU;
	};
	union {
		float tv;
		float dvTV;
	};
} LVERTEX, *LPLVERTEX;

typedef struct {
	union {
		float x;
		float sx;
		float dvSX;
	};
	union {
		float y;
		float sy;
		float dvSY;
	};
	union {
		float z;
		float sz;
		float dvSZ;
	};
	union {
		float w;
		float rhw;
		float dvRHW;
	};
	union {
		COLOR color;
		COLOR dcColor;
	};
	union {
		float tu;
		float dvTU;
	};
	union {
		float tv;
		float dvTV;
	};
} TLVERTEX, *LPTLVERTEX;

typedef struct {
	union {
		WORD v1;
		WORD wV1;
	};
	union {
		WORD v2;
		WORD wV2;
	};
	union {
		WORD v3;
		WORD wV3;
	};
	// WORD wFlags;
} TRIANGLE, *LPTRIANGLE;

/*===================================================================
2D Vertices
===================================================================*/

typedef struct VERT2D {
	float	x;
	float	y;
} VERT2D;

typedef struct tagPOINT {
	LONG x;
	LONG y;
} POINT;
/*===================================================================
3D Vertices
===================================================================*/

typedef struct VERT {
	float	x;
	float	y;
	float	z;
	VERT(float nx, float ny, float nz) {x=nx; y=ny; z=nz;}
	VERT() {x=y=z=0.0f;}
} VERT, D3DXVECTOR3, *LPD3DXVECTOR3;

/*===================================================================
3D Normal
===================================================================*/
typedef struct NORMAL {
	union { float nx; float x; };
	union { float ny; float y; };
	union { float nz; float z; };
} NORMAL;

/*===================================================================
4 X 4 Matrix
===================================================================*/

typedef struct MATRIX {
	float	_11, _12, _13, _14;
	float	_21, _22, _23, _24;
	float	_31, _32, _33, _34;
	float	_41, _42, _43, _44;
} MATRIX;

/*===================================================================
3 X 3 Matrix
===================================================================*/

typedef struct MATRIX3X3 {
	float	_11, _12, _13;
	float	_21, _22, _23;
	float	_31, _32, _33;
} MATRIX3X3;

/*===================================================================
Vector
===================================================================*/

typedef struct VECTOR {
	float	x;
	float	y;
	float	z;
} VECTOR;

/*===================================================================
Short Vector
===================================================================*/

typedef struct SHORTVECTOR {
	int16_t	x;
	int16_t	y;
	int16_t	z;
} SHORTVECTOR;

/*===================================================================
Plane
===================================================================*/
typedef struct PLANE {
	VECTOR Normal;
	float Offset;
} PLANE;

static int NP2(int a)
{
  int j = 1;
  while (j<a) j=j*2;
  return j;
}

// Textures
class IDirect3DTexture9 {
 protected:
  GLuint texID;
  int w, h;	// real size
  int w2, h2;	// pow2 size
 public:
  float wf, hf;	// ratio...
  IDirect3DTexture9() {texID = 0; w=h=w2=h2=0; wf=hf=1.0f;}
  ~IDirect3DTexture9() {if (texID) glDeleteTextures(1, &texID);}
  void LoadTexture(const char* name);
  void Bind() {glBindTexture(GL_TEXTURE_2D, texID);}
  void UnBind() {glBindTexture(GL_TEXTURE_2D, 0);}
};

typedef struct IDirect3DTexture9 *LPDIRECT3DTEXTURE9, *PDIRECT3DTEXTURE9;
/*============================================================


  SOUND related functions....

===============================================================*/


//
// Generic Functions
//
bool sound_init( void );
void sound_destroy( void );
//
// Listener
//
bool sound_listener_position( float x, float y, float z );
bool sound_listener_velocity( float x, float y, float z );
bool sound_listener_orientation(
	float fx, float fy, float fz, // forward vector
	float ux, float uy, float uz // up vector
);

typedef struct sound_source_t sound_source_t;
typedef struct sound_buffer_t sound_buffer_t;

typedef wchar_t WCHAR;
typedef unsigned int HRESULT;
typedef DWORD* LPDWORD;
typedef void* LPVOID;

typedef sound_source_t sound_source_t;

class IDirectSoundBuffer8 {
 public:
  sound_source_t* source;
  sound_buffer_t* buffer;
  IDirectSoundBuffer8();
  ~IDirectSoundBuffer8();

  HRESULT SetVolume(LONG lVolume);
  HRESULT Play(DWORD dwReserved1, DWORD dwPriority, DWORD dwFlags);
  HRESULT SetFrequency(DWORD dwFrequency);
  HRESULT SetCurrentPosition(DWORD dwNewPosition);
  HRESULT GetCurrentPosition(LPDWORD pdwCurrentPlayCursor, LPDWORD pdwCurrentWriteCursor);
  HRESULT Stop();
  HRESULT SetPan(LONG lPan);
  HRESULT Release();
  HRESULT Lock(DWORD dwOffset, DWORD dwBytes, LPVOID * ppvAudioPtr1, LPDWORD  pdwAudioBytes1, LPVOID * ppvAudioPtr2, LPDWORD pdwAudioBytes2, DWORD dwFlags);
  HRESULT Unlock(LPVOID pvAudioPtr1, DWORD dwAudioBytes1, LPVOID pvAudioPtr2, DWORD dwAudioBytes2);
};

typedef IDirectSoundBuffer8* LPDIRECTSOUNDBUFFER8;
#define LPDIRECTSOUNDBUFFER LPDIRECTSOUNDBUFFER8

typedef struct {
 WORD wFormatTag;	/* format type */
 WORD nChannels;	/* number of channels */
 DWORD nSamplesPerSec;	/* sample rate */
 DWORD nAvgBytesPerSec;	/* for buffer estimation */
 WORD nBlockAlign; 	/* block size of data */
} WAVEFORMAT, *LPWAVEFORMAT;

#define WAVE_FORMAT_PCM 1

typedef struct {
 WAVEFORMAT wf;
 WORD wBitsPerSample;
} PCMWAVEFORMAT, *LPPCMWAVEFORMAT;

typedef struct {
 WORD wFormatTag;	/* format type */
 WORD nChannels;	/* number of channels (i.e. mono, stereo...) */
 DWORD nSamplesPerSec;	/* sample rate */
 DWORD nAvgBytesPerSec;	/* for buffer estimation */
 WORD nBlockAlign;	/* block size of data */
 WORD wBitsPerSample;	/* number of bits per sample of mono data */
 WORD cbSize;		/* the count in bytes of the size of */
			/* extra information (after cbSize) */
} WAVEFORMATEX,*LPWAVEFORMATEX;

typedef struct {
 uint32_t f1;
 uint16_t f2;
 uint16_t f3;
 uint8_t f4[8];
} GUID;
typedef const GUID* LPCGUID;

typedef void* LPUNKNOWN;

typedef uint32_t HWND;

typedef struct DSBUFFERDESC {
    DWORD dwSize;
    DWORD dwFlags;
    DWORD dwBufferBytes;
    DWORD dwReserved;
    LPWAVEFORMATEX lpwfxFormat;
    GUID guid3DAlgorithm;
} DSBUFFERDESC, *LPDSBUFFERDESC, *const LPCDSBUFFERDESC;

class IDirectSound8 {
 public:
  IDirectSound8() {};
  ~IDirectSound8() {};
  HRESULT SetCooperativeLevel(HWND hwnd, DWORD dwFlags) {return DS_OK;};
  HRESULT Release() {return DS_OK;};
  HRESULT CreateSoundBuffer(LPCDSBUFFERDESC pcDSBufferDesc, LPDIRECTSOUNDBUFFER * ppDSBuffer, LPUNKNOWN pUnkOuter);
};
typedef IDirectSound8* LPDIRECTSOUND8;

HRESULT DirectSoundCreate8(LPCGUID lpcGuidDevice, LPDIRECTSOUND8 * ppDS8, LPUNKNOWN pUnkOuter);

/*============================================================


  UTILITY functions....

===============================================================*/

#define MB_OK 1

#define MessageBox(a, text, type, button) printf("%ls: %ls\n", text, type)

#define UINT uint32_t

#define DXUTGetHWND() 0

/*=============================================================
 * 
 * Matrix functions
 * 
===============================================================*/
#ifdef USEGLM
#define D3DXMATRIX glm::mat4
#else
typedef struct _D3DXMATRIX {
 float  m[16];
} D3DXMATRIX;
#endif

D3DXMATRIX* D3DXMatrixPerspectiveFovLH(D3DXMATRIX *pOut, FLOAT fovy, FLOAT Aspect, FLOAT zn, FLOAT zf);
D3DXMATRIX* D3DXMatrixIdentity(D3DXMATRIX* pOut);
D3DXMATRIX* D3DXMatrixRotationX(D3DXMATRIX* pOut, FLOAT Angle);
D3DXMATRIX* D3DXMatrixRotationY(D3DXMATRIX* pOut, FLOAT Angle);
D3DXMATRIX* D3DXMatrixRotationZ(D3DXMATRIX* pOut, FLOAT Angle);
D3DXMATRIX* D3DXMatrixTranslation(D3DXMATRIX* pOut, FLOAT x, FLOAT y, FLOAT z);
D3DXMATRIX* D3DXMatrixScaling(D3DXMATRIX *pOut, FLOAT sx, FLOAT sy, FLOAT sz);

D3DXMATRIX* D3DXMatrixMultiply(D3DXMATRIX* pOut, const D3DXMATRIX* pM1, const D3DXMATRIX* pM2);
D3DXMATRIX* D3DXMatrixLookAtLH(D3DXMATRIX* pOut, const D3DXVECTOR3* pEye, const D3DXVECTOR3* pAt, const D3DXVECTOR3* pUp);
/*=============================================================
 * 
 * IDirect3DDevice9
 * 
===============================================================*/
typedef enum D3DTRANSFORMSTATETYPE { 
  D3DTS_VIEW         = 2,
  D3DTS_PROJECTION   = 3,
  D3DTS_WORLD        = 4,
  D3DTS_TEXTURE0     = 16,
  D3DTS_TEXTURE1     = 17,
  D3DTS_TEXTURE2     = 18,
  D3DTS_TEXTURE3     = 19,
  D3DTS_TEXTURE4     = 20,
  D3DTS_TEXTURE5     = 21,
  D3DTS_TEXTURE6     = 22,
  D3DTS_TEXTURE7     = 23,
  D3DTS_FORCE_DWORD  = 0x7fffffff
} D3DTRANSFORMSTATETYPE, *LPD3DTRANSFORMSTATETYPE;

typedef enum D3DRENDERSTATETYPE { 
  D3DRS_ZENABLE                     = 7,
  D3DRS_FILLMODE                    = 8,
  D3DRS_SHADEMODE                   = 9,
  D3DRS_ZWRITEENABLE                = 14,
  D3DRS_ALPHATESTENABLE             = 15,
  D3DRS_LASTPIXEL                   = 16,
  D3DRS_SRCBLEND                    = 19,
  D3DRS_DESTBLEND                   = 20,
  D3DRS_CULLMODE                    = 22,
  D3DRS_ZFUNC                       = 23,
  D3DRS_ALPHAREF                    = 24,
  D3DRS_ALPHAFUNC                   = 25,
  D3DRS_DITHERENABLE                = 26,
  D3DRS_ALPHABLENDENABLE            = 27,
  D3DRS_FOGENABLE                   = 28,
  D3DRS_SPECULARENABLE              = 29,
  D3DRS_FOGCOLOR                    = 34,
  D3DRS_FOGTABLEMODE                = 35,
  D3DRS_FOGSTART                    = 36,
  D3DRS_FOGEND                      = 37,
  D3DRS_FOGDENSITY                  = 38,
  D3DRS_RANGEFOGENABLE              = 48,
  D3DRS_STENCILENABLE               = 52,
  D3DRS_STENCILFAIL                 = 53,
  D3DRS_STENCILZFAIL                = 54,
  D3DRS_STENCILPASS                 = 55,
  D3DRS_STENCILFUNC                 = 56,
  D3DRS_STENCILREF                  = 57,
  D3DRS_STENCILMASK                 = 58,
  D3DRS_STENCILWRITEMASK            = 59,
  D3DRS_TEXTUREFACTOR               = 60,
  D3DRS_WRAP0                       = 128,
  D3DRS_WRAP1                       = 129,
  D3DRS_WRAP2                       = 130,
  D3DRS_WRAP3                       = 131,
  D3DRS_WRAP4                       = 132,
  D3DRS_WRAP5                       = 133,
  D3DRS_WRAP6                       = 134,
  D3DRS_WRAP7                       = 135,
  D3DRS_CLIPPING                    = 136,
  D3DRS_LIGHTING                    = 137,
  D3DRS_AMBIENT                     = 139,
  D3DRS_FOGVERTEXMODE               = 140,
  D3DRS_COLORVERTEX                 = 141,
  D3DRS_LOCALVIEWER                 = 142,
  D3DRS_NORMALIZENORMALS            = 143,
  D3DRS_DIFFUSEMATERIALSOURCE       = 145,
  D3DRS_SPECULARMATERIALSOURCE      = 146,
  D3DRS_AMBIENTMATERIALSOURCE       = 147,
  D3DRS_EMISSIVEMATERIALSOURCE      = 148,
  D3DRS_VERTEXBLEND                 = 151,
  D3DRS_CLIPPLANEENABLE             = 152,
  D3DRS_POINTSIZE                   = 154,
  D3DRS_POINTSIZE_MIN               = 155,
  D3DRS_POINTSPRITEENABLE           = 156,
  D3DRS_POINTSCALEENABLE            = 157,
  D3DRS_POINTSCALE_A                = 158,
  D3DRS_POINTSCALE_B                = 159,
  D3DRS_POINTSCALE_C                = 160,
  D3DRS_MULTISAMPLEANTIALIAS        = 161,
  D3DRS_MULTISAMPLEMASK             = 162,
  D3DRS_PATCHEDGESTYLE              = 163,
  D3DRS_DEBUGMONITORTOKEN           = 165,
  D3DRS_POINTSIZE_MAX               = 166,
  D3DRS_INDEXEDVERTEXBLENDENABLE    = 167,
  D3DRS_COLORWRITEENABLE            = 168,
  D3DRS_TWEENFACTOR                 = 170,
  D3DRS_BLENDOP                     = 171,
  D3DRS_POSITIONDEGREE              = 172,
  D3DRS_NORMALDEGREE                = 173,
  D3DRS_SCISSORTESTENABLE           = 174,
  D3DRS_SLOPESCALEDEPTHBIAS         = 175,
  D3DRS_ANTIALIASEDLINEENABLE       = 176,
  D3DRS_MINTESSELLATIONLEVEL        = 178,
  D3DRS_MAXTESSELLATIONLEVEL        = 179,
  D3DRS_ADAPTIVETESS_X              = 180,
  D3DRS_ADAPTIVETESS_Y              = 181,
  D3DRS_ADAPTIVETESS_Z              = 182,
  D3DRS_ADAPTIVETESS_W              = 183,
  D3DRS_ENABLEADAPTIVETESSELLATION  = 184,
  D3DRS_TWOSIDEDSTENCILMODE         = 185,
  D3DRS_CCW_STENCILFAIL             = 186,
  D3DRS_CCW_STENCILZFAIL            = 187,
  D3DRS_CCW_STENCILPASS             = 188,
  D3DRS_CCW_STENCILFUNC             = 189,
  D3DRS_COLORWRITEENABLE1           = 190,
  D3DRS_COLORWRITEENABLE2           = 191,
  D3DRS_COLORWRITEENABLE3           = 192,
  D3DRS_BLENDFACTOR                 = 193,
  D3DRS_SRGBWRITEENABLE             = 194,
  D3DRS_DEPTHBIAS                   = 195,
  D3DRS_WRAP8                       = 198,
  D3DRS_WRAP9                       = 199,
  D3DRS_WRAP10                      = 200,
  D3DRS_WRAP11                      = 201,
  D3DRS_WRAP12                      = 202,
  D3DRS_WRAP13                      = 203,
  D3DRS_WRAP14                      = 204,
  D3DRS_WRAP15                      = 205,
  D3DRS_SEPARATEALPHABLENDENABLE    = 206,
  D3DRS_SRCBLENDALPHA               = 207,
  D3DRS_DESTBLENDALPHA              = 208,
  D3DRS_BLENDOPALPHA                = 209,
  D3DRS_FORCE_DWORD                 = 0x7fffffff
} D3DRENDERSTATETYPE, *LPD3DRENDERSTATETYPE;

typedef enum D3DCULL { 
  D3DCULL_NONE         = 1,
  D3DCULL_CW           = 2,
  D3DCULL_CCW          = 3,
  D3DCULL_FORCE_DWORD  = 0x7fffffff
} D3DCULL, *LPD3DCULL;

typedef enum D3DPRIMITIVETYPE { 
  D3DPT_POINTLIST      = 1,
  D3DPT_LINELIST       = 2,
  D3DPT_LINESTRIP      = 3,
  D3DPT_TRIANGLELIST   = 4,
  D3DPT_TRIANGLESTRIP  = 5,
  D3DPT_TRIANGLEFAN    = 6,
  D3DPT_FORCE_DWORD    = 0x7fffffff
} D3DPRIMITIVETYPE, *LPD3DPRIMITIVETYPE;

typedef enum D3DTEXTURESTAGESTATETYPE { 
  D3DTSS_COLOROP                = 1,
  D3DTSS_COLORARG1              = 2,
  D3DTSS_COLORARG2              = 3,
  D3DTSS_ALPHAOP                = 4,
  D3DTSS_ALPHAARG1              = 5,
  D3DTSS_ALPHAARG2              = 6,
  D3DTSS_BUMPENVMAT00           = 7,
  D3DTSS_BUMPENVMAT01           = 8,
  D3DTSS_BUMPENVMAT10           = 9,
  D3DTSS_BUMPENVMAT11           = 10,
  D3DTSS_TEXCOORDINDEX          = 11,
  D3DTSS_BUMPENVLSCALE          = 22,
  D3DTSS_BUMPENVLOFFSET         = 23,
  D3DTSS_TEXTURETRANSFORMFLAGS  = 24,
  D3DTSS_COLORARG0              = 26,
  D3DTSS_ALPHAARG0              = 27,
  D3DTSS_RESULTARG              = 28,
  D3DTSS_CONSTANT               = 32,
  D3DTSS_FORCE_DWORD            = 0x7fffffff
} D3DTEXTURESTAGESTATETYPE, *LPD3DTEXTURESTAGESTATETYPE;

typedef enum D3DTEXTUREOP { 
  D3DTOP_DISABLE                    = 1,
  D3DTOP_SELECTARG1                 = 2,
  D3DTOP_SELECTARG2                 = 3,
  D3DTOP_MODULATE                   = 4,
  D3DTOP_MODULATE2X                 = 5,
  D3DTOP_MODULATE4X                 = 6,
  D3DTOP_ADD                        = 7,
  D3DTOP_ADDSIGNED                  = 8,
  D3DTOP_ADDSIGNED2X                = 9,
  D3DTOP_SUBTRACT                   = 10,
  D3DTOP_ADDSMOOTH                  = 11,
  D3DTOP_BLENDDIFFUSEALPHA          = 12,
  D3DTOP_BLENDTEXTUREALPHA          = 13,
  D3DTOP_BLENDFACTORALPHA           = 14,
  D3DTOP_BLENDTEXTUREALPHAPM        = 15,
  D3DTOP_BLENDCURRENTALPHA          = 16,
  D3DTOP_PREMODULATE                = 17,
  D3DTOP_MODULATEALPHA_ADDCOLOR     = 18,
  D3DTOP_MODULATECOLOR_ADDALPHA     = 19,
  D3DTOP_MODULATEINVALPHA_ADDCOLOR  = 20,
  D3DTOP_MODULATEINVCOLOR_ADDALPHA  = 21,
  D3DTOP_BUMPENVMAP                 = 22,
  D3DTOP_BUMPENVMAPLUMINANCE        = 23,
  D3DTOP_DOTPRODUCT3                = 24,
  D3DTOP_MULTIPLYADD                = 25,
  D3DTOP_LERP                       = 26,
  D3DTOP_FORCE_DWORD                = 0x7fffffff
} D3DTEXTUREOP, *LPD3DTEXTUREOP;

typedef enum D3DBLEND { 
  D3DBLEND_ZERO             = 1,
  D3DBLEND_ONE              = 2,
  D3DBLEND_SRCCOLOR         = 3,
  D3DBLEND_INVSRCCOLOR      = 4,
  D3DBLEND_SRCALPHA         = 5,
  D3DBLEND_INVSRCALPHA      = 6,
  D3DBLEND_DESTALPHA        = 7,
  D3DBLEND_INVDESTALPHA     = 8,
  D3DBLEND_DESTCOLOR        = 9,
  D3DBLEND_INVDESTCOLOR     = 10,
  D3DBLEND_SRCALPHASAT      = 11,
  D3DBLEND_BOTHSRCALPHA     = 12,
  D3DBLEND_BOTHINVSRCALPHA  = 13,
  D3DBLEND_BLENDFACTOR      = 14,
  D3DBLEND_INVBLENDFACTOR   = 15,
  D3DBLEND_SRCCOLOR2        = 16,
  D3DBLEND_INVSRCCOLOR2     = 17,
  D3DBLEND_FORCE_DWORD      = 0x7fffffff
} D3DBLEND, *LPD3DBLEND;


typedef struct D3DSURFACE_DESC {
//  D3DFORMAT           Format;
//  D3DRESOURCETYPE     Type;
//  DWORD               Usage;
//  D3DPOOL             Pool;
//  D3DMULTISAMPLE_TYPE MultiSampleType;
//  DWORD               MultiSampleQuality;
  UINT                Width;
  UINT                Height;
} D3DSURFACE_DESC, *LPD3DSURFACE_DESC;

typedef struct D3DXCOLOR {
  FLOAT r;
  FLOAT g;
  FLOAT b;
  FLOAT a;
  D3DXCOLOR(float a_r, float a_g, float a_b, float a_a) : r(a_r), g(a_g), b(a_b), a(a_a) {};
} D3DXCOLOR, *LPD3DXCOLOR;

typedef DWORD D3DCOLOR;

typedef struct D3DRECT {
  LONG x1;
  LONG y1;
  LONG x2;
  LONG y2;
} D3DRECT;

#define D3DTA_TEXTURE 				1
#define D3DTA_CURRENT				2
#define D3DTA_DIFFUSE				3

#define D3DCLEAR_STENCIL  1
#define D3DCLEAR_TARGET   2
#define D3DCLEAR_ZBUFFER  4

#define D3DUSAGE_WRITEONLY 1

#define D3DFVF_DIFFUSE    (1   )
#define D3DFVF_NORMAL     (1<<1)
#define D3DFVF_XYZ        (1<<2)
#define D3DFVF_XYZRHW     (1<<3)
#define D3DFVF_XYZW       (1<<4)
#define D3DFVF_TEX0       (1<<5)
#define D3DFVF_TEX1       (1<<6)


typedef enum D3DPOOL { 
  D3DPOOL_DEFAULT      = 0,
  D3DPOOL_MANAGED      = 1,
  D3DPOOL_SYSTEMMEM    = 2,
  D3DPOOL_SCRATCH      = 3,
  D3DPOOL_FORCE_DWORD  = 0x7fffffff
} D3DPOOL, *LPD3DPOOL;

struct UTVERTEX
{
    D3DXVECTOR3 pos;	// The untransformed position for the vertex
    DWORD color;		// The vertex diffuse color value
	  FLOAT tu,tv;		// The texture co-ordinates
};
// UTBuffer, used for IDirect3DVertexBuffer9 limited simulation (there are better way of courss to do that)
struct UTBuffer {
	void*	    buffer;
  uint32_t  fvf;
  uint32_t  size; // estimated size of the array
};

typedef void* HANDLE;

class IDirect3DVertexBuffer9
{
public:
  IDirect3DVertexBuffer9(uint32_t capacity, uint32_t fvf);
  ~IDirect3DVertexBuffer9();
  HRESULT Release();
  HRESULT Lock(UINT OffsetToLock, UINT SizeToLock, void **ppbData,DWORD Flags);
  HRESULT Unlock();

  UTBuffer buffer;
};

class IDirect3DDevice9
{
public:
	IDirect3DDevice9();
	~IDirect3DDevice9();
	HRESULT SetTransform(D3DTRANSFORMSTATETYPE State, D3DXMATRIX *pMatrix);
  HRESULT GetTransform(D3DTRANSFORMSTATETYPE State, D3DXMATRIX *pMatrix);
	HRESULT SetRenderState(D3DRENDERSTATETYPE State, int Value);
	HRESULT DrawPrimitive(D3DPRIMITIVETYPE PrimitiveType,UINT StartVertex,UINT PrimitiveCount);
	HRESULT SetTextureStageState(DWORD Stage, D3DTEXTURESTAGESTATETYPE Type, DWORD Value);
	HRESULT SetTexture(DWORD Sampler, IDirect3DTexture9 *pTexture);
  HRESULT Clear(DWORD Count, const D3DRECT *pRects,DWORD Flags, D3DCOLOR Color, float Z, DWORD Stencil);
  HRESULT BeginScene() {return S_OK;};
  HRESULT EndScene() {return S_OK;};
  HRESULT CreateVertexBuffer(UINT Length, DWORD Usage, DWORD FVF, D3DPOOL Pool, IDirect3DVertexBuffer9 **ppVertexBuffer, HANDLE *pSharedHandle);
  HRESULT SetStreamSource(UINT StreamNumber, IDirect3DVertexBuffer9 *pStreamData, UINT OffsetInBytes, UINT Stride);
  HRESULT SetFVF(DWORD FVF);

	// not DX9 function, but easier here
  void ActivateWorldMatrix();
  void DeactivateWorldMatrix();
private:
	UINT colorop[8];
	UINT alphaop[8];
	UINT colorarg1[8];
	UINT colorarg2[8];
  D3DXMATRIX mWorld, mView, mProj, mText, mInv;
  IDirect3DVertexBuffer9 *buffer[8];
  uint32_t  offset[8];
  uint32_t  stride[8];
  DWORD     fvf;
};

class CDXUTTextHelper
{
public:
	CDXUTTextHelper(TTF_Font* font, GLuint sprite, int size);
	~CDXUTTextHelper();
  void SetInsertionPos(int x, int y);
  void DrawTextLine(const wchar_t* line);
  void DrawFormattedTextLine(const wchar_t* line, ...);
  void Begin() {};
  void End() {};
  void SetForegroundColor(D3DXCOLOR clr);
private:
	GLuint 		  m_sprite;
	int 		    m_size;
  int         m_fontsize;
  int         m_posx, m_posy;
  float       m_inv;
  int         m_as[256];
  float       m_forecol[4];
  GLuint      m_texture;
  int         m_sizew, m_sizeh;
};

IDirect3DDevice9 *DXUTGetD3DDevice();

const D3DSURFACE_DESC * DXUTGetBackBufferSurfaceDesc();

DOUBLE DXUTGetTime();

#define StringCchPrintf swprintf
// V macro should test the result...
#define V(a) a
#define SUCCEEDED(a) a == S_OK
#define FAILED(a) a != S_OK

void DXUTReset3DEnvironment();

#define mmioFOURCC(ch0, ch1, ch2, ch3) \
    MAKEFOURCC(ch0, ch1, ch2, ch3)
#define MAKEFOURCC(ch0, ch1, ch2, ch3)  \
    ((DWORD)(BYTE)(ch0) | ((DWORD)(BYTE)(ch1) << 8) |  \
    ((DWORD)(BYTE)(ch2) << 16) | ((DWORD)(BYTE)(ch3) << 24 ))

#define ZeroMemory(a, b) memset(a, 0, b)
#define CopyMemory(a, b, c) memcpy(a, b, c)

#endif //_DX_LINUX_H_