/**************************************************************************

    Car Behaviour.cpp - Functions relating to player's car behaviour

	NOTE: Best to always start a car off on a straight (non-diagonal) piece

	NOTE: All statics and globals that have been initialised will need to be
		  reinitialised when the car is repositioned on the track (e.g. at
		  start of race and when put back on track after coming off)

	NOTE: player_x and player_z are in PC StuntCarRacer format
		  player_y is currently in Amiga StuntCarRacer format
		  Angles have the same magnitude but are unsigned.
		  And sin/cos/tan also need alteration (divide by 2)


/* OUTSTANDING ISSUES / IMPROVEMENTS :-

	1.  SOME FUNCTIONS CONTAIN LOGIC THAT IS DEPENDANT UPON THE ORDER THAT THE
		TRACK PIECES ARE STORED IN (I.E. WHETHER THE PIECE NUMBERS INCREMENT
		AROUND THE TRACK IN A CLOCKWISE OR ANTI-CLOCKWISE MANNER)
	
		LINES THAT HAVE ALREADY BEEN IDENTIFIED HAVE THE COMMENT :-

				// DIRECTION DEPENDANT

		- NEED TO IMPLEMENT A TRACK DIRECTION VALUE (1 OR -1) THAT IS EITHER
		STORED WITH THE TRACK DEFINITION OR CALCULATED AT THE START OF A RACE.
		THE LOGIC WOULD THEN USE THIS VALUE RATHER THAN JUST ADDING OR
		SUBTRACTING 1.

 **************************************************************************/

/*
 * Unfortunately these HIGHER_FRAME_RATE changes didn't work...
 *
//#define	HIGHER_FRAME_RATE	// to cater for four times frame rate
// 10/12/1998 - engine_z_acceleration not now reduced (to enable car to jump as before)
//			  - could try limiting the top speed instead (should be better)
//	or try REDUCTION of 202, INCREASE of 306
*/

/*	============= */
/*	Include files */
/*	============= */
#include "dxstdafx.h"

#include <stdlib.h>

#include "StuntCarRacer.h"
#include "Car_Behaviour.h"
#include "Opponent_Behaviour.h"
#include "Track.h"
#include "3D_Engine.h"
#include "XBOXController.h"

/*	===== */
/*	Debug */
/*	===== */
//#define USE_AMIGA_RECORDING
//#define TEST_AMIGA_UER

//#define PLAY_AMIGA_RECORDING

#if defined(DEBUG) || defined(_DEBUG)
extern FILE *out;
extern bool bTestKey;
#endif

/*	========= */
/*	Constants */
/*	========= */
#ifndef linux
#define	FALSE	0
#define	TRUE	1
#endif

#define	MAX_AMIGA_VOLUME	64
#define DIRECTX_VOLUME_FACTOR	100		// Volume units are in hundredths of decibels

// car behaviour definitions
#define	GRAVITY_ACCELERATION	317		// used to be called CAR_WEIGHT

#define	ROAD_WIDTH	0x0180

#define	SURFACE_SIZE	1024	// used when interpolating (Amiga StuntCarRacer used 256, but 1024 is smoother!)
#define	LOG_SURFACE_SIZE	10	// to base 2

#define	OFF_ROAD_HEIGHT	0x1000

#define	OFF_TRACK_LIMIT	64		// count after which player is put back on track

#define	WRECKED			(wreck_wheel_height_reduction != 0)
#define	NOT_WRECKED		(wreck_wheel_height_reduction == 0)

#define LOCAL_Y_FACTOR	4

/*	=========== */
/*	Global data */
/*	=========== */
long player_current_piece = 0;	// use as players_road_section
long player_current_segment = 0;
long players_distance_into_section = 0;
long players_road_x_position = 0;
long rear_wheel_surface_x_position = 0;
bool drop_start_done = TRUE;
long touching_road = FALSE;
long player_y;
long player_z_speed = 0;

long front_left_damage = 0,
	 front_right_damage = 0,
	 rear_damage = 0;
long damaged = 0;
long new_damage = 0;
long nholes = 0;

long car_collision_x_acceleration,
	 car_collision_y_acceleration,
	 car_collision_z_acceleration;

long boostReserve = 0, boostUnit = 0;
long playerLapNumber;

static CXBOXController P1Controller(1);


#if defined(DEBUG) || defined(_DEBUG)
//long CCPIECE, CCSEGMENT, CCSURFACEX, CCSURFACEZ;
bool debug_position = FALSE;
#endif

extern IDirectSoundBuffer8 *WreckSoundBuffer;
extern IDirectSoundBuffer8 *GroundedSoundBuffer;
extern IDirectSoundBuffer8 *CreakSoundBuffer;
extern IDirectSoundBuffer8 *SmashSoundBuffer;
extern IDirectSoundBuffer8 *OffRoadSoundBuffer;

extern bool bSuperLeague;

/*	=========== */
/*	Static data */
/*	=========== */
static long player_x,
			player_z;

static long player_x_angle = 0,
			player_y_angle = 0,
			player_z_angle = 0;

static long player_world_x_speed = 0,
			player_world_y_speed = 0,
			player_world_z_speed = 0;

static long player_x_speed = 0,
			player_y_speed = 0;

static long accelerate, brake;

static long accelerating = FALSE;	// to remember previous control state

long engine_power = 240;		// (240 standard, 320 super)
long boost_unit_value = 16;	// (16 standard, 12 super)

static long left_right_value;
static long engine_z_acceleration;
/*static*/ long boost_activated;

static long rear_wheel_x_offset, rear_wheel_z_offset;
static long front_left_wheel_x_offset, front_left_wheel_z_offset;
static long front_right_wheel_x_offset, front_right_wheel_z_offset;

static long front_left_road_height = OFF_ROAD_HEIGHT;
static long front_right_road_height = OFF_ROAD_HEIGHT;
static long rear_road_height = OFF_ROAD_HEIGHT;

// wheel heights
static long front_left_actual_height;
static long front_right_actual_height;
static long rear_actual_height;

static long off_left, off_right;
static long wheel_off_road, distance_off_road;
static long at_side_byte, which_side_byte;
static long smaller_limit_required = FALSE;


static long wreck_wheel_height_reduction = 0;		// 0x200 if wrecked

	// set the on_chains flag to FALSE for now (won't implement chains at first)
static long on_chains = FALSE;

static long player_distance_off_road;	// used to determine the value below
static long off_map_status = 0;	// not set exactly like Amiga StuntCarRacer

static long off_track_count = 0;

static long gravity_x_acceleration,
			gravity_y_acceleration,
			gravity_z_acceleration;

static long grounded_delay = 0;
static long grounded_count = 0;
static long damage_value = 0;
static long damaged_count = 0;

long front_left_amount_below_road = 0,
			front_right_amount_below_road = 0,
			rear_amount_below_road = 0;

long front_left_wheel_speed = 0,
	 		front_right_wheel_speed = 0;
long leftwheel_angle = 0, rightwheel_angle = 0;

static long old_front_left_difference = 0,
			old_front_right_difference = 0,
			old_rear_difference = 0;

static long smashed_countdown = 0;

static long car_to_road_collision_z_acceleration;

static long player_x_acceleration,
			player_y_acceleration,
			player_z_acceleration;

static long total_world_x_acceleration,
			total_world_y_acceleration,
			total_world_z_acceleration;

static long player_x_rotation_speed = 0,
			player_y_rotation_speed = 0,
			player_z_rotation_speed = 0;

static long player_final_x_rotation_speed,
			player_final_y_rotation_speed,
			player_final_z_rotation_speed;

static long player_x_rotation_acceleration,
			player_y_rotation_acceleration,
			player_z_rotation_acceleration;

static long Replay = FALSE, ReplayRequested = FALSE, ReplayLooping = FALSE, ReplayFinished = FALSE;

#ifdef USE_AMIGA_RECORDING
static bool ReplayAmigaRecording = FALSE;
static bool StartOfAmigaRecording = FALSE;
static long AmigaRecordingFrame = 0;
#endif

/*	===================== */
/*	Function declarations */
/*	===================== */
static void CarControl (DWORD input);
static void BoostPower (long boost_flag,
						long accelerate,
						long brake);

static void CarMovement (void);
static long GetPieceUsingMap (long x, long z, long *piece_out);
static void CalcXZRelativeToPiece (long x, long z, long piece, long *rx_out, long *rz_out);

static void CalculateWheelXZOffsets (void);

static void CalculateRoadWheelHeights (void);
static void CalculateRoadWheelHeight (long height, long *height_out);
static void CalculateIfCarOffRoad (long *height);
static void CalculateWorldRoadHeight (long wheel, long x, long z, long *y_out);

static void GetSurfaceCoords (long piece, long segment);
static long CalcDistanceOffRoad (long x, long z,
								 long ox, long oz,
								 long ux, long uz,
								 long vx, long vz,
								 long *ex, long *ez);
static void CalcSurfacePosition (long piece,
								 long x, long z,
								 long ox, long oz,
								 long ux, long uz,
								 long vx, long vz,
								 long *sx, long *sz,
								 long *road_x,
								 long *segment_out);

static void CalculateActualWheelHeights (void);
static void CalculateXZSpeeds (void);
static void CalculateGravityAcceleration (void);
static void CarCollisionDetection (void);
static void CalculateWheelCollision (long road_height,
									 long actual_height,
									 long *height_difference_out,
									 long *old_difference_in_out,
									 long *amount_below_road_in_out,
									 long *damage_in_out);
static void CalculateCarCollisionAcceleration (long average_amount_below_road);
static void CalculateInclinationSinCos (long inclination_in,
										long *inclination_sin_out,
										long *inclination_cos_out);
static void LiftCarOntoTrack (void);

static void CalculateTotalAcceleration (void);
static long GetTwiceCollisionYAcceleration (void);
static void CalculateXAcceleration (void);

static void CalculateSteering (void);
static void CalculateSteeringAcceleration (long steering_amount);
static void AlignCarWithRoad (void);
static void AdjustSteeringAcceleration (void);
static void IdentifyPiece (long x, long z, long *piece_in_out);
static void GetPieceCoords (long piece);

static void CalculateWorldAcceleration (void);
static void ReduceWorldAcceleration (void);

static void CalculateXZRotationAcceleration (void);
static void UpdatePlayersRotationSpeed (void);
static void CalculateFinalRotationSpeed (void);
static void UpdatePlayersWorldSpeed (void);
static void UpdatePlayersPosition (void);

static long CalcSectionYAngle (long piece,
							   long x,
							   long z);
static void CalcCurveMeasurements (long piece,
								   long x,
								   long z,
								   long *y_angle_out,
								   long *radius_out,
								   double *distance_from_centre_out);

static void PositionCarAbovePiece (long piece);
static void UpdateEngineRevs (void);
static void DrawDustClouds (void);
static void DrawSparks (void);
static void SetWheelRotationSpeed();

#ifdef NOT_USED
static void RewindRecording (void);
static void Record (DWORD input);
static void PlayBack (DWORD *input);
static void ReadRecordedFile (void);
#endif

#ifdef USE_AMIGA_RECORDING
static bool OpenAmigaRecording( void );
#endif

/*	======================================================================================= */
/*	Function:		ResetPlayer																*/
/*																							*/
/*	Description:	Reset all car behaviour variables to their initial state				*/
/*	======================================================================================= */

void ResetPlayer (void)
	{
	// resets almost everything at the moment, just to make sure
	player_x = 0;
	player_y = 0;
	player_z = 0;

	player_x_angle = 0;
	player_y_angle = 0;
	player_z_angle = 0;

	player_world_x_speed = 0;
	player_world_y_speed = 0;
	player_world_z_speed = 0;

	// calculated
	player_x_speed = 0;
	player_y_speed = 0;
	player_z_speed = 0;

	accelerating = FALSE;

	engine_power = (bSuperLeague)?320:240;		// (240 standard, 320 super)
	boost_unit_value = (bSuperLeague)?12:16;	// (16 standard, 12 super)

	// calculated
	left_right_value = 0;
	engine_z_acceleration = 0;
	boost_activated = 0;

	// calculated
	rear_wheel_x_offset = 0, rear_wheel_z_offset = 0;
	front_left_wheel_x_offset = 0, front_left_wheel_z_offset = 0;
	front_right_wheel_x_offset = 0, front_right_wheel_z_offset = 0;

	front_left_road_height = OFF_ROAD_HEIGHT;
	front_right_road_height = OFF_ROAD_HEIGHT;
	rear_road_height = OFF_ROAD_HEIGHT;

	// calculated
	front_left_actual_height = 0;
	front_right_actual_height = 0;
	rear_actual_height = 0;

	// calculated
	off_left = 0, off_right = 0;
	wheel_off_road = 0, distance_off_road = 0;
	at_side_byte = 0, which_side_byte = 0;

	smaller_limit_required = FALSE;

	wreck_wheel_height_reduction = 0;		// 0x200 if wrecked

	drop_start_done = TRUE;
	touching_road = FALSE;

	// set the on_chains flag to FALSE for now (won't implement chains at first)
	on_chains = FALSE;

	// calculated
	player_distance_off_road = 0;
	off_map_status = 0;
	//off_track_count = 0;	// now done in CarBehaviour

	// calculated
	gravity_x_acceleration = 0;
	gravity_y_acceleration = 0;
	gravity_z_acceleration = 0;

	grounded_delay = 0;

	// calculated
	grounded_count = 0;
	damage_value = 0;

	damaged_count = 0;
	damaged = 0;

	front_left_amount_below_road = 0;
	front_right_amount_below_road = 0;
	rear_amount_below_road = 0;

	old_front_left_difference = 0;
	old_front_right_difference = 0;
	old_rear_difference = 0;

	front_left_damage = 0;
	front_right_damage = 0;
	rear_damage = 0;

	new_damage = 0;
	smashed_countdown = 0;
	nholes = 0;

	// calculated
	car_collision_x_acceleration = 0;
	car_collision_y_acceleration = 0;
	car_collision_z_acceleration = 0;
	car_to_road_collision_z_acceleration = 0;

	// calculated
	player_x_acceleration = 0;
	player_y_acceleration = 0;
	player_z_acceleration = 0;

	// calculated
	total_world_x_acceleration = 0;
	total_world_y_acceleration = 0;
	total_world_z_acceleration = 0;

	player_x_rotation_speed = 0;
	player_y_rotation_speed = 0;
	player_z_rotation_speed = 0;

	// calculated
	player_final_x_rotation_speed = 0;
	player_final_y_rotation_speed = 0;
	player_final_z_rotation_speed = 0;

	// calculated
	player_x_rotation_acceleration = 0;
	player_y_rotation_acceleration = 0;
	player_z_rotation_acceleration = 0;
	return;
	}


/*	======================================================================================= */
/*	Function:		CarBehaviour															*/
/*																							*/
/*	Description:							*/
/*	======================================================================================= */

// eventually make access functions for the following, remove extern definitions
extern bool bNewGame;

extern long TrackID;
extern TRACK_PIECE Track[MAX_PIECES_PER_TRACK];
extern long Track_Map[NUM_TRACK_CUBES][NUM_TRACK_CUBES];	// [x][z]
extern long NumTrackPieces;
extern long PlayersStartPiece;
extern long StartLinePiece;
extern long HalfALapPiece;


long INITIALISE_PLAYER = TRUE;


void CarBehaviour (DWORD input,
				   long *x,
				   long *y,
				   long *z,
				   long *x_angle,
				   long *y_angle,
				   long *z_angle)
	{
	static long first_time = TRUE;

	// temporarily set player values to values provided when required
	if (INITIALISE_PLAYER)
		{
		INITIALISE_PLAYER = FALSE;

		if (! Replay)
			{
			player_x = *x;
			player_y = -(*y / LOCAL_Y_FACTOR);
			player_z = *z;
			player_x_angle = (*x_angle);
			player_y_angle = (*y_angle);
			player_z_angle = (*z_angle);
			}
		}


	// reset player and control action replay as required
	if ((off_track_count > OFF_TRACK_LIMIT) ||
	    (bNewGame) ||
		(ReplayRequested))
		{
		ResetPlayer();

		if (bNewGame || ReplayRequested)
			{
			// reset all animated objects
			ResetDrawBridge();
			ReplayFinished = FALSE;
			}

		if (off_track_count > OFF_TRACK_LIMIT)
			{
			PositionCarAbovePiece(player_current_piece);
			}
		else
			{
			PositionCarAbovePiece(PlayersStartPiece);
			}
		drop_start_done = FALSE;

		if (bNewGame)
			{
			// reset action replay recording
//			Replay = FALSE;
//			RewindRecording();

#ifdef USE_AMIGA_RECORDING
			CloseAmigaRecording();		// So that play will start from beginning
			ReplayAmigaRecording = TRUE;
#endif
			}

#ifdef NOT_USED
		if (ReplayRequested)
			{
			// begin action replay if requested
			Replay = TRUE;
			}
#endif

		off_track_count = 0;
//		ReplayRequested = FALSE;
		}

	//VALUE1 = Replay;

#ifdef NOT_USED
	// replay doesn't currently work on DrawBridge - doesn't know starting DrawBridge frame

	if (ReplayFinished)
        {
        if (ReplayLooping)
            {
        	RewindRecording();
        	ReplayRequested = TRUE;
            }
	    return;
        }

	if (! Replay)
		{
		Record(input);
		}
	else
		{
		// override user input with recorded value
		PlayBack(&input);
		}
#endif

	CarControl(input);
	CarMovement();
	UpdateEngineRevs();

	if (touching_road) drop_start_done = TRUE;	// Amiga StuntCarRacer does this differently


	// output player values for use by functions that draw the world
	*x = player_x;
	*y = -(player_y * LOCAL_Y_FACTOR);
	*z = player_z;

	// following checks angles don't exceed limits
	*x_angle = (player_x_angle & (MAX_ANGLE - 1));
	*y_angle = (player_y_angle & (MAX_ANGLE - 1));
	*z_angle = (player_z_angle & (MAX_ANGLE - 1));

	// Reverse x and z angle because StuntCarRacer's DrawWorld rotates around x and z in
	// the opposite direction to the trig. coefficients calculated by StuntCarRacer's
	// CarBehaviour (i.e. clockwise becomes anti-clockwise or vice-versa)
	*x_angle = (-player_x_angle & (MAX_ANGLE - 1));
	*z_angle = (-player_z_angle & (MAX_ANGLE - 1));

	first_time = FALSE;

	//VALUE1++;		// frame counter
	}

/*	======================================================================================= */
/*	Function:		LimitViewpointY															*/
/*																							*/
/*	Description:	Limit viewpoint Y value to prevent it going below or too close to road	*/
/*					(i.e. prevent road 'tearing')											*/
/*	======================================================================================= */

#define Y_ADJUSTMENT_THRESHOLD 0x480

void LimitViewpointY (long *y)
	{
	long saved_player_z_speed = player_z_speed;
	short sin_x, cos_x;
	short sin_z, cos_z;
	long ry = 0, ly = 0;

//	VALUE1 = (bTestKey ? 1 : 0);
	// calculate required sin.cos values using player x, y and z angles
	CalcYXZTrigCoefficients(player_x_angle,
							player_y_angle,
							player_z_angle);

	player_z_speed = 0xA00;	// prevent CalculateRoadWheelHeight from averaging current and previous heights

	CalculateWheelXZOffsets();
	CalculateRoadWheelHeights();
	CalculateActualWheelHeights();

	player_z_speed = saved_player_z_speed;	// restore original value

	/*
	VALUE1 = front_left_road_height;
	VALUE2 = front_left_actual_height;
	VALUE3 = front_left_road_height - front_left_actual_height;
	*/

	/*
	VALUE1 = front_right_road_height;
	VALUE2 = front_right_actual_height;
	VALUE3 = front_right_road_height - front_right_actual_height;
	*/

	GetSinCos(player_x_angle, &sin_x, &cos_x);	// cosine not used
	GetSinCos(player_z_angle, &sin_z, &cos_z);	// cosine not used

//	VALUE1 = player_y;
//	VALUE1 = front_right_road_height - front_right_actual_height;
//	VALUE2 = VALUE3 = 0;
	if ((front_right_road_height - front_right_actual_height) > Y_ADJUSTMENT_THRESHOLD)
		{
		// Use the CalculateActualWheelHeights() calculations in reverse, with road height, to calculate adjusted player_y
		/*
		front_right_actual_height = player_y;
		front_right_actual_height += ((long)sin_x << (4+15-LOG_PRECISION));
		front_right_actual_height -= ((long)sin_z << (3+15-LOG_PRECISION));
		front_right_actual_height >>= 8;
		*/
#if 0
		if (bTestKey)
			ry = front_right_road_height << 8;
		else
#endif
			ry = (front_right_road_height - Y_ADJUSTMENT_THRESHOLD) << 8;

		ry += ((long)sin_z << (3+15-LOG_PRECISION));
		ry -= ((long)sin_x << (4+15-LOG_PRECISION));
//		VALUE2 = ry;
		}

//	VALUE1 = front_left_road_height - front_left_actual_height;
//	VALUE2 = VALUE3 = 0;
	if ((front_left_road_height - front_left_actual_height) > Y_ADJUSTMENT_THRESHOLD)
		{
		// Use the CalculateActualWheelHeights() calculations in reverse, with road height, to calculate adjusted player_y
		/*
		front_left_actual_height = player_y;
		front_left_actual_height += ((long)sin_x << (4+15-LOG_PRECISION));
		front_left_actual_height += ((long)sin_z << (3+15-LOG_PRECISION));
		front_left_actual_height >>= 8;
		*/
#if 0
		if (bTestKey)
			ly = front_left_road_height << 8;
		else
#endif
			ly = (front_left_road_height - Y_ADJUSTMENT_THRESHOLD) << 8;

		ly -= ((long)sin_z << (3+15-LOG_PRECISION));
		ly -= ((long)sin_x << (4+15-LOG_PRECISION));
//		VALUE3 = ly;
		}

	if (ry)
		{
		if (ly)
		{
			*y = -(((ry + ly) * LOCAL_Y_FACTOR) / 2);	// use average of two values
//			VALUE1 = 1;
		}
		else
		{
			*y = -(ry * LOCAL_Y_FACTOR);
//			VALUE1 = 2;
		}
		}
	else if (ly)
		{
		*y = -(ly * LOCAL_Y_FACTOR);
//		VALUE1 = 3;
		}
	}

	/*
	// Old method...
	// 19/09/2007 attempt to limit player_y to prevent road disappearing.  Doesn't work completely on Draw Bridge track
	long front_road_height = (front_left_road_height + front_right_road_height) << (8-1);
//	long front_road_height = 0;
	VALUE1 = player_y;
	VALUE2 = front_road_height;
	if (player_y > front_road_height)
	{
	//*y = -(player_y * LOCAL_Y_FACTOR);
	VALUE3 = 0;
	}
	else
	{
	*y = -(front_road_height * LOCAL_Y_FACTOR);
	VALUE3 = 1;
	}
	*/

/*	======================================================================================= */
/*	Function:		CarControl																*/
/*																							*/
/*	Description:							*/
/*	======================================================================================= */

static void CarControl (DWORD input)
	{
//	Keys that control car are :-
//			Left = left, Right = right
//			Up = Accelerate, Down = Brake
//			(X) = Accelerate, (B) = Brake on Pandora
//			SPACE = boost
//			(R) = boost on Pandora
//
//  Note: Can't accelerate without boost when using keyboard,
//		  because HASH key is changed to be brake - see below

	long left = (input & KEY_P1_LEFT),
		 right = (input & KEY_P1_RIGHT),
		 boost = (input & KEY_P1_BOOST);

	accelerate = (input & KEY_P1_ACCEL);
	brake = (input & KEY_P1_BRAKE);

	// if none of the resulting keys are pressed then read joystick
#ifdef linux
#warning TODO
#else
	if( !input )
	{
		if(P1Controller.IsConnected())
		{
			// easier to read...
			const XINPUT_GAMEPAD &pad = P1Controller.GetState().Gamepad;
			if(pad.bRightTrigger)
			{
				accelerate = TRUE;
			}

			if(pad.wButtons & XINPUT_GAMEPAD_A)
			{
				boost = TRUE;
			}

			if(pad.wButtons & XINPUT_GAMEPAD_B || pad.bLeftTrigger)
			{
				brake = TRUE;	// select brake
				accelerate = FALSE;
			}

			if( abs(pad.sThumbLX) > XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE )
			{
				(pad.sThumbLX < 0) ? (left = TRUE) : (right = TRUE);
			}
		}
	}
#endif
	left_right_value = 0;
	if ((touching_road) && (! on_chains))
		{
		if (left)
			left_right_value = -15;
		if (right)
			left_right_value = 15;
		}

	long boost_flag;	// active low
	if (boost)
		boost_flag = FALSE;
	else
		boost_flag = TRUE;

	if ((player_z_speed < 120*256) && (! on_chains) && (NOT_WRECKED))
		{
		if (accelerate)
			{
			engine_z_acceleration = engine_power;
			accelerating = TRUE;
			}
		else
			if (brake)
				{
				engine_z_acceleration = -240;
				accelerating = FALSE;
				}
			else
				if (accelerating)
					{
					// car keeps accelerating even when control released
					engine_z_acceleration = engine_power;
					accelerating = TRUE;	// already TRUE
					}
				else
					engine_z_acceleration = 0;
		}
	else
		engine_z_acceleration = 0;

	BoostPower(boost_flag,
			   accelerate,
			   brake);

#ifdef PLAY_AMIGA_RECORDING
	GetRecordedAmigaWord(&left_right_value);
	GetRecordedAmigaWord(&engine_z_acceleration);
	//VALUE1 = engine_z_acceleration;
#endif
	return;
	}


static void BoostPower (long boost_flag,
						long accelerate,
						long brake)
	{
	boost_activated = 0;

	if ((! boost_flag) && (NOT_WRECKED))
		{
		if (accelerating || (accelerate || brake))
			{
			if (boostReserve > 0)
				{
				--boostUnit;
				if (boostUnit < 0)
					{
					boostUnit = boost_unit_value;
					--boostReserve;
					}

				boost_activated = 0x80;
				engine_z_acceleration *= 2;
				}
			}
		}

	return;
	}


/*	======================================================================================= */
/*	Function:		CarMovement																*/
/*																							*/
/*	Description:							*/
/*	======================================================================================= */

static void CarMovement (void)
	{
	// currently uses player_x/y/z and player_x/y/z_angle

	//calculate required sin.cos values using player x, y and z angles
	CalcYXZTrigCoefficients(player_x_angle,
							player_y_angle,
							player_z_angle);

	//fprintf(out, "player_x_angle %d\n", player_x_angle);
	//fprintf(out, "player_y_angle %d\n", player_y_angle);
	//fprintf(out, "player_z_angle %d\n", player_z_angle);

	CalculateWheelXZOffsets();
	CalculateRoadWheelHeights();
	CalculateActualWheelHeights();

	CalculateXZSpeeds();

	SetWheelRotationSpeed();
	CalculateGravityAcceleration();
	CarCollisionDetection();

	//if (B.1bb72 != 0)		// always set
		{
		CalculateTotalAcceleration();

		CalculateSteering();

		CalculateWorldAcceleration();
		ReduceWorldAcceleration();

		CalculateXZRotationAcceleration();
		UpdatePlayersRotationSpeed();
		CalculateFinalRotationSpeed();
		}

	UpdatePlayersWorldSpeed();
	UpdatePlayersPosition();

#ifdef PLAY_AMIGA_RECORDING
	if (StartOfAmigaRecording)
	{
	GetRecordedAmigaLong(&player_x); player_x *= (PC_FACTOR * 4);
	GetRecordedAmigaLong(&player_y);
	GetRecordedAmigaLong(&player_z); player_z *= (PC_FACTOR * 4);
	GetRecordedAmigaWord(&player_x_angle);
	GetRecordedAmigaWord(&player_y_angle);
	GetRecordedAmigaWord(&player_z_angle);

	++AmigaRecordingFrame;
	if (AmigaRecordingFrame > 0)
		StartOfAmigaRecording = FALSE;
	}
	else
	{
	// throw values away
	long temp;
	GetRecordedAmigaLong(&temp);
	GetRecordedAmigaLong(&temp);
	GetRecordedAmigaLong(&temp);
	GetRecordedAmigaWord(&temp);
	GetRecordedAmigaWord(&temp);
	GetRecordedAmigaWord(&temp);
	}
#endif

	// 23/08/1998 - extra bit to set flags
	if (player_distance_off_road >= (256-ROAD_WIDTH/2))
		{
		off_map_status = 0x80;
		}
	else
		{
		off_map_status = 0;
		off_track_count = 0;
		smaller_limit_required = FALSE;
		}

	if ((off_map_status != 0) && (touching_road) && (player_y < 0x1000000))
		{
		off_track_count++;
		smaller_limit_required = TRUE;
		}


	//VALUE1 = player_z_speed;
	//VALUE1 = player_current_piece;

	//VALUE1 = Track[player_current_piece].coords[0].y;
	//long temp = Track[player_current_piece].numSegments;
	//VALUE2 = Track[player_current_piece].coords[(temp*4)].y;

//	fprintf(out, "------------------------------------------------------------\n");
	return;
	}


/*	======================================================================================= */
/*	Function:		GetPieceUsingMap														*/
/*																							*/
/*	Description:	Use Track_Map to get piece number that world x/z point is within		*/
/*	======================================================================================= */

static long GetPieceUsingMap (long x, long z, long *piece_out)
	{
	long map_x, map_z, piece;

	// locate the map square that the point is in
	map_x = x >> LOG_CUBE_SIZE;
	map_z = z >> LOG_CUBE_SIZE;

	if (((map_x < 0) || (map_x >= NUM_TRACK_CUBES)) ||
		((map_z < 0) || (map_z >= NUM_TRACK_CUBES)))
		{
		// off the map
		//fprintf(out, "GetPieceUsingMap - world point is off map\n");
		return(FALSE);
		}

	// lookup piece number within map
	piece = Track_Map[map_x][map_z];
	if (piece == -1)
		{
		// no piece at this place on the map
		//fprintf(out, "GetPieceUsingMap - no piece at map position\n");
		return(FALSE);
		}

	*piece_out = piece;
	return(TRUE);
	}


/*	======================================================================================= */
/*	Function:		CalcXZRelativeToPiece													*/
/*																							*/
/*	Description:	Calculate position of world x/z point, relative to required piece		*/
/*	======================================================================================= */

static void CalcXZRelativeToPiece (long x, long z, long piece, long *rx_out, long *rz_out)
	{
	long piece_x, piece_z;

	// calculate x/z position of piece's front left corner, within world
	piece_x = Track[piece].x << LOG_CUBE_SIZE;
	piece_z = Track[piece].z << LOG_CUBE_SIZE;

	// calculate point's x/z position relative to the piece (and in same range)
	*rx_out = (x - piece_x) >> LOG_PRECISION;
	*rz_out = (z - piece_z) >> LOG_PRECISION;
	}


/*	======================================================================================= */
/*	Function:		CalculateWheelXZOffsets													*/
/*																							*/
/*	Description:	Calculate offsets from player's position (car's centre point)			*/
/*	======================================================================================= */

static void CalculateWheelXZOffsets (void)
	{
	short *trig_coeffs = TrigCoefficients();

	// rear wheel is just (0, 0, -CAR_LENGTH/2) split into components
	rear_wheel_x_offset = ((long)trig_coeffs[Z_X_COMP] * (-CAR_LENGTH/2) * PC_FACTOR);
	rear_wheel_z_offset = ((long)trig_coeffs[Z_Z_COMP] * (-CAR_LENGTH/2) * PC_FACTOR);

	// front left wheel is just (-CAR_WIDTH/2, 0, CAR_LENGTH/2) split into components
	front_left_wheel_x_offset = ((long)trig_coeffs[X_X_COMP] * (-CAR_WIDTH/2) * PC_FACTOR);
	front_left_wheel_x_offset += ((long)trig_coeffs[Z_X_COMP] * (CAR_LENGTH/2) * PC_FACTOR);
	front_left_wheel_z_offset = ((long)trig_coeffs[X_Z_COMP] * (-CAR_WIDTH/2) * PC_FACTOR);
	front_left_wheel_z_offset += ((long)trig_coeffs[Z_Z_COMP] * (CAR_LENGTH/2) * PC_FACTOR);

	// front right wheel is just (CAR_WIDTH/2, 0, CAR_LENGTH/2) split into components
	front_right_wheel_x_offset = ((long)trig_coeffs[X_X_COMP] * (CAR_WIDTH/2) * PC_FACTOR);
	front_right_wheel_x_offset += ((long)trig_coeffs[Z_X_COMP] * (CAR_LENGTH/2) * PC_FACTOR);
	front_right_wheel_z_offset = ((long)trig_coeffs[X_Z_COMP] * (CAR_WIDTH/2) * PC_FACTOR);
	front_right_wheel_z_offset += ((long)trig_coeffs[Z_Z_COMP] * (CAR_LENGTH/2) * PC_FACTOR);

	// could also possibly work out the wheel y offsets here
	// rather than doing it in calculate.actual.wheel.heights
	// but calculate.actual.wheel.heights doesn't use components
	return;
	}

#ifdef NOT_USED
void TempCentrePoint (long *x, long *y, long *z)
	{
	*x = player_x;
	*y = player_y;
	*z = player_z;
	}

void TempRearPoint (long *x, long *y, long *z)
	{
	*x = player_x + rear_wheel_x_offset;
	//*y = player_y;

	*y = (((-rear_actual_height / 32) << LOG_PRECISION) * PC_FACTOR);
	*z = player_z + rear_wheel_z_offset;
	}

void TempFrontLeftPoint (long *x, long *y, long *z)
	{
	*x = player_x + front_left_wheel_x_offset;
	//*y = player_y;

	*y = (((-front_left_actual_height / 32) << LOG_PRECISION) * PC_FACTOR);
	*z = player_z + front_left_wheel_z_offset;
	}

void TempFrontRightPoint (long *x, long *y, long *z)
	{
	*x = player_x + front_right_wheel_x_offset;
	//*y = player_y;

	*y = (((-front_right_actual_height / 32) << LOG_PRECISION) * PC_FACTOR);
	*z = player_z + front_right_wheel_z_offset;
	}


void StuntCarRearWheelXZ (long *x, long *z)
	{
	CalcYXZTrigCoefficients(player_x_angle,
							player_y_angle,
							player_z_angle);

	CalculateWheelXZOffsets();

	*x = rear_wheel_x_offset + player_x;
	*z = rear_wheel_z_offset + player_z;
	}

void StuntCarFrontLeftWheelXZ (long *x, long *z)
	{
	// must have previously called StuntCarRearWheelXZ

	*x = front_left_wheel_x_offset + player_x;
	*z = front_left_wheel_z_offset + player_z;
	}

void StuntCarFrontRightWheelXZ (long *x, long *z)
	{
	// must have previously called StuntCarRearWheelXZ

	*x = front_right_wheel_x_offset + player_x;
	*z = front_right_wheel_z_offset + player_z;
	}


void StuntCarWheelXZ (long piece, long segment, long scrx, long scrz, long *x, long *z)
	{
	long x1, x2, x3, x4;
	long z1, z2, z3, z4;
	long sxa, sxb, sx;
	long sza, szb, sz;

	x1 = Track[piece].coords[(segment*4)].x;
	z1 = Track[piece].coords[(segment*4)].z;

	x2 = Track[piece].coords[(segment*4)+1].x;
	z2 = Track[piece].coords[(segment*4)+1].z;

	segment++;
	x3 = Track[piece].coords[(segment*4)].x;
	z3 = Track[piece].coords[(segment*4)].z;

	x4 = Track[piece].coords[(segment*4)+1].x;
	z4 = Track[piece].coords[(segment*4)+1].z;

	// first do x interpolation
	//fprintf(out, "x1 %d, x2 %d, x3 %d, x4 %d\n", x1, x2, x3, x4);
	//fprintf(out, "scrx %d, scrz %d\n", scrx, scrz);

	sxa = (x1<<LOG_SURFACE_SIZE) + (scrx * (x2-x1));
	sxb = (x3<<LOG_SURFACE_SIZE) + (scrx * (x4-x3));

	sza = (z1<<LOG_SURFACE_SIZE) + (scrx * (z2-z1));
	szb = (z3<<LOG_SURFACE_SIZE) + (scrx * (z4-z3));

	// now do z interpolation
	sx = (sxa<<(LOG_PRECISION-LOG_SURFACE_SIZE)) + ((scrz * (sxb-sxa))>>((LOG_SURFACE_SIZE*2)-LOG_PRECISION));
	//fprintf(out, "sx %d\n", sx);

	sz = (sza<<(LOG_PRECISION-LOG_SURFACE_SIZE)) + ((scrz * (szb-sza))>>((LOG_SURFACE_SIZE*2)-LOG_PRECISION));

	// add x/z position of piece's front left corner, within world
	*x = sx + (Track[piece].x << LOG_CUBE_SIZE);
	*z = sz + (Track[piece].z << LOG_CUBE_SIZE);
	}
#endif

/*	======================================================================================= */
/*	Function:		CalculateRoadWheelHeights												*/
/*																							*/
/*	Description:	Calculate the road height (y value) directly below each car wheel		*/
/*					NOTE: following method is not taken from Amiga StuntCarRacer			*/
/*	======================================================================================= */

typedef enum
	{
	FRONT_LEFT = 0,
	FRONT_RIGHT,
	REAR,
	NUM_WHEEL_POSITIONS,
	CENTRE	// NOTE: This isn't a wheel position, but is used by CalculatePlayersRoadPosition
	} WheelPositionType;


// VALUES FROM FOLLOWING ARE SLIGHTLY DIFFERENT TO AMIGA STUNT CAR RACER, BUT WORK OK

static void CalculateRoadWheelHeights (void)
	{
	long i, height;
	COORD_3D wheel_pos[NUM_WHEEL_POSITIONS];

	at_side_byte = 0;

	// create array of wheel world x/z positions
	wheel_pos[FRONT_LEFT].x = front_left_wheel_x_offset + player_x;
	wheel_pos[FRONT_LEFT].z = front_left_wheel_z_offset + player_z;

	wheel_pos[FRONT_RIGHT].x = front_right_wheel_x_offset + player_x;
	wheel_pos[FRONT_RIGHT].z = front_right_wheel_z_offset + player_z;

	wheel_pos[REAR].x = rear_wheel_x_offset + player_x;
	wheel_pos[REAR].z = rear_wheel_z_offset + player_z;

	// initialise heights to previous values (from globals)
	wheel_pos[FRONT_LEFT].y = front_left_road_height;
	wheel_pos[FRONT_RIGHT].y = front_right_road_height;
	wheel_pos[REAR].y = rear_road_height;

	// calculate world road height at wheel positions
	for (i = 0; i < NUM_WHEEL_POSITIONS; i++)
		{
		CalculateWorldRoadHeight(i, wheel_pos[i].x, wheel_pos[i].z, &height);

		// convert the result to PC StuntCarRacer magnitude
		height = ((height / PC_FACTOR) >> (LOG_PRECISION-3));

		CalculateRoadWheelHeight(height, &wheel_pos[i].y);

		// 23/08/1998 - also store player_distance_off_road
		if (i == REAR)
			player_distance_off_road = abs(distance_off_road);
		}

	// store heights in global variables
	front_left_road_height = wheel_pos[FRONT_LEFT].y;
	front_right_road_height = wheel_pos[FRONT_RIGHT].y;
	rear_road_height = wheel_pos[REAR].y;
	return;
	}


static void CalculateRoadWheelHeight (long height, long *height_out)
	{
	if (wheel_off_road)
		CalculateIfCarOffRoad(&height);

	wheel_off_road = FALSE;

	// get angle in Amiga StuntCarRacer format (i.e. correct sign)
	long angle = (player_x_angle < (_180_DEGREES) ? (player_x_angle) :
													(player_x_angle - _360_DEGREES));

	if ((abs(player_z_speed) >= 0xA00) || (abs(angle) >= 0x600))
		{
		// use height as is
		*height_out = height;
		}
	else
		{
		// save the average of calculated (new) height and the previous value
		// this is possibly for when the car is being lowered onto the road
		*height_out = ((height + *height_out) / 2);
		}

	return;
	}


static void CalculateIfCarOffRoad (long *height)
	{
	// calculate how far the current wheel is off the left or right of the road
	long x = abs(distance_off_road);

	if (x > ((3*CAR_WIDTH)/4))
		{
		// signal whole car is off road
		*height = OFF_ROAD_HEIGHT;
		at_side_byte = (at_side_byte >> 1) | 0x80;
		}
	else
		{
		// use the amount the wheel is off the road to drop the height of the wheel,
		// to make the car fall off the edge gradually (i.e. invisible sloping sides)
		*height -= ((x * 16) + 0x100);

		if (*height < OFF_ROAD_HEIGHT)
			{
			// signal whole car is off road
			*height = OFF_ROAD_HEIGHT;
			at_side_byte = (at_side_byte >> 1) | 0x80;
			}
		else
			{
			// store which side the car is falling off

			// logic here is different to Amiga StuntCarRacer, due to distance_off_road being different
			// from wheel.road.x.position and also plus.180.degrees not being used
			long w = distance_off_road >> 8;

			if (w & 0x80)
				{
				if (off_left)
					which_side_byte = 0x80;	// left
				else if (off_right)
					which_side_byte = 0x40;	// right
				}
			}
		}

	return;
	}


// current surface co-ords
static long sx1, sy1, sz1, sx2, sy2, sz2, sx3, sy3, sz3, sx4, sy4, sz4;


static void CalculateWorldRoadHeight (long wheel, long x, long z, long *y_out)
	{
	// starts with the piece/surface that was used last time
	// this avoids locating the wrong map square,
	// e.g. for diagonal pieces that run into adjacent squares

	static long piece = -1, segment = -1;
	static long first_time = TRUE, prevTrackID = NO_TRACK;

	//fprintf(out, "CalculateWorldRoadHeight\n");

	// Reset variables when the track changes
	if (TrackID != prevTrackID)
	{
		piece = -1;
		segment = -1;
		first_time = TRUE;
		prevTrackID = TrackID;
	}

//****************


	// 14/05/1998 - first section has been re-written to allow the function to handle
	// the case when the point has been off the road and then returned to an entirely
	// different area of the road (e.g. car placed back onto track in different place)
	long this_piece;
	if (! GetPieceUsingMap(x, z, &this_piece))
		{
#if defined(DEBUG) || defined(_DEBUG)
		if (debug_position) fprintf(out, "CalculateWorldRoadHeight error\n");
#endif
		if (first_time)
			{
			// get the four (x,y,z) points for the first surface of the default piece
			piece = 0;
			segment = 0;
			GetSurfaceCoords(piece, segment);
			}
		}
	else
		{
#if defined(DEBUG) || defined(_DEBUG)
		if (debug_position) fprintf(out, "piece %d, this_piece %d\n", piece, this_piece);
#endif
		if ((first_time) ||
			(abs(this_piece - piece) > 1))	// moved by more than one piece
			{
			// check the move is not from the last to first piece, or vice versa
			if ((!((this_piece == (NumTrackPieces - 1)) && (piece == 0))) &&
				(!((this_piece == 0) && (piece == (NumTrackPieces - 1)))))
				{
				// get the four (x,y,z) points for the current surface of the piece
				piece = this_piece;
				segment = 0;
				GetSurfaceCoords(piece, segment);
				}
			}
		}

	first_time = FALSE;		// ensure flag is cleared


//****************


	// find the surface that the point is located within
	// first check point is not before or after surface (z direction)
	long xs, xp, zs, zp, rx = 0, rz = 0;
	long before_surface = TRUE, after_surface = TRUE, num_piece_changes;


	// 'before surface' loop
	num_piece_changes = 0;
	while (before_surface)
		{
		// really only need to do following when piece changes, but do it always at the moment
		CalcXZRelativeToPiece(x, z, piece, &rx, &rz);

#if defined(DEBUG) || defined(_DEBUG)
		if (debug_position)
		{
		fprintf(out, "before_surface sx2, sy2, sz2: 0x%x, 0x%x, 0x%x\n", sx2, sy2, sz2);
		fprintf(out, "before_surface sx3, sy3, sz3: 0x%x, 0x%x, 0x%x\n", sx3, sy3, sz3);
		fprintf(out, "before_surface sx1, sy1, sz1: 0x%x, 0x%x, 0x%x\n", sx1, sy1, sz1);
		fprintf(out, "before_surface sx4, sy4, sz4: 0x%x, 0x%x, 0x%x\n", sx4, sy4, sz4);
		}
#endif
		// calculate top dot product => before_surface
		xs = sx1 - sx4; zs = sz1 - sz4;		// current segment vector
		xp = rx - sx4; zp = rz - sz4;		// current point vector
		before_surface = (((xs * zp) - (xp * zs)) < 0 ? TRUE : FALSE);

		if (before_surface)
			{
			// future improvement: try a move in one direction,
			// if this is worse then move in other direction

			// DIRECTION DEPENDANT - WHOLE SECTION
			if (segment < (Track[piece].numSegments - 1))
				{
				segment++;
				}
			else
				{
				// go to next piece if already at last surface
				piece++; if (piece > (NumTrackPieces - 1)) piece = 0;
				segment = 0;

				num_piece_changes++;
				}

			// get the four (x,y,z) points for the new surface
			GetSurfaceCoords(piece, segment);
			}

		// prevent an infinite loop
		if (num_piece_changes >= NumTrackPieces)
			{
#if defined(DEBUG) || defined(_DEBUG)
			fprintf(out, "CalculateWorldRoadHeight - infinite loop trapped (1)\n");
#endif
			break;
			}
		}

#if defined(DEBUG) || defined(_DEBUG)
	// warn if surface search was inefficient
	if (num_piece_changes > 2)		// arbitrary number
		fprintf(out, "CalculateWorldRoadHeight - %d changes (1)\n", num_piece_changes);
#endif

	// 'after surface' loop
	num_piece_changes = 0;
	while (after_surface)
		{
		// really only need to do following when piece changes, but do it always at the moment
		CalcXZRelativeToPiece(x, z, piece, &rx, &rz);

#if defined(DEBUG) || defined(_DEBUG)
		if (debug_position)
		{
		fprintf(out, "after_surface sx2, sy2, sz2: 0x%x, 0x%x, 0x%x\n", sx2, sy2, sz2);
		fprintf(out, "after_surface sx3, sy3, sz3: 0x%x, 0x%x, 0x%x\n", sx3, sy3, sz3);
		fprintf(out, "after_surface sx1, sy1, sz1: 0x%x, 0x%x, 0x%x\n", sx1, sy1, sz1);
		fprintf(out, "after_surface sx4, sy4, sz4: 0x%x, 0x%x, 0x%x\n", sx4, sy4, sz4);
		}
#endif
		// calculate bottom dot product => after_surface
		xs = sx3 - sx2; zs = sz3 - sz2;		// current segment vector
		xp = rx - sx2; zp = rz - sz2;		// current point vector
		after_surface = (((xs * zp) - (xp * zs)) < 0 ? TRUE : FALSE);

		if (after_surface)
			{
			// future improvement: try a move in one direction,
			// if this is worse then move in other direction

			// DIRECTION DEPENDANT - WHOLE SECTION
			if (segment > 0)
				{
				segment--;
				}
			else
				{
				// go to previous piece if already at first surface
				piece--; if (piece < 0) piece = (NumTrackPieces - 1);
				segment = (Track[piece].numSegments - 1);

				num_piece_changes++;
				}

			// get the four (x,y,z) points for the new surface
			GetSurfaceCoords(piece, segment);
			}

		// prevent an infinite loop
		if (num_piece_changes >= NumTrackPieces)
			{
#if defined(DEBUG) || defined(_DEBUG)
			fprintf(out, "CalculateWorldRoadHeight - infinite loop trapped (2)\n");
#endif
			break;
			}
		}

#if defined(DEBUG) || defined(_DEBUG)
	// warn if surface search was inefficient
	if (num_piece_changes > 2)		// arbitrary number
		fprintf(out, "CalculateWorldRoadHeight - %d changes (2)\n", num_piece_changes);
#endif

//****************


	// now know that point is between start edge and end edge of surface
	// find out if point is off left or right of surface

	if (wheel != CENTRE)	// don't do this for CENTRE position (to allow road_x to include being off the road)
	{
		// calculate left dot product => off_left
		xs = sx2 - sx1; zs = sz2 - sz1;		// current segment vector
		xp = rx - sx1; zp = rz - sz1;		// current point vector
		off_left = (((xs * zp) - (xp * zs)) < 0 ? TRUE : FALSE);

		// calculate right dot product => off_right
		xs = sx4 - sx3; zs = sz4 - sz3;		// current segment vector
		xp = rx - sx3; zp = rz - sz3;		// current point vector
		off_right = (((xs * zp) - (xp * zs)) < 0 ? TRUE : FALSE);

		wheel_off_road = FALSE; distance_off_road = 0;
		if (off_left || off_right)
		{
			long d = 0, ex = 0, ez = 0;

			// wheel is off road
			wheel_off_road = TRUE;

			// need to make sure that road height at edge of surface is calculated
			// (i.e. point has to be within bounds of piece), therefore the local
			// point (rx/rz) is modified by the following, to be at the relevant edge

			if (off_left)
			{
				// get distance from and position at left edge
				d = CalcDistanceOffRoad(rx, rz, sx2, sz2, sx1, sz1, sx3, sz3, &ex, &ez);
			}
			else if (off_right)
			{
				// get distance from and position at right edge
				d = CalcDistanceOffRoad(rx, rz, sx3, sz3, sx4, sz4, sx2, sz2, &ex, &ez);
			}

			// note: following value is -'ve
			distance_off_road = d;

			rx = ex;
			rz = ez;
		}
	}

//****************


	// calculate height of surface at x,z position using linear interpolation

	long sx, sz, calculated_segment;
	long sya, syb, y;
	// get distance from left edge / top edge, i.e. sx / sz
	calculated_segment = segment;

	if (wheel != CENTRE)
	{
		CalcSurfacePosition(piece, rx, rz, sx2, sz2, sx1, sz1, sx3, sz3, &sx, &sz, NULL, &calculated_segment);

		if (wheel == REAR)
		{
		// Reduce sx to (0 - 255)
		rear_wheel_surface_x_position = sx >> (LOG_SURFACE_SIZE-8);
		}
	}
	else
	{
		// Called by CalculatePlayersRoadPosition
		// Set player_current_piece, player_current_segment, players_distance_into_section and players_road_x_position
		long road_x;
		CalcSurfacePosition(piece, rx, rz, sx2, sz2, sx1, sz1, sx3, sz3, &sx, &sz, &road_x, &calculated_segment);

		player_current_piece = piece;
		player_current_segment = calculated_segment;

		players_distance_into_section = (calculated_segment * 256) + (sz >> (LOG_SURFACE_SIZE-8));
		//VALUE1 = players_distance_into_section;
		if (calculated_segment >= Track[piece].numSegments)
		{
			MessageBox(NULL, L"calculated_segment out of range", L"Error", MB_OK);
#if defined(DEBUG) || defined(_DEBUG)
			fprintf(out, "piece %d, calculated_segment %d, numSegments %d\n", piece, calculated_segment, Track[piece].numSegments);
#endif
		}

		players_road_x_position = road_x;
		//VALUE2 = players_road_x_position;
	}


	// 22/10/1998 - if the curve calculation output a different segment to the one that was identified
	//				earlier then the co-ordinates must be retrieved for the calculated segment.
	if (calculated_segment != segment)
		{
		segment = calculated_segment;
		// get the four (x,y,z) points for the new surface
		GetSurfaceCoords(piece, segment);
		}

	/*
	CCPIECE = piece;
	CCSEGMENT = segment;
	CCSURFACEX = sx;
	CCSURFACEZ = sz;
	*/

	// i.e. calculate y at offset (sx, sz)
	//		given (sx1, sy1, sz1)
	//			  (sx2, sy2, sz2)
	//			  (sx3, sy3, sz3)
	//			  (sx4, sy4, sz4)
#if defined(DEBUG) || defined(_DEBUG)
	if (debug_position)
	{
	fprintf(out, "interpolate sx, sz: %d, %d\n", sx, sz);
	fprintf(out, "interpolate sx2, sy2, sz2: 0x%x, 0x%x, 0x%x\n", sx2, sy2, sz2);
	fprintf(out, "interpolate sx3, sy3, sz3: 0x%x, 0x%x, 0x%x\n", sx3, sy3, sz3);
	fprintf(out, "interpolate sx1, sy1, sz1: 0x%x, 0x%x, 0x%x\n", sx1, sy1, sz1);
	fprintf(out, "interpolate sx4, sy4, sz4: 0x%x, 0x%x, 0x%x\n", sx4, sy4, sz4);
	}
#endif

	// first do x interpolation
	sya = sy1 + ((sx * (sy4-sy1)) >> LOG_SURFACE_SIZE);
	syb = sy2 + ((sx * (sy3-sy2)) >> LOG_SURFACE_SIZE);

	// now do z interpolation
	y = (syb << LOG_SURFACE_SIZE) + (sz * (sya-syb));

	// 02/08/1998 - maybe should not do the following - just leave value as is
	//			  - don't need to make the value any bigger
	*y_out = (y << (LOG_PRECISION-LOG_SURFACE_SIZE));
	return;
	}


static void GetSurfaceCoords (long piece, long segment)
	{
	if ((segment < 0) || (segment >= Track[piece].numSegments))
	{
		MessageBox(NULL, L"GetSurfaceCoords segment out of range", L"Error", MB_OK);
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(out, "GetSurfaceCoords piece %d, segment %d, numSegments %d\n", piece, segment, Track[piece].numSegments);
#endif
	}
#if defined(DEBUG) || defined(_DEBUG)
	if (debug_position) fprintf(out, "GetSurfaceCoords piece %d, segment %d, numSegments %d\n", piece, segment, Track[piece].numSegments);
#endif

	sx2 = Track[piece].coords[(segment*4)].x;
	sy2 = Track[piece].coords[(segment*4)].y;
	sz2 = Track[piece].coords[(segment*4)].z;
#if defined(DEBUG) || defined(_DEBUG)
	if (debug_position) fprintf(out, "GetSurfaceCoords sx2, sy2, sz2: 0x%x, 0x%x, 0x%x\n", sx2, sy2, sz2);
#endif

	sx3 = Track[piece].coords[(segment*4)+1].x;
	sy3 = Track[piece].coords[(segment*4)+1].y;
	sz3 = Track[piece].coords[(segment*4)+1].z;
#if defined(DEBUG) || defined(_DEBUG)
	if (debug_position) fprintf(out, "GetSurfaceCoords sx3, sy3, sz3: 0x%x, 0x%x, 0x%x\n", sx3, sy3, sz3);
#endif

	segment++;
	sx1 = Track[piece].coords[(segment*4)].x;
	sy1 = Track[piece].coords[(segment*4)].y;
	sz1 = Track[piece].coords[(segment*4)].z;
#if defined(DEBUG) || defined(_DEBUG)
	if (debug_position) fprintf(out, "GetSurfaceCoords sx1, sy1, sz1: 0x%x, 0x%x, 0x%x\n", sx1, sy1, sz1);
#endif

	sx4 = Track[piece].coords[(segment*4)+1].x;
	sy4 = Track[piece].coords[(segment*4)+1].y;
	sz4 = Track[piece].coords[(segment*4)+1].z;
#if defined(DEBUG) || defined(_DEBUG)
	if (debug_position) fprintf(out, "GetSurfaceCoords sx4, sy4, sz4: 0x%x, 0x%x, 0x%x\n", sx4, sy4, sz4);
#endif
	return;
	}


static long CalcDistanceOffRoad (long x, long z,
								 long ox, long oz,
								 long ux, long uz,
								 long vx, long vz,
								 long *ex, long *ez)
	{
	// ox, oz - origin point

	// z vector
	ux -= ox;
	uz -= oz;

	// x vector
	vx -= ox;
	vz -= oz;

	// calculate (perpendicular ?) distance from left or right edge
	// method is similar to that used when texture mapping
	long v, denominator, distance;

	v = (((x-ox) * uz) + ((oz-z) * ux));	// needs to be divided by denominator
	denominator = ((uz * vx) - (ux * vz));
	// do divide afterwards to avoid need for floating point calculation
	if (denominator == 0)
		distance = 0;	// 27/07/2007 prevent division by zero
	else
		distance = (v * ROAD_WIDTH) / denominator;

	// calculate position where perpendicular meets edge of road
	if (denominator == 0)
	{
		// 27/07/2007 prevent division by zero
		*ex = x;
		*ez = z;
	}
	else
	{
		*ex = x - ((v * vx) / denominator);
		*ez = z - ((v * vz) / denominator);
	}

	return(distance);
	}


static void CalcSurfacePosition (long piece,
								 long x, long z,
								 long ox, long oz,
								 long ux, long uz,
								 long vx, long vz,
								 long *sx, long *sz,
								 long *road_x,
								 long *segment_out)		// only updated by the calculation for curves
	{
	if (Track[piece].type & 0x80)	// curve
		{
		long piece_y_angle, radius;
		long surface_x, numSegments, piece_z;
		double distance_from_centre, d;

		// 22/10/1998 - NOTE: This method is now used for curved pieces because it treats them as true circular arcs
		//					  (based upon calculate.players.road.position) which removes the 'jitter' problem

		// must be a curve (type will be -'ve)
		CalcCurveMeasurements(piece, x, z, &piece_y_angle, &radius, &distance_from_centre);

		// adjust for normal direction of travel
		if (Track[piece].oppositeDirection)
			piece_y_angle = (MAX_ANGLE/8) - piece_y_angle;

		// limit piece_y_angle to valid range
		if (piece_y_angle < 0) piece_y_angle = 0;
		if (piece_y_angle >= (MAX_ANGLE/8)) piece_y_angle = (MAX_ANGLE/8)-1;


		// calculate surface x position
		if (distance_from_centre < (double)radius)
			d = (double)radius - distance_from_centre;
		else
			d = distance_from_centre - (double)radius;

		surface_x = ((long)((d * SURFACE_SIZE) / (ROAD_WIDTH * PC_FACTOR)));
		// Also calculate road_x if required (it has a different range to surface_x)
		if (road_x)
			*road_x = ((long)(d / PC_FACTOR));

		if (surface_x >= SURFACE_SIZE) surface_x = SURFACE_SIZE-1;
		*sx = surface_x;


		// calculate surface z position and output calculated segment
		numSegments = Track[piece].numSegments;
		piece_z = (((piece_y_angle << LOG_SURFACE_SIZE) * numSegments) / (MAX_ANGLE/8));

		*sz = piece_z & (SURFACE_SIZE-1);
		*segment_out = piece_z >> LOG_SURFACE_SIZE;
		return;
		}
	else
		{
		// straight or diagonal straight

		// 22/10/1998 - NOTE: This method is no longer used for curved pieces because it is only
		//					  accurate for rectangular segments and also because curved pieces are
		//					  only approximate circular arcs (which produced the 'jitter' problem)

		// ox, oz - origin point

		// z vector
		ux -= ox;
		uz -= oz;

		// x vector
		vx -= ox;
		vz -= oz;

		// calculate (perpendicular ?) distance from left and top edge
		// method is similar to that used when texture mapping
		long u, v, denominator;

		// left edge - calculate surface x position
		v = (((x-ox) * uz) + ((oz-z) * ux));	// needs to be divided by denominator
		denominator = ((uz * vx) - (ux * vz));
		// do divide afterwards to avoid need for floating point calculation
		if (denominator == 0)
		{
			*sx = 0;	// 28/06/2007 prevent division by zero
			if (road_x)
				*road_x = 0;
		}
		else
		{
			*sx = (v * SURFACE_SIZE) / denominator;
			// Also calculate road_x if required (it has a different range to surface_x)
			if (road_x)
				*road_x = (v * ROAD_WIDTH) / denominator;
		}

		// 07/01/1999
		if (*sx >= SURFACE_SIZE)
			{
			//fprintf(out, "sx overflow trapped\n");
			*sx = SURFACE_SIZE-1;
			}
		if (*sx < 0)
			{
			//fprintf(out, "sx underflow trapped\n");
			*sx = 0;
			}

		// top edge - calculate surface z position
		u = (((x-ox) * vz) + ((oz-z) * vx));	// needs to be divided by denominator
		denominator = ((ux * vz) - (uz * vx));
		// do divide afterwards to avoid need for floating point calculation
		if (denominator == 0)
			*sz = 0;	// 28/06/2007 prevent division by zero
		else
			*sz = (u * SURFACE_SIZE) / denominator;

		// 07/01/1999
		if (*sz >= SURFACE_SIZE)
			{
			//fprintf(out, "sz overflow trapped\n");
			*sz = SURFACE_SIZE-1;
			}
		if (*sz < 0)
			{
			//fprintf(out, "sz underflow trapped\n");
			*sz = 0;
			}
		return;
		}
	}


/*	======================================================================================= */
/*	Function:		CalculateActualWheelHeights												*/
/*																							*/
/*	Description:	Calculate the height (y value) of each car wheel						*/
/*	======================================================================================= */

static void CalculateActualWheelHeights (void)
	{
	short sin_x, cos_x;
	short sin_z, cos_z;

	// see note at bottom of CalculateWheelXZOffsets regarding
	// a possible different method of calculating these heights

	GetSinCos(player_x_angle, &sin_x, &cos_x);	// cosine not used
	GetSinCos(player_z_angle, &sin_z, &cos_z);	// cosine not used


	rear_actual_height = player_y;
	// 29/06/1998 - sign changed on next line
	rear_actual_height -= ((long)sin_x << (4+15-LOG_PRECISION));
	rear_actual_height >>= 8;

	front_right_actual_height = player_y;
	// 29/06/1998 - sign changed on next line
	front_right_actual_height += ((long)sin_x << (4+15-LOG_PRECISION));
	// 29/06/1998 - sign changed on next line
	front_right_actual_height -= ((long)sin_z << (3+15-LOG_PRECISION));
	front_right_actual_height >>= 8;

	front_left_actual_height = player_y;
	// 29/06/1998 - sign changed on next line
	front_left_actual_height += ((long)sin_x << (4+15-LOG_PRECISION));
	// 29/06/1998 - sign changed on next line
	front_left_actual_height += ((long)sin_z << (3+15-LOG_PRECISION));
	front_left_actual_height >>= 8;
	return;
	}


/*	======================================================================================= */
/*	Function:		CalculateXZSpeeds														*/
/*																							*/
/*	Description:	Calculates player's actual X/Z speeds by rotating world speed values	*/
/*	======================================================================================= */

static void CalculateXZSpeeds (void)
{
	short *trig_coeffs = TrigCoefficients();

	// this function basically does the same as RotateCoordinate,
	// then removes the precision from the resulting values

	player_x_speed =  ((player_world_x_speed * (long)trig_coeffs[X_X_COMP]) >> LOG_PRECISION);
	player_x_speed += ((player_world_y_speed * (long)trig_coeffs[X_Y_COMP]) >> LOG_PRECISION);
	player_x_speed += ((player_world_z_speed * (long)trig_coeffs[X_Z_COMP]) >> LOG_PRECISION);

	player_y_speed = 0;	// zero for current implementation

// player's Y speed not used but would be calculated as :-
//
//	player_y_speed =  ((player_world_x_speed * (long)trig_coeffs[Y_X_COMP]) >> LOG_PRECISION);
//	player_y_speed += ((player_world_y_speed * (long)trig_coeffs[Y_Y_COMP]) >> LOG_PRECISION);
//	player_y_speed += ((player_world_z_speed * (long)trig_coeffs[Y_Z_COMP]) >> LOG_PRECISION);

	player_z_speed =  ((player_world_x_speed * (long)trig_coeffs[Z_X_COMP]) >> LOG_PRECISION);
	player_z_speed += ((player_world_y_speed * (long)trig_coeffs[Z_Y_COMP]) >> LOG_PRECISION);
	player_z_speed += ((player_world_z_speed * (long)trig_coeffs[Z_Z_COMP]) >> LOG_PRECISION);
	return;
}


/*	======================================================================================= */
/*	Function:		SetWheelRotationSpeed													*/
/*																							*/
/*	Description:	(not needed yet)			*/
/*	======================================================================================= */

/*
set.wheel.rotation.speed :-

// pos.players.z.speed not stored by this function - use abs(players.z.speed) instead

	if (touching.road == 0)
		{
		// Not touching road, so reduce wheel speed by one quarter
		reduction = wheel.rotation.speed / 4;
		wheel.rotation.speed - reduction;
		return;
		}

	// touching road
	if (abs(players.z.speed) < 0x800)
		{
		// multiply by 8 and use as wheel speed
		wheel.rotation.speed = abs(players.z.speed) * 8;
		}
	else
		{
		// double it, add $3000 and use as wheel speed
		wheel.rotation.speed = (abs(players.z.speed) * 2) + 0x3000;
		if (wheel.rotation.speed > 0xffff)
			wheel.rotation.speed = 0xff00;		// set to maximum value
		}
	return;
*/
static void SetOneWheelRotationSpeed(long touching_road, long player_z_speed, long *wheel_rotation_speed)
{
	if(touching_road == 0) 
	{
		// Not touching road, so reduce wheel speed by one quarter
		long reduction = (*wheel_rotation_speed) / 4;
		*wheel_rotation_speed -= reduction;
		return;
	}
	if(abs(player_z_speed) < 0x800)
		{
		// multiply by 8 and use as wheel speed
		*wheel_rotation_speed = abs(player_z_speed) * 8;
		}
	else
		{
		// double it, add $3000 and use as wheel speed
		*wheel_rotation_speed = (abs(player_z_speed) * 2) + 0x3000;
		if (*wheel_rotation_speed > 0xffff)
			*wheel_rotation_speed = 0xff00;		// set to maximum value
		}
}

static void SetWheelRotationSpeed()
{
	SetOneWheelRotationSpeed(front_left_amount_below_road, player_z_speed, &front_left_wheel_speed);
	SetOneWheelRotationSpeed(front_right_amount_below_road, player_z_speed, &front_right_wheel_speed);
}

/*	======================================================================================= */
/*	Function:		CalculateGravityAcceleration											*/
/*																							*/
/*	Description:	Calculate car acceleration due to gravity								*/
/*	======================================================================================= */

static void CalculateGravityAcceleration (void)
	{
	short *trig_coeffs = TrigCoefficients();

	// Gravity acts on the Y axis only.  Therefore only Y components are used
	// 17/05/1998 - CAR_WEIGHT renamed to GRAVITY_ACCELERATION

	// Acceleration along car's X axis
	gravity_x_acceleration = ((-GRAVITY_ACCELERATION *
											(long)trig_coeffs[X_Y_COMP]) >> LOG_PRECISION);

	// Acceleration along car's Y axis
	gravity_y_acceleration = ((-GRAVITY_ACCELERATION *
											(long)trig_coeffs[Y_Y_COMP]) >> LOG_PRECISION);

	// Acceleration along car's Z axis
	gravity_z_acceleration = ((-GRAVITY_ACCELERATION *
											(long)trig_coeffs[Z_Y_COMP]) >> LOG_PRECISION);

#ifdef	HIGHER_FRAME_RATE
	// 08/11/1998 - allow four times the frame rate by dividing accelerations by four
	gravity_x_acceleration++;
	gravity_y_acceleration++;
	gravity_z_acceleration++;
	gravity_x_acceleration >>= 1;
	gravity_y_acceleration >>= 1;
	gravity_z_acceleration >>= 1;
#endif
	return;
	}


/*	======================================================================================= */
/*	Function:		CarCollisionDetection													*/
/*																							*/
/*	Description:	Calculate car acceleration caused by collision with other objects		*/
/*	======================================================================================= */

long damaged_limit = 10;	// Actually track/league dependant (could add to track data)

	// NOTE: road_cushion_value is 0 for standard league and 1 for super league
	//		 fourteen_frames_elapsed has value of 0 or -1 (set)
long road_cushion_value = 0, fourteen_frames_elapsed = 0;


// following are only global due to use by two functions - could be passed in instead
static long front_left_height_difference,
			front_right_height_difference,
			rear_height_difference;

static long front_difference_below_road,
			overall_difference_below_road;


static void CarCollisionDetection (void)
	{
	// local variables
	long difference;

	long average_front_amount_below_road,
		 average_amount_below_road;


	grounded_count = 0;
	damage_value = 0;
	damaged = 0;

	// Front left wheel collision
	CalculateWheelCollision(front_left_road_height,
							front_left_actual_height,
							&front_left_height_difference,
							&old_front_left_difference,
							&front_left_amount_below_road,
							&front_left_damage);

	// Front right wheel collision
	CalculateWheelCollision(front_right_road_height,
							front_right_actual_height,
							&front_right_height_difference,
							&old_front_right_difference,
							&front_right_amount_below_road,
							&front_right_damage);

	// Rear wheel collision
	CalculateWheelCollision(rear_road_height,
							rear_actual_height,
							&rear_height_difference,
							&old_rear_difference,
							&rear_amount_below_road,
							&rear_damage);


//****************************************

	average_front_amount_below_road = (front_left_amount_below_road + front_right_amount_below_road) >> 1;
	average_amount_below_road = (average_front_amount_below_road + rear_amount_below_road) >> 1;


	CalculateCarCollisionAcceleration(average_amount_below_road);

	difference = (front_left_amount_below_road - front_right_amount_below_road) * 3;
	// limit to maximum
	if (difference > 0x1000) difference = 0x1000;
	if (difference < -0x1000) difference = -0x1000;
	front_difference_below_road = difference;

//****************************************

	difference = average_front_amount_below_road - rear_amount_below_road;
	overall_difference_below_road = difference;


//****************************************

	touching_road = (average_amount_below_road != 0 ? TRUE : FALSE);

	if ((! touching_road) && (! on_chains))
		{
		// get angle in Amiga StuntCarRacer format (i.e. correct sign)
		long angle = (player_x_angle < (_180_DEGREES) ? (player_x_angle) :
														(player_x_angle - _360_DEGREES));

		if (((angle < 0) && ((TrackID == ROLLER_COASTER) || (TrackID == SKI_JUMP)))
			||
			(angle >= 0))
			{
			difference = -128;

			// check roller coaster - don't need to do anything
			// check ski jump
			if ((angle < 0) && (TrackID == SKI_JUMP))
				difference = -8;

			if (angle >= 0x1000)
				difference = -256;

			difference -= overall_difference_below_road;
			if ((difference < 0) && (player_x_rotation_speed >= -256))
				overall_difference_below_road = difference;
			}
		}


	// following function won't do anything at first
	LiftCarOntoTrack();

	car_to_road_collision_z_acceleration = car_collision_z_acceleration;

	CarToCarCollision();

//****************************************

//******** Play grounded sound if necessary ********

	if (grounded_delay > 0) --grounded_delay;

	if (grounded_count == 0)
		return;

	long amiga_volume = (damage_value >> 8) * 4;
	// minimum volume = 28, maximum volume = 64
	if (amiga_volume < 28) amiga_volume = 28;
	if (amiga_volume > 64) amiga_volume = 64;

	GroundedSoundBuffer->SetVolume(AmigaVolumeToDirectX(amiga_volume));

	if (grounded_delay == 0)
		{
		//GroundedSoundBuffer->SetCurrentPosition(0);
		GroundedSoundBuffer->Play(NULL,NULL,NULL);	// not looping
		grounded_delay = 5;
		}

	return;
	}


static void CalculateWheelCollision (long road_height,
									 long actual_height,
									 long *height_difference_out,
									 long *old_difference_in_out,
									 long *amount_below_road_in_out,
									 long *damage_in_out)
	{
	long new_difference;
	long amount_below_road, old_amount_below_road;
	long damage;


	*height_difference_out = road_height - actual_height - wreck_wheel_height_reduction;

	new_difference = *height_difference_out;
	if (new_difference > 0x1400)
		new_difference = 0x1400;
	else if (new_difference < -0x300)
		new_difference = -0x300;

	amount_below_road = new_difference - *old_difference_in_out;
	// 21/05/1998 - '/ 256' changed to '>> 8', to match Amiga StuntCarRacer exactly
	amount_below_road = ((amount_below_road * INCREASE) >> 8) + new_difference;

	if (amount_below_road >= 0)
		{
		old_amount_below_road = *amount_below_road_in_out;
		*amount_below_road_in_out = amount_below_road;

		if ((amount_below_road >= 0x400) && (old_amount_below_road < 0x200))
			grounded_count++;	// wheel grounded - update grounded wheel count

		damage = *amount_below_road_in_out - (road_cushion_value * 256);
		if (damage >= 0x700)
			{
			if (damage > damage_value)
				damage_value = damage;

			damage -= 0x600;
			if (fourteen_frames_elapsed == 0)
				{
				damaged_count++;
				if (damaged_count < damaged_limit)
					{
					damage /= 256;
					// NOTE next line may be unnecessary
					damage &= 0xff;
					damage += (damage / 2);
					damage += *damage_in_out;
					if (damage > 0xff) damage = 0xff;
					*damage_in_out = damage;
					damaged = 0x80;
					}
				}
			if (*amount_below_road_in_out >= 0x1200)
				*amount_below_road_in_out = 0x11ff;
			}
		else
			damaged_count = 0;
		}
	else
		{
		*amount_below_road_in_out = 0;
		damaged_count = 0;
		}

	*old_difference_in_out = new_difference;
	}


static void CalculateCarCollisionAcceleration (long average_amount_below_road)
	{
	// 21/05/1998 - changed to use shifts rather than divides, to match Amiga StuntCarRacer exactly

	// average_amount_below_road is the force exerted by the road on the car.
	//
	// Force is directed through the Y axis of the road surface.  Therefore only
	// Y components are used.
	//
	// X acceleration = force * -cosx.sinz
	//
	// Y acceleration = force * cosx.cosz
	//
	// Z acceleration = force * sinx

	long x_inclination_to_road;
	long y_inclination_to_road = 0;
	long z_inclination_to_road;
	long log_car_length_factor = 4, log_car_width_factor = 3;	// Length is twice the width
	long front_height_difference, surface_value;
	long surface_sinx, surface_cosx;
	long surface_sinz, surface_cosz;
	long surface_cosx_cosz, surface_cosx_sinz;

	// y_inclination_to_road is zero because road exists in X and Z planes only

	// Calculate x_inclination_to_road
	front_height_difference = (front_left_height_difference +
							   front_right_height_difference) >> 1;
	x_inclination_to_road = (front_height_difference -
							 rear_height_difference) >> log_car_length_factor;

	// Calculate sin and cos of X angle between car and road surface
	CalculateInclinationSinCos(x_inclination_to_road,
							   &surface_sinx,
							   &surface_cosx);

	// Calculate z_inclination_to_road
	z_inclination_to_road = (front_left_height_difference -
							 front_right_height_difference) >> log_car_width_factor;

	// Calculate sin and cos of Z angle between car and road surface
	CalculateInclinationSinCos(z_inclination_to_road,
							   &surface_sinz,
							   &surface_cosz);

	surface_cosx_cosz = (surface_cosx * surface_cosz) >> 8;
	surface_cosx_sinz = (surface_cosx * surface_sinz) >> 8;

	//******** Calculate car collision X acceleration ********

	if (z_inclination_to_road < 0)
		surface_value = -surface_cosx_sinz;
	else
		surface_value = surface_cosx_sinz;

	car_collision_x_acceleration = (average_amount_below_road * surface_value) >> 8;

	//******** Calculate car collision Y acceleration ********

	if (y_inclination_to_road < 0)		// never the case at the moment
		surface_value = -surface_cosx_cosz;
	else
		surface_value = surface_cosx_cosz;

	car_collision_y_acceleration = (average_amount_below_road * surface_value) >> 8;

	//******** Calculate car collision Z acceleration ********

	if (x_inclination_to_road < 0)
		surface_value = surface_sinx;
	else
		surface_value = -surface_sinx;

	car_collision_z_acceleration = (average_amount_below_road * surface_value) >> 8;


#ifdef	HIGHER_FRAME_RATE
	// 08/11/1998 - allow four times the frame rate by dividing accelerations by four
	car_collision_x_acceleration++;
	car_collision_y_acceleration++;
	car_collision_z_acceleration++;
	car_collision_x_acceleration >>= 1;
	car_collision_y_acceleration >>= 1;
	car_collision_z_acceleration >>= 1;
#endif
	return;
	}


static long Cosine_Conversion_Table[] =

// Used to convert a sin value from (0*256 - 1*256) into a cosine value.
//
// There are 128 values in this table representing sin values increasing in
// increments of 1/128.
//
// Each value is calculated by getting the inverse sin of the sin value, to
// give the actual angle, then taking the cosine of this angle.  The result
// is then multiplied by 256.
//
// First 8 values should ideally be 256.

// NOTE: They can be changed to 256 at some point, to see what happens, because they are now longs
{
	0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
	0xff,0xff,0xff,0xff,0xff,0xff,0xfe,0xfe,
	0xfe,0xfe,0xfd,0xfd,0xfd,0xfd,0xfc,0xfc,
	0xfb,0xfb,0xfb,0xfa,0xfa,0xf9,0xf9,0xf8,
	0xf8,0xf7,0xf7,0xf6,0xf6,0xf5,0xf4,0xf4,
	0xf3,0xf3,0xf2,0xf1,0xf0,0xf0,0xef,0xee,
	0xed,0xec,0xec,0xeb,0xea,0xe9,0xe8,0xe7,
	0xe6,0xe5,0xe4,0xe3,0xe2,0xe1,0xe0,0xdf,
	0xde,0xdd,0xdb,0xda,0xd9,0xd8,0xd6,0xd5,
	0xd4,0xd2,0xd1,0xcf,0xce,0xcc,0xcb,0xc9,
	0xc8,0xc6,0xc5,0xc3,0xc1,0xbf,0xbe,0xbc,
	0xba,0xb8,0xb6,0xb4,0xb2,0xb0,0xae,0xac,
	0xa9,0xa7,0xa5,0xa2,0xa0,0x9d,0x9b,0x98,
	0x95,0x92,0x8f,0x8c,0x89,0x86,0x83,0x7f,
	0x7c,0x78,0x74,0x70,0x6c,0x68,0x63,0x5e,
	0x59,0x53,0x4d,0x47,0x3f,0x37,0x2d,0x20
};


static void CalculateInclinationSinCos (long inclination_in,
										long *inclination_sin_out,
										long *inclination_cos_out)
	{
	// inclination_in is effectively the sin of the inclination angle

	// but it currently has the sign removed and is limited to 255 to enable indexing
	// into the Cosine_Conversion_Table - the sign is re-introduced by the above routine,
	// just before each of the accelerations is calculated

	// future change would be to remove the table and use trig functions instead
	// this would remove the need for a sign check in the above function and may
	// also remove the need to limit the value below to 255

	inclination_in = abs(inclination_in);

	if (inclination_in < 256)
		*inclination_sin_out = inclination_in;
	else
		*inclination_sin_out = 255;

	// note only 128 values in table
	*inclination_cos_out = Cosine_Conversion_Table[(*inclination_sin_out)/2];
	return;
	}


static void LiftCarOntoTrack (void)
	{
	return;
	}


/*	======================================================================================= */
/*	Function:		CalculateTotalAcceleration												*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

static void CalculateTotalAcceleration (void)
	{
	long reduction, twice_y;

	player_y_acceleration = gravity_y_acceleration +
							car_collision_y_acceleration;

#ifdef	HIGHER_FRAME_RATE
	// 08/11/1998 - allow four times the frame rate by dividing accelerations by four
//	engine_z_acceleration++;		// 10/12/1998
//	engine_z_acceleration >>= 1;	// 10/12/1998
#endif

	// reduce engine_z_acceleration if car is accelerating and not travelling backwards
	// this probably simulates the effect of wind resistance and the
	// car having reduced ability to accelerate as speed increases
	//21/05/1998 - old method - if ((engine_z_acceleration > 0) && (player_z_speed >= 0))
	reduction = ((engine_z_acceleration >> 8) | (player_z_speed >> 8)) & 0xff;
	if ((reduction & 0x80) != 0x80)	// i.e. not negative
		{
		if ((engine_z_acceleration & 0xff) != 0)
			{
			engine_z_acceleration -= reduction;
			}
		}

	// limit engine_z_acceleration to (2 * car_collision_y_acceleration) ?
	// this possibly prevents the car from accelerating
	// if it is not touching the road sufficiently (not enough grip)
	twice_y = GetTwiceCollisionYAcceleration();		// should always be +'ve
	if (abs(engine_z_acceleration) >= twice_y)
		{
		if (engine_z_acceleration < 0)
			twice_y = -twice_y;		// correct sign

		engine_z_acceleration = twice_y;
		}

	player_z_acceleration = engine_z_acceleration +
							gravity_z_acceleration +
							car_collision_z_acceleration;

	CalculateXAcceleration();
	return;
	}


static long GetTwiceCollisionYAcceleration (void)
	{
	if (! touching_road)
		return(0);

	return(car_collision_y_acceleration * 2);
	}


static void CalculateXAcceleration (void)
	{
	long twice_y, acceleration, speed_diff;

	acceleration = gravity_x_acceleration + car_collision_x_acceleration;
	speed_diff = acceleration - player_x_speed;	// speed increase minus current speed

	twice_y = GetTwiceCollisionYAcceleration();		// should always be +'ve
	if (abs(speed_diff) >= twice_y)
		{
		if (player_x_speed < 0)
			twice_y = -twice_y;		// correct sign

		acceleration -= twice_y;
		player_x_acceleration = acceleration;

		// FOLLOWING VALUE NOT USED AT PRESENT
		////collision_in_air = TRUE;	// not sure if it really signifies collision in air
									// don't think it is used anyway
		}
	else
		{
		// why isn't gravity_x_acceleration added here ?
		player_x_acceleration = car_collision_x_acceleration - player_x_speed;

		// FOLLOWING VALUE NOT USED AT PRESENT
		////collision_in_air = FALSE;
		}

	return;
	}


/*	======================================================================================= */
/*	Function:		CalculateSteering														*/
/*																							*/
/*	Description:	Allow the car to steer													*/
/*	======================================================================================= */

static long y_angle_difference, difference_angle, pos_difference_angle;


static void CalculateSteering (void)
	{
	// basically affects player_y_angle
	//			     and player_y_rotation_acceleration (which affects player_y_angle)
	//
	// reason why player_y_angle sometimes needs direct adjustment:-
	//	   to give a one-off adjustment - adjusting the acceleration has a continuing effect

	static long piece = 0;
	long rx, rz;
	long section_y_angle, scaled_pos_difference_angle;
	long left_hand_bend, steering_amount, section_steering_amount;
	long backwards = FALSE;

	// find the piece that the car is currently on
	IdentifyPiece(player_x, player_z, &piece);
	player_current_piece = piece;

	// get section steering amount
	section_steering_amount = Track[piece].steeringAmount;


	// calculate car x/z position relative to the piece (and in same range)
	CalcXZRelativeToPiece(player_x, player_z, piece, &rx, &rz);

	// calculate y angle of piece at the point where the centre of the car lies
	section_y_angle = CalcSectionYAngle(piece, rx, rz);

	// 22/05/1998 - temporarily reverse section_y_angle
	section_y_angle = (-section_y_angle & (MAX_ANGLE - 1));

	// calculate the difference between the section and player's y angle
	// this value should go increasingly -'ve when turning to the right
	// and should go increasingly +'ve when turning to the left
	y_angle_difference = section_y_angle - player_y_angle;

	// extra adjustment due to PC StuntCarRacer angles not taking full words
	// should make y_angle_difference range from -180 to 180 degrees
	if (y_angle_difference > (_180_DEGREES)) y_angle_difference -= (_360_DEGREES);
	if (y_angle_difference < -(_180_DEGREES)) y_angle_difference += (_360_DEGREES);
	// this value should go increasingly -'ve when turning to the right
	// and should go increasingly +'ve when turning to the left

	// extra logic to allow car to drive round track in either direction
	// Amiga StuntCarRacer didn't allow for this
	// 01/07/1998 - NOTE: backwards flag only applies to curves
	if (y_angle_difference > (_90_DEGREES))
		{
		y_angle_difference -= (_180_DEGREES);
		backwards = TRUE;
		}
	if (y_angle_difference < -(_90_DEGREES))
		{
		y_angle_difference += (_180_DEGREES);
		backwards = TRUE;
		}

	//SECTION_Y_ANGLE = section_y_angle;


	// If player is on a curved section then adjust the difference angle
	left_hand_bend = FALSE;
	if ((Track[piece].type == 0x80) || (Track[piece].type == 0xc0))
		{
		// curve
		// 01/07/1998 - correctly identify left/right hand bend when driving round backwards
		if ((Track[piece].type == 0x80) ^ Track[piece].oppositeDirection ^ backwards)
			{
			// right hand bend
			y_angle_difference += 217;
			}
		else
			{
			// left hand bend
			y_angle_difference -= 217;
			left_hand_bend = TRUE;
			}
		}


	difference_angle = y_angle_difference;
	pos_difference_angle = abs(y_angle_difference);

	// Save a scaled positive difference angle ranging from 0 to $7fff
	if (pos_difference_angle < 0x800)
		scaled_pos_difference_angle = pos_difference_angle << 4;
	else
		scaled_pos_difference_angle = 0x7fff;	// set to maximum


	// If on last segment of road section then get data for next section
		// (perhaps because last co-ords aren't used by StuntCarRacer ?)
		// - not done at present


	//fprintf(out, "left_right_value %d\n", left_right_value);
	if (left_right_value != 0)
		{
		// player.is.steering

		// work out if pos_difference_angle is going to increase
		// i.e. car is trying to keep in line with the track or not
		long increasing = ((difference_angle < 0) ^ (left_right_value < 0));

		if ((Track[piece].type == 0x80) || (Track[piece].type == 0xc0))
			{
			// curve
			//fprintf(out, "curve\n");
			if ((left_right_value >= 0) ^ left_hand_bend)
				{
				// steering into the bend
				steering_amount = section_steering_amount + 45;
				}
			else
				{
				// steering away from bend
				steering_amount = section_steering_amount - 35;

				// NOTE: left_right_value below just used as +'ve/-'ve flag
				if (left_hand_bend)
					left_right_value = -1;
				else
					left_right_value = 1;

				// ensure steering assistance is not done
				increasing = TRUE;
				}
			}
		else
			{
			// straight
			//fprintf(out, "straight\n");
			steering_amount = section_steering_amount;
			}

		if (! increasing)
			{
			// Add current difference (between player and road) onto steering amount
			// to assist steering when car is trying to keep in line with track
			steering_amount += (scaled_pos_difference_angle >> 8);
			}

		CalculateSteeringAcceleration(steering_amount);
		// end of function
		}
	else
		{
		// player.not.steering
		y_angle_difference = 0;		// zero steering acceleration

		if ((Track[piece].type == 0x00) || (Track[piece].type == 0x40))
			{
			// straight
			AlignCarWithRoad();
			AdjustSteeringAcceleration();
			}
		else
			{
			// curve

			// NOTE: left_right_value below just used as +'ve/-'ve flag
			if (left_hand_bend)
				left_right_value = -1;
			else
				left_right_value = 1;

			steering_amount = section_steering_amount;
			// give effect of centrifugal force ?
			CalculateSteeringAcceleration(steering_amount);
			}
		}

	return;
	}


static void CalculateSteeringAcceleration (long steering_amount)
	{
	// Steering acceleration increases as player's speed increases

	long steering_acceleration;
	// get y_angle_difference, pos_difference_angle from calling function


	// following value calculated in slightly odd way, to match Amiga StuntCarRacer
	steering_acceleration = (player_z_speed * steering_amount) >> 8;

	if (left_right_value < 0)
		{
		// steering left
		steering_acceleration = -steering_acceleration;
		}

	steering_acceleration = steering_acceleration >> 3;


	// store steering acceleration
	y_angle_difference = steering_acceleration;

	if (pos_difference_angle >= (30*256))
		{
		AlignCarWithRoad();
		}
	AdjustSteeringAcceleration();
	return;
	}


static void AlignCarWithRoad (void)
	{
	// Following code used to gradually bring the car back in
	// line with the road - this helps steering considerably

	long adjust, speed;

	// eventually get difference_angle, pos_difference_angle from calling function

	adjust = pos_difference_angle;

	if (adjust >= 256)
		{
		adjust -= (30*256);
		if (adjust >= 0)
			{
			// this section makes a large adjustment, e.g. 60 degrees,
			// for when the car is very out of line (e.g. sideways with respect to road)

			// just use remainder to adjust player's y angle
			// needs to correct signs because PC StuntCarRacer rotation is in opposite direction
			if (difference_angle >= 0)
				player_y_angle += adjust;
			else
				player_y_angle -= adjust;

			return;
			}

		// set adjustment amount to maximum
		adjust = 255;
		}

	// Adjustment of player's Y angle increases as player's speed increases

	speed = abs(player_z_speed) + 0xa00;
	if (speed > 0x7f00)
		speed = 0x7f00;		// set speed amount to maximum



	adjust = ((adjust * speed) >> 15);

#ifdef	HIGHER_FRAME_RATE
	// 08/11/1998 - allow four times the frame rate by dividing adjustment by four
	adjust++;
	adjust >>= 1;
#endif

	if (adjust == 0) adjust = 1;		// atleast do some adjusting


	// needs to correct signs because PC StuntCarRacer rotation is in opposite direction
	if (difference_angle >= 0)
		player_y_angle += adjust;
	else
		player_y_angle -= adjust;

	return;
	}


static void AdjustSteeringAcceleration (void)
	{
	// eventually get y_angle_difference from calling function

	long acceleration = y_angle_difference - player_y_rotation_speed;

	// store steering acceleration
	// needs to correct signs because PC StuntCarRacer rotation is in opposite direction
	if (touching_road)
		player_y_rotation_acceleration = acceleration;
	else
		player_y_rotation_acceleration = 0;	// steering disabled

#ifdef	HIGHER_FRAME_RATE
	// 08/11/1998 - allow four times the frame rate by dividing accelerations by four
	player_y_rotation_acceleration++;
	player_y_rotation_acceleration >>= 1;
#endif

	return;
	}


// current piece x/z co-ords (i.e. four corners of piece)
static long px1, pz1, px2, pz2, px3, pz3, px4, pz4;


static void IdentifyPiece (long x, long z, long *piece_in_out)
	{
	// find the piece that the point is located within
	long piece = *piece_in_out;

	// defaults to the input piece if no piece could be found using the map
	GetPieceUsingMap(x, z, &piece);

	// get the four (x,y,z) corner points of the piece
	GetPieceCoords(piece);


//****************


	// check point is not before or after piece (z direction)
	long xs, xp, zs, zp, rx, rz;
	long before_piece = TRUE, after_piece = TRUE, num_piece_changes;


	// 'before piece' loop
	num_piece_changes = 0;
	while (before_piece)
		{
		CalcXZRelativeToPiece(x, z, piece, &rx, &rz);

		// calculate top dot product => before_piece
		xs = px1 - px4; zs = pz1 - pz4;		// current segment vector
		xp = rx - px4; zp = rz - pz4;		// current point vector
		before_piece = (((xs * zp) - (xp * zs)) < 0 ? TRUE : FALSE);

		if (before_piece)
			{
			// future improvement: try a move in one direction,
			// if this is worse then move in other direction

			// DIRECTION DEPENDANT - WHOLE SECTION
			// go to next piece
			piece++; if (piece > (NumTrackPieces - 1)) piece = 0;
			num_piece_changes++;

			// get the four (x,y,z) corner points of the new piece
			GetPieceCoords(piece);
			}

		// prevent an infinite loop
		if (num_piece_changes >= NumTrackPieces)
			{
#if defined(DEBUG) || defined(_DEBUG)
			fprintf(out, "IdentifyPiece - infinite loop trapped (1)\n");
#endif
			break;
			}
		}

#if defined(DEBUG) || defined(_DEBUG)
	// warn if piece search was inefficient
	if (num_piece_changes > 2)		// arbitrary number
		fprintf(out, "IdentifyPiece - %d changes (1)\n", num_piece_changes);
#endif


	// 'after piece' loop
	num_piece_changes = 0;
	while (after_piece)
		{
		CalcXZRelativeToPiece(x, z, piece, &rx, &rz);

		// calculate bottom dot product => after_piece
		xs = px3 - px2; zs = pz3 - pz2;		// current segment vector
		xp = rx - px2; zp = rz - pz2;		// current point vector
		after_piece = (((xs * zp) - (xp * zs)) < 0 ? TRUE : FALSE);

		if (after_piece)
			{
			// future improvement: try a move in one direction,
			// if this is worse then move in other direction

			// DIRECTION DEPENDANT - WHOLE SECTION
			// go to previous piece
			piece--; if (piece < 0) piece = (NumTrackPieces - 1);
			num_piece_changes++;

			// get the four (x,y,z) corner points of the new piece
			GetPieceCoords(piece);
			}

		// prevent an infinite loop
		if (num_piece_changes >= NumTrackPieces)
			{
#if defined(DEBUG) || defined(_DEBUG)
			fprintf(out, "IdentifyPiece - infinite loop trapped (2)\n");
#endif
			break;
			}
		}

#if defined(DEBUG) || defined(_DEBUG)
	// warn if piece search was inefficient
	if (num_piece_changes > 2)		// arbitrary number
		fprintf(out, "IdentifyPiece - %d changes (2)\n", num_piece_changes);
#endif

	*piece_in_out = piece;
	return;
	}


static void GetPieceCoords (long piece)
	{
	long numSegments = Track[piece].numSegments;

	px2 = Track[piece].coords[0].x;
	pz2 = Track[piece].coords[0].z;

	px3 = Track[piece].coords[1].x;
	pz3 = Track[piece].coords[1].z;

	px1 = Track[piece].coords[(numSegments*4)].x;
	pz1 = Track[piece].coords[(numSegments*4)].z;

	px4 = Track[piece].coords[(numSegments*4)+1].x;
	pz4 = Track[piece].coords[(numSegments*4)+1].z;

	return;
	}


/*	======================================================================================= */
/*	Function:		CalculateWorldAcceleration												*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

static void CalculateWorldAcceleration (void)
	{
	short *trig_coeffs = TrigCoefficients();

	// Adds components of player's (i.e. rotated) X, Y and Z accelerations
	// to give world acceleration values.

	// this function basically does the same as WorldOffset,
	// then removes the precision from the resulting values

	total_world_x_acceleration =  ((player_x_acceleration * (long)trig_coeffs[X_X_COMP]) >> LOG_PRECISION);
	total_world_x_acceleration += ((player_y_acceleration * (long)trig_coeffs[Y_X_COMP]) >> LOG_PRECISION);
	total_world_x_acceleration += ((player_z_acceleration * (long)trig_coeffs[Z_X_COMP]) >> LOG_PRECISION);

	total_world_y_acceleration =  ((player_x_acceleration * (long)trig_coeffs[X_Y_COMP]) >> LOG_PRECISION);
	total_world_y_acceleration += ((player_y_acceleration * (long)trig_coeffs[Y_Y_COMP]) >> LOG_PRECISION);
	total_world_y_acceleration += ((player_z_acceleration * (long)trig_coeffs[Z_Y_COMP]) >> LOG_PRECISION);

	total_world_z_acceleration =  ((player_x_acceleration * (long)trig_coeffs[X_Z_COMP]) >> LOG_PRECISION);
	total_world_z_acceleration += ((player_y_acceleration * (long)trig_coeffs[Y_Z_COMP]) >> LOG_PRECISION);
	total_world_z_acceleration += ((player_z_acceleration * (long)trig_coeffs[Z_Z_COMP]) >> LOG_PRECISION);
	return;
	}


/*	======================================================================================= */
/*	Function:		ReduceWorldAcceleration													*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

extern bool player_close_to_opponent;
extern bool opponent_behind_player;


static void ReduceWorldAcceleration (void)
	{
	long	amount = 0, factor, normal_situation = TRUE;
	long	y_speed, z_speed, reduction;

	factor = 1;		// set maximum reduction factor

	if ((touching_road) || (on_chains))
		{
		amount = abs(car_to_road_collision_z_acceleration >> 8);

		if ((amount >= 3) || (off_map_status != 0) || (WRECKED) || (on_chains))
			{
			// collision_z_acceleration large, off map, wrecked or on chains
			if ((WRECKED) || (on_chains))
				factor = 3;		// set medium reduction factor

			amount = 0x6000;
			normal_situation = FALSE;
			}
		}

	// Normal case - car not on chains, little Z collision with road
	if (normal_situation)
		{
		// reduce accelerations, depending upon car speed

		// get greatest of player's x, y and z speeds
		amount = abs(player_x_speed);

		y_speed = abs(player_y_speed);		// zero for current implementation
		if (y_speed > amount)
			amount = y_speed;

		z_speed = abs(player_z_speed);
		if (z_speed > amount)
			amount = z_speed;

		factor = 5;		// set minimum reduction factor

		// Check slipstream
		//
		// If player and opponent are in line left to right and the opponent is
		// infront of the player then the player is in the slipstream of the
		// opponent, so there is less drag on the player's car.
		if ((player_close_to_opponent) && (!opponent_behind_player))
			{
			// Make reduction smaller
			amount -= (20*128);
			if (amount < 0) amount = 0;
			}
		}

	// Reduce acceleration values using current speed values.
	// amount = reduction amount, factor = overall reduction factor.
	reduction = (((player_world_x_speed * amount) >> 16) >> factor);
	total_world_x_acceleration -= reduction;

	reduction = (((player_world_y_speed * amount) >> 16) >> factor);
	total_world_y_acceleration -= reduction;

	reduction = (((player_world_z_speed * amount) >> 16) >> factor);
	total_world_z_acceleration -= reduction;
	return;
	}


/*	======================================================================================= */
/*	Function:		CalculateXZRotationAcceleration											*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

static void CalculateXZRotationAcceleration (void)
	{
	// Calculate values using current car rotation speeds and inclination values
	// between the car and the road, in order to damp the car X and Z angles
	// and keep the car level with the road, on its X and Z axes.  Also give
	// effect of acceleration.

	// Remember that players_y_rotation_acceleration is set by CalculateSteering()

	// overall.difference.below.road is effectively car X inclination.
	//
	// front.difference.below.road is effectively car Z inclination.

	// question: why aren't the x/z inclinations calculated by
	//			 calculate_car_collision_acceleration used here ?
	//
	// - perhaps values used are really accelerations rather than inclinations

	player_x_rotation_acceleration = overall_difference_below_road -
										(player_x_rotation_speed >> 4);
	if (touching_road)
		{
		// This part lifts the car up at the front during forwards acceleration
		// and, vice versa, dips the front of the car during backwards acceleration.
		player_x_rotation_acceleration += (player_z_acceleration >> 2);
		}

	player_z_rotation_acceleration = front_difference_below_road -
										(player_z_rotation_speed >> 4);

#ifdef	HIGHER_FRAME_RATE
	// 08/11/1998 - allow four times the frame rate by dividing accelerations by four
	player_x_rotation_acceleration++;
	player_z_rotation_acceleration++;
	player_x_rotation_acceleration >>= 1;
	player_z_rotation_acceleration >>= 1;
#endif
	return;
	}


/*	======================================================================================= */
/*	Function:		UpdatePlayersRotationSpeed												*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

static void UpdatePlayersRotationSpeed (void)
	{
	long acceleration;

	acceleration = ((player_x_rotation_acceleration * REDUCTION) >> 8);
	player_x_rotation_speed += acceleration;

	acceleration = ((player_y_rotation_acceleration * REDUCTION) >> 8);
	player_y_rotation_speed += acceleration;

	acceleration = ((player_z_rotation_acceleration * REDUCTION) >> 8);
	player_z_rotation_speed += acceleration;
	return;
	}


/*	======================================================================================= */
/*	Function:		CalculateFinalRotationSpeed												*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

static void CalculateFinalRotationSpeed (void)
	{
	short sin_x, cos_x;
	short sin_z, cos_z;

	GetSinCos(player_x_angle, &sin_x, &cos_x);	// cosine not used
	GetSinCos(player_z_angle, &sin_z, &cos_z);

	// shouldn't need changing because Amiga StuntCarRacer Z rotation appears to be same as
	// PC StuntCarRacer Z rotation (i.e. RotX = Xcosz - Ysinz, RotY = Xsinz + Ycosz)
	// and so does X rotation

	player_final_x_rotation_speed =  ((player_x_rotation_speed * (long)cos_z) >> LOG_PRECISION);
	player_final_x_rotation_speed += ((player_y_rotation_speed * (long)-sin_z) >> LOG_PRECISION);

	player_final_y_rotation_speed =  ((player_x_rotation_speed * (long)sin_z) >> LOG_PRECISION);
	player_final_y_rotation_speed += ((player_y_rotation_speed * (long)cos_z) >> LOG_PRECISION);

	// Calculate final Z rotation speed by rotating Y rotation speed about
	// the X axis and adding it onto the Z rotation speed.
	player_final_z_rotation_speed =  player_z_rotation_speed;
	player_final_z_rotation_speed += ((player_final_y_rotation_speed * (long)sin_x) >> LOG_PRECISION);
	return;
	}


/*	======================================================================================= */
/*	Function:		UpdatePlayersWorldSpeed													*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

static void UpdatePlayersWorldSpeed (void)
	{
	long acceleration;

	acceleration = ((total_world_x_acceleration * REDUCTION) >> 8);
	player_world_x_speed += acceleration;

	acceleration = ((total_world_y_acceleration * REDUCTION) >> 8);
	player_world_y_speed += acceleration;

	acceleration = ((total_world_z_acceleration * REDUCTION) >> 8);
	player_world_z_speed += acceleration;
	return;
	}

/*	======================================================================================= */
/*	Function:		UpdatePlayersPosition													*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

static void UpdatePlayersPosition (void)
	{
	long speed, angle, limit;

//******** Set player's new position ********

#ifdef ORIGINAL
	// following speeds could be worked out differently, using just one shift, then an AND
	// not sure yet why the speeds need the bottom bits clear anyway
	speed = ((player_world_x_speed * REDUCTION) >> 8);
	speed <<= 6;
	// convert to PC StuntCarRacer magnitude
	speed *= (PC_FACTOR * 4);
	player_x += speed;

	speed = ((player_world_y_speed * REDUCTION) >> 8);
	speed <<= 7;	// not sure why this is different
	player_y += speed;

	speed = ((player_world_z_speed * REDUCTION) >> 8);
	speed <<= 6;
	// convert to PC StuntCarRacer magnitude
	speed *= (PC_FACTOR * 4);
	player_z += speed;
#else
	// 22/10/1998 - simplified the above
	speed = ((player_world_x_speed * REDUCTION) * PC_FACTOR);
	player_x += speed;

	speed = ((player_world_y_speed * REDUCTION) >> 1);
	player_y += speed;

	speed = ((player_world_z_speed * REDUCTION) * PC_FACTOR);
	player_z += speed;
#endif

	if (player_y >= 0x10000000)
		player_y = 0x10000000;

//******** Set player's new angles ********

	speed = ((player_final_x_rotation_speed * REDUCTION) >> 8);
	player_x_angle += speed;

	speed = ((player_final_y_rotation_speed * REDUCTION) >> 8);
	player_y_angle += speed;

	speed = ((player_final_z_rotation_speed * REDUCTION) >> 8);
	player_z_angle += speed;

	// 19/05/1998 - limit to valid range as no longer stored as words
	player_x_angle &= (MAX_ANGLE - 1);
	player_y_angle &= (MAX_ANGLE - 1);
	player_z_angle &= (MAX_ANGLE - 1);

//******** Check player's X angle ********

	if ((at_side_byte == 0xe0) && (smaller_limit_required))
		{
		// all wheels off road and car on ground
		limit = 11*256;
		}
	else // not off side of track
		{
		limit = 45*256;
		}

	// get angle in Amiga StuntCarRacer format (i.e. correct sign)
	angle = (player_x_angle < (_180_DEGREES) ? (player_x_angle) :
											   (player_x_angle - _360_DEGREES));

	if (abs(angle) > limit)
		{
		if (angle >= 0)
			angle = limit;
		else
			angle = -limit;

		// get players_x_angle in PC StuntCarRacer format (i.e. correct sign)
		player_x_angle = (angle > 0 ? (angle) : (angle + _360_DEGREES));

		if (((player_x_rotation_speed >= 0) && (angle < 0)) ||
			((player_x_rotation_speed < 0) && (angle >= 0)))
			{
			// values have different signs
			player_x_rotation_speed = 0;
			}
		}

//******** Check player's Z angle ********

	// get angle in Amiga StuntCarRacer format (i.e. correct sign)
	angle = (player_z_angle < (_180_DEGREES) ? (player_z_angle) :
											   (player_z_angle - _360_DEGREES));

	if (abs(angle) > limit)
		{
		if (angle >= 0)
			angle = limit;
		else
			angle = -limit;

		// get players_z_angle in PC StuntCarRacer format (i.e. correct sign)
		player_z_angle = (angle > 0 ? (angle) : (angle + _360_DEGREES));

		if (((player_z_rotation_speed >= 0) && (angle < 0)) ||
			((player_z_rotation_speed < 0) && (angle >= 0)))
			{
			// values have different signs
			player_z_rotation_speed = 0;
			}
		}

//****************************************

	// rest of Amiga StuntCarRacer code not needed
	return;
	}


/*	======================================================================================= */
/*	Function:		CalcSectionYAngle														*/
/*																							*/
/*	Description:	Calculates the piece y angle at the x/z point (e.g. centre of car).		*/
/*																							*/
/*					(Assumes the provided x/z point is within and relative to the piece.)	*/
/*	======================================================================================= */

static long CalcSectionYAngle (long piece,
							   long x,
							   long z)
	{
	long section_y_angle;
	long radius;					// not used
	double distance_from_centre;	// not used

	// check for and handle straight
	if (Track[piece].type == 0x00)
		{
		section_y_angle = -Track[piece].roughPieceAngle;
		section_y_angle &= (MAX_ANGLE - 1);
		return(section_y_angle);
		}
	// check for and handle diagonal straight
	else if (Track[piece].type == 0x40)
		{
		// Amiga StuntCarRacer always adds 0x2000 on for these pieces (i.e. 45 degrees)
		section_y_angle = -(Track[piece].roughPieceAngle + (MAX_ANGLE/8));
		section_y_angle &= (MAX_ANGLE - 1);
		return(section_y_angle);
		}

	// must be a curve (type will be -'ve)
	CalcCurveMeasurements(piece, x, z, &section_y_angle, &radius, &distance_from_centre);

	// change sign if right hand curve (i.e. default calculation is for left hand curve)
	if (! Track[piece].curveToLeft)
		section_y_angle = -section_y_angle;

	// add on rough piece angle to get final section y angle
	section_y_angle -= Track[piece].roughPieceAngle;

	// adjust for normal direction of travel
	if (Track[piece].oppositeDirection)
		section_y_angle += (MAX_ANGLE/2);	// plus 180 degrees

	// limit to valid range
	section_y_angle &= (MAX_ANGLE - 1);

	return(section_y_angle);
	}


/*	======================================================================================= */
/*	Function:		CalcCurveMeasurements													*/
/*																							*/
/*	Description:	Calculates 1) y angle within the piece at the x/z point.				*/
/*							   2) inner or outer edge radius of the piece.					*/
/*							   3) distance from the piece's circle centre to the x/z point.	*/
/*																							*/
/*					(Assumes the provided x/z point is within and relative to the piece.)	*/
/*	======================================================================================= */

static void CalcCurveMeasurements (long piece,
								   long x,
								   long z,
								   long *y_angle_out,
								   long *radius_out,
								   double *distance_from_centre_out)
	{
	long xf, zf, xl, zl, xo, zo, xc, zc;
	long numSegments, radius;
	double o, a, radians, angle;

	// NOTE: Assumes x/z are relative to (and in same range as) piece co-ordinates

	// start of code - initialise outputs to zero
	*y_angle_out = 0;
	*radius_out = 0;
	*distance_from_centre_out = 0;

	// calculate radius of circle that piece is taken from
	// calculates inner or outer edge radius, depending upon co-ordinate layout
	numSegments = Track[piece].numSegments;

	// get first and last co-ordinates from inner or outer edge
	long first = 0, last = numSegments*4;

	xf = Track[piece].coords[first].x;
	zf = Track[piece].coords[first].z;
	xl = Track[piece].coords[last].x;
	zl = Track[piece].coords[last].z;

	// assumes all curved pieces are 45 degree circular arcs
	radius = abs(xl - xf) + abs(zl - zf);

	// 14/05/1998 - need to use horizontal/vertical edge when calculating circle centre
	// check first edge is horizontal/vertical, if not then use last edge
	xo = Track[piece].coords[first+1].x;
	zo = Track[piece].coords[first+1].z;
	if ((xo != xf) && (zo != zf))
		{
		// use last edge
		// note that variable names are now misleading (i.e. opposite meaning)
		xf = Track[piece].coords[last].x;
		zf = Track[piece].coords[last].z;
		xl = Track[piece].coords[first].x;
		zl = Track[piece].coords[first].z;

		xo = Track[piece].coords[last+1].x;
		zo = Track[piece].coords[last+1].z;
		}

	// check resulting edge is horizontal/vertical
	if ((xo != xf) && (zo != zf))
		{
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(out, "Piece %d has no horizontal or vertical edge\n", piece);
#endif
		return;
		}

	// calculate co-ordinate of circle centre
	// uses first co-ordinate from other edge, for comparison
	if (xo != xf)
		{
		// piece edge is horizontal
		if (xf < xl)
			xc = xf + radius;
		else
			xc = xf - radius;

		zc = zf;

		o = (double)(z - zc);
		a = (double)(x - xc);
		}
	else if (zo != zf)
		{
		// piece edge is vertical
		xc = xf;

		if (zf < zl)
			zc = zf + radius;
		else
			zc = zf - radius;

		o = (double)(x - xc);
		a = (double)(z - zc);
		}
	else
		{
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(out, "Piece %d edge is invalid (both ends are same)\n", piece);
#endif
		return;
		}

	// use inverse tan to calculate basic angle in radians
	if (a == 0)		// prevent division by zero
		radians = (double)PI / (double)2;	// 90 degrees
	else
		radians = atan(o/a);	// inverse tan

	// convert radians to internal angle (also round up)
	angle = ((radians * (double)MAX_ANGLE) / ((double)2 * (double)PI));
	// convert to absolute and round up as follows (because abs() isn't for doubles)
	if (angle > 0)
		*y_angle_out = (long)(angle + (double)0.5);
	else
		*y_angle_out = (long)((double)0.5 - angle);


	// output radius
	*radius_out = radius;


	// calculate distance from circle centre to (x,z) point
	*distance_from_centre_out = sqrt((o*o) + (a*a));
	return;
	}


/*	======================================================================================= */
/*	Function:		AmigaVolumeToDirectX													*/
/*																							*/
/*	Description:	Convert an Amiga volume level to a value for use with DirectX			*/
/*	======================================================================================= */

long AmigaVolumeToDirectX (long amiga_volume)
	{
	static long first_time = TRUE;
	static long directx_volume[MAX_AMIGA_VOLUME+1];		// range 0 to MAX
	long i;
	double db;

	if ( first_time )
	    {
		// populate the lookup table
		// NOTE: volume 0 cannot be calculated
		directx_volume[0] = -100 * DIRECTX_VOLUME_FACTOR;	// -100 dB, essentially silent

		for ( i = 1; i < (MAX_AMIGA_VOLUME+1); i++ )
			{
			db = (double)20 * log10((double)i/(double)MAX_AMIGA_VOLUME);
			directx_volume[i] = (long)(db * (double)DIRECTX_VOLUME_FACTOR);
			}

		first_time = FALSE;
		}

	// validate Amiga volume
	if ((amiga_volume < 0) || (amiga_volume > MAX_AMIGA_VOLUME))
		{
#if defined(DEBUG) || defined(_DEBUG)
		fprintf(out, "Invalid Amiga Volume %d - defaulting to maximum\n", amiga_volume);
#endif
		amiga_volume = MAX_AMIGA_VOLUME;
		}

	// return DirectX volume
	return(directx_volume[amiga_volume]);
	}


/*	======================================================================================= */
/*	Function:		PositionCarAbovePiece													*/
/*																							*/
/*	Description:	Position car above middle of piece, facing correct direction			*/
/*	======================================================================================= */

/*
extracts from :-

set.players.restart.position
	find suitable road section for car to start on
	position car above middle of section's square, facing correct direction
	calculate player's x offset from centre of road (flag if off road)
	put player to one side of the road (player.to.side.of.road)
	return;
*/

extern unsigned char sections_car_can_be_put_on[];


static void PositionCarAbovePiece (long piece)
{
	long piece_x, piece_z, height;

	//******** Find section to lower car onto ********
	for (;;)
	{
		long t = GetPieceAngleAndTemplate(piece);
		t &= 0xf;	// templateNum
		if (sections_car_can_be_put_on[t] & 0x80)
		{
			// go to previous piece if already at first surface
			piece--; if (piece < 0) piece = (NumTrackPieces - 1);
		}
		else
			break;
	}

	// Should also reject Track specific pieces (DAT.1c8e8)


	// calculate x/z position of piece's front left corner, within world
	piece_x = Track[piece].x << LOG_CUBE_SIZE;
	piece_z = Track[piece].z << LOG_CUBE_SIZE;

	// set car x/z position to middle of piece
	player_x = piece_x + CUBE_SIZE/2;// + CUBE_SIZE/16;
	player_z = piece_z + CUBE_SIZE/2;// + CUBE_SIZE/16;

	// set car y position
//	debug_position = TRUE;
	CalculateWorldRoadHeight(0, player_x, player_z, &height);
#if defined(DEBUG) || defined(_DEBUG)
	debug_position = FALSE;
	fprintf(out, "PositionCarAbovePiece x,z: 0x%x,0x%x.  CalculateWorldRoadHeight: 0x%x\n", player_x, player_z, height);
#endif
	// convert the result to PC StuntCarRacer magnitude
	height = ((height / PC_FACTOR) >> (LOG_PRECISION-3));

	height = (height + 0xc00) * 256;
	player_y = height;
#if defined(DEBUG) || defined(_DEBUG)
	fprintf(out, "PositionCarAbovePiece player_y 0x%x\n", player_y);
#endif

	// clear car x/z angle
	player_x_angle = 0;
	player_z_angle = 0;

	// set car y angle
	player_y_angle = Track[piece].roughPieceAngle;

	if (Track[piece].oppositeDirection)
		{
		player_y_angle += (MAX_ANGLE/2);	// plus 180 degrees
		}

	// check for and handle diagonal straight
	if (Track[piece].type == 0x40)
		{
		// Amiga StuntCarRacer always adds 0x2000 on for these pieces (i.e. 45 degrees)
		player_y_angle += (MAX_ANGLE/8);
		}

	player_y_angle &= (MAX_ANGLE - 1);

	/*
	 * Then player.to.side.of.road
	 *
	 * Shift player in x direction by 160.
	 *
	 * This is actually x = 160, z = 0 being rotated about the y axis and then added to the player x and z.
	 */
	short sin_y, cos_y;
	GetSinCos(player_y_angle, &sin_y, &cos_y);
	player_x += (160 * (long)cos_y);
	player_z -= (160 * (long)sin_y);
}


/*	======================================================================================= */
/*	Function:		CalculateDisplaySpeed													*/
/*																							*/
/*	Description:	Calculate speed value for display, using player_z_speed					*/
/*	======================================================================================= */

long CalculateDisplaySpeed (void)
	{
	long speed;

	speed = player_z_speed;
	if (speed < 0) speed = 0;

	speed = ((speed * 183) >> 15);

	return(speed);
	}

/*	======================================================================================= */
/*	Function:		UpdateEngineRevs														*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

static long engineRevs = 0;
static long engineRevsChange = 0;
static long engineFluctuation = 0;

// Tested against Amiga
static void UpdateEngineRevs (void)
{
int c;

#ifdef	TEST_AMIGA_UER
	long temp;
	if (GetRecordedAmigaWord(&temp))
	{
		++VALUE2;
		touching_road = temp ? TRUE : FALSE;
	}

	if (GetRecordedAmigaWord(&temp))	//players.input
	{
		accelerate = temp & 0x01 ? TRUE : FALSE;
		brake = temp & 0x02 ? TRUE : FALSE;

	GetRecordedAmigaWord(&player_z_speed);
	GetRecordedAmigaWord(&engineRevs);
	}
#endif

	if (!touching_road)
	{
		// Not touching road, so test if joystick is held forwards or backwards
		c = 0;
		if (accelerate || brake)
			c = 0x9000;
	}
	else
	{
		// Touching road
		c = player_z_speed & (~0xf);	// zero low four bits
		if (c < 0) c = -c;
	}

	c += 0x580;
	c = c >> 3;
	if (engineRevs < 192)
	{
		// If engine revs. are low then increase them slowly (e.g. at race start)
		c = 2;
	}
	else
	{
		// Otherwise calculate revs. change depending on current engine revs.
		c -= engineRevs;
		c = c >> 3;
	}

	engineRevsChange = c;


	/*
	 * Now adjust revs. change
	 */
	if (engineRevsChange >= 0x100)
	{
		// If revs. change is $100 or greater then set to $100
		engineRevsChange = 0x100;
	}
	else if (engineRevsChange < 0)
	{
		if (touching_road)
		{
			// Touching road, so set revs. change to $ff00 minimum
			if (engineRevsChange < -0x100)
				engineRevsChange = -0x100;
		}
		else
		{
			// Not touching road, so set revs. change to $ffe0 minimum
			if (engineRevsChange < -0x20)
				engineRevsChange = -0x20;
		}
	}

	engineFluctuation = rand() & 0xf;

#ifdef	TEST_AMIGA_UER
	CompareRecordedAmigaWord("engine.revs.change", &engineRevsChange);
#endif
}


/*	======================================================================================= */
/*	Function:		FramesWheelsEngine														*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

extern long engineSoundPlaying;

int enginePeriod = 198;
int engineSoundIndex = -1;

//#define	JUST_USE_ONE_SOUND

// Ideas to try:
// All sounds playing but mute the ones that aren't required - WORSE
// Start the new sound playing at the same percentage through as the previous sound - SLIGHTLY BETTER

void FramesWheelsEngine (IDirectSoundBuffer8 *engineSoundBuffers[])
{
/* SECTION BELOW HASN'T BEEN CONVERTED
	clr.w	d1
	clr.w	d2
	tst.b	frame.count
	beq	fwe1
	subq.b	#1,frame.count

fwe1	tst.b	fade.frame.count
	beq	fwe2
	subq.b	#1,fade.frame.count

fwe2	tst.b	B.5d724
	bpl	fwe3

	tst.b	no.wheel.update
	bne	fwe3
	jsr	update.wheel.rotation

fwe3	move.w	sprite.DMA.value,dmacon+custom
*/
// wheel update

leftwheel_angle = (leftwheel_angle+front_left_wheel_speed)&0xfffff;
rightwheel_angle = (leftwheel_angle+front_right_wheel_speed)&0xfffff;

int period, index;
DWORD freq;
int r = engineRevs + engineRevsChange;
static int lastEngineSoundIndex = -1;
DWORD currentPlayCursor;

	if (r < 0)
	{
		//if (turnEngineOff)
		//	{
		// stop engine sound
		// return;
		//	}

		r = 0;
	}

	engineRevs = r;

	r += 378;
	period = 4800000 / r;

	index = 6;

#ifndef JUST_USE_ONE_SOUND
	if (period >= 0x3fff) period = 0x3ffe;

	period = period | engineFluctuation;
	if (period < 124) period = 124;	// lowest possible period

	// Calculate sound index that will give period < 256
	while (period >= 256)
	{
		period >>= 1;
		--index;

		if (index < 0) index = 0;
	}
	freq = AMIGA_PAL_HZ / period;	// Rearranging formula: period = clock constant (AMIGA_PAL_HZ) / frequency (samples per second)

#else

	// Calculate r for sample after tick over sound (i.e. index 1)
	// (Tick over sound cannot be played at high enough frequency)
	// (Even index 1 requires frequencies > 100000Hz sometimes, so may not work on all systems)
	while (index > 1)
	{
		period >>= 1;
		--index;

		r <<= 1;
	}
	freq = ((AMIGA_PAL_HZ/1000) * r) / (4800000/1000);
#endif

	// temp store new engine sound index and period
	enginePeriod = period;
	engineSoundIndex = index;

//	fprintf(out, "period %d, freq %d\n", period, freq);
	if (!engineSoundPlaying)
	{
		// Reset last index so that logic below will restart the engine (e.g. after game was paused)
		lastEngineSoundIndex = -1;
	}

	if (engineSoundIndex != lastEngineSoundIndex)
	{
		// Stop the old engine sound
		if (lastEngineSoundIndex >= 0)
		{
			engineSoundBuffers[lastEngineSoundIndex]->GetCurrentPosition(&currentPlayCursor, NULL);
			engineSoundBuffers[lastEngineSoundIndex]->Stop();
		}
		else
			currentPlayCursor = 0;

		// Start the new engine sound

		// Attempt to start at same position through as previous sound
		if (engineSoundIndex > lastEngineSoundIndex)
			currentPlayCursor = currentPlayCursor / 2;
		else
			currentPlayCursor = currentPlayCursor * 2;

		engineSoundBuffers[engineSoundIndex]->SetCurrentPosition(currentPlayCursor);
		engineSoundBuffers[engineSoundIndex]->Play(NULL,NULL,DSBPLAY_LOOPING);

	lastEngineSoundIndex = engineSoundIndex;
	engineSoundPlaying = TRUE;
	}

	// Set the frequency of the current engine sound
	engineSoundBuffers[engineSoundIndex]->SetFrequency(freq);
}

#ifdef TESTENGINE
extern IDirectSoundBuffer8 *EngineSoundBuffers[];

void EngineSoundStopped (void)
{
	/*
DWORD freq = 3546895 / enginePeriod;

	fprintf(out, "Engine sound stopped\n");

	// Start the new engine sound
	EngineSoundBuffers[engineSoundIndex]->SetCurrentPosition(0);
	EngineSoundBuffers[engineSoundIndex]->Play(NULL,NULL,NULL);

	// Set the frequency of the current engine sound
	EngineSoundBuffers[engineSoundIndex]->SetFrequency(freq);

	engineSoundPlaying = TRUE;
	*/

int period, index;
DWORD freq;
int r;

//	touching_road = TRUE;
//	player_z_speed += 0x100;
//	UpdateEngineRevs();

	engineRevsChange = 2;

	r = engineRevs + engineRevsChange;

	engineRevs = r;

	r += 378;
	period = 4800000 / r;

	index = 6;

	if (period >= 0x3fff) period = 0x3ffe;

//	period = period | engineFluctuation;
	if (period < 124) period = 124;	// lowest possible period

	// Calculate sound index that will give period < 256
	while (period >= 256)
	{
		period >>= 1;
		--index;

		if (index < 0) index = 0;
	}
	freq = AMIGA_PAL_HZ / period;

	enginePeriod = period;
	engineSoundIndex = index;

//	if (index > 0)
//		return;

	// Start the new engine sound
	EngineSoundBuffers[engineSoundIndex]->SetCurrentPosition(0);
	EngineSoundBuffers[engineSoundIndex]->Play(NULL,NULL,NULL);

	// Set the frequency of the current engine sound
	EngineSoundBuffers[engineSoundIndex]->SetFrequency(freq);
}
#endif


/*	======================================================================================= */
/*	Function:		CalculatePlayersRoadPosition											*/
/*																							*/
/*	Description:	Calculate player position values required for Opponent Behaviour		*/
/*	======================================================================================= */

void CalculatePlayersRoadPosition (void)
{
long height;	// Not used

	// Calculate the position of the car's centre
	CalculateWorldRoadHeight(CENTRE, player_x, player_z, &height);
}


/*	======================================================================================= */
/*	Function:		DrawOtherGraphics														*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

void DrawOtherGraphics( void )
{
	// Draw other graphics that are done as part of 'draw.world'
	if ((!on_chains) && (off_map_status != 0))
		DrawDustClouds();

	DrawSparks();

	which_side_byte = 0;	// Amiga StuntCarRacer cleared this in update.wheel.positions
}

/*	======================================================================================= */
/*	Function:		DrawDustClouds															*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

static void DrawDustClouds (void)
{
	// currently just plays the sound effect

	int p = rand();
	p &= 0x1c;
	p += 450;

	OffRoadSoundBuffer->SetFrequency(AMIGA_PAL_HZ / p);

	if (!touching_road)
		return;

//	OffRoadSoundBuffer->Stop();
//	OffRoadSoundBuffer->SetCurrentPosition(0);
	OffRoadSoundBuffer->Play(NULL,NULL,NULL);	// not looping
}

/*	======================================================================================= */
/*	Function:		DrawSparks																*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

static void DrawSparks (void)
{
int p;

	// currently just plays the sound effect

	//VALUE1 = distance_off_road;
	//VALUE2 = which_side_byte;
	if (which_side_byte) goto on_an_edge;

	if (NOT_WRECKED) return;	// if car is not scraping on road

on_an_edge:
	if (off_map_status != 0) return;	// dust clouds will be drawn instead

	p = abs(player_z_speed) >> 8;
	if (p < 1) return;		// if speed is not large enough

	if (p > 50) p = 50;		// set to maximum
	// ferocity.of.sparks.or.clouds = p

	p >>= 1;
	if (p > 31) p = 31;

	p ^= 0x31;
	p &= 0xff;
	p <<= 2;
	p += 170;

	WreckSoundBuffer->SetFrequency(AMIGA_PAL_HZ / p);

	if (!touching_road)
		return;

//	WreckSoundBuffer->SetCurrentPosition(0);
	WreckSoundBuffer->Play(NULL,NULL,NULL);	// not looping
}

/*	======================================================================================= */
/*	Function:		UpdateDamage															*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

void UpdateDamage (void)
{
	if (damaged)
	{
		long d = (front_left_damage + front_right_damage) / 2;	// average front damage
		new_damage = (d + rear_damage) / 2;					// total average damage
		// value new_damage must be used to draw damage line
	}

	if (smashed_countdown)
	{
		--smashed_countdown;
		if (smashed_countdown == 69)
		{
			// change smash to hole, by copying 'damage hole' graphic to damage.hole.position
			nholes++;
			goto PlayCreakSound;
		}

		if (damaged) goto PlayCreakSound;

		return;
	}

	if (!damaged) return;

	if (damage_value < 0x1400) goto PlayCreakSound;

	// if (damage.hole.position == 0) goto PlayCreakSound;
	//--damage.hole.position
	// copy 'damage hole smashed' graphic to damage.hole.position
	nholes++;

	smashed_countdown = 69;

	// Play smash sound effect
	//SmashSoundBuffer->SetCurrentPosition(0);
	SmashSoundBuffer->Play(NULL,NULL,NULL);	// not looping
	return;

PlayCreakSound:
	long amiga_volume = (damage_value >> 8) * 4;
	// minimum volume = 28, maximum volume = 64
	if (amiga_volume < 28) amiga_volume = 28;
	if (amiga_volume > 64) amiga_volume = 64;

	CreakSoundBuffer->SetVolume(AmigaVolumeToDirectX(amiga_volume));
	//CreakSoundBuffer->SetCurrentPosition(0);
	CreakSoundBuffer->Play(NULL,NULL,NULL);	// not looping
	return;
}

/*	======================================================================================= */
/*	Function:		UpdateLapData															*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

#define	LAP_THAT_FINISHES_RACE (4)

extern long opponents_current_piece;	// use as opponents_road_section

bool raceFinished, raceWon;
long lapNumber[NUM_CARS];
static bool carOnFirstHalfOfLap[NUM_CARS] = {false, false};

void ResetLapData (long car)
{
	raceFinished = raceWon = FALSE;
	lapNumber[car] = 0;
	carOnFirstHalfOfLap[car] = false;
}

void UpdateLapData (void)
{
	long car, current_piece, start_finish_piece = (StartLinePiece + 1 < NumTrackPieces) ? (StartLinePiece + 1) : 0;

	for (car = OPPONENT; car < NUM_CARS; car++)
	{
		current_piece = car == PLAYER ? player_current_piece : opponents_current_piece;

		if (carOnFirstHalfOfLap[car])
		{
			if (current_piece == HalfALapPiece)
				carOnFirstHalfOfLap[car] = false;
		}
		else if (current_piece == start_finish_piece)
		{
			carOnFirstHalfOfLap[car] = true;
			++lapNumber[car];
		}
	}

//	VALUE2 = lapNumber[OPPONENT];
//	VALUE3 = carOnFirstHalfOfLap[PLAYER] ? 1 : 0;

	for (car = OPPONENT; car < NUM_CARS; car++)
	{
		if (!raceFinished)
		{
			if (lapNumber[car] == LAP_THAT_FINISHES_RACE)
			{
				raceFinished = true;

				// frames to show message for = 44; about 5.64 seconds

				if (CalculateIfWinning(start_finish_piece) < 0)
					raceWon = true;
				else
					raceWon = false;
			}
		}
	}
}

#ifdef NOT_USED
/*	======================================================================================= */
/*	Function:		RewindRecording,														*/
/*					Record,																	*/
/*					PlayBack,																*/
/*					BeginActionReplay														*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

#define	RECORDING_SIZE	(4096)

typedef struct
	{
	BYTE input;		// this is sufficient to hold required input
	} RECORDING;

static size_t RecordingIndex, EndOfRecording;			// indexes into following buffer
static RECORDING RecordingBuffer[RECORDING_SIZE];


static void RewindRecording (void)
	{
	RecordingIndex = 0;
	}


static void Record (DWORD input)
	{
	if (RecordingIndex < RECORDING_SIZE)
		{
		RecordingBuffer[RecordingIndex].input = (BYTE)input;
		++RecordingIndex;
		}

	//VALUE2 = RecordingIndex;
	}


static void PlayBack (DWORD *input)
	{
	if (RecordingIndex < EndOfRecording)
		{
		*input = (DWORD)RecordingBuffer[RecordingIndex].input;
		++RecordingIndex;
		}
	else
		{
		*input = 0;
		RewindRecording();
		Replay = FALSE;
		ReplayFinished = TRUE;
		}

	//VALUE2 = RecordingIndex;
	}


static void WriteRecordingToFile (void)
	{
	char filename[80];
	FILE *f;
	size_t i, size;

	sprintf(filename, "Track%dRecording.bin", TrackID);

	if ((f = fopen(filename, "wb")) == NULL )		// write, binary
		{
		fprintf(out, "Can't open %s\n", filename);
		return;
		}

	size = EndOfRecording;
	if ((i = fwrite(RecordingBuffer, sizeof(RECORDING), size, f)) != size)
		{
		fprintf(out, "Can't write %s correctly (%d)\n", filename, i);
		fclose(f);
		return;
		}

	fclose(f);
	return;
	}


static void ReadRecordingFromFile (void)
	{
	char filename[80];
	errno_t err;
	FILE *in_file;
	size_t i;

	memset(RecordingBuffer, 0, sizeof(RecordingBuffer));

	sprintf_s(filename, sizeof(filename), "Track%dRecording.bin", TrackID);

	if ((err = fopen_s(&in_file, filename, "rb")) != 0)		// read, binary
		{
		fprintf(out, "Can't open %s\n", filename);
		return;
		}

	i = fread(RecordingBuffer, sizeof(char), RECORDING_SIZE, in_file);
	if (i == 0)
		{
		fprintf(out, "Can't read %s correctly (%d)\n", filename, i);
		fclose(in_file);
		return;
		}
	EndOfRecording = i;

	fclose(in_file);
	return;
	}


// request replay of last game
void RequestGameReplay (void)
	{
	EndOfRecording = RecordingIndex;
//	note - think this function has a bug WriteRecordingToFile();
	RewindRecording();
	ReplayRequested = TRUE;

	ReplayLooping = FALSE;
	}


// request replay of pre-recorded game
void RequestStoredReplay (void)
	{
	ReadRecordingFromFile();
	RewindRecording();
	ReplayRequested = TRUE;

	ReplayLooping = TRUE;
	}
#endif

#ifdef USE_AMIGA_RECORDING
/*	======================================================================================= */
/*	Function:		GetRecordedAmigaWord,													*/
/*					GetRecordedAmigaLong,													*/
/*																							*/
/*	Description:				*/
/*	======================================================================================= */

static FILE *AmigaFile = NULL;


static bool OpenAmigaRecording( void )
{
errno_t err;

	if (AmigaFile) return(TRUE);	// Already open

	if ((err = fopen_s(&AmigaFile, "SCRecording.bin", "rb")) != 0)		// read, binary
		{
		fprintf(out, "Can't open SCRecording.bin\n");
		return(FALSE);
		}

	StartOfAmigaRecording = TRUE;
	AmigaRecordingFrame = 0;
	return(TRUE);
}

bool GetRecordedAmigaWord( long *value_out )
{
char b[2];
short s;
size_t i;

	if (!ReplayAmigaRecording) return(FALSE);

	if (!OpenAmigaRecording()) return(FALSE);

	i = fread(b, sizeof(char), 2, AmigaFile);
    if (i == 0)
		{
		int e = ferror(AmigaFile);
		if (e) fprintf(out, "Can't read Amiga word correctly (%d)\n", e);

		return(FALSE);
		}

	s = ((b[0] & 0xff) << 8) | (b[1] & 0xff);

	*value_out = (long)s;
	return(TRUE);
}

bool GetRecordedAmigaLong( long *value_out )
{
char b[4];
long l;
size_t i;

	if (!ReplayAmigaRecording) return(FALSE);

	if (!OpenAmigaRecording()) return(FALSE);

	i = fread(b, sizeof(char), 4, AmigaFile);
    if (i == 0)
		{
		int e = ferror(AmigaFile);
		if (e) fprintf(out, "Can't read Amiga long correctly (%d)\n", e);

		return(FALSE);
		}

	l = ((b[0] & 0xff) << 24) | ((b[1] & 0xff) << 16) | ((b[2] & 0xff) << 8) | (b[3] & 0xff);

	*value_out = l;
	return(TRUE);
}

void CompareAmigaWord( char *name, long amiga_value, long *value )
{
	if (*value != amiga_value)
//	if (abs(*value - amiga_value) > 1)
	{
		++VALUE1;	// Count differences
		fprintf(out, "%s different %d %d (VALUE2 %d)\n", name, amiga_value, *value, VALUE2);
//		*value = amiga_value;	// Use Amiga value when different
	}
}

void CompareRecordedAmigaWord( char *name, long *value )
{
long amiga_value;

	if (!GetRecordedAmigaWord(&amiga_value)) return;

	CompareAmigaWord( name, amiga_value, value );
}

void CloseAmigaRecording( void )
{
	if (AmigaFile)
	{
		fclose(AmigaFile);
		AmigaFile = NULL;
	}
}
#endif
