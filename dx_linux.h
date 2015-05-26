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
#include <SDL/SDL.h>
#include <AL/al.h>

#ifdef HAVE_GLES
#define glColor4ubv(a) glColor4ub((a)[0], (a)[1], (a)[2], (a)[3])
#define gluOrtho2D(a, b, c, d) glOrthof(a, b, c, d, -1, 1)
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
#define TRUE true
#define FALSE false

#define S_OK	0x00000000
#define E_ABORT	0x80004004
#define E_FAIL	0x80004005

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
typedef DWORD COLOR; // bgra

// bjd - taken from d3dtypes.h
#define RGBA_MAKE(r, g, b, a) 	((COLOR) (((a) << 24) | ((r) << 16) | ((g) << 8) | (b)))
#define	RGB_MAKE(r, g, b) 	((COLOR) (((r) << 16) | ((g) << 8) | (b)))
// COLOR is packed bgra
#define RGBA_GETALPHA(rgb) 	((rgb) >> 24)
#define RGBA_GETRED(rgb) 	(((rgb) >> 16) & 0xff)
#define RGBA_GETGREEN(rgb) 	(((rgb) >> 8) & 0xff)
#define RGBA_GETBLUE(rgb) 	((rgb) & 0xff)
#define RENDERVAL(val) 		((float)val)

#define D3DCOLOR_XRGB(r, g, b) 	RGB_MAKE(r, g, b)

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

// Textures
class IDirect3DTexture9 {
 protected:
  GLuint texID;
 public:
  IDirect3DTexture9() {texID = 0;}
  ~IDirect3DTexture9() {if (texID) glDeleteTextures(1, &texID);}
};

typedef struct IDirect3DTexture9 *LPDIRECT3DTEXTURE9, *PDIRECT3DTEXTURE9;
/*============================================================


  SOUND related functions....

===============================================================*/


// this will eventually be removed but is required right now
bool Sound3D;
// the game appears to need this probably wont in openAL
int sound_minimum_volume;
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

typedef sound_source_t sound_source_t;

class IDirectSoundBuffer8 {
 public:
  sound_source_t* source;
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
};

typedef IDirectSoundBuffer8* LPDIRECTSOUNDBUFFER8;

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
} DSBUFFERDESC;

class IDirectSound8 {
 public:
  IDirectSound8();
  ~IDirectSound8();
  HRESULT SetCooperativeLevel(HWND hwnd, DWORD dwFlags);
  HRESULT Release();
};
typedef IDirectSound8* LPDIRECTSOUND8;

HRESULT DirectSoundCreate8(
         LPCGUID lpcGuidDevice,
         LPDIRECTSOUND8 * ppDS8,
         LPUNKNOWN pUnkOuter
);

/*============================================================


  UTILITY functions....

===============================================================*/

#define MB_OK 1

#define MessageBox(a, text, type, button) printf("%ls: %ls\n", text, type)

#define UINT uint32_t

#define DXUTGetHWND() 0

#endif //_DX_LINUX_H_
