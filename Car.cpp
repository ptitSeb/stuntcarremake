/**************************************************************************

    Car.cpp - Functions for manipulating car (excluding player's car behaviour)

 **************************************************************************/

/*	============= */
/*	Include files */
/*	============= */
#include "dxstdafx.h"

#include "Car.h"
#include "StuntCarRacer.h"
#include "3D_Engine.h"
#include "Atlas.h"
/*	===== */
/*	Debug */
/*	===== */
extern FILE *out;

/*	========= */
/*	Constants */
/*	========= */
#define SCR_BASE_COLOUR	26

#define	MAX_VERTICES_PER_CAR	(142*3)

/*	=========== */
/*	Static data */
/*	=========== */

/*	===================== */
/*	Function declarations */
/*	===================== */
/*
static void DrawHorizon( long viewpoint_y,
						 long viewpoint_x_angle,
						 long viewpoint_z_angle );
*/

#ifdef NOT_USED
/*	======================================================================================= */
/*	Functions:		DrawCar																	*/
/*					DrawCarTopSection														*/
/*					DrawCarBottomSection													*/
/*					DrawCarRightWheels														*/
/*					DrawCarLeftWheels														*/
/*					DrawCarRightWheelTread													*/
/*					DrawCarLeftWheelTread													*/
/*					MakeCarWheels															*/
/*																							*/
/*	Description:	Draw a 3D car into the required buffer									*/
/*	======================================================================================= */

static void MakeCarWheels( COORD_3D *cptr,
						   long num_edges,
						   long axle_length,
						   long axle_y,
						   long axle_spacing,
						   long wheel_radius,
						   long wheel_width )
	{
	// pointers to each wheel's co-ordinates
	COORD_3D *front_right_inner_ptr = cptr;
	COORD_3D *front_right_outer_ptr = front_right_inner_ptr + num_edges;
	COORD_3D *front_left_inner_ptr =  front_right_outer_ptr + num_edges;
	COORD_3D *front_left_outer_ptr =  front_left_inner_ptr + num_edges;
	COORD_3D *rear_right_inner_ptr =  front_left_outer_ptr + num_edges;
	COORD_3D *rear_right_outer_ptr =  rear_right_inner_ptr + num_edges;
	COORD_3D *rear_left_inner_ptr =  rear_right_outer_ptr + num_edges;
	COORD_3D *rear_left_outer_ptr =  rear_left_inner_ptr + num_edges;

	// wheel centre co-ordinates
	long front_right_inner_x = (axle_length/2);
	long front_right_outer_x = (axle_length/2) + wheel_width;
	long front_left_inner_x = -front_right_inner_x;
	long front_left_outer_x = -front_right_outer_x;
	long rear_right_inner_x = front_right_inner_x;
	long rear_right_outer_x = front_right_outer_x;
	long rear_left_inner_x = front_left_inner_x;
	long rear_left_outer_x = front_left_outer_x;

	long front_right_y = axle_y;
	long front_left_y = axle_y;
	long rear_right_y = axle_y;
	long rear_left_y = axle_y;

	long front_right_z = (axle_spacing/2);
	long front_left_z = front_right_z;
	long rear_right_z = -(axle_spacing/2);
	long rear_left_z = rear_right_z;

	long i, y, z;
	double angle, step;

	// start of code
	angle = PI/11;
	step = ((double)2 * (double)PI) / (double)num_edges;

	for ( i = 0; i < num_edges; i++ )
		{
		y = (long)(cos( angle ) * (double)wheel_radius);
		z = (long)(sin( angle ) * (double)wheel_radius);
		angle += step;

		if (angle > (2 * PI))
			angle -= (2 * PI);

		// store current co-ordinate for front right wheel
		front_right_inner_ptr->x = front_right_inner_x;
		front_right_inner_ptr->y = (y + front_right_y);
		front_right_inner_ptr->z = (z + front_right_z);
		front_right_inner_ptr++;

		front_right_outer_ptr->x = front_right_outer_x;
		front_right_outer_ptr->y = (y + front_right_y);
		front_right_outer_ptr->z = (z + front_right_z);
		front_right_outer_ptr++;

		// store current co-ordinate for front left wheel
		front_left_inner_ptr->x = front_left_inner_x;
		front_left_inner_ptr->y = (y + front_left_y);
		front_left_inner_ptr->z = (z + front_left_z);
		front_left_inner_ptr++;

		front_left_outer_ptr->x = front_left_outer_x;
		front_left_outer_ptr->y = (y + front_left_y);
		front_left_outer_ptr->z = (z + front_left_z);
		front_left_outer_ptr++;

		// store current co-ordinate for rear right wheel
		rear_right_inner_ptr->x = rear_right_inner_x;
		rear_right_inner_ptr->y = (y + rear_right_y);
		rear_right_inner_ptr->z = (z + rear_right_z);
		rear_right_inner_ptr++;

		rear_right_outer_ptr->x = rear_right_outer_x;
		rear_right_outer_ptr->y = (y + rear_right_y);
		rear_right_outer_ptr->z = (z + rear_right_z);
		rear_right_outer_ptr++;

		// store current co-ordinate for rear left wheel
		rear_left_inner_ptr->x = rear_left_inner_x;
		rear_left_inner_ptr->y = (y + rear_left_y);
		rear_left_inner_ptr->z = (z + rear_left_z);
		rear_left_inner_ptr++;

		rear_left_outer_ptr->x = rear_left_outer_x;
		rear_left_outer_ptr->y = (y + rear_left_y);
		rear_left_outer_ptr->z = (z + rear_left_z);
		rear_left_outer_ptr++;
		}
	}


static void DrawCar( BYTE base_colour )
	{
	static long first_time = TRUE;

	// currently has same length as behavioural car, but is about 20% narrower
	// 24/04/1998 because co-ordinates are divided by 8

	// car co-ordinates		  x,   y,   z
	static COORD_3D car[] = {{416,-256,1024},	// floor
							 {-416,-256,1024},
							 {416,-256,-1024},
							 {-416,-256,-1024},
							 //
							 {416,-500,950},	// wing and door tops
							 {-416,-500,950},
							 {416,-600,400},
							 {-416,-600,400},
							 {416,-600,-1000},
							 {-416,-600,-1000},
							 {416,-600,-350},
							 {-416,-600,-350},
							 //
							 {364,-800,100},	// roof
							 {-364,-800,100},
							 {364,-800,-350},
							 {-364,-800,-350},
							 {364,-800,-800},
							 {-364,-800,-800},
							 //
							 {0,0,0},			// front right wheel inner
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 //
							 {0,0,0},			// front right wheel outer
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 //
							 {0,0,0},			// front left wheel inner
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 //
							 {0,0,0},			// front left wheel outer
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 //
							 {0,0,0},			// rear right wheel inner
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 //
							 {0,0,0},			// rear right wheel outer
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 //
							 {0,0,0},			// rear left wheel inner
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 //
							 {0,0,0},			// rear left wheel outer
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0},
							 {0,0,0}};

	// car roof surface
	long car_roof[4] = {12, 16, 17, 13};	// offsets into co-ordinates above

	// start of code
	if (first_time)
		{
		first_time = FALSE;
		MakeCarWheels(&car[18],
					  8,		  // number of edges per wheel
					  (1024-192), // axle length (i.e. distance between left and right wheels)
					  -240,		  // axle y position (i.e. ground clearance)
					  1500,		  // axle spacing (i.e. wheelbase)
					  240,		  // wheel radius (same as ground clearance)
					  192);		  // wheel width

		// temporarily reduce car size at runtime
		// eventually car size will be decided and this code can be removed
		long i, reduce = 8;
		for (i = 0; i < (sizeof(car) / sizeof(COORD_3D)); i++)
			{
			car[i].x /= reduce;
			car[i].y /= reduce;
			car[i].z /= reduce;
			}
		}

	if (TransformCoordinates(car, sizeof(car)) != TRUE)
		return;

	// now decide whether car top or bottom section should be drawn first
	// this decision is taken depending upon the visibility of the car roof
	if (PolygonVisible(car_roof) == TRUE)
		{
		DrawCarBottomSection(base_colour);
		DrawCarTopSection(base_colour);

		SetTextureColour(base_colour + 4);
		Polygon(car_roof, 4);		// ideally wouldn't do visibility check again here
		}
	else
		{
		DrawCarTopSection(base_colour);
		DrawCarBottomSection(base_colour);
		}
	}


static void DrawCarTopSection( BYTE base_colour )
	{
	// car top surfaces, e.g. windows and areas behind them
	long car_top_side1[4] = {10, 8, 16, 14};	// area behind side windows
	long car_top_side2[4] = {15, 17, 9, 11};

	long car_front_window[4] = {6, 12, 13, 7};
	long car_side_window1[4] = {6, 10, 14, 12};
	long car_side_window2[4] = {13, 15, 11, 7};
	long car_rear_window[4] = {9, 17, 16, 8};

	// start of code
	SetTextureColour(base_colour + 3);
	Polygon(car_top_side1, 4);
	Polygon(car_top_side2, 4);

	SetTextureColour(base_colour + 5);
	Polygon(car_front_window, 4);
	Polygon(car_side_window1, 4);
	Polygon(car_side_window2, 4);
	Polygon(car_rear_window, 4);
	}


static void DrawCarBottomSection( BYTE base_colour )
	{
	// car bottom surfaces, e.g. wings, bonnet, bottom of doors
	long car_side1[5] = {0, 2, 8, 6, 4};
	long car_side2[5] = {9, 3, 1, 5, 7};

	long car_floor[4] = {0, 1, 3, 2};

	long car_front[4] = {0, 4, 5, 1};
	long car_rear[4] = {3, 9, 8, 2};

	long car_bonnet[4] = {4, 6, 7, 5};

	// start of code
	// decide order in which to draw right wheels, floor and left wheels,
	// depending upon the visibility of one of the car sides (can use either)
	if (PolygonVisible(car_side1) == TRUE)
		{
		DrawCarLeftWheels(base_colour);

		SetTextureColour(base_colour + 1);
		Polygon(car_floor, 4);

		SetTextureColour(base_colour + 2);
		Polygon(car_side1, 5);		// ideally wouldn't do visibility check again here

		DrawCarRightWheels(base_colour);
		}
	else
		{
		DrawCarRightWheels(base_colour);

		SetTextureColour(base_colour + 1);
		Polygon(car_floor, 4);

		SetTextureColour(base_colour + 2);
		Polygon(car_side2, 5);

		DrawCarLeftWheels(base_colour);
		}

	SetTextureColour(base_colour + 3);
	Polygon(car_front, 4);
	Polygon(car_rear, 4);

	SetTextureColour(base_colour + 4);
	Polygon(car_bonnet, 4);
	}


static void DrawCarRightWheels( BYTE base_colour )
	{
	long front_right_inner_wheel[8] = {18, 19, 20, 21, 22, 23, 24, 25};
	long front_right_outer_wheel[8] = {33, 32, 31, 30, 29, 28, 27, 26};
	long rear_right_inner_wheel[8] = {50, 51, 52, 53, 54, 55, 56, 57};
	long rear_right_outer_wheel[8] = {65, 64, 63, 62, 61, 60, 59, 58};

	long wheel_orientation[3] = {0, 3, 6};

	// start of code
	if (TransformedZ(18) < TransformedZ(50))
		{
		// front wheel is infront of rear wheel
		SetTextureColour(base_colour + 6);
		PolygonEx(rear_right_inner_wheel, 8, wheel_orientation);
		PolygonEx(rear_right_outer_wheel, 8, wheel_orientation);

		SetTextureColour(base_colour + 7);
		DrawCarRightWheelTread(18+32);

		SetTextureColour(base_colour + 6);
		PolygonEx(front_right_inner_wheel, 8, wheel_orientation);
		PolygonEx(front_right_outer_wheel, 8, wheel_orientation);

		SetTextureColour(base_colour + 7);
		DrawCarRightWheelTread(18);
		}
	else
		{
		// front wheel is behind rear wheel
		SetTextureColour(base_colour + 6);
		PolygonEx(front_right_inner_wheel, 8, wheel_orientation);
		PolygonEx(front_right_outer_wheel, 8, wheel_orientation);

		SetTextureColour(base_colour + 7);
		DrawCarRightWheelTread(18);

		SetTextureColour(base_colour + 6);
		PolygonEx(rear_right_inner_wheel, 8, wheel_orientation);
		PolygonEx(rear_right_outer_wheel, 8, wheel_orientation);

		SetTextureColour(base_colour + 7);
		DrawCarRightWheelTread(18+32);
		}
	}


static void DrawCarLeftWheels( BYTE base_colour )
	{
	long front_left_inner_wheel[8] = {41, 40, 39, 38, 37, 36, 35, 34};
	long front_left_outer_wheel[8] = {42, 43, 44, 45, 46, 47, 48, 49};
	long rear_left_inner_wheel[8] = {73, 72, 71, 70, 69, 68, 67, 66};
	long rear_left_outer_wheel[8] = {74, 75, 76, 77, 78, 79, 80, 81};

	long wheel_orientation[3] = {0, 3, 6};

	// start of code
	if (TransformedZ(34) < TransformedZ(66))
		{
		// front wheel is infront of rear wheel
		SetTextureColour(base_colour + 6);
		PolygonEx(rear_left_inner_wheel, 8, wheel_orientation);
		PolygonEx(rear_left_outer_wheel, 8, wheel_orientation);

		SetTextureColour(base_colour + 7);
		DrawCarLeftWheelTread(18+48);

		SetTextureColour(base_colour + 6);
		PolygonEx(front_left_inner_wheel, 8, wheel_orientation);
		PolygonEx(front_left_outer_wheel, 8, wheel_orientation);

		SetTextureColour(base_colour + 7);
		DrawCarLeftWheelTread(18+16);
		}
	else
		{
		// front wheel is behind rear wheel
		SetTextureColour(base_colour + 6);
		PolygonEx(front_left_inner_wheel, 8, wheel_orientation);
		PolygonEx(front_left_outer_wheel, 8, wheel_orientation);

		SetTextureColour(base_colour + 7);
		DrawCarLeftWheelTread(18+16);

		SetTextureColour(base_colour + 6);
		PolygonEx(rear_left_inner_wheel, 8, wheel_orientation);
		PolygonEx(rear_left_outer_wheel, 8, wheel_orientation);

		SetTextureColour(base_colour + 7);
		DrawCarLeftWheelTread(18+48);
		}
	}


// following two functions are hard-coded for eight tread surfaces

static void DrawCarRightWheelTread( long offset )	// offset into co-ordinates
	{
	long tread1[4] = {1 + offset, 0 + offset, 8 + offset, 9 + offset};
	long tread2[4] = {2 + offset, 1 + offset, 9 + offset, 10 + offset};
	long tread3[4] = {3 + offset, 2 + offset, 10 + offset, 11 + offset};
	long tread4[4] = {4 + offset, 3 + offset, 11 + offset, 12 + offset};
	long tread5[4] = {5 + offset, 4 + offset, 12 + offset, 13 + offset};
	long tread6[4] = {6 + offset, 5 + offset, 13 + offset, 14 + offset};
	long tread7[4] = {7 + offset, 6 + offset, 14 + offset, 15 + offset};
	long tread8[4] = {0 + offset, 7 + offset, 15 + offset, 8 + offset};

	// start of code
	Polygon(tread1, 4);
	Polygon(tread2, 4);
	Polygon(tread3, 4);
	Polygon(tread4, 4);
	Polygon(tread5, 4);
	Polygon(tread6, 4);
	Polygon(tread7, 4);
	Polygon(tread8, 4);
	}


static void DrawCarLeftWheelTread( long offset )	// offset into co-ordinates
	{
	long tread1[4] = {0 + offset, 1 + offset, 9 + offset, 8 + offset};
	long tread2[4] = {1 + offset, 2 + offset, 10 + offset, 9 + offset};
	long tread3[4] = {2 + offset, 3 + offset, 11 + offset, 10 + offset};
	long tread4[4] = {3 + offset, 4 + offset, 12 + offset, 11 + offset};
	long tread5[4] = {4 + offset, 5 + offset, 13 + offset, 12 + offset};
	long tread6[4] = {5 + offset, 6 + offset, 14 + offset, 13 + offset};
	long tread7[4] = {6 + offset, 7 + offset, 15 + offset, 14 + offset};
	long tread8[4] = {7 + offset, 0 + offset, 8 + offset, 15 + offset};

	// start of code
	Polygon(tread1, 4);
	Polygon(tread2, 4);
	Polygon(tread3, 4);
	Polygon(tread4, 4);
	Polygon(tread5, 4);
	Polygon(tread6, 4);
	Polygon(tread7, 4);
	Polygon(tread8, 4);
	}
#endif

/*	======================================================================================= */
/*	Function:		DrawCar																	*/
/*																							*/
/*	Description:	Draw the car using the supplied viewpoint								*/
/*	======================================================================================= */
static IDirect3DVertexBuffer9 *pCarVB = NULL;
static long numCarVertices = 0;

static void StoreCarTriangle( COORD_3D *c1, COORD_3D *c2, COORD_3D *c3, UTVERTEX *pVertices, DWORD colour )
{
D3DXVECTOR3 v1, v2, v3;//, edge1, edge2, surface_normal;

	if ((numCarVertices+3) > MAX_VERTICES_PER_CAR)
	{
		MessageBox(NULL, L"Exceeded numCarVertices", L"StoreCarTriangle", MB_OK);
		return;
	}

	v1 = D3DXVECTOR3( (float)c1->x, (float)c1->y, (float)c1->z );
	v2 = D3DXVECTOR3( (float)c2->x, (float)c2->y, (float)c2->z );
	v3 = D3DXVECTOR3( (float)c3->x, (float)c3->y, (float)c3->z );

	/*
	// Calculate surface normal
	edge1 = v2-v1; edge2 = v3-v2;
	D3DXVec3Cross( &surface_normal, &edge1, &edge2 );
	D3DXVec3Normalize( &surface_normal, &surface_normal );
	*/

	pVertices[numCarVertices].pos = v1;
//	pVertices[numCarVertices].normal = surface_normal;
	pVertices[numCarVertices].color = colour;
	++numCarVertices;

	pVertices[numCarVertices].pos = v2;
//	pVertices[numCarVertices].normal = surface_normal;
	pVertices[numCarVertices].color = colour;
	++numCarVertices;

	pVertices[numCarVertices].pos = v3;
//	pVertices[numCarVertices].normal = surface_normal;
	pVertices[numCarVertices].color = colour;
	++numCarVertices;
}


static void CreateCarInVB( UTVERTEX *pVertices )
{
static long first_time = TRUE;
// car co-ordinates
static COORD_3D car[16+8] = {
//x,				y,					z
{-VCAR_WIDTH/2,		-VCAR_HEIGHT/4,		-VCAR_LENGTH/2},		// rear left wheel
{-VCAR_WIDTH/2,		0,					-VCAR_LENGTH/2},
{-VCAR_WIDTH/4,		0,					-VCAR_LENGTH/2},
{-VCAR_WIDTH/4,		-VCAR_HEIGHT/4,		-VCAR_LENGTH/2},

{VCAR_WIDTH/4,		-VCAR_HEIGHT/4,		-VCAR_LENGTH/2},		// rear right wheel
{VCAR_WIDTH/4,		0,					-VCAR_LENGTH/2},
{VCAR_WIDTH/2,		0,					-VCAR_LENGTH/2},
{VCAR_WIDTH/2,		-VCAR_HEIGHT/4,		-VCAR_LENGTH/2},

{-VCAR_WIDTH/2,		-VCAR_HEIGHT/4,		VCAR_LENGTH/2},		// front left wheel
{-VCAR_WIDTH/2,		0,					VCAR_LENGTH/2},
{-VCAR_WIDTH/4,		0,					VCAR_LENGTH/2},
{-VCAR_WIDTH/4,		-VCAR_HEIGHT/4,		VCAR_LENGTH/2},

{VCAR_WIDTH/4,		-VCAR_HEIGHT/4,		VCAR_LENGTH/2},		// front right wheel
{VCAR_WIDTH/4,		0,					VCAR_LENGTH/2},
{VCAR_WIDTH/2,		0,					VCAR_LENGTH/2},
{VCAR_WIDTH/2,		-VCAR_HEIGHT/4,		VCAR_LENGTH/2},

{-VCAR_WIDTH/4,		-VCAR_HEIGHT/8,		-VCAR_LENGTH/2},		// car rear points
{-(3*VCAR_WIDTH)/16,	VCAR_HEIGHT/4,	-VCAR_LENGTH/2},
{(3*VCAR_WIDTH)/16,	VCAR_HEIGHT/4,		-VCAR_LENGTH/2},
{VCAR_WIDTH/4,		-VCAR_HEIGHT/8,		-VCAR_LENGTH/2},

{-VCAR_WIDTH/4,		-VCAR_HEIGHT/8,		VCAR_LENGTH/2},		// car front points
{-VCAR_WIDTH/4,		0,					VCAR_LENGTH/2},
{VCAR_WIDTH/4,		0,					VCAR_LENGTH/2},
{VCAR_WIDTH/4,		-VCAR_HEIGHT/8,		VCAR_LENGTH/2}};

	/*
	if (first_time)
		{
		first_time = FALSE;
		// temporarily reduce car size at runtime
		// eventually car size will be decided and this code can be removed
		long i, reduce = 2;
		for (i = 0; i < (sizeof(car) / sizeof(COORD_3D)); i++)
			{
			car[i].x /= reduce;
			car[i].y /= reduce;
			car[i].z /= reduce;
			}
		}
	*/

	// rear left wheel
	DWORD colour = SCRGB(SCR_BASE_COLOUR+0);
/**/
	#define vertices pVertices
	// viewing from back
	StoreCarTriangle(&car[0], &car[1], &car[2], vertices, colour);
	StoreCarTriangle(&car[0], &car[2], &car[3], vertices, colour);
	// viewing from front
	StoreCarTriangle(&car[3], &car[2], &car[1], vertices, colour);
	StoreCarTriangle(&car[3], &car[1], &car[0], vertices, colour);

	// rear right wheel
	// viewing from back
	StoreCarTriangle(&car[0+4], &car[1+4], &car[2+4], vertices, colour);
	StoreCarTriangle(&car[0+4], &car[2+4], &car[3+4], vertices, colour);
	// viewing from front
	StoreCarTriangle(&car[3+4], &car[2+4], &car[1+4], vertices, colour);
	StoreCarTriangle(&car[3+4], &car[1+4], &car[0+4], vertices, colour);
/**/
/**/
	// front left wheel
	// viewing from back
	StoreCarTriangle(&car[0+8], &car[1+8], &car[2+8], vertices, colour);
	StoreCarTriangle(&car[0+8], &car[2+8], &car[3+8], vertices, colour);
	// viewing from front
	StoreCarTriangle(&car[3+8], &car[2+8], &car[1+8], vertices, colour);
	StoreCarTriangle(&car[3+8], &car[1+8], &car[0+8], vertices, colour);

	// front right wheel
	// viewing from back
	StoreCarTriangle(&car[0+12], &car[1+12], &car[2+12], vertices, colour);
	StoreCarTriangle(&car[0+12], &car[2+12], &car[3+12], vertices, colour);
	// viewing from front
	StoreCarTriangle(&car[3+12], &car[2+12], &car[1+12], vertices, colour);
	StoreCarTriangle(&car[3+12], &car[1+12], &car[0+12], vertices, colour);
/**/

	// car left side
	colour = SCRGB(SCR_BASE_COLOUR+12);
	StoreCarTriangle(&car[4+16], &car[5+16], &car[1+16], vertices, colour);
	StoreCarTriangle(&car[4+16], &car[1+16], &car[0+16], vertices, colour);
	// car right side
	StoreCarTriangle(&car[3+16], &car[2+16], &car[6+16], vertices, colour);
	StoreCarTriangle(&car[3+16], &car[6+16], &car[7+16], vertices, colour);

	// car back
	colour = SCRGB(SCR_BASE_COLOUR+10);
	StoreCarTriangle(&car[0+16], &car[1+16], &car[2+16], vertices, colour);
	StoreCarTriangle(&car[0+16], &car[2+16], &car[3+16], vertices, colour);
	// car front
	StoreCarTriangle(&car[7+16], &car[6+16], &car[5+16], vertices, colour);
	StoreCarTriangle(&car[7+16], &car[5+16], &car[4+16], vertices, colour);

	// car top
	colour = SCRGB(SCR_BASE_COLOUR+15);
	StoreCarTriangle(&car[1+16], &car[5+16], &car[6+16], vertices, colour);
	StoreCarTriangle(&car[1+16], &car[6+16], &car[2+16], vertices, colour);
	// car bottom
	colour = SCRGB(SCR_BASE_COLOUR+9);
	StoreCarTriangle(&car[3+16], &car[7+16], &car[4+16], vertices, colour);
	StoreCarTriangle(&car[3+16], &car[4+16], &car[0+16], vertices, colour);
	#undef vertices
}

HRESULT CreateCarVertexBuffer (IDirect3DDevice9 *pd3dDevice)
{
	if (pCarVB == NULL)
	{
		if( FAILED( pd3dDevice->CreateVertexBuffer( MAX_VERTICES_PER_CAR*sizeof(UTVERTEX),
				D3DUSAGE_WRITEONLY, D3DFVF_UTVERTEX, D3DPOOL_DEFAULT, &pCarVB, NULL ) ) )
			return E_FAIL;
	}

	UTVERTEX *pVertices;
	if( FAILED( pCarVB->Lock( 0, 0, (void**)&pVertices, 0 ) ) )
		return E_FAIL;
	numCarVertices = 0;
	CreateCarInVB(pVertices);
	pCarVB->Unlock();
	return S_OK;
}


void FreeCarVertexBuffer (void)
{
	if (pCarVB) pCarVB->Release(), pCarVB = NULL;
}


void DrawCar (IDirect3DDevice9 *pd3dDevice)
{
	pd3dDevice->SetRenderState( D3DRS_ZENABLE, TRUE );
	pd3dDevice->SetRenderState( D3DRS_CULLMODE, D3DCULL_CCW );

	pd3dDevice->SetStreamSource( 0, pCarVB, 0, sizeof(UTVERTEX) );
	pd3dDevice->SetFVF( D3DFVF_UTVERTEX );
	pd3dDevice->DrawPrimitive( D3DPT_TRIANGLELIST, 0, numCarVertices/3 );	// 3 points per triangle
}

struct TRANSFORMEDTEXVERTEX
{
    FLOAT x, y, z, rhw; // The transformed position for the vertex.
	FLOAT u, v;			// Texture
};
#define D3DFVF_TRANSFORMEDTEXVERTEX (D3DFVF_XYZRHW|D3DFVF_TEX1)

struct TRANSFORMEDCOLVERTEX
{
    FLOAT x, y, z, rhw;	// The transformed position for the vertex.
	DWORD color;		// Color
};
#define D3DFVF_TRANSFORMEDCOLVERTEX (D3DFVF_XYZRHW|D3DFVF_DIFFUSE)

static IDirect3DVertexBuffer9 *pCockpitVB = NULL, *pSpeedBarCB = NULL;
#define MAX_COCKIPTVB 512
static int old_speedbar = -1;
static int old_leftwheel = -1, old_rightwheel = -1;

extern IDirect3DTexture9 *g_pAtlas;
extern long front_left_amount_below_road, front_right_amount_below_road;
extern long leftwheel_angle, rightwheel_angle;
extern long boost_activated;
extern long new_damage;
extern long nholes;

HRESULT CreateCockpitVertexBuffer (IDirect3DDevice9 *pd3dDevice)
{
	InitAtlasCoord();
	if (pCockpitVB == NULL)
	{
		if( FAILED( pd3dDevice->CreateVertexBuffer( MAX_COCKIPTVB*sizeof(TRANSFORMEDTEXVERTEX),
				D3DUSAGE_WRITEONLY, D3DFVF_TRANSFORMEDTEXVERTEX, D3DPOOL_DEFAULT, &pCockpitVB, NULL ) ) )
			return E_FAIL;
	}
	if (pSpeedBarCB == NULL)
	{
		if ( FAILED( pd3dDevice->CreateVertexBuffer( 4*sizeof(TRANSFORMEDCOLVERTEX),
				D3DUSAGE_WRITEONLY, D3DFVF_TRANSFORMEDCOLVERTEX, D3DPOOL_DEFAULT, &pSpeedBarCB, NULL ) ) )
			return E_FAIL;
	}
	return S_OK;
}


void FreeCockpitVertexBuffer (void)
{
	if (pCockpitVB) pCockpitVB->Release(), pCockpitVB = NULL;
	if (pSpeedBarCB) pSpeedBarCB->Release(), pSpeedBarCB = NULL;
	/*if (pLeftwheelVB) pLeftwheelVB->Release(), pLeftwheelVB = NULL;
	if (pRightwheelVB) pRightwheelVB->Release(), pRightwheelVB = NULL;*/
}

extern long CalculateDisplaySpeed (void);

static int cockpit_vtx = 0;
static AddQuad(TRANSFORMEDTEXVERTEX *pVertices, float x1, float y1, float x2, float y2, float z, int idx, int revX, float w) {
	float u1 = (revX)?atlas_tx2[idx]:atlas_tx1[idx], v1 = atlas_ty1[idx];
	float u2 = (revX)?atlas_tx1[idx]:atlas_tx2[idx], v2 = atlas_ty2[idx];
	if(w!=1.0f) {
		u2 = u1 + (u2-u1)*w;
	}
	pVertices+=cockpit_vtx;
	pVertices[0].x = x1; pVertices[0].y = y1; pVertices[0].z = z; pVertices[0].rhw = 1.0f;
	pVertices[1].x = x2; pVertices[1].y = y1; pVertices[1].z = z; pVertices[1].rhw = 1.0f;
	pVertices[2].x = x2; pVertices[2].y = y2; pVertices[2].z = z; pVertices[2].rhw = 1.0f;
	pVertices[0].u = u1; pVertices[0].v = v1;
	pVertices[1].u = u2; pVertices[1].v = v1;
	pVertices[2].u = u2; pVertices[2].v = v2;
	cockpit_vtx += 3;
	pVertices += 3;
	pVertices[0].x = x1; pVertices[0].y = y1; pVertices[0].z = z; pVertices[0].rhw = 1.0f;
	pVertices[1].x = x2; pVertices[1].y = y2; pVertices[1].z = z; pVertices[1].rhw = 1.0f;
	pVertices[2].x = x1; pVertices[2].y = y2; pVertices[2].z = z; pVertices[2].rhw = 1.0f;
	pVertices[0].u = u1; pVertices[0].v = v1;
	pVertices[1].u = u2; pVertices[1].v = v2;
	pVertices[2].u = u1; pVertices[2].v = v2;
	cockpit_vtx += 3;
}

void DrawCockpit (IDirect3DDevice9 *pd3dDevice)
{
	// Prepare Cockpit drawing
	TRANSFORMEDTEXVERTEX *pVertices;
	cockpit_vtx = 0;
	if( FAILED( pCockpitVB->Lock( 0, 0, (void**)&pVertices, 0 ) ) )
		return E_FAIL;
	old_leftwheel = (front_left_amount_below_road>>6);
	float X1 = 0.0f+31.f*2, X2 = 31.f*2+2*24.0f;
	float Y1 = 480.0f-56.0f*2.4f-20*2.4f, Y2 = 480.0f-20*2.4f;
	Y1-=old_leftwheel;
	Y2-=old_leftwheel;
	AddQuad(pVertices, X1, Y1, X2, Y2, 0.8f, eWheel0+(leftwheel_angle>>16)%6, 0,1);
	old_rightwheel = (front_right_amount_below_road>>6);
	X1 = 640.f-31.f*2 - 24.f*2, X2 = 640.f-31.f*2;
	Y1 = 480.0f-56.0f*2.4f-20*2.4f, Y2 = 480.0f-20*2.4f;
	Y1-=old_rightwheel;
	Y2-=old_rightwheel;
	AddQuad(pVertices, X1, Y1, X2, Y2, 0.8f, eWheel0+(rightwheel_angle>>16)%6, 1,1);

	int engineFrame = eEngine;
	if(boost_activated) {
		static int frame = 0;
		frame = (frame+1)%16;
		const int engineframes[8] = {0,0,0,1,2,2,2,1};
		engineFrame = eEngineFlames0 + engineframes[frame>>1];
	}
	AddQuad(pVertices, 42.0f*2.0f, 123.0f*2.4f, (42.0f+235.0f)*2.0f, (123.f+35.0f)*2.4f, 0.89f, engineFrame, 0,1);
	AddQuad(pVertices, 41.f*2.f, 0.0f, (41.f+238.f)*2.f, 16.f*2.4f, 0.9f, eCockpitTop, 0,1);
	AddQuad(pVertices, 0.0f, 0.0f, 41.f*2.f, 153.f*2.4f, 0.9f, eCockpitLeft, 0,1);
	AddQuad(pVertices, 279.f*2.f, 0.0f, 640.0f, 153.f*2.4f, 0.9f, eCockpitRight, 0,1);
	AddQuad(pVertices, 0.0f, 153.f*2.4f, 640.0f, 480.0f, 0.9f, eCockpitBottom, 0,1);
	if (new_damage) {
		// cracking... width is 238, offset is 41 (in 320x200 screen space)
		float dam = new_damage; if (dam>238) dam=238;
		X1 = 41.0f*2.0f; X2 = (41.0f+dam)*2.0f;
		Y1 = 0.0f; Y2 = 0.0f+8.0f*2.4;
		AddQuad(pVertices, X1, Y1, X2, Y2, 0.91f, eCracking, 0, dam/238.0f);
	}
	for (int i=0; i<nholes; i++) {
		X1 = (47.0f+24.0f*i)*2; X2 = X1 + 12.0f*2.0f;
		Y1 = 0.0f; Y2 = 0.0f+8.0f*2.4f;
		AddQuad(pVertices, X1, Y1, X2, Y2, 0.95f, eHole, 0,1);
	}

	pCockpitVB->Unlock();

	// Prepare speedbar
	if (old_speedbar != CalculateDisplaySpeed()) {
		old_speedbar = CalculateDisplaySpeed();
		TRANSFORMEDCOLVERTEX *pVertices;
		if( FAILED( pSpeedBarCB->Lock( 0, 0, (void**)&pVertices, 0 ) ) )
			return;
		float X1 = 196.0f, X2 = 196.0f + ((CalculateDisplaySpeed() >= 240) ? 240.0f : (float)CalculateDisplaySpeed())/240.0f*242.0f;
		float Y1 = 480.0f-61.0f, Y2=480.0f-61.0f+3.0f;
		pVertices[0].x = X1; pVertices[0].y = Y1; pVertices[0].z = 1.0f; pVertices[0].rhw = 1.0f; pVertices[0].color = 0xff00ffff;
		pVertices[1].x = X2; pVertices[1].y = Y1; pVertices[1].z = 1.0f; pVertices[1].rhw = 1.0f; pVertices[1].color = 0xff00ffff;
		pVertices[2].x = X2; pVertices[2].y = Y2; pVertices[2].z = 1.0f; pVertices[2].rhw = 1.0f; pVertices[2].color = 0xff00ffff;
		pVertices[3].x = X1; pVertices[3].y = Y2; pVertices[3].z = 1.0f; pVertices[3].rhw = 1.0f; pVertices[3].color = 0xff00ffff;
		pSpeedBarCB->Unlock();
	}

	pd3dDevice->SetRenderState( D3DRS_ZENABLE, FALSE );
	pd3dDevice->SetRenderState( D3DRS_CULLMODE, D3DCULL_NONE );
	
	pd3dDevice->SetRenderState(D3DRS_ALPHABLENDENABLE, TRUE);
	pd3dDevice->SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
	pd3dDevice->SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);

	pd3dDevice->SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_BLENDDIFFUSEALPHA);
	pd3dDevice->SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
	pd3dDevice->SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
	pd3dDevice->SetTextureStageState(0, D3DTSS_COLOROP, D3DTSS_COLORARG1);
	pd3dDevice->SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
	pd3dDevice->SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_DISABLE);
#ifdef WIN32
	pd3dDevice->SetSamplerState(0, D3DSAMP_ADDRESSU, D3DTADDRESS_CLAMP);
	pd3dDevice->SetSamplerState(0, D3DSAMP_ADDRESSV, D3DTADDRESS_CLAMP);
#endif
	// Draw Cockpit
	pd3dDevice->SetTexture( 0, g_pAtlas );
	pd3dDevice->SetStreamSource( 0, pCockpitVB, 0, sizeof(TRANSFORMEDTEXVERTEX) );

	pd3dDevice->SetFVF( D3DFVF_TRANSFORMEDTEXVERTEX );
	pd3dDevice->DrawPrimitive( D3DPT_TRIANGLELIST, 0, cockpit_vtx/3 );	// 3 points per triangle

	// Draw Speed bar
	pd3dDevice->SetTextureStageState( 0, D3DTSS_COLOROP, D3DTOP_DISABLE );
	pd3dDevice->SetStreamSource( 0, pSpeedBarCB, 0, sizeof(TRANSFORMEDCOLVERTEX) );

	pd3dDevice->SetFVF( D3DFVF_TRANSFORMEDCOLVERTEX );
	pd3dDevice->DrawPrimitive( D3DPT_TRIANGLEFAN, 0, 2 );	// 3 points per triangle

	pd3dDevice->SetRenderState( D3DRS_ZENABLE, TRUE );
	pd3dDevice->SetRenderState(D3DRS_ALPHABLENDENABLE, FALSE);
	//pd3dDevice->SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_DISABLE);
}