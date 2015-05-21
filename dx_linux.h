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

typedef int32_t LONG;
typedef float FLOAT;
#define TRUE true
#define FALSE false

#define S_OK	0x00000000
#define E_ABORT	0x80004004
#define E_FAIL	0x80004005

// taken from d3d9.h
typedef DWORD COLOR; // bgra

// bjd - taken from d3dtypes.h
#define RGBA_MAKE(r, g, b, a) ((COLOR) (((a) << 24) | ((r) << 16) | ((g) << 8) | (b)))
#define	RGB_MAKE(r, g, b) ((COLOR) (((r) << 16) | ((g) << 8) | (b)))
// COLOR is packed bgra
#define RGBA_GETALPHA(rgb) ((rgb) >> 24)
#define RGBA_GETRED(rgb) (((rgb) >> 16) & 0xff)
#define RGBA_GETGREEN(rgb) (((rgb) >> 8) & 0xff)
#define RGBA_GETBLUE(rgb) ((rgb) & 0xff)
#define RENDERVAL(val) ((float)val)

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

#define DSBPLAY_LOOPING  1

class IDirectSoundBuffer8 {
 public:
  sound_source_t source;
  IDirectSoundBuffer8() {};

  HRESULT SetVolume(LONG lVolume) {sound_volume(&source, lVolume); return 0;}
  HRESULT Play(DWORD dwReserved1, DWORD dwPriority, DWORD dwFlags) {if (dwFlags&DSBPLAY_LOOPING) sound_play_looping(&source); else sound_play(&source); return 0;}
  HRESULT SetFrequency(DWORD dwFrequency) {sound_set_pitch(&source, dwFrequency); return 0;}
  HRESULT SetCurrentPosition(DWORD dwNewPosition) {sound_set_pitch(&source, dwNewPosition); return 0;}
  HRESULT GetCurrentPosition(LPDWORD pdwCurrentPlayCursor, LPDWORD pdwCurrentWriteCursor) 
  {
	if (pdwCurrentPlayCursor)
		*pdwCurrentPlayCursor = sound_get_position(&source);
	return 0;
  }
  HRESULT Stop() {sound_stop(&source); return 0;}
};


/*============================================================


  UTILITY functions....

===============================================================*/

#define MB_OK 1

#define MessageBox(a, text, type, button) printf("%ls: %ls\n", text, type)

#endif //_DX_LINUX_H_
