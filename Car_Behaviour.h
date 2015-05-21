
#ifndef	_CAR_BEHAVIOUR
#define	_CAR_BEHAVIOUR

/*	========= */
/*	Constants */
/*	========= */
#define	CAR_WIDTH	64
#define	CAR_LENGTH	128

// new controls for Car Behaviour, Player 1
// must not clash with other KEY definitions
#define KEY_P1_LEFT		0x00000001l
#define KEY_P1_RIGHT	0x00000002l
#define KEY_P1_HASH		0x00000004l
#define KEY_P1_BRAKE_BOOST	0x00000008l
#define KEY_P1_ACCEL_BOOST	0x00000010l

#define	AMIGA_PAL_HZ	(3546895)

#define	REDUCTION	238		// (238/256)
#define	INCREASE	276		// (276/256)

typedef enum
	{
	OPPONENT = 0,
	PLAYER,
	NUM_CARS
	} CarType;

/*	===================== */
/*	Structure definitions */
/*	===================== */

/*	============================== */
/*	External function declarations */
/*	============================== */
extern void ResetPlayer (void);

extern void CarBehaviour (DWORD input,
						  long *x,
						  long *y,
						  long *z,
						  long *x_angle,
						  long *y_angle,
						  long *z_angle);

extern void LimitViewpointY (long *y);

extern long AmigaVolumeToDirectX (long amiga_volume);

extern long CalculateDisplaySpeed (void);

extern void FramesWheelsEngine (IDirectSoundBuffer8 *engineSoundBuffers[]);
extern void EngineSoundStopped (void);

extern void CalculatePlayersRoadPosition (void);

extern void DrawOtherGraphics (void);
extern void UpdateDamage (void);

extern void ResetLapData (long car);
extern void UpdateLapData (void);

#ifdef USE_AMIGA_RECORDING
extern void RequestGameReplay (void);
extern void RequestStoredReplay (void);

// Following only used for testing against Amiga
extern bool GetRecordedAmigaWord( long *value_out );
extern bool GetRecordedAmigaLong( long *value_out );
extern void CompareAmigaWord( char *name, long amiga_value, long *value );
extern void CompareRecordedAmigaWord( char *name, long *value );
extern void CloseAmigaRecording( void );
#endif

#endif	/* _CAR_BEHAVIOUR */
