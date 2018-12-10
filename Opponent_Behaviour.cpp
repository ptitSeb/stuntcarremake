/**************************************************************************

  Opponent Behaviour.cpp - Functions relating to opponents's car behaviour

 **************************************************************************/


/*	============= */
/*	Include files */
/*	============= */
#include "dxstdafx.h"

#include <stdlib.h>

#include "StuntCarRacer.h"
#include "Opponent_Behaviour.h"
#include "Car_Behaviour.h"
#include "Track.h"
#include "3D_Engine.h"

/*	===== */
/*	Debug */
/*	===== */
//#define	TEST_AMIGA_RWP
//#define	TEST_AMIGA_OPI
//#define	TEST_AMIGA_MOTOS
//#define	TEST_AMIGA_ROS

#define	OPPONENT_SHADOW
//#define USE_OPP_CENTRE_POS
//#define CALC_FRONT_X_Z_FROM_SCRATCH

#if defined(DEBUG) || defined(_DEBUG)
extern FILE *out;
extern bool bTestKey;
#endif

/*	========= */
/*	Constants */
/*	========= */
#ifdef linux
#undef FALSE
#undef TRUE
#endif
#define	FALSE	0
#define	TRUE	1

#define	NUM_OPPONENTS	(11)
#define	NUM_X_SPANS		(32)

#define LOCAL_Y_FACTOR	4

extern float fTimeRatio;
extern float fTimeRatio2;
extern bool bFramePlain;

typedef enum
	{
	REAR_LEFT = 0,
	REAR_RIGHT,
	FRONT,
	NUM_OPP_WHEEL_POSITIONS
	} OppWheelPositionType;

/*	=========== */
/*	Global data */
/*	=========== */
long opponentsID = NO_OPPONENT;	// 0 to 10
long opponents_current_piece = 0;	// use as opponents_road_section

bool player_close_to_opponent = FALSE;
bool opponent_behind_player = FALSE;

extern bool bSuperLeague;
extern unsigned char sections_car_can_be_put_on[]; 				// both array are used for opponents speed values computation
extern char Piece_Angle_And_Template[MAX_PIECES_PER_TRACK];

// SEB: The opponents_speed_values, that is pre-computed, is not used anymore and Opponents_Speed_Value function is used now
// Values for each piece of each track (Global because MoveDrawBridge() modifies the Draw Bridge values)
// NOTE: These are for the Standard league.  Super league values are different
unsigned char opponents_speed_values[NUM_TRACKS][MAX_PIECES_PER_TRACK] =
{
	{
	/* Little Ramp data */
	0x76,0x6c,0x62,0x58,0x7a,0x7a,0x70,0x66,0x5c,0x52,0x48,0x48,0x48,0x7a,0x7a,0x7a,
	0x7a,0x7a,0x7a,0x7a,0x70,0x66,0x5c,0x52,0x48,0x48,0x48,0x48,0x78,0x6e,0x64,0x5a,
	0x50,0x46,0x7a,0x70,0x66,0x5c,0x52,0x48,0x48,0x48,0x48,0x7c
	},
	{
	/* Stepping Stones data */
	0xf2,0xe8,0xde,0xd4,0x67,0x5d,0x53,0x49,0x3f,0x4b,0x41,0x41,0xc1,0xd2,0xc8,0xbe,
	0xc7,0xbd,0xc5,0xbb,0xc4,0xba,0x55,0x4b,0x41,0x41,0x41,0x60,0x56,0x4c,0x42,0x7d,
	0x7d,0x73,0x69,0x5f,0x55,0x4b,0x41,0x41,0x41,0xfd,0xfd,0xfd,0xf3,0x7d,0x7d,0x73,
	0x69,0x5f,0x55,0x4b,0x41,0x41,0x41,0x7c
	},
	{
	/* Hump Back data */
	0x52,0x4d,0x77,0x77,0x77,0x6d,0x63,0x59,0x4f,0x45,0x45,0x45,0x77,0x77,0x77,0x77,
	0x77,0x77,0x77,0x6d,0x63,0x59,0x4f,0x45,0x45,0x45,0x56,0x4c,0x77,0x77,0x6d,0x63,
	0x59,0x4f,0x45,0x45,0x45,0x4f,0x61,0x57,0x4d,0x45,0x4f,0x45,0x45,0x63,0x59,0x4f,
	0x45,0x45,0x45,0x66,0x5c
	},
	{
	/* Big Ramp data */
	0x7a,0x7a,0x7a,0x7a,0x7a,0x7a,0x70,0x66,0x5c,0x52,0x48,0x48,0x48,0x58,0x4e,0x4b,
	0x69,0x5f,0x55,0x4b,0x46,0x66,0x5c,0x52,0x48,0x48,0x48,0x48,0x7e,0xf4,0xea,0xe0,
	0xd6,0x7a,0x7a,0x70,0x66,0x5c,0x52,0x48,0x48,0x48,0x48,0x7c
	},
	{
	/* Ski Jump data */
	0x42,0xec,0xe2,0xd8,0x77,0x77,0x77,0x6d,0x63,0x59,0x4f,0x4f,0x4f,0x4f,0x63,0x59,
	0x4f,0x4f,0x72,0x68,0x5e,0x54,0x4a,0x40,0x36,0x4f,0x4f,0x4f,0x6a,0xe0,0xd6,0xcc,
	0xc2,0x63,0x59,0x4f,0xcf,0xcf,0xcf,0xc9,0x56,0x56,0x56,0x7e,0x7e,0x7e,0x7e,0x7e,
	0x7e,0x74,0x6a,0x60,0x56,0x56,0x56,0x56,0x56,0x7e,0x7e,0x7e,0x7e,0x7e,0x7e,0x74,
	0x6a,0x60,0x56,0x56,0x56,0x7e,0x7e,0x74,0x6a,0x60,0x56,0x56,0x5a,0x52
	},
	{
	/* Draw Bridge data */
	0x76,0x76,0x6c,0x62,0x69,0x5f,0x55,0x50,0x58,0x58,0x58,0x76,0x76,0x76,0x6c,0x62,
	0x58,0x58,0x58,0x4d,0x43,0x76,0x76,0x76,0x76,0x76,0x6c,0x62,0x58,0x58,0x58,0x58,
	0x58,0x78,0x78,0x78,0x78,0x78,0x78,0x78,0x78,0x78,0xf8,0xee,0xe4,0x5a,0x50,0xc6,
	0x76,0x76,0x76,0xbb,0xbb,0x76,0x76,0x76,0x6c,0x62,0xd8,0xd8,0xd8,0xe4,0xf6,0xec,
	0xe2,0xd8,0x76,0x76,0x76,0x76,0x6c,0x62,0x58,0x58,0x58,0x58,0x58,0x7c
	},
	{
	/* High Jump data */
	0xe7,0xdd,0xd3,0x77,0x77,0x77,0x77,0x6d,0x63,0x59,0x4f,0x4f,0x4f,0x7a,0x7a,0x7a,
	0x7a,0x7a,0x70,0x66,0x5c,0x52,0x52,0x55,0x59,0x4f,0x4f,0x77,0x77,0x77,0x77,0x6d,
	0x63,0x59,0x4f,0x4f,0xcf,0xe7,0xdd,0xd3,0xce,0x77,0x77,0x77,0x77,0x6d,0x63,0x59,
	0x4f,0x4f,0x4f,0x7c,0x41,0x41,0x41,0x7c
	},
	{
	/* Roller Coaster data */
	0x66,0x5c,0x52,0x48,0x3e,0x34,0x2a,0x29,0x6a,0x60,0x56,0x56,0x56,0x40,0x36,0x7e,
	0x7e,0x7e,0x7e,0x7e,0x7e,0x74,0x6a,0x60,0x56,0x56,0x54,0x4a,0x7e,0x7e,0x7e,0x7e,
	0x7e,0x7e,0x7e,0x74,0x6a,0x60,0x56,0x56,0x56,0x56,0x56,0x7e,0x7e,0x7e,0x7e,0x7e,
	0x7e,0x74,0x6a,0x60,0x56,0x56,0x56,0x56,0x56,0x7e,0x7e,0x7e,0x7e,0x7e,0x7e,0x74,
	0x6a,0x60,0x56,0x56,0x56,0x7e,0x7e,0x74,0x6a,0x60,0x56,0x56,0x5a,0x52
	}
};

WCHAR *opponentNames[NUM_OPPONENTS] =
{
	L"Hot Rod     ",
	L"Whizz Kid   ",
	L"Bad Guy     ",
	L"The Dodger  ",
	L"Big Ed      ",
	L"Max Boost   ",
	L"Dare Devil  ",
	L"High Flyer  ",
	L"Bully Boy   ",
	L"Jumping Jack",
	L"Road Hog    "
};

extern IDirectSoundBuffer8 *HitCarSoundBuffer;

/*	=========== */
/*	Static data */
/*	=========== */
// Opponent attributes
#define OBSTRUCTS_PLAYER	2
#define	WHEELIE		4
#define	DRIVES_NEAR_EDGE	8
#define UNUSED4	16
#define PUSH_PLAYER	32
#define UNUSED6	64

static unsigned char opponent_attributes[NUM_OPPONENTS] =
{
// Hot Rod
PUSH_PLAYER|OBSTRUCTS_PLAYER,
// Whizz Kid
PUSH_PLAYER,
// Bad Guy
UNUSED6|PUSH_PLAYER|OBSTRUCTS_PLAYER,
// The Dodger
PUSH_PLAYER,
// Big Ed
PUSH_PLAYER|UNUSED4|DRIVES_NEAR_EDGE|WHEELIE|OBSTRUCTS_PLAYER,
// Max Boost
WHEELIE,
// Dare Devil
PUSH_PLAYER|UNUSED4,
// High Flyer
UNUSED4|WHEELIE,
// Bully Boy
UNUSED6|DRIVES_NEAR_EDGE|OBSTRUCTS_PLAYER,
// Jumping Jack
UNUSED4,
// Road Hog
DRIVES_NEAR_EDGE
};

// Values for each track
static unsigned char opp_track_speed_values[] =	//DAT.1fe2c
{
	// Standard league
	0x07,0x07,0x07,0x07,0x07,0x07,0x07,0x07,
	0x41,0x3a,0x3e,0x41,0x48,0x51,0x48,0x4f,
	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,	// used when creating opponents.speed.values
	0x48,0x41,0x45,0x48,0x4f,0x58,0x4f,0x56,	// used when creating opponents.speed.values

	// Super league
	0x07,0x03,0x03,0x03,0x03,0x03,0x07,0x03,
	0x66,0x57,0x57,0x59,0x59,0x69,0x62,0x64,
	0x07,0x03,0x03,0x03,0x03,0x01,0x03,0x03,	// used when creating opponents.speed.values
	0x61,0x55,0x53,0x56,0x58,0x5b,0x5a,0x62		// used when creating opponents.speed.values
};

static long opponents_distance_into_section;
static long opponents_road_x_position;

// Three co-ordinates needed for opponent behaviour (as per original Amiga StuntCarRacer)
static COORD_3D opp_rear_left_road_pos;
static COORD_3D opp_rear_right_road_pos;
static long opp_front_road_pos_y;	//X,Z not needed

// Additional co-ordinates needed for PC StuntCarRacer (for calculating opponent orientation)
static COORD_3D opp_front_left_road_pos;
static COORD_3D opp_front_right_road_pos;
#ifdef USE_OPP_CENTRE_POS
COORD_XZ opp_centre_road_pos;
#endif

static COORD_3D opp_shadow_rear_left;
static COORD_3D opp_shadow_rear_right;
static COORD_3D opp_shadow_front_left;
static COORD_3D opp_shadow_front_right;

// wheel heights
static long opp_actual_height[NUM_OPP_WHEEL_POSITIONS];

static long opp_smallest_difference;

static long opp_old_rear_left_difference;
static long opp_old_rear_right_difference;
static long opp_old_front_difference;

static long opp_new_rear_left_difference;
static long opp_new_rear_right_difference;
static long opp_new_front_difference;

static long opp_touching_road;

static long opp_y_acceleration[NUM_OPP_WHEEL_POSITIONS];
static long opp_y_speed[NUM_OPP_WHEEL_POSITIONS];

long opp_engine_power = 236;		// (236 standard, 314 super)
static long opponents_engine_z_acceleration;
static long opponents_max_speed;
static long opponents_z_speed;
static bool opponents_required_z_speed_reached;


/*	===================== */
/*	Function declarations */
/*	===================== */
static void ResetOpponent (void);
static void CalculateOpponentsRoadWheelPositions( void );
static void GetSurfaceCoords( long piece, long segment );
static long CalcSurfacePosition( long *next_segment, long distance, long z_shift );
static void CalculateOpponentsRoadWheelHeight( long sx, long sz, long *y_out );
static void OpponentMovement( void );

static void UpdateOpponentsActualWheelHeights( void );
static void CalculateWheelDifference( long road_height,
									  long actual_height,
									  long height_adjust,
									  long *old_difference_in_out,
									  long *new_difference_out,
									  long *touching_road);
static long LimitOpponentWheels( long max_difference, long wheel1, long wheel2 );
static void AverageWheelYSpeeds( long wheel1, long wheel2 );

static void RandomizeOpponentsSteering( void );

static void GetOpponentsEngineAcceleration( void );
static void AdjustOpponentsEngineAcceleration( void );
static void UpdateOpponentsZSpeed( void );

static void CalculateDistancesBetweenPlayers( void );

static void OpponentPlayerInteraction( void );
static void MoveOpponentToOneSide( void );
static void OpponentPushPlayer( void );


/*	======================================================================================= */
/*	Function:		ResetOpponent															*/
/*																							*/
/*	Description:	Reset all opponent behaviour variables to their initial state			*/
/*	======================================================================================= */

static void ResetOpponent (void)
	{
	opponentsID = rand() % NUM_OPPONENTS;
//	opponentsID = 9;	// Jumping Jack

	opp_old_rear_left_difference = 0;
	opp_old_rear_right_difference = 0;
	opp_old_front_difference = 0;

	for (long i = 0; i < NUM_OPP_WHEEL_POSITIONS; i++)
	{
		opp_y_speed[i] = 0;
	}

	opponents_z_speed = 0;
	opponents_required_z_speed_reached = FALSE;

	player_close_to_opponent = FALSE;
	opponent_behind_player = FALSE;
	return;
	}

/*	======================================================================================= */
/*	Function:		OpponentBehaviour														*/
/*																							*/
/*	Description:							*/
/*	======================================================================================= */

extern bool bNewGame;
extern long TrackID;
extern TRACK_PIECE Track[MAX_PIECES_PER_TRACK];
extern long Track_Map[NUM_TRACK_CUBES][NUM_TRACK_CUBES];	// [x][z]
extern long NumTrackPieces;
extern long PlayersStartPiece;

//#define USE_ROAD_Y
#define NEW_OPP_METHOD
// current surface co-ords
static long sx1, sy1, sz1, sx2, sy2, sz2, sx3, sy3, sz3, sx4, sy4, sz4;

void OpponentBehaviour (long *x,
						long *y,
						long *z,
						float *x_angle,
						float *y_angle,
						float *z_angle,
						bool bOpponentPaused)
{
	long opponent_x, opponent_y, opponent_z;
	float opponent_x_angle = 0.0f, opponent_y_angle = 0.0f, opponent_z_angle = 0.0f;

	// reset opponent
	if (bNewGame)
		{
		ResetOpponent();

		opponents_current_piece = PlayersStartPiece;
		opponents_distance_into_section = 0x400;	// half way into section
		opponents_road_x_position = 0x4c;
//temp		opponents_road_x_position = 0x1c;
//temp		opponents_road_x_position = 0xe4;

		// initialise.opponent.data
		CalculateOpponentsRoadWheelPositions();
		// Position the opponent a random amount above the road
		int r = rand();
		r &= 0x7f;
		r += 0x68;
		opp_actual_height[REAR_LEFT] = opp_rear_left_road_pos.y + r;
		opp_actual_height[REAR_RIGHT] = opp_rear_right_road_pos.y + r;
		opp_actual_height[FRONT] = opp_front_road_pos_y + r;
		// end initialise.opponent.data

		// Set opponent_max_speed
		long s = (long)rand() & (long)opp_track_speed_values[TrackID+(bSuperLeague?32:0)];
		s += (long)opp_track_speed_values[TrackID+8+(bSuperLeague?32:0)];
		opponents_max_speed = s;
//temp		opponents_max_speed = 10;

		bNewGame = FALSE;
		}


	CalculatePlayersRoadPosition();
	if (!bOpponentPaused)
	{
		OpponentMovement();
		CalculateDistancesBetweenPlayers();
		OpponentPlayerInteraction();
	}
	else
		CalculateDistancesBetweenPlayers();

	CalculateOpponentsRoadWheelPositions();

	//
	// Calculate opponent's new centre point ...
	//

	/*
	 * Calculate opponent's x position
	 */
	opponent_x = (opp_front_left_road_pos.x + opp_front_right_road_pos.x + opp_rear_left_road_pos.x + opp_rear_right_road_pos.x) / 4;
	opponent_x <<= LOG_PRECISION;

#ifdef USE_OPP_CENTRE_POS
//	VALUE1 = (bTestKey ? 1 : 0);
	VALUE2 = VALUE3 = 0;
	if (bTestKey)
	{
		VALUE2 = opponent_x;
		opponent_x = opp_centre_road_pos.x;
		opponent_x <<= LOG_PRECISION;
		VALUE3 = opponent_x;
	}
#endif

	/*
	 * Calculate opponent's y position
	 */
#ifdef NEW_OPP_METHOD
	long vis_rear_left_y, vis_rear_right_y, vis_front_y;
	vis_rear_left_y = opp_rear_left_road_pos.y > opp_actual_height[REAR_LEFT] ? opp_rear_left_road_pos.y : opp_actual_height[REAR_LEFT];
	vis_rear_right_y = opp_rear_right_road_pos.y > opp_actual_height[REAR_RIGHT] ? opp_rear_right_road_pos.y : opp_actual_height[REAR_RIGHT];
	vis_front_y = opp_front_road_pos_y > opp_actual_height[FRONT] ? opp_front_road_pos_y : opp_actual_height[FRONT];
	long rear_y = (vis_rear_left_y + vis_rear_right_y) / 2;
	opponent_y = (rear_y + vis_front_y) / 2;
#else
	long road_y = (opp_rear_left_road_pos.y + opp_rear_right_road_pos.y) / 2;
	road_y = (road_y + opp_front_road_pos_y) / 2;
	#ifdef USE_ROAD_Y
	long rear_y = (opp_rear_left_road_pos.y + opp_rear_right_road_pos.y) / 2;
	opponent_y = (rear_y + opp_front_road_pos_y) / 2;
	#else
	long rear_y = (opp_actual_height[REAR_LEFT] + opp_actual_height[REAR_RIGHT]) / 2;
	opponent_y = (rear_y + opp_actual_height[FRONT]) / 2;
	#endif
	if (opponent_y < road_y) opponent_y = road_y;
#endif

	// Raise the opponent slightly (to stop them sinking into road due to inaccurate heights)
	opponent_y += 20;
	opponent_y <<= (LOG_PRECISION-3);

	/*
	 * Calculate opponent's z position
	 */
	opponent_z = (opp_front_left_road_pos.z + opp_front_right_road_pos.z + opp_rear_left_road_pos.z + opp_rear_right_road_pos.z) / 4;
	opponent_z <<= LOG_PRECISION;

#ifdef USE_OPP_CENTRE_POS
	if (bTestKey)
	{
		opponent_z = opp_centre_road_pos.z;
		opponent_z <<= LOG_PRECISION;
	}
#endif

	//
	// Calculate opponent's new angles
	//

	// Along car's x axis, only use y and z components
#ifdef USE_ROAD_Y
	double yd = (double)(rear_y - opp_front_road_pos_y) / 2;	// Note y is halved because of unit differences between y and x,z
#else
	#ifdef NEW_OPP_METHOD
	double yd = (double)(rear_y - vis_front_y) / 2;	// Note y is halved because of unit differences between y and x,z
	#else
	double yd = (double)(rear_y - opp_actual_height[FRONT]) / 2;	// Note y is halved because of unit differences between y and x,z
	#endif
#endif
	long rear_x = (opp_rear_left_road_pos.x + opp_rear_right_road_pos.x) / 2;
	long rear_z = (opp_rear_left_road_pos.z + opp_rear_right_road_pos.z) / 2;
	long front_x = (opp_front_left_road_pos.x + opp_front_right_road_pos.x) / 2;
	long front_z = (opp_front_left_road_pos.z + opp_front_right_road_pos.z) / 2;
	double xd = (double)(rear_x - front_x);
	double zd = (double)(rear_z - front_z);
	double carzd = sqrt((xd*xd) + (zd*zd));
	opponent_x_angle = (float)atan2(yd, carzd);

	// Along car's y axis, only use x and z components
	xd = (double)(opp_rear_left_road_pos.x - opp_rear_right_road_pos.x);
	zd = (double)(opp_rear_left_road_pos.z - opp_rear_right_road_pos.z);
//	opponent_y_angle = (float)atan2(xd, zd) + D3DX_PI/2;
	opponent_y_angle = (float)atan2(zd, -xd);

	// Along car's z axis, only use x and y components
#ifdef USE_ROAD_Y
	yd = (double)(opp_rear_left_road_pos.y - opp_rear_right_road_pos.y) / 2;	// Note y is halved because of unit differences between y and x,z
#else
	#ifdef NEW_OPP_METHOD
	yd = (double)(vis_rear_left_y - vis_rear_right_y) / 2;	// Note y is halved because of unit differences between y and x,z
	#else
	yd = (double)(opp_actual_height[REAR_LEFT] - opp_actual_height[REAR_RIGHT]) / 2;	// Note y is halved because of unit differences between y and x,z
	#endif
#endif
	double carxd = sqrt((xd*xd) + (zd*zd));
	opponent_z_angle = (float)atan2(-yd, carxd);

	// output opponent values for use by functions that draw the world
	*x = opponent_x;
	*y = -(opponent_y * LOCAL_Y_FACTOR);
	*z = opponent_z;
	*x_angle = opponent_x_angle;
	*y_angle = opponent_y_angle;
	*z_angle = opponent_z_angle;
}

/*	======================================================================================= */
/*	Function:		CalculateOpponentsRoadWheelPositions									*/
/*																							*/
/*	Description:							*/
/*	======================================================================================= */

// current surface co-ords
//static long sx1, sy1, sz1, sx2, sy2, sz2, sx3, sy3, sz3, sx4, sy4, sz4;

static long B1bbbe[3] = {0,0,0};	// set by randomize.opponents.steering
									// third value is opponents.random.steering.count

static long opponents_x_spans[NUM_X_SPANS] =
{27,27,27,27,27,26,26,26,25,25,25,24,23,23,22,21,20,19,18,17,15,14,11,9,7,7,7,7,7,7,7,7};

#ifdef OPPONENT_SHADOW
extern void RemoveShadowTriangles( void );
extern void StoreShadowTriangle( D3DXVECTOR3 v1, D3DXVECTOR3 v2, D3DXVECTOR3 v3, long other_colour );
#endif


// All three road heights tested against Amiga
static void CalculateOpponentsRoadWheelPositions( void )
{
long distance, segment, surface_position;
long piece = opponents_current_piece, next_segment;
long left_side_x, left_side_z, right_side_x, right_side_z;
bool draw_shadow = TRUE;

	/*
	 * Rear wheels
	 */
#ifdef	TEST_AMIGA_RWP
	if (GetRecordedAmigaWord(&piece))
		++VALUE2;
	GetRecordedAmigaWord(&opponents_distance_into_section);
	GetRecordedAmigaWord(&opponents_road_x_position);
	GetRecordedAmigaWord(&opp_actual_height[REAR_LEFT]);
	GetRecordedAmigaWord(&opp_actual_height[REAR_RIGHT]);
	GetRecordedAmigaWord(&opp_actual_height[FRONT]);
#endif
	// Rear wheel position
	distance = opponents_distance_into_section - 64;
	if (distance < 0)
	{
		// DIRECTION DEPENDANT

		// go to previous piece
		piece--; if (piece < 0) piece = (NumTrackPieces - 1);

		distance += (Track[piece].numSegments * 256);
	}
#ifdef	TEST_AMIGA_RWP
	CompareRecordedAmigaWord("opponents.road.section.m64", &piece);
	CompareRecordedAmigaWord("opponents.distance.into.section.minus64", &distance);
#endif
	// Fetch 4 surface co-ords surrounding rear wheels (opponents.distance.into.section.minus64 / 256)
	segment = distance >> 8;
	GetSurfaceCoords(piece, segment);
	// Don't draw opponent's shadow on black road segments
	if (Track[piece].roadColour[segment] == SCR_BASE_COLOUR + 0)
		draw_shadow = FALSE;

	// Calculate segment left side x,z at opponents.distance.into.section.minus64
	surface_position = CalcSurfacePosition(&next_segment, distance, B1bbbe[0]);
	if (!next_segment)
	{
		left_side_x = sx2 + ((surface_position * (sx1-sx2)) >> 8);
		left_side_z = sz2 + ((surface_position * (sz1-sz2)) >> 8);
	}
	else
	{
		// Use other end's value as base
		// (Amiga StuntCarRacer does this, but not correct as should really use next segment's values)
		left_side_x = sx1 + ((surface_position * (sx1-sx2)) >> 8);
		left_side_z = sz1 + ((surface_position * (sz1-sz2)) >> 8);
	}

	// Calculate segment right side x,z at opponents.distance.into.section.minus64
	surface_position = CalcSurfacePosition(&next_segment, distance, B1bbbe[2]);
	if (!next_segment)
	{
		right_side_x = sx3 + ((surface_position * (sx4-sx3)) >> 8);
		right_side_z = sz3 + ((surface_position * (sz4-sz3)) >> 8);
	}
	else
	{
		// Use other end's value as base
		// (Amiga StuntCarRacer does this, but not correct as should really use next segment's values)
		right_side_x = sx4 + ((surface_position * (sx4-sx3)) >> 8);
		right_side_z = sz4 + ((surface_position * (sz4-sz3)) >> 8);
	}

	next_segment = FALSE;
	long i = abs(opp_actual_height[REAR_LEFT] - opp_actual_height[REAR_RIGHT]) >> 4;
	// Get half the x distance that the opponent's rear wheels span
	if (i < 0) i = 0;
	if (i >= NUM_X_SPANS) i = NUM_X_SPANS-1;
	long opponents_x_span = opponents_x_spans[i];

	// For calculating the opponent's shadow co-ordinates, the original StuntCarRacer spans are slightly
	// too big, so need to be reduced to take into account the greater width of sloped segments
	long xd = right_side_x - left_side_x;
	long yd = (sy3 - sy2) / LOCAL_Y_FACTOR;
	long zd = right_side_z - left_side_z;
	long base_width = (long)(sqrt((double)((xd*xd) + (zd*zd))));
	long slope_width = (long)(sqrt((double)((base_width*base_width) + (yd*yd))));
	long opponents_shadow_x_span = (opponents_x_span * base_width) / slope_width;
//	if (!bTestKey)
//		opponents_shadow_x_span = opponents_x_span;

	long sx, sz;
	sz = distance & 0xff;	// z position of rear wheels

	// Calculate rear left road co-ordinate (as per Amiga opp.rear.left.road.height)
	sx = opponents_road_x_position - opponents_x_span;	// x position of rear left wheel
	CalculateOpponentsRoadWheelHeight(sx, sz, &opp_rear_left_road_pos.y);
	opp_rear_left_road_pos.x = left_side_x + ((sx * xd) >> 8);
	opp_rear_left_road_pos.z = left_side_z + ((sx * zd) >> 8);
#ifdef	TEST_AMIGA_RWP
	CompareRecordedAmigaWord("opp.rear.left.road.height", &opp_rear_left_road_pos.y);
#endif
	// Calculate rear left shadow co-ordinate
	sx = opponents_road_x_position - opponents_shadow_x_span;
	CalculateOpponentsRoadWheelHeight(sx, sz, &opp_shadow_rear_left.y);
	opp_shadow_rear_left.x = left_side_x + ((sx * xd) >> 8);
	opp_shadow_rear_left.z = left_side_z + ((sx * zd) >> 8);

	// Calculate rear right road co-ordinate (as per Amiga opp.rear.right.road.height)
	sx = opponents_road_x_position + opponents_x_span;	// x position of rear right wheel
	CalculateOpponentsRoadWheelHeight(sx, sz, &opp_rear_right_road_pos.y);
	opp_rear_right_road_pos.x = left_side_x + ((sx * xd) >> 8);
	opp_rear_right_road_pos.z = left_side_z + ((sx * zd) >> 8);
#ifdef	TEST_AMIGA_RWP
	CompareRecordedAmigaWord("opp.rear.right.road.height", &opp_rear_right_road_pos.y);
#endif
	// Calculate rear right shadow co-ordinate
	sx = opponents_road_x_position + opponents_shadow_x_span;
	CalculateOpponentsRoadWheelHeight(sx, sz, &opp_shadow_rear_right.y);
	opp_shadow_rear_right.x = left_side_x + ((sx * xd) >> 8);
	opp_shadow_rear_right.z = left_side_z + ((sx * zd) >> 8);


	long piece_x, piece_y, piece_z;
	// Calculate position of piece's bottom front left corner, within world
	piece_x = Track[piece].x << (LOG_CUBE_SIZE-LOG_PRECISION);
	piece_y = Track[piece].y << (LOG_CUBE_SIZE-LOG_PRECISION);
	piece_z = Track[piece].z << (LOG_CUBE_SIZE-LOG_PRECISION);
	// Position rear road co-ordinates within world
	opp_rear_left_road_pos.x += piece_x;
	opp_rear_right_road_pos.x += piece_x;
	opp_rear_left_road_pos.z += piece_z;
	opp_rear_right_road_pos.z += piece_z;
	// Position rear shadow co-ordinates within world
	opp_shadow_rear_left.x += piece_x;
	opp_shadow_rear_right.x += piece_x;
	opp_shadow_rear_left.z += piece_z;
	opp_shadow_rear_right.z += piece_z;


//****************


#ifdef USE_OPP_CENTRE_POS
	long cdistance = opponents_distance_into_section;
	// Fetch 4 surface co-ords surrounding centre point
	segment = cdistance >> 8;
	GetSurfaceCoords(opponents_current_piece, segment);

	surface_position = cdistance & 0xff;
	left_side_x = sx2 + ((surface_position * (sx1-sx2)) >> 8);
	left_side_z = sz2 + ((surface_position * (sz1-sz2)) >> 8);

	right_side_x = sx3 + ((surface_position * (sx4-sx3)) >> 8);
	right_side_z = sz3 + ((surface_position * (sz4-sz3)) >> 8);

	sx = opponents_road_x_position & 0xff;	// x position of front wheel

	// Calculate centre road x,z co-ordinates
	opp_centre_road_pos.x = left_side_x + ((sx * (right_side_x-left_side_x)) >> 8);
	opp_centre_road_pos.z = left_side_z + ((sx * (right_side_z-left_side_z)) >> 8);

	// Calculate position of piece's bottom front left corner, within world
	piece_x = Track[opponents_current_piece].x << (LOG_CUBE_SIZE-LOG_PRECISION);
	piece_z = Track[opponents_current_piece].z << (LOG_CUBE_SIZE-LOG_PRECISION);
	// Position centre road co-ordinates within world
	opp_centre_road_pos.x += piece_x;
	opp_centre_road_pos.z += piece_z;
#endif


//****************


	/*
	 * Front wheels
	 */
	long diff, xdiff, zdiff;

	// Calculate front left and right road x,z co-ordinates
	diff = opp_rear_right_road_pos.x - opp_rear_left_road_pos.x;
	xdiff = diff + (diff >> 1);	// car length is 1.5 times width
	diff = opp_rear_right_road_pos.z - opp_rear_left_road_pos.z;
	zdiff = diff + (diff >> 1);	// car length is 1.5 times width
	opp_front_left_road_pos.x = opp_rear_left_road_pos.x - zdiff;
	opp_front_left_road_pos.z = opp_rear_left_road_pos.z + xdiff;
	opp_front_right_road_pos.x = opp_rear_right_road_pos.x - zdiff;
	opp_front_right_road_pos.z = opp_rear_right_road_pos.z + xdiff;
	/* Don't need to add piece_x,piece_z as already have world position (from rear wheels) */

	// Calculate front left and right shadow x,z co-ordinates
	diff = opp_shadow_rear_right.x - opp_shadow_rear_left.x;
	xdiff = diff + (diff >> 1);	// car length is 1.5 times width
	diff = opp_shadow_rear_right.z - opp_shadow_rear_left.z;
	zdiff = diff + (diff >> 1);	// car length is 1.5 times width
	opp_shadow_front_left.x = opp_shadow_rear_left.x - zdiff;
	opp_shadow_front_left.z = opp_shadow_rear_left.z + xdiff;
	opp_shadow_front_right.x = opp_shadow_rear_right.x - zdiff;
	opp_shadow_front_right.z = opp_shadow_rear_right.z + xdiff;
	/* Don't need to add piece_x,piece_z as already have world position (from rear wheels) */


	// Add 128 to get z of opponent's front
	distance += 128;
	if (distance >= (Track[piece].numSegments * 256))
	{
		// DIRECTION DEPENDANT

		distance -= (Track[piece].numSegments * 256);

		// go to next piece
		piece++; if (piece > (NumTrackPieces - 1)) piece = 0;
	}
	// Fetch 4 surface co-ords surrounding front wheels
	segment = distance >> 8;
	GetSurfaceCoords(piece, segment);
	// Don't draw opponent's shadow on black road segments
	if (Track[piece].roadColour[segment] == SCR_BASE_COLOUR + 0)
		draw_shadow = FALSE;

	/* temporary code
#ifdef	TEST_AMIGA_RWP
	long tsx, tsz, ty1, ty2, ty3, ty4;
	GetRecordedAmigaWord(&tsx);
	GetRecordedAmigaWord(&tsz);
	GetRecordedAmigaWord(&ty1);
	GetRecordedAmigaWord(&ty2);
	GetRecordedAmigaWord(&ty3);
	GetRecordedAmigaWord(&ty4);
#endif
	*/

	sz = distance & 0xff;	// z position of front wheel
	sx = opponents_road_x_position & 0xff;	// x position of front wheel

	// Calculate front road y co-ordinate (as per Amiga opp.front.road.height)
	CalculateOpponentsRoadWheelHeight(sx, sz, &opp_front_road_pos_y);
#ifdef	TEST_AMIGA_RWP
	CompareRecordedAmigaWord("opp.front.road.height", &opp_front_road_pos_y);
#endif

	// Calculate front left road y co-ordinate
	sx = opponents_road_x_position - opponents_x_span;	// x position of front left wheel
	CalculateOpponentsRoadWheelHeight(sx, sz, &opp_front_left_road_pos.y);

	// Calculate front right road y co-ordinate
	sx = opponents_road_x_position + opponents_x_span;	// x position of front right wheel
	CalculateOpponentsRoadWheelHeight(sx, sz, &opp_front_right_road_pos.y);

#ifdef CALC_FRONT_X_Z_FROM_SCRATCH
	VALUE1 = VALUE2 = 0;
	if (bTestKey)
	{
		VALUE1 = opp_front_right_road_pos.x;
		surface_position = sz;
		left_side_x = sx2 + ((surface_position * (sx1-sx2)) >> 8);
		left_side_z = sz2 + ((surface_position * (sz1-sz2)) >> 8);

		right_side_x = sx3 + ((surface_position * (sx4-sx3)) >> 8);
		right_side_z = sz3 + ((surface_position * (sz4-sz3)) >> 8);

		xd = right_side_x - left_side_x;
		zd = right_side_z - left_side_z;

		sx = opponents_road_x_position - opponents_x_span;	// x position of front left wheel
		opp_front_left_road_pos.x = left_side_x + ((sx * xd) >> 8);
		opp_front_left_road_pos.z = left_side_z + ((sx * zd) >> 8);

		sx = opponents_road_x_position + opponents_x_span;	// x position of front right wheel
		opp_front_right_road_pos.x = left_side_x + ((sx * xd) >> 8);
		opp_front_right_road_pos.z = left_side_z + ((sx * zd) >> 8);

		// Calculate position of piece's bottom front left corner, within world
		piece_x = Track[piece].x << (LOG_CUBE_SIZE-LOG_PRECISION);
		piece_y = Track[piece].y << (LOG_CUBE_SIZE-LOG_PRECISION);
		piece_z = Track[piece].z << (LOG_CUBE_SIZE-LOG_PRECISION);
		// Position front road co-ordinates within world
		opp_front_left_road_pos.x += piece_x;
		opp_front_left_road_pos.z += piece_z;
		opp_front_right_road_pos.x += piece_x;
		opp_front_right_road_pos.z += piece_z;
		VALUE2 = opp_front_right_road_pos.x;
	}
#endif

#ifdef OPPONENT_SHADOW
	// Calculate front left shadow y co-ordinate
	sx = opponents_road_x_position - opponents_shadow_x_span;
	CalculateOpponentsRoadWheelHeight(sx, sz, &opp_shadow_front_left.y);

	// Calculate front right shadow y co-ordinate
	sx = opponents_road_x_position + opponents_shadow_x_span;
	CalculateOpponentsRoadWheelHeight(sx, sz, &opp_shadow_front_right.y);

	// Y co-ordinates need to be divided by 4 for display, but they're
	// already /2 because are in Amiga format (i.e. not * PC_FACTOR).
	// Also add 7 to y so that shadow is slightly above road and isn't clipped as much
	D3DXVECTOR3 v1, v2, v3, v4;
	v2 = D3DXVECTOR3( (float)opp_shadow_rear_left.x, 7 + (float)opp_shadow_rear_left.y/2, (float)opp_shadow_rear_left.z );
	v3 = D3DXVECTOR3( (float)opp_shadow_rear_right.x, 7 + (float)opp_shadow_rear_right.y/2, (float)opp_shadow_rear_right.z );

	v1 = D3DXVECTOR3( (float)opp_shadow_front_left.x, 7 + (float)opp_shadow_front_left.y/2, (float)opp_shadow_front_left.z );
	v4 = D3DXVECTOR3( (float)opp_shadow_front_right.x, 7 + (float)opp_shadow_front_right.y/2, (float)opp_shadow_front_right.z );

	RemoveShadowTriangles();
	if (draw_shadow)
	{
		StoreShadowTriangle(v2, v1, v3, 0);
		StoreShadowTriangle(v1, v4, v3, 0);
	}
#endif

//	VALUE1 = opp_rear_left_road_pos.y;
//	VALUE2 = opp_front_road_pos_y;
//	VALUE3 = opp_rear_right_road_pos.y;
	return;
}


static void GetSurfaceCoords( long piece, long segment )
{
	if ((segment < 0) || (segment >= Track[piece].numSegments))
	{
		MessageBox(NULL, L"GetSurfaceCoords(opponent) segment out of range", L"Error", MB_OK);
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(out, "GetSurfaceCoords(opponent) piece %d, segment %d, numSegments %d\n", piece, segment, Track[piece].numSegments);
#endif
	}

	sx2 = Track[piece].coords[(segment*4)].x;
	sy2 = Track[piece].coords[(segment*4)].y;
	sz2 = Track[piece].coords[(segment*4)].z;

	sx3 = Track[piece].coords[(segment*4)+1].x;
	sy3 = Track[piece].coords[(segment*4)+1].y;
	sz3 = Track[piece].coords[(segment*4)+1].z;

	segment++;
	sx1 = Track[piece].coords[(segment*4)].x;
	sy1 = Track[piece].coords[(segment*4)].y;
	sz1 = Track[piece].coords[(segment*4)].z;

	sx4 = Track[piece].coords[(segment*4)+1].x;
	sy4 = Track[piece].coords[(segment*4)+1].y;
	sz4 = Track[piece].coords[(segment*4)+1].z;
	return;
}


static long CalcSurfacePosition( long *next_segment, long distance, long z_shift )
{
long surface_position = distance & 0xff;

	*next_segment = FALSE;
	surface_position += z_shift;
	if (surface_position >= 256)
	{
		*next_segment = TRUE;
		surface_position &= 0xff;
	}

	return(surface_position);
}


static void CalculateOpponentsRoadWheelHeight( long sx, long sz, long *y_out )
{
long sya, syb, y;

	// calculate height of surface at x,z position using linear interpolation

	// i.e. calculate y at offset (sx, sz)
	//		given (sx1, sy1, sz1)
	//			  (sx2, sy2, sz2)
	//			  (sx3, sy3, sz3)
	//			  (sx4, sy4, sz4)

	// first do x interpolation
	sya = sy1 + ((sx * (sy4-sy1)) >> 8);
	syb = sy2 + ((sx * (sy3-sy2)) >> 8);

	// now do z interpolation
	y = (syb << 8) + (sz * (sya-syb));

	*y_out = y >> 9;
	return;
}


/*	======================================================================================= */
/*	Function:		OpponentMovement														*/
/*																							*/
/*	Description:							*/
/*	======================================================================================= */

extern bool drop_start_done;


// Tested against Amiga
static void OpponentMovement( void )
{
static long byte_count = 0;

	if (!drop_start_done)
		return;

	UpdateOpponentsActualWheelHeights();
	/*
	//temp
	opp_actual_height[REAR_LEFT] = opp_rear_left_road_pos.y;
	opp_actual_height[REAR_RIGHT] = opp_rear_right_road_pos.y;
	opp_actual_height[FRONT] = opp_front_road_pos_y;
	*/
	if(bFramePlain) {
		RandomizeOpponentsSteering();
		GetOpponentsEngineAcceleration();
		AdjustOpponentsEngineAcceleration();
#ifdef TEST_AMIGA_AOEA
		long temp;
		if (GetRecordedAmigaWord(&temp))
		{
			bool flag = temp & 0x80 ? TRUE : FALSE;
			if (flag != opponents_required_z_speed_reached)
			{
				++VALUE1;	// Count differences
				fprintf(out, "%s different %d %d (VALUE2 %d)\n", "opponents.required.z.speed.reached", temp, opponents_required_z_speed_reached, VALUE2);
				opponents_required_z_speed_reached = flag;	// Use Amiga value when different
			}
		}
		CompareRecordedAmigaWord("opponents.engine.z.acceleration", &opponents_engine_z_acceleration);
#endif
		UpdateOpponentsZSpeed();


#ifdef TEST_AMIGA_OM
		if (GetRecordedAmigaWord(&opponents_z_speed))
			++VALUE2;

		GetRecordedAmigaWord(&opponents_current_piece);
		GetRecordedAmigaWord(&byte_count);
		GetRecordedAmigaWord(&opponents_distance_into_section);
#endif
	}	//bFramePlain
	// TO DO: Tidy up
	long value = ((long)(opponents_z_speed * fTimeRatio) * (Track[opponents_current_piece].lengthReduction << 7)) << 1;
	value >>= 16;
	value *= REDUCTION;
	value >>= 8;
	value <<= 3;
	long byte = value & 0xff;
	value >>= 8;
	byte_count += byte;
	if (byte_count > 0xff)
	{
		++value;
		byte_count &= 0xff;
	}
	opponents_distance_into_section += value;
	

	if (opponents_distance_into_section >= (Track[opponents_current_piece].numSegments * 256))
	{
		// DIRECTION DEPENDANT

		opponents_distance_into_section -= (Track[opponents_current_piece].numSegments * 256);

		// go to next piece
		opponents_current_piece++;
		if (opponents_current_piece > (NumTrackPieces - 1)) opponents_current_piece = 0;
	}

#ifdef TEST_AMIGA_OM
	if(bFramePlain) {
		CompareRecordedAmigaWord("opponents.road.section", &opponents_current_piece);
		CompareRecordedAmigaWord("opponents.distance.into.section", &opponents_distance_into_section);
	}
#endif
}


/*	======================================================================================= */
/*	Function:		UpdateOpponentsActualWheelHeights										*/
/*																							*/
/*	Description:							*/
/*	======================================================================================= */

// Tested against Amiga
static void UpdateOpponentsActualWheelHeights( void )
{
long height_adjust, touching_road, total_diff, i, acceleration, speed;

	if(bFramePlain) {
	opp_smallest_difference = -32768;

#ifdef	TEST_AMIGA_AWH
	if (GetRecordedAmigaWord(&opponentsID))
		++VALUE2;
	GetRecordedAmigaWord(&opponents_current_piece);
	GetRecordedAmigaWord(&opp_rear_left_road_pos.y);
	GetRecordedAmigaWord(&opp_rear_right_road_pos.y);
	GetRecordedAmigaWord(&opp_front_road_pos_y);

	GetRecordedAmigaWord(&opp_actual_height[REAR_LEFT]);
	GetRecordedAmigaWord(&opp_actual_height[REAR_RIGHT]);
	GetRecordedAmigaWord(&opp_actual_height[FRONT]);

	GetRecordedAmigaWord(&opp_old_rear_left_difference);
	GetRecordedAmigaWord(&opp_old_rear_right_difference);
	GetRecordedAmigaWord(&opp_old_front_difference);
#endif

	if (Track[opponents_current_piece].type & 0x80)	// curve
		height_adjust = 124;	// increase collision when on a curve
	else
		height_adjust = 40;

#ifdef	TEST_AMIGA_AWH
	CompareRecordedAmigaWord("height.adjust", &height_adjust);
#endif

	touching_road = 0;

	CalculateWheelDifference(opp_rear_left_road_pos.y,
							 opp_actual_height[REAR_LEFT],
							 height_adjust,
							 &opp_old_rear_left_difference,
							 &opp_new_rear_left_difference,
							 &touching_road);

	CalculateWheelDifference(opp_rear_right_road_pos.y,
							 opp_actual_height[REAR_RIGHT],
							 height_adjust,
							 &opp_old_rear_right_difference,
							 &opp_new_rear_right_difference,
							 &touching_road);

	CalculateWheelDifference(opp_front_road_pos_y,
							 opp_actual_height[FRONT],
							 height_adjust,
							 &opp_old_front_difference,
							 &opp_new_front_difference,
							 &touching_road);

	if (touching_road)
		opp_touching_road = TRUE;
	else
		opp_touching_road = FALSE;

#ifdef	TEST_AMIGA_AWH
	CompareRecordedAmigaWord("opp.old.rear.left.difference", &opp_old_rear_left_difference);
	CompareRecordedAmigaWord("opp.old.rear.right.difference", &opp_old_rear_right_difference);
	CompareRecordedAmigaWord("opp.old.front.difference", &opp_old_front_difference);

	CompareRecordedAmigaWord("opp.new.rear.left.difference", &opp_new_rear_left_difference);
	CompareRecordedAmigaWord("opp.new.rear.right.difference", &opp_new_rear_right_difference);
	CompareRecordedAmigaWord("opp.new.front.difference", &opp_new_front_difference);

	CompareRecordedAmigaWord("touching.road", &touching_road);
	long temp;
	if (GetRecordedAmigaWord(&temp))
	{
		if ((temp && !opp_touching_road) ||
			(!temp && opp_touching_road))
		{
			++VALUE1;	// Count differences
			fprintf(out, "%s different %d %d (VALUE2 %d)\n", "opp.touching.road", temp, opp_touching_road, VALUE2);
			opp_touching_road = temp ? TRUE : FALSE;	// Use Amiga value when different
		}
	}
#endif


	// Make accelerations from 6 parts wheel difference in question and 1 part
	// of the other two wheels (only one central front wheel is considered)
	total_diff = opp_new_rear_left_difference + opp_new_rear_right_difference + opp_new_front_difference;

	opp_y_acceleration[REAR_LEFT] = ((total_diff + opp_new_rear_left_difference + (opp_new_rear_left_difference << 2))) >> 3;
	opp_y_acceleration[REAR_RIGHT] = ((total_diff + opp_new_rear_right_difference + (opp_new_rear_right_difference << 2))) >> 3;
	opp_y_acceleration[FRONT] = ((total_diff + opp_new_front_difference + (opp_new_front_difference << 2))) >> 3;


	// Randomly make opponent do a wheelie (if they have that attribute)
	if ((opponent_attributes[opponentsID] & WHEELIE))
		{
		i = opp_y_speed[FRONT] | opp_y_acceleration[FRONT];
		if ((i & 0xfffc) == 0)		// If front of car isn't moving much vertically
			{
			i = rand() & 0xf;
			if (i == 0)
				opp_y_speed[FRONT] = 160;	// Make opponent do a wheelie
			}
		}


	// Update rear left wheel y speed and height
	acceleration = ((opp_y_acceleration[REAR_LEFT] * REDUCTION) >> 8);
	opp_y_speed[REAR_LEFT] += acceleration;

	// Update rear right wheel y speed and height
	acceleration = ((opp_y_acceleration[REAR_RIGHT] * REDUCTION) >> 8);
	opp_y_speed[REAR_RIGHT] += acceleration;

	// Update front wheel y speed and height
	acceleration = ((opp_y_acceleration[FRONT] * REDUCTION) >> 8);
	opp_y_speed[FRONT] += acceleration;
	}
	speed = ((long)(opp_y_speed[REAR_LEFT] * REDUCTION * fTimeRatio) >> 9);
	opp_actual_height[REAR_LEFT] += speed;
	speed = ((long)(opp_y_speed[REAR_RIGHT] * REDUCTION * fTimeRatio) >> 9);
	opp_actual_height[REAR_RIGHT] += speed;
	speed = ((long)(opp_y_speed[FRONT] * REDUCTION * fTimeRatio) >> 9);
	opp_actual_height[FRONT] += speed;

	// Limit movement of opponent's wheels
	long diff = LimitOpponentWheels(296, REAR_LEFT, REAR_RIGHT);

	if (diff < 0)
		// Use rear right wheel (because this is higher than rear left)
		LimitOpponentWheels(368, REAR_RIGHT, FRONT);
	else
		LimitOpponentWheels(368, REAR_LEFT, FRONT);

#ifdef	TEST_AMIGA_AWH
	if(bFramePlain) {
	CompareRecordedAmigaWord("opp.rear.left.y.acceleration", &opp_y_acceleration[REAR_LEFT]);
	CompareRecordedAmigaWord("opp.rear.right.y.acceleration", &opp_y_acceleration[REAR_RIGHT]);
	CompareRecordedAmigaWord("opp.front.y.acceleration", &opp_y_acceleration[FRONT]);

	CompareRecordedAmigaWord("opp.rear.left.y.speed", &opp_y_speed[REAR_LEFT]);
	CompareRecordedAmigaWord("opp.rear.right.y.speed", &opp_y_speed[REAR_RIGHT]);
	CompareRecordedAmigaWord("opp.front.y.speed", &opp_y_speed[FRONT]);

	CompareRecordedAmigaWord("opp.rear.left.actual.height", &opp_actual_height[REAR_LEFT]);
	CompareRecordedAmigaWord("opp.rear.right.actual.height", &opp_actual_height[REAR_RIGHT]);
	CompareRecordedAmigaWord("opp.front.actual.height", &opp_actual_height[FRONT]);
	}
#endif
}


static void CalculateWheelDifference( long road_height,
									  long actual_height,
									  long height_adjust,
									  long *old_difference_in_out,
									  long *new_difference_out,
									  long *touching_road)
{
long new_difference;
long amount_below_road;

	new_difference = road_height - actual_height;
	if (new_difference > opp_smallest_difference)
		opp_smallest_difference = new_difference;

	new_difference += height_adjust;
	if (new_difference < 0)
	{
		// wheel above road
		if (new_difference < -96) new_difference = -96;	// set to maximum amount above road
	}

	amount_below_road = new_difference - *old_difference_in_out;
	amount_below_road = ((amount_below_road * INCREASE) >> 8) + new_difference;

	if (amount_below_road < 0) amount_below_road = 0;
	if (amount_below_road > 1023) amount_below_road = 1023;

	*touching_road |= amount_below_road;

	amount_below_road -= height_adjust;
	*new_difference_out = amount_below_road;
	*old_difference_in_out = new_difference;
}


// Adjusts opponent wheel heights and y speeds to limit car's x and z angle
// Especially important when in the air on more extreme tracks (e.g. Roller Coaster)
static long LimitOpponentWheels( long max_difference, long wheel1, long wheel2 )
{
long diff, drop, speed_diff;

	diff = opp_actual_height[wheel1] - opp_actual_height[wheel2];

	drop = max_difference - abs(diff);
	if (drop < 0)
	{
		// Drop highest wheel
		if (diff >= 0)
			opp_actual_height[wheel1] += drop;
		else
			opp_actual_height[wheel2] += drop;

		if (wheel2 != FRONT)
		{
			// Get here on first call to function
			// Average rear wheel y speeds
			AverageWheelYSpeeds(REAR_LEFT, REAR_RIGHT);
			return(diff);
		}

		// Average rear wheel y speeds
		AverageWheelYSpeeds(REAR_LEFT, REAR_RIGHT);
		// Average front and rear wheels y speeds (both rear wheel values are currently the same)
		AverageWheelYSpeeds(FRONT, REAR_RIGHT);
		// Average rear wheels y speeds again
		AverageWheelYSpeeds(REAR_LEFT, REAR_RIGHT);
	}

	if (wheel2 != FRONT)
		return(diff);	// Finish if first call to function

	// Following is reached on second call to function
	if (opp_touching_road)
		return(diff);

	// Adjust wheel y speeds when opponent in air, possibly to make the car pitch forwards
	speed_diff = opp_y_speed[wheel1] - opp_y_speed[FRONT];
	if (speed_diff < 16)
	{
		static long	y_speed_adjustments[] = {4,4,-4};

		for (long i = 0; i < NUM_OPP_WHEEL_POSITIONS; i++)
		{
			opp_y_speed[i] += y_speed_adjustments[i];
		}
	}

	return(diff);
}


static void AverageWheelYSpeeds( long wheel1, long wheel2 )
{
	long average = (opp_y_speed[wheel1] + opp_y_speed[wheel2]) >> 1;
	opp_y_speed[wheel1] = average;
	opp_y_speed[wheel2] = average;
}

static long Opponent_Speed_Value( long TrackID, long pos )
{
/*srd111a	move.l	#road.section.angle.and.piece,a1
	move.b	(a1,d1.w),d0
	andi.b	#$f,d0
	move.b	d0,d2
	move.l	#sections.car.can.be.put.on,a2
	move.b	(a2,d2.w),d0
	bpl	srd112

	move.b	B.63ce1,d0
	subi.b	#10,d0
	move.b	d0,value
	move.b	B.63ce1,d0
	jmp	srd113a

srd112	move.b	value,d0
	addi.b	#10,d0
	bmi	srd113
	move.b	d0,value

srd113	move.b	value,d0

srd113a	move.b	prompt.chars,d2
	beq	srd114

	subq.b	#1,prompt.chars
	ori.b	#$80,d0

srd114	move.l	#opponents.speed.values,a1
	move.b	d0,(a1,d1.w)
*/
	static long oldpos = -1;
	static long oldtrack = -1;
	static bool oldleague = false;
	static long oldspeed = 0;
	if(pos==oldpos && oldtrack==TrackID && oldleague==bSuperLeague)
		return oldspeed;
	oldpos = pos;
	oldleague = bSuperLeague;
	oldtrack = TrackID;

	long b = Piece_Angle_And_Template[pos];
	b = sections_car_can_be_put_on[b&0x0f];
	long B63ce1 = (long)rand() & (long)opp_track_speed_values[TrackID+16+(bSuperLeague?32:0)];
		 B63ce1 += (long)opp_track_speed_values[TrackID+24+(bSuperLeague?32:0)];
	long /*value,*/ d0;
	if (b<0) {
		//value = B63ce1-10;
		d0 = B63ce1;
	} else {
		if (B63ce1<(0x7f-10))
			d0 = /*value =*/ B63ce1+10;
		else
			d0 = /*value =*/ B63ce1;
	}
	oldspeed = d0;
	return d0;
}


/*	======================================================================================= */
/*	Function:		RandomizeOpponentsSteering												*/
/*																							*/
/*	Description:							*/
/*	======================================================================================= */

static long B1bb9d = 0;
static long B1bbc2 = 0;
static long B1bbbd = 0;

static long TAB5be34[] =
{0x20,0x50,0x60,0x70,0x70,0x60,0x50,0x20,
-0x20,-0x50,-0x60,-0x70,-0x70,-0x60,-0x50,-0x20};


// Tested against Amiga
static void RandomizeOpponentsSteering( void )
{
// TO DO: Tidy up, rename variables, remove gotos
long d0, d1, d2;
long value;

#ifdef TEST_AMIGA_ROS
	if (GetRecordedAmigaWord(&opponentsID))
		++VALUE2;

	long temp, fourteen_frames_elapsed = 0;
	if (GetRecordedAmigaWord(&temp))
	{
		opp_touching_road = temp ? TRUE : FALSE;
	}

	GetRecordedAmigaWord(&B1bbbe[2]);	//opponents.random.steering.count
	GetRecordedAmigaWord(&B1bb9d);
	GetRecordedAmigaWord(&B1bbc2);
	GetRecordedAmigaWord(&opponents_current_piece);

	if (GetRecordedAmigaWord(&temp))
		opponent_behind_player = temp & 0x80 ? TRUE : FALSE;

	GetRecordedAmigaWord(&fourteen_frames_elapsed);
#endif

	if (!opp_touching_road)
		return;

	d1 = 0;
	B1bbbe[0] = B1bbbe[1] = 0;
	B1bbbd = 0;
	d0 = B1bbbe[2];	//opponents.random.steering.count
	if (!d0) goto ros1;

#ifdef TEST_AMIGA_ROS
	if (!fourteen_frames_elapsed)
#endif
	B1bbbe[2] -= 1;

	d0 += B1bbc2;
	d0 &= 0xf;
	d2 = d0;
	d0 = TAB5be34[d2];
	if (d0 < 0)
	{
		d0 = -d0;
		d1++;
	}
	B1bbbe[d1] = d0;

	d2 += 5;
	d2 &= 0xf;
	d0 = TAB5be34[d2];
	B1bbbd = d0;
	goto ros2;

ros1:
	d2 = opponents_current_piece;
	if (/*opponents_speed_values[TrackID][d2]*/Opponent_Speed_Value(TrackID, d2) < 0)
		goto ros2;

	if (opponent_behind_player)
		goto ros2;

	if (Track[opponents_current_piece].type & 0x80)	// curve
		goto ros2;

	d2 = 8;
	if ((B1bb9d & 0x80) == 0)	// not curved piece
		goto ros2;

	if (B1bb9d & 0x40)	// diagonal piece (45 degrees)
		d2 = 16;

	B1bbc2 = d2;

	value = rand() & 0x1f;
#ifdef TEST_AMIGA_ROS
	GetRecordedAmigaWord(&value);
#endif
	if (opponentsID < value)
		goto ros2;

	B1bbbe[2] = 16;	//opponents.random.steering.count

ros2:
	d0 = Track[opponents_current_piece].oppositeDirection ? 0x40 : 0;
	d0 ^= Track[opponents_current_piece].type;
	B1bb9d = d0;

#ifdef TEST_AMIGA_ROS
	CompareRecordedAmigaWord("B1bbbe[0]", &B1bbbe[0]);
	CompareRecordedAmigaWord("B1bbbe[1]", &B1bbbe[1]);
	CompareRecordedAmigaWord("B1bbbe[2]", &B1bbbe[2]);
	CompareRecordedAmigaWord("B1bb9d", &B1bb9d);
	CompareRecordedAmigaWord("B1bbc2", &B1bbc2);

	// Amiga just uses a signed byte
	B1bbbd &= 0xff;
	CompareRecordedAmigaWord("B1bbbd", &B1bbbd);
	if (B1bbbd & 0x80) B1bbbd = B1bbbd - 0x100;	//sign extend again
#endif

	//VALUE3 = B1bbbe[2];	//opponents.random.steering.count
	return;
}


/*	======================================================================================= */
/*	Function:		GetOpponentsEngineAcceleration											*/
/*																							*/
/*	Description:							*/
/*	======================================================================================= */

// Tested against Amiga
static void GetOpponentsEngineAcceleration( void )
{
long power = opp_engine_power;

#ifdef TEST_AMIGA_GOEA
	if (GetRecordedAmigaWord(&B1bbbe[2]))	//opponents.random.steering.count
		++VALUE2;

	long temp;
	if (GetRecordedAmigaWord(&temp))
	{
		opp_touching_road = temp ? TRUE : FALSE;
	}
#endif

	if (B1bbbe[2] != 0)	//opponents.random.steering.count
		power -= 25;

	if (opp_touching_road)
		opponents_engine_z_acceleration = power;
	else
		opponents_engine_z_acceleration = 0;

#ifdef TEST_AMIGA_GOEA
	CompareRecordedAmigaWord("opponents.engine.z.acceleration", &opponents_engine_z_acceleration);
#endif
	return;
}


// Tested against Amiga
static void AdjustOpponentsEngineAcceleration( void )
{
long speed_value, speed, opponents_required_z_speed;

#ifdef TEST_AMIGA_AOEA
	long temp;
	if (GetRecordedAmigaWord(&temp))
	{
		++VALUE2;
		opp_touching_road = temp ? TRUE : FALSE;
	}
	GetRecordedAmigaWord(&opponents_current_piece);
	GetRecordedAmigaWord(&opponents_max_speed);
	GetRecordedAmigaWord(&opponents_z_speed);
	GetRecordedAmigaWord(&opponents_engine_z_acceleration);
#endif

	if (!opp_touching_road)
		return;

	speed_value = /*opponents_speed_values[TrackID][opponents_current_piece]*/Opponent_Speed_Value(TrackID, opponents_current_piece);
	speed = speed_value;
	if ((speed & 0x80) == 0)
	{
		if (speed > opponents_max_speed)
			speed = opponents_max_speed;
	}

	opponents_required_z_speed = speed & 0x7f;

	speed = opponents_z_speed >> 8;
	speed -= opponents_required_z_speed;
	if (speed == 0)
	{
		opponents_required_z_speed_reached = TRUE;
		return;
	}
	if (speed > 0)
	{
		// Speed is greater than required speed
		opponents_required_z_speed_reached = TRUE;
		opponents_engine_z_acceleration = -opponents_engine_z_acceleration;
		if (speed < 14)
			return;
	}

	if ((speed_value & 0x80) || (speed >= 0) || (!opponents_required_z_speed_reached))
	{
		opponents_engine_z_acceleration <<= 1;
		return;
	}

	if (speed >= -2)
		return;		// Value is -2 or -1

	opponents_required_z_speed_reached = FALSE;
	opponents_engine_z_acceleration <<= 1;
	return;
}


// Tested against Amiga
static void UpdateOpponentsZSpeed( void )
{
long acceleration_adjust = 0, s, a;

#ifdef TEST_AMIGA_UOZS
	long temp;
	if (GetRecordedAmigaWord(&temp))
	{
		++VALUE2;
		opp_touching_road = temp ? TRUE : FALSE;
	}
	GetRecordedAmigaWord(&opponents_z_speed);

	if (GetRecordedAmigaWord(&temp))
		player_close_to_opponent = temp & 0x80 ? TRUE : FALSE;
	if (GetRecordedAmigaWord(&temp))
		opponent_behind_player = temp & 0x80 ? TRUE : FALSE;

	GetRecordedAmigaWord(&opponents_engine_z_acceleration);
	GetRecordedAmigaWord(&opponents_current_piece);

	GetRecordedAmigaWord(&opp_rear_left_road_pos.y);
	GetRecordedAmigaWord(&opp_rear_right_road_pos.y);
	GetRecordedAmigaWord(&opp_front_road_pos_y);
#endif

	if (opponents_z_speed >= 0)
	{
		s = opponents_z_speed >> 7;

		// Reduce speed value if opponent close behind player
		if (player_close_to_opponent && opponent_behind_player)
		{
			s -= 20;
			if (s < 0) s = 0;
		}

		// A fraction of the square of the speed is subtracted from acceleration
		// This only has a small effect
		acceleration_adjust = ((opponents_z_speed >> 8) * s) >> 6;

		// Reduce the acceleration further if on the road
		if (opp_touching_road)
		{
			if (opponents_engine_z_acceleration >= 0)
			{
				// Subtract fraction of speed from acceleration
				s = (opponents_z_speed >> 8);
				a = opponents_engine_z_acceleration - s;

				if (Track[opponents_current_piece].type & 0x80)	// curve
				{
					// Subtract again when on a curve, then reduce further
					a -= s;
					a -= 35;
				}
				opponents_engine_z_acceleration = a;
			}
		}
	}

	a = opponents_engine_z_acceleration - acceleration_adjust;
	if (opp_touching_road)
	{
		long d = (opp_rear_left_road_pos.y + opp_rear_right_road_pos.y) >> 1;
		d -= opp_front_road_pos_y;
		// d is -'ve when opponent pitched backwards, +'ve when pitched forwards

		long pitch = abs(d), adjust;
		if (pitch >= 512) pitch = 510;

		pitch >>= 1;		// pitch value / 2
		adjust = pitch + (pitch >> 2);	// (5 * pitch value) / 8

		if (d < 0) adjust = -adjust;

		// Acceleration is reduced when opponent pitched backwards, increased when pitched forwards
		// i.e. effect of gravity
		a += adjust;
	}

	long acceleration = (a * REDUCTION) >> 8;
	opponents_z_speed += acceleration;
	if (opponents_z_speed < 0) opponents_z_speed = 0;

//	VALUE2 = opponents_engine_z_acceleration;
//	VALUE3 = opponents_z_speed;
#ifdef TEST_AMIGA_UOZS
	CompareRecordedAmigaWord("opponents.engine.z.acceleration", &opponents_engine_z_acceleration);
	CompareRecordedAmigaWord("opponents.z.speed", &opponents_z_speed);
#endif
	return;
}


/*	======================================================================================= */
/*	Function:		CalculateDistancesBetweenPlayers										*/
/*																							*/
/*	Description:							*/
/*	======================================================================================= */

extern long player_current_piece;
extern long players_distance_into_section;
extern long players_road_x_position;
extern long rear_wheel_surface_x_position;

static long difference_between_players = 0;
static long smallest_distance_between_players = 0;


static void CalculateDistancesBetweenPlayers( void )
{
static long distances_around_road[MAX_PIECES_PER_TRACK], total_road_distance;
static long previousTrackID = NO_TRACK;

//	VALUE1 = player_current_piece;
//	VALUE2 = players_distance_into_section;
//	VALUE3 = opponents_current_piece;

	// Re-calculate road distances when track changes
	if (previousTrackID != TrackID)
	{
		long piece;
		long distance = 0;
		for (piece = 0; piece < NumTrackPieces; piece++)
			{
			distances_around_road[piece] = distance << 5;

			distance += Track[piece].numSegments;
			}
		total_road_distance = distance << 5;

		previousTrackID = TrackID;
	}

	long diff, abs_diff, opposite;
	diff = (opponents_distance_into_section - players_distance_into_section) >> 3;
	diff += distances_around_road[opponents_current_piece] - distances_around_road[player_current_piece];
	// NOTE: following value can only be relied upon when player and opponent are on same piece
	// (it's wrong when they're on different sides of track start/end, e.g. opponent on piece 0, player on piece 43)
	difference_between_players = diff;
//	VALUE1 = diff;
	/*
	fprintf(out, "opponent %2x %3x, player %2x %3x, diff %x\n",
		opponents_current_piece, opponents_distance_into_section,
		player_current_piece, players_distance_into_section, difference_between_players);
	*/

	abs_diff = abs(diff);
	opposite = total_road_distance - abs_diff;	// difference between players in opposite direction

	// compare two road distances
	if (abs_diff < opposite)
	{
		// get smallest distance
		smallest_distance_between_players = abs_diff;
		diff = -diff;
	}
	else
		smallest_distance_between_players = opposite;

//	VALUE2 = smallest_distance_between_players;

	if (diff > 0)
		opponent_behind_player = TRUE;
	else
		opponent_behind_player = FALSE;

//	VALUE3 = opponent_behind_player ? 1 : 0;
	return;
}


/*	======================================================================================= */
/*	Function:		CalculateIfWinning														*/
/*																							*/
/*	Description:	Returns negative if player is winning									*/
/*	======================================================================================= */

extern long lapNumber[];


long CalculateIfWinning( long start_finish_piece )
{
long result, p, o;

	result = lapNumber[OPPONENT] - lapNumber[PLAYER];
	if (result != 0)	// on different laps
		return(result);

	p = player_current_piece - start_finish_piece;
	if (p < 0)
		p += NumTrackPieces;

	o = opponents_current_piece - start_finish_piece;
	if (o < 0)
		o += NumTrackPieces;

	result = o - p;
	if (result != 0)	// on different pieces
		return(result);

	result = difference_between_players;
	return(result);
}


/*	======================================================================================= */
/*	Function:		CarToCarCollisionDetection												*/
/*																							*/
/*	Description:	Calculates opponent collision with player								*/
/*	======================================================================================= */

static long B1bbc3 = 0, B1bbeb = 0;
static long x_difference, player_to_right;
static long cars_collided;
static long car_to_car_x_acceleration, car_to_car_y_acceleration, car_to_car_z_acceleration;

// player's values
extern long touching_road;
extern long player_y;
extern long player_z_speed;
extern long front_left_damage, front_right_damage, rear_damage, damaged;


static void CarToCarCollisionDetection( void )
{
// TO DO: Tidy up, rename variables, remove gotos
long d0, d3, d4;
long players_smaller_y;

	if (!drop_start_done)
		return;

	if (!opp_touching_road)
		goto ctccd1;

	if (touching_road)
		goto ctccd2;

ctccd1:
	players_smaller_y = player_y >> 11;
	d0 = players_smaller_y - opp_actual_height[REAR_LEFT];
	d4 = d0;
	d0 += 40;
	d0 = abs(d0);

	if (d0 >= 192)
	{
		B1bbc3 = 3;
		return;
	}

	if (!B1bbc3)
		goto ctccd2;

	--B1bbc3;
	d3 = 256 - d0;
	if (d4 < 0)
		d3 = -d3;

	d3 <<= 4;
	car_to_car_y_acceleration = d3;

ctccd2:
	d0 = x_difference;
	if (d0 >= 45)
		goto ctccd4;

	d0 = smallest_distance_between_players & 0xff;
	if (d0 > 8)
		goto ctccd4;

	d0 = 0x800;
	if (player_to_right)
		goto ctccd3;

	d0 = -0x800;

ctccd3:
	car_to_car_x_acceleration = d0;

ctccd4:
	if (B1bbeb & 0x80)
		goto ctccd5;

	d3 = 3;
	d0 = opponents_z_speed - player_z_speed;
	if (d0 < 0)
		d3 = -3;

	d0 >>= 1;
	d0 += d3;
	car_to_car_z_acceleration = d0;

ctccd5:
	cars_collided = 0x80;
	B1bbeb = 0x80;

	d3 = 512;
	d0 = abs(car_to_car_x_acceleration);
	d3 += d0;

	d0 = abs(car_to_car_y_acceleration);
	d3 += d0;

	d0 = abs(car_to_car_z_acceleration);
	d3 += d0;

	d3 >>= 8;

	d0 = rear_damage + d3;
	if (d0 > 255) d0 = 255;
	rear_damage = d0;

	d0 = front_right_damage + d3;
	if (d0 > 255) d0 = 255;
	front_right_damage = d0;

	d0 = front_left_damage + d3;
	if (d0 > 255) d0 = 255;
	front_left_damage = d0;

	damaged = 0x80;
	return;
}


static long cars_collided_delay = 0;

// player's values
extern long car_collision_x_acceleration, car_collision_y_acceleration, car_collision_z_acceleration;


void CarToCarCollision( void )
{
long d0;

	if (cars_collided_delay > 0)
		--cars_collided_delay;

	if (!cars_collided)
		return;

	cars_collided = 0;

	d0 = opponents_z_speed - car_to_car_z_acceleration;
	if (d0 < 0) d0 = 0;
	opponents_z_speed = d0;

	d0 = car_to_car_y_acceleration >> 4;
	opp_y_speed[REAR_LEFT] -= d0;
	opp_y_speed[REAR_RIGHT] -= d0;
	opp_y_speed[FRONT] -= d0;

	//VALUE1 = car_to_car_x_acceleration;
	//VALUE2 = car_to_car_y_acceleration;
	//VALUE3 = car_to_car_z_acceleration;
	car_collision_x_acceleration += car_to_car_x_acceleration;
	car_collision_y_acceleration += car_to_car_y_acceleration;
	car_collision_z_acceleration += car_to_car_z_acceleration;

	car_to_car_x_acceleration = 0;
	car_to_car_y_acceleration = 0;
	car_to_car_z_acceleration = 0;

//******** Play collision sound if necessary ********

	if (cars_collided_delay > 0)
		return;

	//HitCarSoundBuffer->SetCurrentPosition(0);
	HitCarSoundBuffer->Play(NULL,NULL,NULL);	// not looping

	cars_collided_delay = 5;
	return;
}


/*	======================================================================================= */
/*	Function:		OpponentPlayerInteraction												*/
/*																							*/
/*	Description:	Calculates opponent movement sideways and collision with player			*/
/*	======================================================================================= */

static long opponents_suggested_road_x_position;

extern unsigned char sections_car_can_be_put_on[];


// Tested against Amiga
static void OpponentPlayerInteraction( void )
{
// TO DO: Tidy up, rename variables, remove gotos
long d0, d1, d2;
long count, piece;
	if(!bFramePlain)
		return;

	//VALUE2 = players_road_x_position;
	//VALUE3 = rear_wheel_surface_x_position;

#ifdef TEST_AMIGA_OPI
	if (GetRecordedAmigaWord(&opponentsID))
		++VALUE2;

	GetRecordedAmigaWord(&opponents_road_x_position);
	GetRecordedAmigaWord(&rear_wheel_surface_x_position);
	GetRecordedAmigaWord(&smallest_distance_between_players);

	long temp;
	if (GetRecordedAmigaWord(&temp))
		opponent_behind_player = temp & 0x80 ? TRUE : FALSE;

	GetRecordedAmigaWord(&players_road_x_position);
	GetRecordedAmigaWord(&opponents_current_piece);
	GetRecordedAmigaWord(&opponents_distance_into_section);
	GetRecordedAmigaWord(&B1bbbd);
	if (B1bbbd & 0x80) B1bbbd = B1bbbd - 0x100;	//sign extend

	if (GetRecordedAmigaWord(&temp))
		opp_touching_road = temp ? TRUE : FALSE;
#endif

	d1 = opponentsID;
	d2 = 0;
	player_close_to_opponent = FALSE;

	d0 = opponents_road_x_position & 0xff;
	opponents_suggested_road_x_position = d0;

	d0 -= rear_wheel_surface_x_position;
	if (d0 < 0)
	{
		d0 = -d0;
		--d2;	// flag that player is to right of opponent
	}
	x_difference = d0;
	player_to_right = d2;

	if ((smallest_distance_between_players >> 8) != 0)
		goto far_away;

	// Player and opponent are within $100 of each other (ahead or behind)
	d0 = smallest_distance_between_players;
	if (smallest_distance_between_players >= 64)
		goto close_checked;

	if (opponent_behind_player)
		goto flag_close;

	if (x_difference >= 50)
		goto close_checked;

	// Either:-
	//  Opponent less than 64 behind player
	//  OR Player less than 64 behind and less then 50 to the left or right of opponent
flag_close:
	player_close_to_opponent = TRUE;

close_checked:
	if (d0 >= 16)
		goto opi3;

	//tst.b	machine
	//beq	opi1

	//if ((opponents_road_x_position & 0xff) != 0)
	//	goto opi3;

//opi1
	if (x_difference >= 50)
		goto opi3;

	d0 = players_road_x_position >> 8;
	if (d0 < 1)	goto opi2;
	if (d0 != 1) goto opi3;

	d0 = players_road_x_position & 0xff;
	if (d0 >= 0x80)
		goto opi3;

opi2:
	CarToCarCollisionDetection();
	goto opi4;

	// not within 16
opi3:
	B1bbc3 = 0;	// clear collision values
	B1bbeb = 0;

	d0 = smallest_distance_between_players & 0xff;
	if (d0 >= 24)
		goto opi6;

opi4:
	if (!(opponent_attributes[opponentsID] & DRIVES_NEAR_EDGE))
		goto opi5;

	if (opponent_behind_player)
		goto opi5;

	d0 = smallest_distance_between_players & 0xff;
	if (d0 >= 14)
		goto far_away;

opi5:
	MoveOpponentToOneSide();
	goto opif;

opi6:
	if (opponent_behind_player)
		goto opi9;

	if (d0 >= 50)
		goto opi7;

	if (!(opponent_attributes[opponentsID] & OBSTRUCTS_PLAYER))
		goto opi8;

	// put opponent at same position as player
	opponents_suggested_road_x_position = rear_wheel_surface_x_position;
	goto opic;

opi7:
	if (d0 >= 200)
		goto far_away;

	if (!(opponent_attributes[opponentsID] & PUSH_PLAYER))	// opponent pushing player off track
		goto far_away;

opi8:
	OpponentPushPlayer();
	goto opic;

opi9:
	OpponentPushPlayer();
	goto opif;

// Player and opponent atleast $100 from each other (ahead or behind)
far_away:
	d2 = 64;
	if (opponent_attributes[opponentsID] & DRIVES_NEAR_EDGE)
		d2 = 110;

	if (opponentsID & 1)
		d2 = 255-d2;	// to other side of road

	opponents_suggested_road_x_position = d2;

opic:
	// move opponent to middle of road if approaching or on a curve
	piece = opponents_current_piece;
	for (count = 2; count > 0; count--)
	{
		d0 = GetPieceAngleAndTemplate(piece);
		d0 &= 0xf;	// templateNum
		if (sections_car_can_be_put_on[d0] & 0x80)
			opponents_suggested_road_x_position = 128;	// middle of road

		// go to next piece
		piece++; if (piece > (NumTrackPieces - 1)) piece = 0;
	}

opif:
	d0 = B1bbbd;
	if (d0 < 0) goto opi10;
	if (d0) goto opi11;

	d0 = opponents_suggested_road_x_position;
	d0 -= opponents_road_x_position & 0xff;
	if (!d0) goto opi13;
	if (d0 >= 0) goto opi11;

opi10:
	if (d0 >= -16)
		goto opi13;

	d0 = -9;
	goto opi12;

opi11:
	if (d0 < 16)
		goto opi13;

	d0 = 9;

opi12:
	d0 += opponents_road_x_position & 0xff;

	if (!opp_touching_road)
		goto opi13;

	if (d0 < 0)	//temp, remove
		MessageBox(NULL, L"Less than 0", L"Error", MB_OK);	//temp
	if (d0 >= 225)
		goto opi13;

	if (d0 < 32)
		goto opi13;

	opponents_road_x_position = d0;

opi13:
	//VALUE1 = player_close_to_opponent;
#ifdef TEST_AMIGA_OPI
	CompareRecordedAmigaWord("x.difference", &x_difference);

	if (GetRecordedAmigaWord(&temp))
	{
		long val = temp & 0x80 ? -1 : 0;
		CompareAmigaWord("player.to.right", val, &player_to_right);
	}

	if (GetRecordedAmigaWord(&temp))
	{
		long amiga_flag = temp & 0x80 ? TRUE : FALSE;
		long flag = player_close_to_opponent;
		CompareAmigaWord("player.close.to.opponent", amiga_flag, &flag);
	}
	CompareRecordedAmigaWord("opponents.suggested.road.x.position", &opponents_suggested_road_x_position);
	CompareRecordedAmigaWord("opponents.road.x.position", &opponents_road_x_position);
#endif
	return;
}


// Tested against Amiga
// position opponent on left or right
static void MoveOpponentToOneSide( void )
{
#ifdef TEST_AMIGA_MOTOS
	if (GetRecordedAmigaWord(&x_difference))
		++VALUE2;

	long temp;
	if (GetRecordedAmigaWord(&temp))
	{
		player_to_right = temp & 0x80 ? -1 : 0;
	}
#endif

long d0 = x_difference;

	if (d0 >= 56)
		return;
//	++VALUE3;
	if (player_to_right & 0x80)
		opponents_suggested_road_x_position = 32;
	else
		opponents_suggested_road_x_position = 256-32;

#ifdef TEST_AMIGA_MOTOS
	CompareRecordedAmigaWord("opponents.suggested.road.x.position", &opponents_suggested_road_x_position);
#endif
	return;
}


// Tested against Amiga
// opponent pushing player off track
static void OpponentPushPlayer( void )
{
long d0 = x_difference;

	if (d0 >= 56)
		return;

	d0 = rear_wheel_surface_x_position;

	if (player_to_right & 0x80)
	{
		if (d0 < 96)
			opponents_suggested_road_x_position = 256-32;
		else
			opponents_suggested_road_x_position = 32;
	}
	else
	{
		if (d0 >= (256-96))
			opponents_suggested_road_x_position = 32;
		else
			opponents_suggested_road_x_position = 256-32;
	}

	return;
}


/*	======================================================================================= */
/*	Function:		CalculateOpponentsDistance												*/
/*																							*/
/*	Description:	Calculate distance between opponent and player							*/
/*	======================================================================================= */

long CalculateOpponentsDistance (void)
	{
	// should do every fourth frame

	long dist = smallest_distance_between_players;
	dist += (dist >> 2);
	dist >>= 2;

	if (opponent_behind_player)
		dist = -dist;

	return(dist);
	}
