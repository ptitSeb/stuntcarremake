//--------------------------------------------------------------------------------------
// File: StuntCarRacer.cpp
//
// NOTE: This project builds with Microsoft Visual C++ 2008 Express Edition and requires
// Microsoft DirectX SDK (April 2007).  It is based on examples from that DirectX SDK.
//
// Copyright (c) Microsoft Corporation. All rights reserved.
//--------------------------------------------------------------------------------------

#include "dxstdafx.h"

#include "resource.h"

#include "StuntCarRacer.h"
#include "3D_Engine.h"
#include "Backdrop.h"
#include "Track.h"
#include "Car.h"
#include "Car_Behaviour.h"
#include "Opponent_Behaviour.h"
#include "wavefunctions.h"
#include "Atlas.h"

#ifdef linux
#define STRING "%S"
#else
#define STRING L"%s"
#endif


//-----------------------------------------------------------------------------
// Defines, constants, and global variables
//-----------------------------------------------------------------------------

#define DEFAULT_FRAME_GAP	(6)		// 4 Used to limit frame rate.  Amiga StuntCarRacer uses value of 6 (called MIN.FRAMES)

#define	HEIGHT_ABOVE_ROAD	(100)

#define	FURTHEST_Z (131072.0f)

GameModeType GameMode = TRACK_MENU;

// Both the following are used for keyboard input
UINT keyPress = '\0';
DWORD lastInput = 0;

static IDirectSound8 *ds;
IDirectSoundBuffer8 *WreckSoundBuffer = NULL;
IDirectSoundBuffer8 *HitCarSoundBuffer = NULL;
IDirectSoundBuffer8 *GroundedSoundBuffer = NULL;
IDirectSoundBuffer8 *CreakSoundBuffer = NULL;
IDirectSoundBuffer8 *SmashSoundBuffer = NULL;
IDirectSoundBuffer8 *OffRoadSoundBuffer = NULL;
IDirectSoundBuffer8 *EngineSoundBuffers[8] = {NULL};

IDirect3DTexture9 *g_pAtlas = NULL;

int wideScreen = 0;

static long frameGap = DEFAULT_FRAME_GAP;
static bool bFrameMoved = FALSE;

bool bShowStats = FALSE;
bool bNewGame = FALSE;
bool bPaused = FALSE;
bool bPlayerPaused = FALSE;
bool bOpponentPaused = FALSE;
long bTrackDrawMode = 0;
bool bOutsideView = FALSE;
long engineSoundPlaying = FALSE;
double gameStartTime, gameEndTime;
bool bSuperLeague = FALSE;

#if defined(DEBUG) || defined(_DEBUG)
FILE *out;
bool bTestKey = FALSE;
char OutputFile[] = "SCRlog.txt";
long VALUE1 = 1, VALUE2 = 2, VALUE3 = 3;
#endif

extern long TrackID;
extern long boostReserve, boostUnit, StandardBoost, SuperBoost;
extern long INITIALISE_PLAYER;
extern bool raceFinished, raceWon;
extern long lapNumber[];

// League / Super League variable
extern long damaged_limit;
extern long road_cushion_value;
extern long engine_power;
extern long boost_unit_value;
extern long opp_engine_power;

//-----------------------------------------------------------------------------
// Static variables
//-----------------------------------------------------------------------------
// Player 1 orientation
static long player1_x = 0,
			player1_y = 0,
			player1_z = 0;

static long player1_x_angle = (0<<6),
			player1_y_angle = (0<<6),
			player1_z_angle = (0<<6);

// Opponent orientation
static long opponent_x = 0,
			opponent_y = 0,
			opponent_z = 0;

static float opponent_x_angle = 0.0f, opponent_y_angle = 0.0f, opponent_z_angle = 0.0f;

// Viewpoint 1 orientation
static long viewpoint1_x, viewpoint1_y, viewpoint1_z;
static long viewpoint1_x_angle, viewpoint1_y_angle, viewpoint1_z_angle;

// Target (lookat) point
static long target_x, target_y, target_z;

/**************************************************************************
  DSInit

  Description:
    Initialize all the DirectSound specific stuff
 **************************************************************************/

bool DSInit()
	{
    HRESULT err;

	//
	//	First create a DirectSound object

	err = DirectSoundCreate8(NULL, &ds, NULL);

    if (err != DS_OK)
        return FALSE;

	//
	//	Now set the cooperation level

    err = ds->SetCooperativeLevel(DXUTGetHWND(), DSSCL_NORMAL );

    if (err != DS_OK)
        return FALSE;
	
	return TRUE;
	}

/**************************************************************************
  DSSetMode

	Initialises all DirectSound samples etc

 **************************************************************************/

bool DSSetMode()
	{
	int i;

	// Amiga channels 1 and 2 are right side, channels 0 and 3 are left side

	if ((WreckSoundBuffer = MakeSoundBuffer(ds, L"WRECK")) == NULL)
		return FALSE;
	WreckSoundBuffer->SetPan(DSBPAN_RIGHT);
	WreckSoundBuffer->SetVolume(AmigaVolumeToDirectX(64));

	if ((HitCarSoundBuffer = MakeSoundBuffer(ds, L"HITCAR")) == NULL)
		return FALSE;
	HitCarSoundBuffer->SetFrequency(AMIGA_PAL_HZ / 238);
	HitCarSoundBuffer->SetPan(DSBPAN_RIGHT);
	HitCarSoundBuffer->SetVolume(AmigaVolumeToDirectX(56));

	if ((GroundedSoundBuffer = MakeSoundBuffer(ds, L"GROUNDED")) == NULL)
		return FALSE;
	GroundedSoundBuffer->SetFrequency(AMIGA_PAL_HZ / 400);
	GroundedSoundBuffer->SetPan(DSBPAN_RIGHT);

	if ((CreakSoundBuffer = MakeSoundBuffer(ds, L"CREAK")) == NULL)
		return FALSE;
	CreakSoundBuffer->SetFrequency(AMIGA_PAL_HZ / 238);
	CreakSoundBuffer->SetPan(DSBPAN_RIGHT);
	CreakSoundBuffer->SetVolume(AmigaVolumeToDirectX(64));

	if ((SmashSoundBuffer = MakeSoundBuffer(ds, L"SMASH")) == NULL)
		return FALSE;
	SmashSoundBuffer->SetFrequency(AMIGA_PAL_HZ / 280);
	SmashSoundBuffer->SetPan(DSBPAN_LEFT);
	SmashSoundBuffer->SetVolume(AmigaVolumeToDirectX(64));

	if ((OffRoadSoundBuffer = MakeSoundBuffer(ds, L"OFFROAD")) == NULL)
		return FALSE;
	OffRoadSoundBuffer->SetPan(DSBPAN_RIGHT);
	OffRoadSoundBuffer->SetVolume(AmigaVolumeToDirectX(64));

	if ((EngineSoundBuffers[0] = MakeSoundBuffer(ds, L"TICKOVER")) == NULL)
		return FALSE;
	if ((EngineSoundBuffers[1] = MakeSoundBuffer(ds, L"ENGINEPITCH2")) == NULL)
		return FALSE;
	if ((EngineSoundBuffers[2] = MakeSoundBuffer(ds, L"ENGINEPITCH3")) == NULL)
		return FALSE;
	if ((EngineSoundBuffers[3] = MakeSoundBuffer(ds, L"ENGINEPITCH4")) == NULL)
		return FALSE;
	if ((EngineSoundBuffers[4] = MakeSoundBuffer(ds, L"ENGINEPITCH5")) == NULL)
		return FALSE;
	if ((EngineSoundBuffers[5] = MakeSoundBuffer(ds, L"ENGINEPITCH6")) == NULL)
		return FALSE;
	if ((EngineSoundBuffers[6] = MakeSoundBuffer(ds, L"ENGINEPITCH7")) == NULL)
		return FALSE;
	if ((EngineSoundBuffers[7] = MakeSoundBuffer(ds, L"ENGINEPITCH8")) == NULL)
		return FALSE;

	for (i = 0; i < 8; i++)
	{
		EngineSoundBuffers[i]->SetPan(DSBPAN_LEFT);
		// Original Amiga volume was 48, but have reduced this for testing
		EngineSoundBuffers[i]->SetVolume(AmigaVolumeToDirectX(48/2));
	}

	return TRUE;
	}

/**************************************************************************
  DSTerm
 **************************************************************************/

void DSTerm()
	{
    if (WreckSoundBuffer)		WreckSoundBuffer->Release(),	WreckSoundBuffer = NULL;
    if (HitCarSoundBuffer)		HitCarSoundBuffer->Release(),	HitCarSoundBuffer = NULL;
    if (GroundedSoundBuffer)	GroundedSoundBuffer->Release(),	GroundedSoundBuffer = NULL;
    if (CreakSoundBuffer)		CreakSoundBuffer->Release(),	CreakSoundBuffer = NULL;
    if (SmashSoundBuffer)		SmashSoundBuffer->Release(),	SmashSoundBuffer = NULL;
    if (OffRoadSoundBuffer)		OffRoadSoundBuffer->Release(),	OffRoadSoundBuffer = NULL;

	for (int i = 0; i < 8; i++)
	{
		if (EngineSoundBuffers[i]) EngineSoundBuffers[i]->Release(), EngineSoundBuffers[i] = NULL;
	}

    if (ds) ds->Release(), ds = NULL;
	}

/*	======================================================================================= */
/*	Function:		InitialiseData															*/
/*																							*/
/*	Description:																			*/
/*	======================================================================================= */

static long InitialiseData( void )
	{
	long success = FALSE;
#if defined(DEBUG) || defined(_DEBUG)
	errno_t err;

	if ((err = fopen_s( &out, OutputFile, "w" )) != 0)
		return FALSE;
#endif

	CreateSinCosTable();

	ConvertAmigaTrack(LITTLE_RAMP);

	// Seed the random-number generator with current time so that
	// the numbers will be different every time we run
	srand( (unsigned)time( NULL ) );

	success = TRUE;

	return(success);
	}

/*	======================================================================================= */
/*	Function:		FreeData																*/
/*																							*/
/*	Description:																			*/
/*	======================================================================================= */

static void FreeData( void )
	{
	FreeTrackData();
	DSTerm();
#if defined(DEBUG) || defined(_DEBUG)
	fclose( out );
#endif
//	CloseAmigaRecording();
	return;
	}

/*	======================================================================================= */
/*	Function:		GetScreenDimensions														*/
/*																							*/
/*	Description:	Provide screen width and height											*/
/*	======================================================================================= */

void GetScreenDimensions( long *screen_width,
						  long *screen_height )
	{
#ifdef linux
	/*const SDL_VideoInfo* info = SDL_GetVideoInfo();
	*screen_width = info->current_w;
	*screen_height = info->current_h; */
	*screen_width = (wideScreen)?800:640;
	*screen_height = 480;
#else
	const D3DSURFACE_DESC *desc;
	desc = DXUTGetBackBufferSurfaceDesc();

	*screen_width = desc->Width;
	*screen_height = desc->Height;
#endif
	}

//--------------------------------------------------------------------------------------
// Colours
//--------------------------------------------------------------------------------------

#define NUM_PALETTE_ENTRIES     (42+6)
//#define	PALETTE_COMPONENT_BITS	(8)		// bits per colour r/g/b component

static PALETTEENTRY SCPalette[NUM_PALETTE_ENTRIES] =
	{
		{0x00, 0x00, 0x00},
		{0x00, 0x00, 0x00},
		{0x00, 0x00, 0x00},
		{0x00, 0x00, 0x00},
		{0x00, 0x00, 0x00},
		{0x00, 0x00, 0x00},
		{0x00, 0x00, 0x00},
		{0x00, 0x00, 0x00},
		{0x00, 0x00, 0x00},
		{0x00, 0x00, 0x00},

		// car colours 1
		{0x00, 0x00, 0x00},
		{0x88, 0x00, 0x22},
		{0xaa, 0x00, 0x33},
		{0xcc, 0x00, 0x44},
		{0xee, 0x00, 0x55},
		{0x22, 0x22, 0x33},
		{0x44, 0x44, 0x44},
		{0x33, 0x33, 0x33},

		// car colours 2
		{0x00, 0x00, 0x00},
		{0x22, 0x00, 0x88},
		{0x33, 0x00, 0xaa},
		{0x44, 0x00, 0xcc},
		{0x55, 0x00, 0xee},
		{0x22, 0x22, 0x33},
		{0x44, 0x44, 0x44},
		{0x33, 0x33, 0x33},

		// track colours (i.e. Stunt Car Racer car colours)
		{0x00, 0x00, 0x00},
		{0x99, 0x99, 0x77},
		{0xbb, 0xbb, 0x99},
		{0xff, 0xff, 0x00},
		{0x99, 0xbb, 0x33},
		{0x55, 0x77, 0x77},
		{0x55, 0xbb, 0xff},
		{0x55, 0x99, 0xff},
		{0x33, 0x55, 0x77},
		{0x55, 0x00, 0x00}, // 9
		{0x77, 0x33, 0x33},	//10
		{0x99, 0x55, 0x55},
		{0xdd, 0x99, 0x99}, //12
		{0x77, 0x77, 0x55},
		{0xbb, 0xbb, 0xbb},
		{0xff, 0xff, 0xff},

		// extra track colours (altered super league)
		{ 51,   51,  119},	// SCR_BASE_COLOUR+16
		{119,  153,  119},
		{ 85,  153,   85},
		{0x00, 0x00, 0x55}, //19
		{0x33, 0x33, 0x77},	//20
		{0x99, 0x99, 0xdd}, //21
	};


DWORD SCRGB (long colour_index)		// return full RGB value
	{
	return(D3DCOLOR_XRGB(SCPalette[colour_index].peRed,
					SCPalette[colour_index].peGreen,
					SCPalette[colour_index].peBlue));
	}

DWORD Fill_Colour, Line_Colour;

void SetSolidColour (long colour_index)
	{
/*
    static DWORD reducedSCPalette[NUM_PALETTE_ENTRIES];
    static long first_time = TRUE;

    // make all reduced palette values on first call
    if (first_time)
        {
        long i;
        for (i = 0; i < NUM_PALETTE_ENTRIES; i++)
            {
            // reduce R/G/B to 5/8 of original
            reducedSCPalette[i] = D3DCOLOR_XRGB((5*SCPalette[i].peRed)/8,
			                               (5*SCPalette[i].peGreen)/8,
			                               (5*SCPalette[i].peBlue)/8);
            }

        first_time = FALSE;
        }

	Fill_Colour = reducedSCPalette[colour_index];
*/
	Fill_Colour = SCRGB(colour_index);
	}


void SetLineColour (long colour_index)
	{
	Line_Colour = SCRGB(colour_index);
	}


void SetTextureColour (long colour_index)
	{
	Fill_Colour = SCRGB(colour_index);
	}

#ifdef NOT_USED
/*	======================================================================================= */
/*	Function:		EnforceConstantFrameRate												*/
/*																							*/
/*	Description:	Attempt to keep frame rate close to MAX_FRAME_RATE						*/
/*	======================================================================================= */

static void EnforceConstantFrameRate( long max_frame_rate )
	{
	static long first_time = TRUE;

	static DWORD last_time_ms;
	DWORD this_time_ms, frame_time_ms;
	DWORD min_frame_time_ms = (1000/max_frame_rate);
	long remaining_ms;	// use long because it is signed (DWORD isn't)


	if (first_time)
		{
		first_time = FALSE;
		last_time_ms = timeGetTime();
		}
	else
		{
		this_time_ms = timeGetTime();
		frame_time_ms = this_time_ms - last_time_ms;

		remaining_ms = (long)min_frame_time_ms - (long)frame_time_ms;
		last_time_ms = this_time_ms;

		if (remaining_ms > 0)
			{
			Sleep(remaining_ms);
			last_time_ms += (DWORD)remaining_ms;
			}
		}

	return;
	}
#endif

//--------------------------------------------------------------------------------------
// Global variables
//--------------------------------------------------------------------------------------
#ifdef linux
TTF_Font *g_pFont = NULL;
TTF_Font *g_pFontLarge = NULL;
GLuint   g_pSprite = 0;	// Texture for batching text calls
#else
ID3DXFont *g_pFont = NULL;         // Font for drawing text
ID3DXFont *g_pFontLarge = NULL;    // Font for drawing large text
ID3DXSprite *g_pSprite = NULL;       // Sprite for batching draw text calls
#endif

#ifndef linux
//--------------------------------------------------------------------------------------
// Rejects any devices that aren't acceptable by returning false
//--------------------------------------------------------------------------------------
bool CALLBACK IsDeviceAcceptable( D3DCAPS9 *pCaps, D3DFORMAT AdapterFormat, 
                                  D3DFORMAT BackBufferFormat, bool bWindowed, void *pUserContext )
{
    // Typically want to skip backbuffer formats that don't support alpha blending
    IDirect3D9 *pD3D = DXUTGetD3DObject(); 
    if( FAILED( pD3D->CheckDeviceFormat( pCaps->AdapterOrdinal, pCaps->DeviceType,
                    AdapterFormat, D3DUSAGE_QUERY_POSTPIXELSHADER_BLENDING, 
                    D3DRTYPE_TEXTURE, BackBufferFormat ) ) )
        return false;

    return true;
}


//--------------------------------------------------------------------------------------
// Before a device is created, modify the device settings as needed
//--------------------------------------------------------------------------------------
bool CALLBACK ModifyDeviceSettings( DXUTDeviceSettings *pDeviceSettings, const D3DCAPS9 *pCaps, void *pUserContext )
{
    // For the first device created if its a REF device, optionally display a warning dialog box
    static bool s_bFirstTime = true;
    if( s_bFirstTime )
    {
        s_bFirstTime = false;
        if( pDeviceSettings->DeviceType == D3DDEVTYPE_REF )
            DXUTDisplaySwitchingToREFWarning();
    }

    return true;
}


//--------------------------------------------------------------------------------------
// Create any D3DPOOL_MANAGED resources here 
//--------------------------------------------------------------------------------------
HRESULT CALLBACK OnCreateDevice( IDirect3DDevice9 *pd3dDevice, const D3DSURFACE_DESC *pBackBufferSurfaceDesc, void *pUserContext )
{
    HRESULT hr;

//    V_RETURN( g_DialogResourceManager.OnCreateDevice( pd3dDevice ) );
//    V_RETURN( g_SettingsDlg.OnCreateDevice( pd3dDevice ) );

    // Initialize the fonts
    V_RETURN( D3DXCreateFont( pd3dDevice, 15, 0, FW_BOLD, 1, FALSE, DEFAULT_CHARSET, 
                              OUT_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH | FF_DONTCARE, 
                              L"Arial", &g_pFont ) );

    V_RETURN( D3DXCreateFont( pd3dDevice, 25, 0, FW_BOLD, 1, FALSE, DEFAULT_CHARSET, 
                              OUT_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH | FF_DONTCARE, 
                              L"Arial", &g_pFontLarge ) );

    return S_OK;
}


//--------------------------------------------------------------------------------------
// Create any D3DPOOL_DEFAULT resources here 
//--------------------------------------------------------------------------------------
HRESULT CALLBACK OnResetDevice( IDirect3DDevice9 *pd3dDevice, 
                                const D3DSURFACE_DESC *pBackBufferSurfaceDesc, void *pUserContext )
{
    HRESULT hr;

//    V_RETURN( g_DialogResourceManager.OnResetDevice() );
//    V_RETURN( g_SettingsDlg.OnResetDevice() );

    if( g_pFont )
        V_RETURN( g_pFont->OnResetDevice() );
    if( g_pFontLarge )
        V_RETURN( g_pFontLarge->OnResetDevice() );

    // Create a sprite to help batch calls when drawing many lines of text
    V_RETURN( D3DXCreateSprite( pd3dDevice, &g_pSprite ) );

	if (CreatePolygonVertexBuffer(pd3dDevice) != S_OK)
		return E_FAIL;
	if (CreateTrackVertexBuffer(pd3dDevice) != S_OK)
		return E_FAIL;
	if (CreateShadowVertexBuffer(pd3dDevice) != S_OK)
		return E_FAIL;
	if (CreateCarVertexBuffer(pd3dDevice) != S_OK)
		return E_FAIL;
	if (CreateCockpitVertexBuffer(pd3dDevice) != S_OK)
		return E_FAIL;

	if ( FAILED( D3DXCreateTextureFromFile( pd3dDevice, L"Bitmap\\atlas.png", &g_pAtlas ) ) )
		return E_FAIL;
	
	InitAtlasCoord();

	// Set the projection transform (view and world are updated per frame)
    D3DXMATRIX matProj;
	FLOAT fAspect = pBackBufferSurfaceDesc->Width / (FLOAT)pBackBufferSurfaceDesc->Height;
    D3DXMatrixPerspectiveFovLH( &matProj, D3DX_PI/4, fAspect, 0.5f, FURTHEST_Z );
    pd3dDevice->SetTransform( D3DTS_PROJECTION, &matProj );

    pd3dDevice->SetRenderState( D3DRS_ZENABLE,      TRUE );
    pd3dDevice->SetRenderState( D3DRS_SHADEMODE,    D3DSHADE_FLAT );
    pd3dDevice->SetRenderState( D3DRS_LIGHTING,     FALSE );

	// Disable texture mapping by default (only DrawTrack() enables it)
	pd3dDevice->SetTextureStageState( 0, D3DTSS_COLOROP, D3DTOP_DISABLE );

	return S_OK;
}
#else
// some helper functions....
void CreateFonts()
{
	if(!TTF_WasInit() && TTF_Init()==-1) {
		printf("TTF_Init: %s\n", TTF_GetError());
		exit(1);
	}

	if (g_pFont==NULL)
	{
		g_pFont = TTF_OpenFont("DejaVuSans-Bold.ttf", 15);
	}
	if (g_pFontLarge==NULL)
	{
		g_pFontLarge = TTF_OpenFont("DejaVuSans-Bold.ttf", 25);
	}
	printf("Font created (%p / %p)\n", g_pFont, g_pFontLarge);
}
void LoadTextures()
{
	if (!g_pAtlas) g_pAtlas = new IDirect3DTexture9();
	g_pAtlas->LoadTexture("Bitmap/atlas.png");
	InitAtlasCoord();
	printf("Texture loaded\n");
}
void CreateBuffers(IDirect3DDevice9 *pd3dDevice)
{
	if (CreatePolygonVertexBuffer(pd3dDevice) != S_OK)
		printf("Error creating PolygonVertexBuffer\n");
	if (CreateTrackVertexBuffer(pd3dDevice) != S_OK)
		printf("Error creating TrackVertexBuffer\n");
	if (CreateShadowVertexBuffer(pd3dDevice) != S_OK)
		printf("Error creating ShadowVertexBuffer\n");
	if (CreateCarVertexBuffer(pd3dDevice) != S_OK)
		printf("Error creating CarVertexBuffer\n");
	if (CreateCockpitVertexBuffer(pd3dDevice) != S_OK)
		printf("Error creating CarVertexBuffer\n");

}
#endif	//!linux
/*	======================================================================================= */
/*	Function:		CalcTrackMenuViewpoint													*/
/*																							*/
/*	Description:	*/
/*	======================================================================================= */

static void CalcTrackMenuViewpoint( void )
{
static long circle_y_angle = 0;

short sin, cos;
long centre = (NUM_TRACK_CUBES * CUBE_SIZE)/2;
long radius = ((NUM_TRACK_CUBES - 2) * CUBE_SIZE)/PRECISION;

	// Target orientation - centre of world
	target_x = (NUM_TRACK_CUBES * CUBE_SIZE)/2;
	target_y = 0;
	target_z = (NUM_TRACK_CUBES * CUBE_SIZE)/2;

	// camera moves in a circle around the track
	if (!bPaused) circle_y_angle += 128;
	circle_y_angle &= (MAX_ANGLE - 1);

	GetSinCos(circle_y_angle, &sin, &cos);

	viewpoint1_x = centre + (sin * radius);
	viewpoint1_y = -CUBE_SIZE * 3;
	viewpoint1_z = centre + (cos * radius);

	LockViewpointToTarget(viewpoint1_x,
						  viewpoint1_y,
						  viewpoint1_z,
						  target_x,
						  target_y,
						  target_z,
						  &viewpoint1_x_angle,
						  &viewpoint1_y_angle);
	viewpoint1_z_angle = 0;
}

/*	======================================================================================= */
/*	Function:		CalcTrackPreviewViewpoint												*/
/*																							*/
/*	Description:	*/
/*	======================================================================================= */

#define NUM_PREVIEW_CAMERAS (9)

static void CalcTrackPreviewViewpoint( void )
{
	// Target orientation - opponent
	target_x = opponent_x,
	target_y = opponent_y,
	target_z = opponent_z;

#ifndef  PREVIEW_METHOD1
	long centre = (NUM_TRACK_CUBES * CUBE_SIZE)/2;

	viewpoint1_x = centre;

	if (TrackID == DRAW_BRIDGE)
		viewpoint1_y = opponent_y - (CUBE_SIZE*5)/2;	// Draw Bridge requires a higher viewpoint
	else
		viewpoint1_y = opponent_y - CUBE_SIZE/2;

	viewpoint1_z = centre;

    viewpoint1_x += (target_x-viewpoint1_x)/2;
    viewpoint1_z += (target_z-viewpoint1_z)/2;

	// lock viewpoint y angle to target
	LockViewpointToTarget(viewpoint1_x,
						  viewpoint1_y,
						  viewpoint1_z,
						  target_x,
						  target_y,
						  target_z,
						  &viewpoint1_x_angle,
						  &viewpoint1_y_angle);
#else
    // cameras - four at corners, four half way along, one at centre
    long camera_x[NUM_PREVIEW_CAMERAS] =
                                        {CUBE_SIZE,
                                         CUBE_SIZE,
                                         (NUM_TRACK_CUBES-1) * CUBE_SIZE,
                                         (NUM_TRACK_CUBES-1) * CUBE_SIZE,
                                         //
                                         0,
                                         (NUM_TRACK_CUBES/2) * CUBE_SIZE,
                                         (NUM_TRACK_CUBES) * CUBE_SIZE,
                                         (NUM_TRACK_CUBES/2) * CUBE_SIZE,
                                         //
                                         (NUM_TRACK_CUBES/2) * CUBE_SIZE
                                        };
    long camera_z[NUM_PREVIEW_CAMERAS] =
                                        {CUBE_SIZE,
                                         (NUM_TRACK_CUBES-1) * CUBE_SIZE,
                                         (NUM_TRACK_CUBES-1) * CUBE_SIZE,
                                         CUBE_SIZE,
                                         //
                                         (NUM_TRACK_CUBES/2) * CUBE_SIZE,
                                         (NUM_TRACK_CUBES) * CUBE_SIZE,
                                         (NUM_TRACK_CUBES/2) * CUBE_SIZE,
                                         0,
                                         //
                                         (NUM_TRACK_CUBES/2) * CUBE_SIZE
                                        };

    // calculate nearest camera
    long camera, distance, shortest_distance = 0, nearest = 0;
    double o, a;
    for (camera = 0; camera < NUM_PREVIEW_CAMERAS; camera++)
        {
        o = double(camera_x[camera] - target_x);
        a = double(camera_z[camera] - target_z);
        distance = (long)sqrt((o*o) + (a*a));

        if (camera == 0)
            {
            shortest_distance = distance;
            nearest = camera;
            }
        else if (distance < shortest_distance)
            {
            shortest_distance = distance;
            nearest = camera;
            }
        }

	viewpoint1_x = camera_x[nearest];
	viewpoint1_y = player1_y - CUBE_SIZE/2;
	viewpoint1_z = camera_z[nearest];

	LockViewpointToTarget(viewpoint1_x,
						  viewpoint1_y,
						  viewpoint1_z,
						  target_x,
						  target_y,
						  target_z,
						  &viewpoint1_x_angle,
						  &viewpoint1_y_angle);
#endif

	viewpoint1_z_angle = 0;
}

/*	======================================================================================= */
/*	Function:		CalcGameViewpoint														*/
/*																							*/
/*	Description:	*/
/*	======================================================================================= */

static void CalcGameViewpoint( void )
{
long x_offset, y_offset, z_offset;

	if (bOutsideView)
	{
		// set Viewpoint 1 to behind Player 1
		// 04/11/1998 - would probably need to do a final rotation (i.e. of the trig. coefficients)
		//			    to allow a viewpoint with e.g. a different X angle to that of the player.
		//				For the car this would mean the following rotations: Y,X,Z, Y,X,Z, X
		//				For the viewpoint this would mean the following rotations: Y,X,Z, X (possibly!)
		CalcYXZTrigCoefficients(player1_x_angle,
								player1_y_angle,
								player1_z_angle);

		// vector from centre of car
		x_offset = 0;
		y_offset = 0xc0;
		z_offset = 0x300;
		WorldOffset(&x_offset, &y_offset, &z_offset);
		viewpoint1_x = (player1_x - x_offset);
		viewpoint1_y = (player1_y - y_offset);
		viewpoint1_z = (player1_z - z_offset);

		viewpoint1_x_angle = player1_x_angle;
		//viewpoint1_x_angle = (player1_x_angle + (48<<6)) & (MAX_ANGLE-1);
		viewpoint1_y_angle = player1_y_angle;
		//viewpoint1_y_angle = (player1_y_angle - (64<<6)) & (MAX_ANGLE-1);
		viewpoint1_z_angle = player1_z_angle;
		//viewpoint1_x_angle = 0;
		//viewpoint1_z_angle = 0;
	}
	else
	{
		viewpoint1_x = player1_x;
		viewpoint1_y = player1_y - (HEIGHT_ABOVE_ROAD << LOG_PRECISION);
//		viewpoint1_y = player1_y - (90 << LOG_PRECISION);
		viewpoint1_z = player1_z;

		viewpoint1_x_angle = player1_x_angle;
		viewpoint1_y_angle = player1_y_angle;
		viewpoint1_z_angle = player1_z_angle;
	}
}

//--------------------------------------------------------------------------------------
// Handle updates to the scene
//--------------------------------------------------------------------------------------
static D3DXMATRIX matWorldTrack, matWorldCar, matWorldOpponentsCar;


static void SetCarWorldTransform( void )
{
D3DXMATRIX matRot, matTemp, matTrans;

	D3DXMatrixIdentity(&matRot);
	float xa = (((float)player1_x_angle * 2 * D3DX_PI) / 65536.0f);
	float ya = (((float)player1_y_angle * 2 * D3DX_PI) / 65536.0f);
	float za = (((float)player1_z_angle * 2 * D3DX_PI) / 65536.0f);
	// Produce and combine the rotation matrices
	D3DXMatrixRotationZ(&matTemp, za);
	D3DXMatrixMultiply(&matRot, &matRot, &matTemp);
	D3DXMatrixRotationX(&matTemp, xa);
	D3DXMatrixMultiply(&matRot, &matRot, &matTemp);
	D3DXMatrixRotationY(&matTemp, ya);
	D3DXMatrixMultiply(&matRot, &matRot, &matTemp);
	// Produce the translation matrix
	// Position car slightly higher than wheel height (VCAR_HEIGHT/4) so wheels are fully visible
	D3DXMatrixTranslation( &matTrans, (float)(player1_x>>LOG_PRECISION), (float)(-player1_y>>LOG_PRECISION)+VCAR_HEIGHT/3, (float)(player1_z>>LOG_PRECISION) );
	// Combine the rotation and translation matrices to complete the world matrix
	D3DXMatrixMultiply(&matWorldCar, &matRot, &matTrans);
}


static void SetOpponentsCarWorldTransform( void )
{
D3DXMATRIX matRot, matTemp, matTrans;

	D3DXMatrixIdentity(&matRot);
//	float xa = (((float)opponent_x_angle * 2 * D3DX_PI) / 65536.0f);
//	float ya = (((float)opponent_y_angle * 2 * D3DX_PI) / 65536.0f);
//	float za = (((float)opponent_z_angle * 2 * D3DX_PI) / 65536.0f);
	// Produce and combine the rotation matrices
	D3DXMatrixRotationZ(&matTemp, opponent_z_angle);
	D3DXMatrixMultiply(&matRot, &matRot, &matTemp);
	D3DXMatrixRotationX(&matTemp, opponent_x_angle);
	D3DXMatrixMultiply(&matRot, &matRot, &matTemp);
	D3DXMatrixRotationY(&matTemp, opponent_y_angle);
	D3DXMatrixMultiply(&matRot, &matRot, &matTemp);
	// Produce the translation matrix
	// Position car at wheel height (VCAR_HEIGHT/4)
	D3DXMatrixTranslation( &matTrans, (float)(opponent_x>>LOG_PRECISION), (float)(-opponent_y>>LOG_PRECISION)+VCAR_HEIGHT/4, (float)(opponent_z>>LOG_PRECISION) );
	// Combine the rotation and translation matrices to complete the world matrix
	D3DXMatrixMultiply(&matWorldOpponentsCar, &matRot, &matTrans);
}


static void StopEngineSound( void )
{
	if (engineSoundPlaying)
	{
		for (int i = 0; i < 8; i++)
			EngineSoundBuffers[i]->Stop();

		engineSoundPlaying = FALSE;
	}
}


void CALLBACK OnFrameMove( IDirect3DDevice9 *pd3dDevice, double fTime, float fElapsedTime, void *pUserContext )
{
static D3DXVECTOR3 vUpVec( 0.0f, 1.0f, 0.0f );
static long frameCount = 0;
DWORD input = lastInput;	// take copy of user input
D3DXMATRIX matRot, matTemp, matTrans, matView;

	bFrameMoved = FALSE;
//	VALUE3 = frameGap;

	if (GameMode == GAME_OVER)
	{
		StopEngineSound();
		return;
	}

	if (bPaused)
	{
		StopEngineSound();
	}

	if (TrackID == NO_TRACK)
		return;

	// Track preview and game mode run at reduced frame rate
	if ((GameMode == TRACK_PREVIEW) || (GameMode == GAME_IN_PROGRESS))
	{
		if (GameMode == GAME_IN_PROGRESS)
		{
			// Following function should run at 50Hz
			if (!bPaused) FramesWheelsEngine(EngineSoundBuffers);
		}

		if (frameCount > 0)
			--frameCount;

		if (frameCount == 0)
		{
			frameCount = frameGap;
			//DXUTPause( false, false );	//pausing doesn't work properly
		}
		else
		{
			//if (frameCount == frameGap-1) DXUTPause( true, true );	//pausing doesn't work properly
			return;
		}
	}
	else if (GameMode == TRACK_MENU)
	{
		// Stop engine sound if at track menu or if game has finished
		StopEngineSound();
	}

	if ((GameMode == GAME_IN_PROGRESS) && (keyPress == 'R'))
	{
		// point car in opposite direction
		player1_y_angle += _180_DEGREES;
		player1_y_angle &= (MAX_ANGLE-1);
		INITIALISE_PLAYER = TRUE;
		keyPress = '\0';
	}

	if (!bPaused)
		MoveDrawBridge();

	// Car behaviour
	if ((GameMode == TRACK_PREVIEW) || (GameMode == GAME_IN_PROGRESS))
	{
		if (!bPaused)
		{
			if ((GameMode == GAME_IN_PROGRESS) && (!bPlayerPaused))
				CarBehaviour(input,
							 &player1_x,
							 &player1_y,
							 &player1_z,
							 &player1_x_angle,
							 &player1_y_angle,
							 &player1_z_angle);

			OpponentBehaviour(&opponent_x,
							  &opponent_y,
							  &opponent_z,
							  &opponent_x_angle,
							  &opponent_y_angle,
							  &opponent_z_angle,
							  bOpponentPaused);
		}

		LimitViewpointY(&player1_y);
	}

	if ((GameMode == TRACK_MENU) || (GameMode == TRACK_PREVIEW))
	{
		if (GameMode == TRACK_MENU)
			CalcTrackMenuViewpoint();
		else
		{
			CalcTrackPreviewViewpoint();

			// Set the car's world transform matrix
			SetOpponentsCarWorldTransform();
		}

		// Set Direct3D transforms, ready for OnFrameRender
		viewpoint1_x >>= LOG_PRECISION;
		// NOTE: viewpoint1_y must be preserved for use by DrawBackdrop
		viewpoint1_z >>= LOG_PRECISION;

		target_x >>= LOG_PRECISION;
		target_y = -target_y;
		target_y >>= LOG_PRECISION;
		target_z >>= LOG_PRECISION;

		// Set the track's world transform matrix
		D3DXMatrixIdentity( &matWorldTrack );

		//
		// Set the view transform matrix
		//
		// Set the eye point
		D3DXVECTOR3 vEyePt( (float)viewpoint1_x, (float)(-viewpoint1_y>>LOG_PRECISION), (float)viewpoint1_z );
		// Set the lookat point
		D3DXVECTOR3 vLookatPt( (float)target_x, (float)target_y, (float)target_z );
		D3DXMatrixLookAtLH( &matView, &vEyePt, &vLookatPt, &vUpVec );
		pd3dDevice->SetTransform( D3DTS_VIEW, &matView );
	}
	else if (GameMode == GAME_IN_PROGRESS)
	{
		CalcGameViewpoint();

		// Set Direct3D transforms, ready for OnFrameRender
		viewpoint1_x >>= LOG_PRECISION;
		// NOTE: viewpoint1_y must be preserved for use by DrawBackdrop
		viewpoint1_z >>= LOG_PRECISION;

		// Set the track's world transform matrix
		D3DXMatrixIdentity( &matWorldTrack );

		// Set the opponent's car world transform matrix
		/*
		// temp set opponent's position to same as player
		if ((opponent_x == 0) && (opponent_y == 0) && (opponent_z == 0))
		{
			opponent_x = player1_x;
			opponent_y = player1_y + (0xc00 * 256 * 4);	// Subtract amount above road, added by PositionCarAbovePiece()
			opponent_z = player1_z;
			opponent_x_angle = player1_x_angle;
			opponent_y_angle = player1_y_angle;
			opponent_z_angle = player1_z_angle;
		}
		*/
		SetOpponentsCarWorldTransform();

		if (bOutsideView)
		{
			// Set the car's world transform matrix
			SetCarWorldTransform();
		}

		//
		// Set the view transform matrix
		//
		// Produce the translation matrix
		D3DXMatrixTranslation( &matTrans, (float)-viewpoint1_x, (float)(viewpoint1_y>>LOG_PRECISION), (float)-viewpoint1_z );
		D3DXMatrixIdentity(&matRot);
		float xa = (((float)-viewpoint1_x_angle * 2 * D3DX_PI) / 65536.0f);
		float ya = (((float)-viewpoint1_y_angle * 2 * D3DX_PI) / 65536.0f);
		float za = (((float)-viewpoint1_z_angle * 2 * D3DX_PI) / 65536.0f);
		// Produce and combine the rotation matrices
#ifdef linux
		D3DXMatrixRotationY(&matTemp, ya + D3DX_PI);
		D3DXMatrixMultiply(&matRot, &matRot, &matTemp);
		D3DXMatrixRotationX(&matTemp, -xa);
		D3DXMatrixMultiply(&matRot, &matRot, &matTemp);
		D3DXMatrixRotationZ(&matTemp, -za);
		D3DXMatrixMultiply(&matRot, &matRot, &matTemp);
#else
		D3DXMatrixRotationY(&matTemp, ya);
		D3DXMatrixMultiply(&matRot, &matRot, &matTemp);
		D3DXMatrixRotationX(&matTemp, xa);
		D3DXMatrixMultiply(&matRot, &matRot, &matTemp);
		D3DXMatrixRotationZ(&matTemp, za);
		D3DXMatrixMultiply(&matRot, &matRot, &matTemp);
#endif
		// Combine the rotation and translation matrices to complete the world matrix
		D3DXMatrixMultiply(&matView, &matTrans, &matRot);
#ifdef linux
		D3DXMatrixScaling(&matTrans, +1, -1, +1);
		D3DXMatrixMultiply(&matView, &matView, &matTrans);
#endif
		pd3dDevice->SetTransform( D3DTS_VIEW, &matView );
	}

	if (!bPaused)
		bFrameMoved = TRUE;
}


/*	======================================================================================= */
/*	Function:		HandleTrackMenu															*/
/*																							*/
/*	Description:	Output track menu text													*/
/*	======================================================================================= */
#ifdef linux
#define FIRSTMENU SDLK_1
#define STARTMENU SDLK_s
#define LEAGUEMENU SDLK_l
#else
#define FIRSTMENU '1'
#define STARTMENU 'S'
#define LEAGUEMENU 'L'
#endif

static void HandleTrackMenu( CDXUTTextHelper &txtHelper )
	{
	long i, track_number;
	UINT firstMenuOption, lastMenuOption;
	txtHelper.SetInsertionPos( 2+(wideScreen?10:0), 15*8 );
	txtHelper.DrawTextLine( L"Choose track :-" );

	for (i = 0, firstMenuOption = FIRSTMENU; i < NUM_TRACKS; i++)
		{
		txtHelper.DrawFormattedTextLine( L"'%d' -  " STRING, (i+1), GetTrackName(i) );
		}
	lastMenuOption = i + FIRSTMENU - 1;

	// output instructions
	const D3DSURFACE_DESC *pd3dsdBackBuffer = DXUTGetBackBufferSurfaceDesc();
	txtHelper.SetInsertionPos( 2+(wideScreen?10:0), pd3dsdBackBuffer->Height-15*8 );
	txtHelper.DrawFormattedTextLine( L"Current track - " STRING L".  Press 'S' to select, Escape to quit", (TrackID == NO_TRACK ? L"None" : GetTrackName(TrackID)));
	txtHelper.DrawTextLine( L"'L' to switch Super League On/Off");

	if (((keyPress >= firstMenuOption) && (keyPress <= lastMenuOption)) || (keyPress == LEAGUEMENU))
		{
		if(keyPress == LEAGUEMENU) {
			bSuperLeague = !bSuperLeague;
			track_number = TrackID;
			CreateCarVertexBuffer(DXUTGetD3DDevice());	// recreate car
		} else 
			track_number = keyPress - firstMenuOption;	// start at 0

		if (! ConvertAmigaTrack(track_number))
			{
#if defined(DEBUG) || defined(_DEBUG)
			fprintf(out, "Failed to convert track %d\n", track_number);
#endif
			MessageBox(NULL, L"Failed to convert track", L"Error", MB_OK);	//temp
			return;
			}

		if (CreateTrackVertexBuffer(DXUTGetD3DDevice()) != S_OK)
			{
#if defined(DEBUG) || defined(_DEBUG)
			fprintf(out, "Failed to create track vertex buffer %d\n", track_number);
#endif
			MessageBox(NULL, L"Failed to create track vertex buffer", L"Error", MB_OK);	//temp
			return;
			}

		keyPress = '\0';
		}

	if ((keyPress == STARTMENU) && (TrackID != NO_TRACK))
		{
		bNewGame = TRUE;	// Used here just to reset the opponent's car, which is then shown during the track preview
		ResetPlayer();		// Also reset player to clear values if there was a previous game (CarBehaviour normally does this, but isn't called for track preview)
        GameMode = TRACK_PREVIEW;
		bPlayerPaused = bOpponentPaused = FALSE;
		keyPress = '\0';
		}
	

	return;
	}


/*	======================================================================================= */
/*	Function:		HandleTrackPreview														*/
/*																							*/
/*	Description:	Output track preview text												*/
/*	======================================================================================= */

static void HandleTrackPreview( CDXUTTextHelper &txtHelper )
	{
	// output instructions
	const D3DSURFACE_DESC *pd3dsdBackBuffer = DXUTGetBackBufferSurfaceDesc();
	txtHelper.SetInsertionPos( 2+(wideScreen?10:0), pd3dsdBackBuffer->Height-15*9 );
	txtHelper.DrawFormattedTextLine( L"Selected track - " STRING L".  Press 'S' to start game", (TrackID == NO_TRACK ? L"None" : GetTrackName(TrackID)));
	txtHelper.DrawTextLine( L"'M' for track menu, Escape to quit");
	txtHelper.DrawTextLine( L"(Press F4 to change scenery, F9 / F10 to adjust frame rate)" );

	txtHelper.SetInsertionPos( 2+(wideScreen?10:0), pd3dsdBackBuffer->Height-15*6 );
	txtHelper.DrawTextLine( L"Keyboard controls during game :-" );
	#ifdef PANDORA
	txtHelper.DrawTextLine( L"  DPad = Steer, (X) = Accelerate, (B) = Brake, (R) = Nitro" );
	#else
	txtHelper.DrawTextLine( L"  S = Steer left, D = Steer right, Enter = Accelerate, Space = Brake" );
	#endif
	txtHelper.DrawTextLine( L"  R = Point car in opposite direction, P = Pause, O = Unpause" );
	txtHelper.DrawTextLine( L"  M = Back to track menu, Escape = Quit" );

	if (keyPress == STARTMENU)
		{
		bNewGame = TRUE;
        GameMode = GAME_IN_PROGRESS;
		// initialise game data
		ResetLapData(OPPONENT);
		ResetLapData(PLAYER);
		gameStartTime = DXUTGetTime();
		gameEndTime = 0;
		if(bSuperLeague) {
			boostReserve = SuperBoost;
			road_cushion_value = 1;
			engine_power = 320;
			boost_unit_value = 12;
			opp_engine_power = 314;
		} else {
			boostReserve = StandardBoost;	// SuperBoost for super league
			road_cushion_value = 0;
			engine_power = 240;
			boost_unit_value = 16;
			opp_engine_power = 236;
		}
		boostUnit = 0;
		bPlayerPaused = bOpponentPaused = FALSE;
		keyPress = '\0';
		}

	return;
	}


//--------------------------------------------------------------------------------------
// Render the help and statistics text. This function uses the ID3DXFont interface for 
// efficient text rendering.  Also render text specific to GameMode.
//--------------------------------------------------------------------------------------
extern long new_damage;
extern long opponentsID;
extern WCHAR *opponentNames[];

void RenderText( double fTime )
{
    // The helper object simply helps keep track of text position, and color
    // and then it calls pFont->DrawText( m_pSprite, strMsg, -1, &rc, DT_NOCLIP, m_clr );
    // If NULL is passed in as the sprite object, then it will work fine however the 
    // pFont->DrawText() will not be batched together.  Batching calls will improve perf.
#ifdef linux
	static
#endif
    CDXUTTextHelper txtHelper( g_pFont, g_pSprite, 15 );

    // Output statistics
    txtHelper.Begin();
	txtHelper.SetForegroundColor( D3DXCOLOR( 1.0f, 1.0f, 0.0f, 1.0f ) );
	if (bShowStats)
	{
		txtHelper.SetInsertionPos( 2+(wideScreen?10:0), 0 );
#ifndef linux
		txtHelper.DrawTextLine( DXUTGetFrameStats(true) );
		txtHelper.DrawTextLine( DXUTGetDeviceStats() );
#else
		
		txtHelper.DrawFormattedTextLine( L"fTime: %0.1f  sin(fTime): %0.4f", fTime, sin(fTime) );
#endif

#if defined(DEBUG) || defined(_DEBUG)
		// Output VALUE1, VALUE, VALUE3
		txtHelper.DrawFormattedTextLine( L"V1: %08x, V2: %08x, V3: %08x", VALUE1, VALUE2, VALUE3 );
#else
		// Output version
		txtHelper.DrawTextLine( L"Version 1.0" );
#endif
	}

	switch (GameMode)
		{
		case TRACK_MENU:
			HandleTrackMenu(txtHelper);
			txtHelper.End();
			break;

		case TRACK_PREVIEW:
			HandleTrackPreview(txtHelper);
			txtHelper.End();
			break;

		case GAME_IN_PROGRESS:
		case GAME_OVER:
			// Show car speed, damage and race details
			const D3DSURFACE_DESC *pd3dsdBackBuffer = DXUTGetBackBufferSurfaceDesc();
			WCHAR lapText[3] = L"  ";
			// Output opponent's name for four seconds at race start
			if (((DXUTGetTime() - gameStartTime) < 4.0) && (opponentsID != NO_OPPONENT))
			{
				txtHelper.SetInsertionPos( 250+(wideScreen?80:0), pd3dsdBackBuffer->Height-15*20 );
				txtHelper.DrawFormattedTextLine( L"Opponent: " STRING, opponentNames[opponentsID] );
			}
			txtHelper.SetInsertionPos( 2+(wideScreen?80:0), pd3dsdBackBuffer->Height-15*2 );
			if (lapNumber[PLAYER] > 0)
				StringCchPrintf( lapText, 3, L"%d", lapNumber[PLAYER] );
			txtHelper.SetForegroundColor( D3DXCOLOR( 0.0f, 0.0f, 0.0f, 1.0f ) );
			txtHelper.SetInsertionPos( 75+(wideScreen?80:0), pd3dsdBackBuffer->Height-52 );
			txtHelper.DrawFormattedTextLine( L"L" STRING L"        B%02d", lapText, boostReserve );
			if (CalculateOpponentsDistance() >= 0)
				txtHelper.SetInsertionPos( 72+(wideScreen?80:0), pd3dsdBackBuffer->Height-29 );
			else
				txtHelper.SetInsertionPos( 76+(wideScreen?80:0), pd3dsdBackBuffer->Height-29 );
			txtHelper.DrawFormattedTextLine( L"         %+05d", CalculateOpponentsDistance() );

			txtHelper.End();

			if (raceFinished)
			{
				#ifdef linux
				static
				#endif
				CDXUTTextHelper txtHelperLarge( g_pFontLarge, g_pSprite, 25 );

				txtHelperLarge.Begin();

				double currentTime = DXUTGetTime(), diffTime;
				if (gameEndTime == 0.0)
					gameEndTime = currentTime;

				// Show race finished text for six seconds, then end the game
				diffTime = currentTime - gameEndTime;
				if (diffTime > 6.0)
				{
					GameMode = GAME_OVER;
				}

				if (GameMode == GAME_OVER)
				{
#ifdef 	linux
					txtHelperLarge.SetInsertionPos( 250+(wideScreen?80:0), pd3dsdBackBuffer->Height-25*13 );
					txtHelperLarge.DrawTextLine( L"GAME OVER" );
					txtHelperLarge.SetInsertionPos( 132+(wideScreen?80:0), pd3dsdBackBuffer->Height-25*11 );
					txtHelperLarge.DrawTextLine( L"Press 'M' for track menu" );
#else
					txtHelperLarge.SetInsertionPos( 124+(wideScreen?80:0), pd3dsdBackBuffer->Height-25*12 );
					txtHelperLarge.DrawTextLine( L"GAME OVER: Press 'M' for track menu" );
#endif
				}
				else
				{
					long intTime = (long)diffTime;
					// Text flashes white/black, changing every half second
					if ((diffTime - (double)intTime) < 0.5)
						txtHelperLarge.SetForegroundColor( D3DXCOLOR( 1.0f, 1.0f, 1.0f, 1.0f ) );
					else
						txtHelperLarge.SetForegroundColor( D3DXCOLOR( 0.0f, 0.0f, 0.0f, 1.0f ) );

					txtHelperLarge.SetInsertionPos( 250+(wideScreen?80:0), pd3dsdBackBuffer->Height-25*12 );

					if (raceWon)
						txtHelperLarge.DrawTextLine( L"RACE WON" );
					else
						txtHelperLarge.DrawTextLine( L"RACE LOST" );
				}

				txtHelperLarge.End();
			}
			break;
		}
//	VALUE2 = raceFinished ? 1 : 0;
//	VALUE3 = (long)gameEndTime;
}


#ifdef NOT_USED
//-----------------------------------------------------------------------------
// Name: SetupLights()
// Desc: Sets up the lights and materials for the scene.
//-----------------------------------------------------------------------------
void SetupLights( IDirect3DDevice9 *pd3dDevice )
{
D3DXVECTOR3 vecDir;
D3DLIGHT9 light;

    // Set up a material. The material here just has the diffuse and ambient
    // colors set to white. Note that only one material can be used at a time.
    D3DMATERIAL9 mtrl;
    ZeroMemory( &mtrl, sizeof(D3DMATERIAL9) );
    mtrl.Diffuse.r = mtrl.Ambient.r = 1.0f;
    mtrl.Diffuse.g = mtrl.Ambient.g = 1.0f;
    mtrl.Diffuse.b = mtrl.Ambient.b = 1.0f;
    mtrl.Diffuse.a = mtrl.Ambient.a = 1.0f;
    pd3dDevice->SetMaterial( &mtrl );

	/*
    // Set up a white spotlight
    ZeroMemory( &light, sizeof(D3DLIGHT9) );
    light.Type       = D3DLIGHT_SPOT;
    light.Diffuse.r  = 1.0f;
    light.Diffuse.g  = 1.0f;
    light.Diffuse.b  = 1.0f;
	// Set position vector
//	light.Position = D3DXVECTOR3(32768.0f, 1000.0f, 32768.0f);
	if (GameMode == TRACK_MENU)
	{
		light.Position.x = 32768.0f;
		light.Position.y = 16384.0f;
		light.Position.z = 32768.0f;
	}
	else
	{
		light.Position.x = (player1_x>>LOG_PRECISION);
		light.Position.y = 16384.0f;
		light.Position.z = (player1_z>>LOG_PRECISION);
	}
	// Set direction vector to simulate sunlight
    vecDir = D3DXVECTOR3(0.0f, -1.0f, 0.0f);
    D3DXVec3Normalize( (D3DXVECTOR3*)&light.Direction, &vecDir );
    light.Range       = 32768;//((float)sqrt(FLT_MAX));
	light.Falloff = 1.0f;
	light.Attenuation0 = 1.0f;
	light.Attenuation1 = 0.0f;
	light.Attenuation2 = 0.0f;
	light.Theta = PI/3;
	light.Phi = PI/2;
	pd3dDevice->SetLight( 0, &light );
    pd3dDevice->LightEnable( 0, TRUE );
	*/

	/**/
    // Set up four white, directional lights
    ZeroMemory( &light, sizeof(D3DLIGHT9) );
    light.Type       = D3DLIGHT_DIRECTIONAL;
    light.Diffuse.r  = 0.33f;
    light.Diffuse.g  = 0.33f;
    light.Diffuse.b  = 0.33f;
	// Set direction vector to simulate sunlight
    vecDir = D3DXVECTOR3(0.2f, -0.7f, 0.5f);
    D3DXVec3Normalize( (D3DXVECTOR3*)&light.Direction, &vecDir );
    light.Range       = 10000.0f;
    pd3dDevice->SetLight( 1, &light );
    pd3dDevice->LightEnable( 1, TRUE );
	/**/
    vecDir = D3DXVECTOR3(0.2f, -0.7f, -0.5f);
    D3DXVec3Normalize( (D3DXVECTOR3*)&light.Direction, &vecDir );
    pd3dDevice->SetLight( 2, &light );
    pd3dDevice->LightEnable( 2, TRUE );
	/**/
    vecDir = D3DXVECTOR3(-0.2f, -0.7f, 0.5f);
    D3DXVec3Normalize( (D3DXVECTOR3*)&light.Direction, &vecDir );
    pd3dDevice->SetLight( 3, &light );
    pd3dDevice->LightEnable( 3, TRUE );
	/**/
    vecDir = D3DXVECTOR3(-0.2f, -0.7f, -0.5f);
    D3DXVec3Normalize( (D3DXVECTOR3*)&light.Direction, &vecDir );
    pd3dDevice->SetLight( 4, &light );
    pd3dDevice->LightEnable( 4, TRUE );
	/**/

    // Finally, turn on some ambient light and turn lighting on
    pd3dDevice->SetRenderState( D3DRS_AMBIENT, 0x00303030 );
	pd3dDevice->SetRenderState( D3DRS_LIGHTING, TRUE );
}
#endif


//--------------------------------------------------------------------------------------
// Render the scene 
//--------------------------------------------------------------------------------------

void CALLBACK OnFrameRender( IDirect3DDevice9 *pd3dDevice, double fTime, float fElapsedTime, void *pUserContext )
{
HRESULT hr;

//    // Clear the render target and the zbuffer
//    V( pd3dDevice->Clear(0, NULL, D3DCLEAR_TARGET | D3DCLEAR_ZBUFFER, D3DCOLOR_ARGB(0, 45, 50, 170), 1.0f, 0) );

    // Clear the zbuffer
    V( pd3dDevice->Clear(0, NULL, D3DCLEAR_ZBUFFER, 0, 1.0f, 0) );

    // Render the scene
    if( SUCCEEDED( pd3dDevice->BeginScene() ) )
    {
		// Disable Z buffer and polygon culling, ready for DrawBackdrop()
		pd3dDevice->SetRenderState( D3DRS_ZENABLE, FALSE );
		pd3dDevice->SetRenderState( D3DRS_CULLMODE, D3DCULL_NONE );

		// Draw Backdrop
		DrawBackdrop(viewpoint1_y, viewpoint1_x_angle, viewpoint1_y_angle, viewpoint1_z_angle);

//		SetupLights(pd3dDevice);

		// Draw Track
		pd3dDevice->SetTransform( D3DTS_WORLD, &matWorldTrack );
		DrawTrack(pd3dDevice);

		switch (GameMode)
			{
			case TRACK_MENU:
				break;

			case TRACK_PREVIEW:
				// Draw Opponent's Car
				pd3dDevice->SetTransform( D3DTS_WORLD, &matWorldOpponentsCar );
				DrawCar(pd3dDevice);
				break;

			case GAME_IN_PROGRESS:
			case GAME_OVER:
				// Draw Opponent's Car
				pd3dDevice->SetTransform( D3DTS_WORLD, &matWorldOpponentsCar );
				DrawCar(pd3dDevice);

				if (bOutsideView)
				{
				// Draw Player1's Car
				pd3dDevice->SetTransform( D3DTS_WORLD, &matWorldCar );
				DrawCar(pd3dDevice);
				}
				else
				{
				// draw cockpit...
				DrawCockpit(pd3dDevice);
				}
				break;
			}

		if (GameMode == GAME_IN_PROGRESS)
		{
			DrawOtherGraphics();

			//jsr	display.speed.bar
			if (bFrameMoved) UpdateDamage();

			UpdateLapData();
			//jsr	display.opponents.distance
		}

		RenderText( fTime );

		// End the scene
		pd3dDevice->EndScene();
	}
}

#ifndef linux
//--------------------------------------------------------------------------------------
// Handle messages to the application 
//--------------------------------------------------------------------------------------
LRESULT CALLBACK MsgProc( HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam, 
                          bool *pbNoFurtherProcessing, void *pUserContext )
{
    return 0;
}

//--------------------------------------------------------------------------------------
// As a convenience, DXUT inspects the incoming windows messages for
// keystroke messages and decodes the message parameters to pass relevant keyboard
// messages to the application.  The framework does not remove the underlying keystroke 
// messages, which are still passed to the application's MsgProc callback.
//--------------------------------------------------------------------------------------
void CALLBACK KeyboardProc( UINT nChar, bool bKeyDown, bool bAltDown, void *pUserContext )
{
    if( bKeyDown )
    {
		keyPress = nChar;
        switch( nChar )
        {
#if defined(DEBUG) || defined(_DEBUG)
        case VK_F1:
            bTestKey = !bTestKey;
            break;
#endif
        case VK_F2:
            ++bTrackDrawMode;
			if (bTrackDrawMode > 1) bTrackDrawMode = 0;
			DXUTReset3DEnvironment();
            break;

        case VK_F4:
            NextSceneryType();
            break;

        case VK_F5:
            bShowStats = !bShowStats;
            break;

        case VK_F6:
            bPlayerPaused = !bPlayerPaused;
            break;

        case VK_F7:
            bOpponentPaused = !bOpponentPaused;
            break;

		case VK_F9:
			if (frameGap > 1) frameGap--;
			break;

		case VK_F10:
			frameGap++;
			break;

#if defined(DEBUG) || defined(_DEBUG)
		case VK_BACK:
			bOutsideView = !bOutsideView;
            break;
#endif
		case 'M':
			if (GameMode != TRACK_MENU)
			{
				GameMode = TRACK_MENU;

				opponentsID = NO_OPPONENT;

				// reset all animated objects
				ResetDrawBridge();
			}
            break;

		case 'O':
			bPaused = FALSE;
            break;

		case 'P':
			bPaused = TRUE;
            break;

		case 'Z':
			bNewGame = TRUE;		// for testing to try stopping car positioning bug
            break;

		// controls for Car Behaviour, Player 1
        case VK_LEFT:
            lastInput |= KEY_P1_LEFT;
            break;

        case VK_RIGHT:
            lastInput |= KEY_P1_RIGHT;
            break;

        case VK_SPACE:
            lastInput |= KEY_P1_BOOST;
            break;

		case VK_DOWN:
            lastInput |= KEY_P1_BRAKE;
            break;

        case VK_UP:
            lastInput |= KEY_P1_ACCEL;
            break;
        }

#ifdef NOT_USED
        switch( nChar )
        {
            case VK_LEFT: fEyeX -= 1000.0f; break;
            case VK_RIGHT: fEyeX += 1000.0f; break;
            case VK_UP: fEyeY -= 1000.0f; break;
            case VK_DOWN: fEyeY += 1000.0f; break;
            case VK_PRIOR: fEyeZ -= 1000.0f; break;	// pgup
            case VK_NEXT: fEyeZ += 1000.0f; break;	// pgdn
        }
#endif
    }
	else
	{
		keyPress = '\0';
        switch( nChar )
        {
		// controls for Car Behaviour, Player 1
        case VK_LEFT:
            lastInput &= ~KEY_P1_LEFT;
            break;

        case VK_RIGHT:
            lastInput &= ~KEY_P1_RIGHT;
            break;

        case VK_SPACE:	// couldn't find VK_ definition for HASH key
            lastInput &= ~KEY_P1_BOOST;
            break;

		case VK_DOWN:
            lastInput &= ~KEY_P1_BRAKE;
            break;

        case VK_UP:
            lastInput &= ~KEY_P1_ACCEL;
            break;
		}
	}
}


//--------------------------------------------------------------------------------------
// Release resources created in the OnResetDevice callback here 
//--------------------------------------------------------------------------------------
void CALLBACK OnLostDevice( void *pUserContext )
{
//    g_DialogResourceManager.OnLostDevice();
//    g_SettingsDlg.OnLostDevice();
//    CDXUTDirectionWidget::StaticOnLostDevice();
    if( g_pFont )
        g_pFont->OnLostDevice();
    if( g_pFontLarge )
        g_pFontLarge->OnLostDevice();
    SAFE_RELEASE(g_pSprite);

	FreePolygonVertexBuffer();
	FreeTrackVertexBuffer();
	FreeShadowVertexBuffer();
	FreeCarVertexBuffer();
	FreeCockpitVertexBuffer();

	if (g_pAtlas) g_pAtlas->Release(), g_pAtlas = NULL;
}


//--------------------------------------------------------------------------------------
// Release resources created in the OnCreateDevice callback here
//--------------------------------------------------------------------------------------
void CALLBACK OnDestroyDevice( void *pUserContext )
{
//    g_DialogResourceManager.OnDestroyDevice();
//    g_SettingsDlg.OnDestroyDevice();
    SAFE_RELEASE(g_pFont);
    SAFE_RELEASE(g_pFontLarge);

	FreePolygonVertexBuffer();
	FreeTrackVertexBuffer();
	FreeShadowVertexBuffer();
	FreeCarVertexBuffer();
	FreeCockpitVertexBuffer();
}


//--------------------------------------------------------------------------------------
// Initialize everything and go into a render loop
//--------------------------------------------------------------------------------------
INT WINAPI WinMain( HINSTANCE, HINSTANCE, LPSTR, int )
{
    // Enable run-time memory check for debug builds.
#if defined(DEBUG) | defined(_DEBUG)
    _CrtSetDbgFlag( _CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF );
#endif

    // Set the callback functions
    DXUTSetCallbackDeviceCreated( OnCreateDevice );
    DXUTSetCallbackDeviceReset( OnResetDevice );
    DXUTSetCallbackDeviceLost( OnLostDevice );
    DXUTSetCallbackDeviceDestroyed( OnDestroyDevice );
    DXUTSetCallbackMsgProc( MsgProc );
    DXUTSetCallbackKeyboard( KeyboardProc );
    DXUTSetCallbackFrameRender( OnFrameRender );
    DXUTSetCallbackFrameMove( OnFrameMove );
   
    // Perform any application-level initialization here
	if (!InitialiseData())
	    return DXUTGetExitCode();

    // Initialize DXUT and create the desired Win32 window and Direct3D device for the application
    DXUTInit( true, true, true, false ); // Parse the command line, handle the default hotkeys, show msgboxes, don't handle Alt-Enter
    DXUTSetCursorSettings( true, true ); // Show the cursor and clip it when in full screen
    DXUTCreateWindow( L"StuntCarRacer" );
    DXUTCreateDevice( D3DADAPTER_DEFAULT, true, 640, 480, IsDeviceAcceptable, ModifyDeviceSettings );

//	DXUTSetConstantFrameTime( true, 0.033f );	// Doesn't seem to work

	//
	//	Initialise sound objects
	//
	if (!DSInit())
		return FALSE;

	if (!DSSetMode())
		return FALSE;

    // Start the render loop
    DXUTMainLoop();

    // Perform any application-level cleanup here
	FreeData();

    return DXUTGetExitCode();
}

#else

bool process_events()
{
    SDL_Event event;
    while( SDL_PollEvent( &event ) ) {
        switch( event.type ) {
        case SDL_KEYDOWN:
			keyPress = event.key.keysym.sym;
			// some special cases for French keyboards
			if((event.key.keysym.mod & KMOD_SHIFT) == 0)
			switch(event.key.keysym.sym) {
				case SDLK_AMPERSAND:	keyPress = SDLK_1; break;
				case 233:				keyPress = SDLK_2; break;
				case SDLK_QUOTEDBL:		keyPress = SDLK_3; break;
				case SDLK_QUOTE:		keyPress = SDLK_4; break;
				case SDLK_LEFTPAREN:	keyPress = SDLK_5; break;
				case SDLK_MINUS:		keyPress = SDLK_6; break;
				case 232:				keyPress = SDLK_7; break;
				case SDLK_UNDERSCORE:	keyPress = SDLK_8; break;
				case 231:				keyPress = SDLK_9; break;
				case 224:				keyPress = SDLK_0; break;
			}
            switch( keyPress ) {
#if defined(DEBUG) || defined(_DEBUG)
				case SDLK_F1:
					bTestKey = !bTestKey;
					break;
#endif
				case SDLK_F2:
					++bTrackDrawMode;
					if (bTrackDrawMode > 1) bTrackDrawMode = 0;
					DXUTReset3DEnvironment();
					break;

				case SDLK_F4:
					NextSceneryType();
					break;

				case SDLK_F5:
					bShowStats = !bShowStats;
					break;

				case SDLK_F6:
					bPlayerPaused = !bPlayerPaused;
					break;

				case SDLK_F7:
					bOpponentPaused = !bOpponentPaused;
					break;

				case SDLK_F9:
					if (frameGap > 1) frameGap--;
					break;

				case SDLK_F10:
					frameGap++;
					break;

#if defined(DEBUG) || defined(_DEBUG)
				case SDLK_BACK:
					bOutsideView = !bOutsideView;
					break;
#endif
				case SDLK_m:
					if (GameMode != TRACK_MENU)
					{
						GameMode = TRACK_MENU;

						opponentsID = NO_OPPONENT;

						// reset all animated objects
						ResetDrawBridge();
					}
					break;

				case SDLK_o:
					bPaused = FALSE;
					break;

				case SDLK_p:
					bPaused = TRUE;
					break;

				case SDLK_z:
					bNewGame = TRUE;		// for testing to try stopping car positioning bug
					break;

				// controls for Car Behaviour, Player 1
				case SDLK_LEFT:
					lastInput |= KEY_P1_LEFT;
					break;

				case SDLK_RIGHT:
					lastInput |= KEY_P1_RIGHT;
					break;

#ifdef PANDORA
				case SDLK_RCTRL:
#else
				case SDLK_SPACE:
				case SDLK_RSHIFT:
				case SDLK_LSHIFT:
#endif
					lastInput |= KEY_P1_BOOST;
					break;

#ifdef PANDORA
				case SDLK_END:
#else
				case SDLK_DOWN:
#endif
					lastInput |= KEY_P1_BRAKE;
					break;

#ifdef PANDORA
				case SDLK_PAGEDOWN:
#else
				case SDLK_UP:
#endif
					lastInput |= KEY_P1_ACCEL;
					break;

				case SDLK_ESCAPE:
					return false;
				}
            break;
        case SDL_KEYUP:
			keyPress = 0;
            switch( event.key.keysym.sym ) {
				// controls for Car Behaviour, Player 1
				case SDLK_LEFT:
					lastInput &= ~KEY_P1_LEFT;
					break;

				case SDLK_RIGHT:
					lastInput &= ~KEY_P1_RIGHT;
					break;

#ifdef PANDORA
				case SDLK_RCTRL:
#else
				case SDLK_SPACE:
				case SDLK_RSHIFT:
				case SDLK_LSHIFT:
#endif
					lastInput &= ~KEY_P1_BOOST;
					break;

#ifdef PANDORA
				case SDLK_END:
#else
				case SDLK_DOWN:
#endif
					lastInput &= ~KEY_P1_BRAKE;
					break;

#ifdef PANDORA
				case SDLK_PAGEDOWN:
#else
				case SDLK_UP:
#endif
					lastInput &= ~KEY_P1_ACCEL;
					break;
				}
			break;
        case SDL_QUIT:
            return false;
        }
    }
	return true;
}

int GL_MSAA = 0;
int main(int argc, const char** argv)
{
#ifdef USE_SDL2
	SDL_Window *window = NULL;
	SDL_GLContext context = NULL;
	if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_JOYSTICK)==-1) {
		printf("Could not initialise SDL2: %s\n", SDL_GetError());
		exit(-1);
	}
#else
	SDL_Surface *screen = NULL;
	if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_JOYSTICK | SDL_INIT_EVENTTHREAD)==-1) {
		printf("Could not initialise SDL: %s\n", SDL_GetError());
		exit(-1);
	}
#endif
	atexit(SDL_Quit);

	TTF_Init();

	// crude command line parameter reading
	int nomsaa = 0;
	int fullscreen = 0;
	int desktop = 0;
	int givehelp = 0;

	for (int i=1; i<argc; i++) {
		if(!strcmp(argv[i], "-f"))
			fullscreen = 1;
		else if(!strcmp(argv[i], "--fullscreen"))
			fullscreen = 1;
		else if(!strcmp(argv[i], "-d"))
			desktop = 1;
		else if(!strcmp(argv[i], "--desktop"))
			desktop = 1;
		else if(!strcmp(argv[i], "-n"))
			nomsaa = 1;
		else if(!strcmp(argv[i], "--nomsaa"))
			nomsaa = 1;
		else givehelp = 1;
	}
	if(givehelp) {
		printf("Unrecognized parameter.\nOptions are:\n\t-f|--fullscreen\tUse fullscreen\n\t-n|--nomsaa\tDisable MSAA\n");
		exit(0);
	}

    SDL_GL_SetAttribute( SDL_GL_RED_SIZE, 5 );
    SDL_GL_SetAttribute( SDL_GL_GREEN_SIZE, 5 );
    SDL_GL_SetAttribute( SDL_GL_BLUE_SIZE, 5 );
    SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE, 16 );
    SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );

#ifdef PANDORA
	int revision = 5;
	FILE *f = fopen("/etc/powervr-esrev", "r");
	if (f) {
		fscanf(f, "%d", &revision);
		fclose(f);
		printf("Pandora Model detected = %d\n", revision);
	}
	if(revision==5 && !nomsaa) {
		// only do MSAA for Gigahertz model
		SDL_GL_SetAttribute( SDL_GL_MULTISAMPLEBUFFERS, 1);
		SDL_GL_SetAttribute( SDL_GL_MULTISAMPLESAMPLES, 2);
		GL_MSAA=1;
	}
#else
	if(!nomsaa) {
		SDL_GL_SetAttribute( SDL_GL_MULTISAMPLEBUFFERS, 1);
		SDL_GL_SetAttribute( SDL_GL_MULTISAMPLESAMPLES, 4);
		GL_MSAA=1;
	}
#endif
	int flags = 0;
	wideScreen = 0;
	int screenH, screenW, screenX, screenY;
#ifdef USE_SDL2
	flags = SDL_WINDOW_OPENGL;
#else
	flags = SDL_OPENGL | SDL_DOUBLEBUF;
#endif
	if(fullscreen)
#ifdef USE_SDL2
		flags |= SDL_WINDOW_FULLSCREEN;
#else
		flags |= SDL_FULLSCREEN;
#endif
#ifdef PANDORA
#ifdef USE_SDL2
		flags |= SDL_WINDOW_FULLSCREEN;
#else
	flags |= SDL_FULLSCREEN;
#endif
	screenW = 800; screenH = 480;
#elif defined(CHIP)
#ifdef USE_SDL2
		flags |= SDL_WINDOW_FULLSCREEN;
#else
	flags |= SDL_FULLSCREEN;
#endif
	screenW = 480; screenH = 272;
#else
	if(desktop || fullscreen) {
#ifdef USE_SDL2
		flags |= (desktop)?SDL_WINDOW_FULLSCREEN_DESKTOP:SDL_WINDOW_FULLSCREEN;
#else
		flags |= SDL_FULLSCREEN;
#endif
		if(desktop) {
#ifdef USE_SDL2
			screenW = 640;
			screenH = 480;
#else
			const SDL_VideoInfo* infos = SDL_GetVideoInfo();
			screenW = infos->current_w;
			screenH = infos->current_h;
#endif
		} else {
			screenW = 640;
			screenH = 480;
		}
	} else {
		screenW = 800;
		screenH = 480;
	}
#endif
#ifdef USE_SDL2
	window = SDL_CreateWindow("StuntCarRemake", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, screenW, screenH, flags);
	if(window==NULL && GL_MSAA) {
		// fallback to no MSAA
		GL_MSAA=0;
		SDL_GL_SetAttribute( SDL_GL_MULTISAMPLEBUFFERS, 0);
		SDL_GL_SetAttribute( SDL_GL_MULTISAMPLESAMPLES, 0);
		window = SDL_CreateWindow("StuntCarRemake", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, screenW, screenH, flags);
	}
	if(window==NULL) {
		printf("Couldn't create Window (%dx%d): %s\n", screenW, screenH, SDL_GetError());
		exit(-2);
	}
	context = SDL_GL_CreateContext(window);
	if(context==NULL) {
			printf("Couldn't create OpenGL Context: %s\n", SDL_GetError());
			exit(-3);
	}
	SDL_GetWindowSize(window, &screenW, &screenH);
#else
	screen = SDL_SetVideoMode( screenW, screenH, 32, flags );
    if ( screen == NULL ) {
		// fallback to no MSAA
		GL_MSAA=0;
		SDL_GL_SetAttribute( SDL_GL_MULTISAMPLEBUFFERS, 0);
		SDL_GL_SetAttribute( SDL_GL_MULTISAMPLESAMPLES, 0);
		screen = SDL_SetVideoMode( screenW, screenH, 32, flags );
    	if ( screen == NULL ) {
#ifdef PANDORA
			printf("Couldn't set 800x480x16 video mode: %s\n", SDL_GetError());
#else
			printf("Couldn't set %dx%dx32 video mode: %s\n", screenW, screenH, SDL_GetError());
#endif
        	exit(-2);
		}
    } else {
		glEnable(GL_MULTISAMPLE);
	}
#endif
	// automatic guess the scale
	float screenScale = 1.;
	if(screenW/640. < screenH/480.)
		screenScale = screenW/640.;
	else
		screenScale = screenH/480.;
	// is it a Wide screen ration?
	if((screenW/screenScale - 640)>=80)
		wideScreen=1;
	screenX = (screenW-(wideScreen?800.:640.)*screenScale)/2.;
	screenY = (screenH-480.*screenScale)/2.;
	screenW = (wideScreen?800:640)*screenScale;
	screenH = 480*screenScale;
#ifdef USE_SDL2
	if(flags&SDL_WINDOW_FULLSCREEN || flags&SDL_WINDOW_FULLSCREEN_DESKTOP)
#else
	if(flags&SDL_FULLSCREEN)
#endif
		SDL_ShowCursor(SDL_DISABLE);
	glViewport(screenX, screenY, screenW, screenH);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	screenH = 480;
	screenW = wideScreen?800:640;
	glOrtho(0, screenW, screenH, 0, 0, FURTHEST_Z);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glPixelStorei(GL_PACK_ALIGNMENT, 1);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

	IDirect3DDevice9 pd3dDevice;

    D3DXMATRIX matProj;
	FLOAT fAspect = screenW / 480.0f;
    D3DXMatrixPerspectiveFovLH( &matProj, D3DX_PI/4, fAspect, 0.5f, FURTHEST_Z );
    pd3dDevice.SetTransform( D3DTS_PROJECTION, &matProj );

	glEnable(GL_DEPTH_TEST);
	glAlphaFunc(GL_NOTEQUAL, 0);
//	glEnable(GL_ALPHA_TEST);
//	glShadeModel(GL_FLAT);
	glDisable(GL_LIGHTING);
	// Disable texture mapping by default (only DrawTrack() enables it)
	pd3dDevice.SetTextureStageState( 0, D3DTSS_COLOROP, D3DTOP_DISABLE );

	sound_init();

	double fLastTime = DXUTGetTime();

	CreateFonts();
	LoadTextures();

	if (!InitialiseData()) {
		printf("Error initialising data\n");
		exit(-3);
	}

	CreateBuffers(&pd3dDevice);

	DSInit();
	DSSetMode();

	bool run = true;
	glClearColor(0,0,0,1);
	double fTime;
	fLastTime = fTime = DXUTGetTime();
    while( run ) {
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		double fTime = DXUTGetTime();
		run = process_events();
		OnFrameMove( &pd3dDevice, fTime, fTime - fLastTime, NULL );
        OnFrameRender( &pd3dDevice, fTime, fTime - fLastTime, NULL );
#ifdef USE_SDL2
		SDL_GL_SwapWindow(window);
#else
		SDL_GL_SwapBuffers();
#endif

		int32_t timetowait = (1.0f/50.0f - (fTime-fLastTime))*1000;
		//int32_t timetowait = (1.0f/60.0f - (fTime-fLastTime))*1000;
		if (timetowait>0)
			SDL_Delay(timetowait);

		fLastTime = fTime;
    }

	FreeData();

	sound_destroy();
	TTF_Quit();
	SDL_Quit();
	
	exit(0);
}
#endif
