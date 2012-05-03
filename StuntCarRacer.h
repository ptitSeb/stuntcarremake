
#ifndef	_STUNT_CAR_RACER
#define	_STUNT_CAR_RACER

/*	========= */
/*	Constants */
/*	========= */
#define SCR_BASE_COLOUR	26

typedef enum
	{
	TRACK_MENU = 0,
	TRACK_PREVIEW,
	GAME_IN_PROGRESS,
	GAME_OVER
	} GameModeType;

/*
// Untransformed coloured vertex
#define D3DFVF_UTVERTEX (D3DFVF_XYZ|D3DFVF_NORMAL|D3DFVF_DIFFUSE)
*/
// Untransformed coloured textured vertex
#define D3DFVF_UTVERTEX (D3DFVF_XYZ|D3DFVF_DIFFUSE|D3DFVF_TEX1)

/*	===================== */
/*	Structure definitions */
/*	===================== */
/*
// Untransformed coloured vertex
struct UTVERTEX
{
    D3DXVECTOR3 pos;	// The untransformed position for the vertex
	D3DXVECTOR3 normal;	// The surface normal for the vertex
    DWORD color;		// The vertex diffuse color value
};
*/
// Untransformed coloured textured vertex
struct UTVERTEX
{
    D3DXVECTOR3 pos;	// The untransformed position for the vertex
    DWORD color;		// The vertex diffuse color value
	FLOAT tu,tv;		// The texture co-ordinates
};

/*	============================== */
/*	External function declarations */
/*	============================== */
extern void GetScreenDimensions( long *screen_width,
								 long *screen_height );

extern DWORD SCRGB (long colour_index);
extern DWORD SCColour (long colour_index);

extern void SetSolidColour (long colour_index);
extern void SetLineColour (long colour_index);
extern void SetTextureColour (long colour_index);

// Debug
extern long VALUE1, VALUE2, VALUE3;

#endif	/* _STUNT_CAR_RACER */
