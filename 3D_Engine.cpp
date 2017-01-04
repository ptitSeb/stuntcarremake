/**************************************************************************

    3D Engine.cpp - Functions for producing 3D graphics

 **************************************************************************/

/*	============= */
/*	Include files */
/*	============= */
#include "dxstdafx.h"

#include "StuntCarRacer.h"
#include "3D_Engine.h"

/*	===== */
/*	Debug */
/*	===== */
#if defined(DEBUG) || defined(_DEBUG)
extern FILE *out;
extern long	VALUE1, VALUE2;
#endif

/*	========= */
/*	Constants */
/*	========= */
//#define	FALSE	0
//#define	TRUE	1

#define	SIN_COS_TABLE_SIZE	MAX_ANGLE + (MAX_ANGLE/4)	// makes use of sine/cosine overlap

/*	=========== */
/*	Global data */
/*	=========== */
extern DWORD Fill_Colour, Line_Colour;

/*	=========== */
/*	Static data */
/*	=========== */
static short Sin_Cos[SIN_COS_TABLE_SIZE];

short Trig_Coeffs2[NUM_TRIG_COEFFS];
static short Trig_Coeffs[NUM_TRIG_COEFFS];
static long World_X_Offset, World_Y_Offset, World_Z_Offset;

/*	The location of transformed co-ordinates can now be changed - for DrawZClippedPiece */
static COORD_3D Default_Transformed_Coords[MAX_COORDS];
static COORD_3D *Transformed_Coords = Default_Transformed_Coords;

/*	The location of screen co-ordinates can now be changed - for DrawPiece */
static COORD_2D Default_Screen_Coords[MAX_COORDS];	// could use POINT structure
static COORD_2D *Screen_Coords = Default_Screen_Coords;

#ifdef NOT_USED
long TEMPZ[MAX_POLY_SIDES];
#endif

/*	===================== */
/*	Function declarations */
/*	===================== */
static long LockAngle( long opposite,
					   long adjacent,
					   long clockwise );

/*	======================================================================================= */
/*	Function:		CreateSinCosTable														*/
/*																							*/
/*	Description:	Calculate and store sine/cosine values needed for 3D rotation			*/
/*	======================================================================================= */

void CreateSinCosTable( void )
	{
	long i;
	double angle, step, value;

	angle = 0;
	step = ((double)2 * (double)PI) / (double)MAX_ANGLE;
	for ( i = 0; i < SIN_COS_TABLE_SIZE; i++ )
		{
		value = sin( angle );
		value = value * (double)PRECISION;

		Sin_Cos[i] = (short)value;
		angle += step;
		}
	}

/*	======================================================================================= */
/*	Function:		GetSinCos																*/
/*																							*/
/*	Description:	Provide sine/cosine of supplied angle									*/
/*	======================================================================================= */

void GetSinCos( long angle,
				short *sin,
				short *cos )
	{
	*sin = Sin_Cos[angle];
	*cos = Sin_Cos[angle + (MAX_ANGLE/4)];
	}

#ifdef NOT_USED
/*	======================================================================================= */
/*	Function:		SetWorldOffset															*/
/*																							*/
/*	Description:	Set World X, Y and Z offsets needed for 3D transformation				*/
/*	======================================================================================= */

void SetWorldOffset( long x_offset,
					 long y_offset,
					 long z_offset )
	{
	World_X_Offset = x_offset;
	World_Y_Offset = y_offset;
	World_Z_Offset = z_offset;
	}

/*	======================================================================================= */
/*	Function:		SetCoords																*/
/*																							*/
/*	Description:	Set the locations to be used for subsequent graphic operations			*/
/*	======================================================================================= */

void SetCoords( COORD_3D *tptr,
				COORD_2D *sptr )
	{
	Transformed_Coords = tptr;
	Screen_Coords = sptr;
	}

/*	======================================================================================= */
/*	Function:		DefaultCoords															*/
/*																							*/
/*	Description:	Default the locations to be used for subsequent graphic operations		*/
/*	======================================================================================= */

void DefaultCoords( void )
	{
	Transformed_Coords = Default_Transformed_Coords;
	Screen_Coords = Default_Screen_Coords;
	}
#endif
/*	======================================================================================= */
/*	Function:		CalcYXZTrigCoefficients													*/
/*																							*/
/*	Description:	Calculate all coefficients needed for 3D rotation in order Y, X, Z		*/
/*																							*/
/*					NOTE: Uses '3D Maths' rotations :-										*/
/*							Y-Rotation - Anti-clockwise										*/
/*							X-Rotation - Anti-Clockwise										*/
/*							Z-Rotation - Anti-Clockwise										*/
/*	======================================================================================= */

void CalcYXZTrigCoefficients( long x_angle,
							  long y_angle,
							  long z_angle )
	{
	short sin_x, sin_y, sin_z;
	short cos_x, cos_y, cos_z;

	/*	========================= */
	/*	Get sine/cosine of angles */
	/*	========================= */
	sin_x = Sin_Cos[x_angle];
	sin_y = Sin_Cos[y_angle];
	sin_z = Sin_Cos[z_angle];

	cos_x = Sin_Cos[x_angle + (MAX_ANGLE/4)];
	cos_y = Sin_Cos[y_angle + (MAX_ANGLE/4)];
	cos_z = Sin_Cos[z_angle + (MAX_ANGLE/4)];

	/*	================================ */
	/*	Calculate rotated x coefficients */
	/*	================================ */
	/*
	Trig_Coeffs[X_X_COMP] = ((cos_y * cos_z) - (((sin_x * sin_y) / PRECISION) * sin_z)) / PRECISION;
	Trig_Coeffs[X_Y_COMP] = -(cos_x * sin_z) / PRECISION;
	Trig_Coeffs[X_Z_COMP] = ((sin_y * cos_z) + (((sin_x * cos_y) / PRECISION) * sin_z)) / PRECISION;
	*/
	Trig_Coeffs[X_X_COMP] = (short)(((cos_y * cos_z) + (((sin_x * sin_y) / PRECISION) * sin_z)) / PRECISION);
	Trig_Coeffs[X_Y_COMP] = (short)(-(cos_x * sin_z) / PRECISION);
	Trig_Coeffs[X_Z_COMP] = (short)((-(sin_y * cos_z) + (((sin_x * cos_y) / PRECISION) * sin_z)) / PRECISION);

	/*	================================ */
	/*	Calculate rotated y coefficients */
	/*	================================ */
	/*
	Trig_Coeffs[Y_X_COMP] = ((cos_y * sin_z) + (((sin_x * sin_y) / PRECISION) * cos_z)) / PRECISION;
	Trig_Coeffs[Y_Y_COMP] = (cos_x * cos_z) / PRECISION;
	Trig_Coeffs[Y_Z_COMP] = ((sin_y * sin_z) - (((sin_x * cos_y) / PRECISION) * cos_z)) / PRECISION;
	*/
	Trig_Coeffs[Y_X_COMP] = (short)(((cos_y * sin_z) - (((sin_x * sin_y) / PRECISION) * cos_z)) / PRECISION);
	Trig_Coeffs[Y_Y_COMP] = (short)((cos_x * cos_z) / PRECISION);
	Trig_Coeffs[Y_Z_COMP] = (short)((-(sin_y * sin_z) - (((sin_x * cos_y) / PRECISION) * cos_z)) / PRECISION);

	/*	================================ */
	/*	Calculate rotated z coefficients */
	/*	================================ */
	/*
	Trig_Coeffs[Z_X_COMP] = -(cos_x * sin_y) / PRECISION;
	Trig_Coeffs[Z_Y_COMP] = sin_x;
	Trig_Coeffs[Z_Z_COMP] = (cos_x * cos_y) / PRECISION;
	*/
	Trig_Coeffs[Z_X_COMP] = (short)((cos_x * sin_y) / PRECISION);
	Trig_Coeffs[Z_Y_COMP] = sin_x;
	Trig_Coeffs[Z_Z_COMP] = (short)((cos_x * cos_y) / PRECISION);
	}

/*	======================================================================================= */
/*	Function:		TrigCoefficients														*/
/*																							*/
/*	Description:	Return ptr. to coefficients needed for 3D rotation						*/
/*	======================================================================================= */

short *TrigCoefficients( void )
	{
	return(Trig_Coeffs);
	}

/*	======================================================================================= */
/*	Function:		RotateCoordinate														*/
/*																							*/
/*	Description:	Perform 3D rotation on supplied co-ordinate								*/
/*	======================================================================================= */
#ifdef NOT_USED
void RotateCoordinate( long *xptr,
					   long *yptr,
					   long *zptr )
	{
	long x, y, z;

	x = *xptr;
	y = *yptr;
	z = *zptr;

	*xptr = (x * (long)Trig_Coeffs[X_X_COMP]) +
			(y * (long)Trig_Coeffs[X_Y_COMP]) +
			(z * (long)Trig_Coeffs[X_Z_COMP]);

	*yptr = (x * (long)Trig_Coeffs[Y_X_COMP]) +
			(y * (long)Trig_Coeffs[Y_Y_COMP]) +
			(z * (long)Trig_Coeffs[Y_Z_COMP]);

	*zptr = (x * (long)Trig_Coeffs[Z_X_COMP]) +
			(y * (long)Trig_Coeffs[Z_Y_COMP]) +
			(z * (long)Trig_Coeffs[Z_Z_COMP]);
	}
#endif
/*	======================================================================================= */
/*	Function:		WorldOffset (opposite of RotateCoordinate)								*/
/*																							*/
/*	Description:	Takes the input vector and provides the World vector					*/
/*					for the given rotation (i.e. sums X/Y/Z components)						*/
/*	======================================================================================= */

void WorldOffset( long *xptr,
				  long *yptr,
				  long *zptr )
	{
	long x, y, z;

	x = *xptr;
	y = *yptr;
	z = *zptr;

	*xptr = (x * (long)Trig_Coeffs[X_X_COMP]) +
			(y * (long)Trig_Coeffs[Y_X_COMP]) +
			(z * (long)Trig_Coeffs[Z_X_COMP]);

	*yptr = (x * (long)Trig_Coeffs[X_Y_COMP]) +
			(y * (long)Trig_Coeffs[Y_Y_COMP]) +
			(z * (long)Trig_Coeffs[Z_Y_COMP]);

	*zptr = (x * (long)Trig_Coeffs[X_Z_COMP]) +
			(y * (long)Trig_Coeffs[Y_Z_COMP]) +
			(z * (long)Trig_Coeffs[Z_Z_COMP]);
	}

/*	======================================================================================= */
/*	Function:		TransformCoordinates													*/
/*																							*/
/*	Description:	Perform 3D rotation and translation on required co-ordinates			*/
/*	======================================================================================= */
#ifdef NOT_USED
long TransformCoordinates( COORD_3D *cptr,
						   long size )
	{
	long i, number;
	long x, y, z;
	long trans_x, trans_y, trans_z;
	long screen_width, screen_height;

	// calculate number of co-ordinates
	number = size / sizeof(COORD_3D);

	// finish if too many co-ordinates
	if (number > MAX_COORDS)
		return(FALSE);

	GetScreenDimensions(&screen_width, &screen_height);

	// transform each co-ordinate in turn
	for (i = 0; i < number; i++)
		{
		x = cptr->x;
		y = cptr->y;
		z = cptr->z;
		cptr++;

		// rotate current co-ordinate
		trans_x = (x * (long)Trig_Coeffs[X_X_COMP]) +
				  (y * (long)Trig_Coeffs[X_Y_COMP]) +
				  (z * (long)Trig_Coeffs[X_Z_COMP]);

		trans_y = (x * (long)Trig_Coeffs[Y_X_COMP]) +
				  (y * (long)Trig_Coeffs[Y_Y_COMP]) +
				  (z * (long)Trig_Coeffs[Y_Z_COMP]);

		trans_z = (x * (long)Trig_Coeffs[Z_X_COMP]) +
				  (y * (long)Trig_Coeffs[Z_Y_COMP]) +
				  (z * (long)Trig_Coeffs[Z_Z_COMP]);

		// add world offsets
		trans_x += World_X_Offset;
		trans_y += World_Y_Offset;
		trans_z += World_Z_Offset;

		// finish if any z negative (i.e. infront of screen)
		if (trans_z <= 0)
			return(FALSE);

		// store world x, world y and world z
		Transformed_Coords[i].x = trans_x;
		Transformed_Coords[i].y = trans_y;
		Transformed_Coords[i].z = trans_z;

		// perspective projection
		z = trans_z >> LOG_FOCUS;

		// debug stuff
		if (z == 0)
			{
#if defined(DEBUG) || defined(_DEBUG)
			fprintf(out, "5.  Preventing division by zero\n");
			//Sleep(10);
#endif

			z = 1;
			}

		x = (trans_x / z) + screen_width/2;
		y = (trans_y / z) + screen_height/2;

		// store screen x and screen y
		Screen_Coords[i].x = x;
		Screen_Coords[i].y = y;
		}

	return(TRUE);
	}

/*	======================================================================================= */
/*	Function:		TransformedZ															*/
/*																							*/
/*	Description:	Return required transformed z co-ordinate								*/
/*	======================================================================================= */

long TransformedZ( long offset )
	{
	return(Transformed_Coords[offset].z);
	}

/*	======================================================================================= */
/*	Function:		TexturedPolygon															*/
/*																							*/
/*	Description:	Set the origin and u,v vectors needed for texture mapping				*/
/*					Use the Polygon function to draw the polygon							*/
/*	======================================================================================= */

long TexturedPolygon( long *cptr,			// pointer to co-ordinate offsets for polygon
					  long sides,
					  long *vptr )			// pointer to co-ordinate offsets for vectors
	{										// in the order: origin, u, v
	long offset;

	long ox, oy, oz;		// origin of surface
	long ux, uy, uz;		// x vector of surface
	long vx, vy, vz;		// y vector of surface

	// could use LOG_PRECISION below
	// get origin of surface
	offset = *vptr++;
	ox = Transformed_Coords[offset].x / PRECISION;
	oy = Transformed_Coords[offset].y / PRECISION;
	oz = Transformed_Coords[offset].z / PRECISION;

	// get x vector of surface
	offset = *vptr++;
	ux = (Transformed_Coords[offset].x / PRECISION) - ox;
	uy = (Transformed_Coords[offset].y / PRECISION) - oy;
	uz = (Transformed_Coords[offset].z / PRECISION) - oz;

	// get y vector of surface
	offset = *vptr;
	vx = (Transformed_Coords[offset].x / PRECISION) - ox;
	vy = (Transformed_Coords[offset].y / PRECISION) - oy;
	vz = (Transformed_Coords[offset].z / PRECISION) - oz;

	SetTextureVectors(ox, oy, oz,
					  ux, uy, uz,
					  vx, vy, vz);

	return(Polygon(cptr, sides));
	}

/*	======================================================================================= */
/*	Function:		PolygonVisible															*/
/*																							*/
/*	Description:	Test if polygon is visible (co-ordinates have clockwise orientation)	*/
/*	======================================================================================= */

long PolygonVisible( long *cptr )		// pointer to co-ordinate offsets for polygon
	{
	long offset;
	long x1, y1, x2, y2, x3, y3;

	// perform orientation test
	offset = *cptr++;
	x1 = Screen_Coords[offset].x; y1 = Screen_Coords[offset].y;
	offset = *cptr++;
	x2 = Screen_Coords[offset].x; y2 = Screen_Coords[offset].y;
	offset = *cptr;
	x3 = Screen_Coords[offset].x; y3 = Screen_Coords[offset].y;

	if ((((x1 - x2) * (y3 - y2)) - ((x3 - x2) * (y1 - y2))) < 0)
		return(TRUE);
	else
		return(FALSE);
	}

/*	======================================================================================= */
/*	Function:		Polygon																	*/
/*																							*/
/*	Description:	Check polygon is visible (co-ordinates have clockwise orientation) and	*/
/*					if so, draw the polygon to the required buffer							*/
/*	======================================================================================= */

long Polygon( long *cptr,			// pointer to co-ordinate offsets for polygon
			  long sides )
	{
	long i, offset;
	POINT points[MAX_POLY_SIDES];
	long x1, y1, x2, y2, x3, y3;

	// finish if too many sides
	if (sides > MAX_POLY_SIDES)
		return(FALSE);

	// store all polygon's points
	for (i = 0; i < sides; i++)
		{
		offset = *cptr++;
		points[i].x = Screen_Coords[offset].x;
		points[i].y = Screen_Coords[offset].y;

		TEMPZ[i] = Transformed_Coords[offset].z;
		}

	// perform orientation test
	x1 = points[0].x; y1 = points[0].y;
	x2 = points[1].x; y2 = points[1].y;
	x3 = points[2].x; y3 = points[2].y;

	if ((((x1 - x2) * (y3 - y2)) - ((x3 - x2) * (y1 - y2))) < 0)
		{
		DrawPolygon(points, sides);
		return(TRUE);
		}
	else
		return(FALSE);
	}

/*	======================================================================================= */
/*	Function:		PolygonEx (Polygon with orientation points specified explicitly)		*/
/*																							*/
/*	Description:	Check polygon is visible (co-ordinates have clockwise orientation) and	*/
/*					if so, draw the polygon to the required buffer							*/
/*	======================================================================================= */

// may also need TexturedPolygonEx

long PolygonEx( long *cptr,			// pointer to co-ordinate offsets for polygon
				long sides,
				long *optr )		// pointer to co-ordinate offsets for orientation check
	{								// (NOTE: these are offsets into the polygon's object,
	long i, offset;					//	rather than offsets into Screen_Coords
	POINT points[MAX_POLY_SIDES];
	long x1, y1, x2, y2, x3, y3;

	// finish if too many sides
	if (sides > MAX_POLY_SIDES)
		return(FALSE);

	// store all polygon's points
	for (i = 0; i < sides; i++)
		{
		offset = *cptr++;
		points[i].x = Screen_Coords[offset].x;
		points[i].y = Screen_Coords[offset].y;

		TEMPZ[i] = Transformed_Coords[offset].z;
		}

	// perform orientation test
	offset = *optr++;
	x1 = points[offset].x; y1 = points[offset].y;
	offset = *optr++;
	x2 = points[offset].x; y2 = points[offset].y;
	offset = *optr;
	x3 = points[offset].x; y3 = points[offset].y;

	if ((((x1 - x2) * (y3 - y2)) - ((x3 - x2) * (y1 - y2))) < 0)
		{
		DrawPolygon(points, sides);
		return(TRUE);
		}
	else
		return(FALSE);
	}

/*	======================================================================================= */
/*	Function:		Line																	*/
/*																							*/
/*	Description:	Draw the line to the required buffer									*/
/*	======================================================================================= */

void Line( long c1,			// co-ordinate offset for line, point 1
		   long c2 )		// co-ordinate offset for line, point 2
	{
	long x1, y1, x2, y2, i, sides = 2;
    D3DTLVERTEX TLVertices[2];
    HRESULT err;

	x1 = Screen_Coords[c1].x;
	y1 = Screen_Coords[c1].y;

	x2 = Screen_Coords[c2].x;
	y2 = Screen_Coords[c2].y;

    TLVertices[0].sx = (float)x1;      // screen x
    TLVertices[0].sy = (float)y1;      // screen y

    TLVertices[1].sx = (float)x2;      // screen x
    TLVertices[1].sy = (float)y2;      // screen y

    for (i = 0; i < sides; i++)
        {
        TLVertices[i].sz = (float)300.0;	// not needed unless Z buffering
        TLVertices[i].rhw = (float)1.0;		// shouldn't be texture mapping a line

        TLVertices[i].color = Line_Colour;
        TLVertices[i].specular = RGB_MAKE(0,0,0);
        }

	// texture vectors not needed, as again, shouldn't be texture mapping a line
    TLVertices[0].tu = 0.0f; TLVertices[0].tv = 1.0f;
    TLVertices[1].tu = 0.0f; TLVertices[1].tv = 0.0f;

    //*** Use DrawPrimitive to draw the face
    err = d3dDevice->DrawPrimitive(D3DPT_LINELIST, D3DVT_TLVERTEX, TLVertices, sides, D3DDP_WAIT);
	}

/*	======================================================================================= */
/*	Function:		PolygonZClipped															*/
/*																							*/
/*	Description:	Clip all polygon's edges to the boundary z = Z_CLIP_BOUNDARY			*/
/*					Check the resulting polygon is visible (co-ordinates have clockwise		*/
/*					orientation) and if so, draw the polygon to the required buffer			*/
/*	======================================================================================= */

// 10/01/1999 - don't take this value any lower, otherwise calculations overflow
#define	Z_CLIP_BOUNDARY	(128)

// static variables for acces by RoadZClipped
static long resulting_sides;	// number left after clipping is complete
static COORD_3D clipped_coords[MAX_POLY_SIDES+1];	// note that x,y are screen co-ordinates

long PolygonZClipped( long *cptr,			// pointer to co-ordinate offsets for polygon
					  long sides,
					  long check_orientation,
					  long *on_screen)	// optional output, may be NULL
	{
	long boundary = Z_CLIP_BOUNDARY << LOG_PRECISION;
	long i, offset, input_sides = sides;
	long below;		// indicating if current co-ordinate is below/above z boundary
	long screen_width, screen_height;
	long x, y;

	COORD_3D *current, *previous;

	resulting_sides = 0;

	// finish if too many sides
	if (sides > MAX_POLY_SIDES)
		return(FALSE);

	GetScreenDimensions(&screen_width, &screen_height);

	//fprintf(out, "PolygonZClipped\n");

	// get pointer to first co-ordinate
	i = 0;
	offset = cptr[i]; i++;
	current = &Transformed_Coords[offset];

	below = (current->z < boundary ? TRUE : FALSE);

	//fprintf(out, "Boundary %d, Screen Width %d, Screen Height %d, Sides %d\n",
	//								boundary, screen_width, screen_height, sides);
	//fprintf(out, "Current (%d,%d,%d), below %d\n", current->x, current->y, current->z, below);

	do
		{
		if (below)
			{
			// find first value above z boundary
			do
				{
				previous = current;

				// get pointer to next co-ordinate
				offset = cptr[i % input_sides]; i++;
				current = &Transformed_Coords[offset];

				//fprintf(out, "Below, Current (%d,%d,%d)\n", current->x, current->y, current->z);

				--sides;
				}
			while ((sides > 0) && (current->z < boundary));

			if (current->z >= boundary)
				{
				// clip edge that crosses boundary
				ZClip(previous, current,	// below, above
					  screen_width, screen_height,
					  &x, &y);
				// store boundary screen co-ordinate
				clipped_coords[resulting_sides].x = x;
				clipped_coords[resulting_sides].y = y;
				clipped_coords[resulting_sides].z = boundary;
				++resulting_sides;

				//fprintf(out, "Below, ZClip gave (%d,%d), resulting sides %d\n",
				//											x, y, resulting_sides);
				}

			below = FALSE;
			}
		else	// above
			{
			// find first value below z boundary
			do
				{
				// store current screen co-ordinate (because it is above boundary)
				clipped_coords[resulting_sides].x = Screen_Coords[offset].x;
				clipped_coords[resulting_sides].y = Screen_Coords[offset].y;
				clipped_coords[resulting_sides].z = current->z;
				resulting_sides++;

				previous = current;

				// get pointer to next co-ordinate
				offset = cptr[i % input_sides]; i++;
				current = &Transformed_Coords[offset];

				//fprintf(out, "Above, Current (%d,%d,%d)\n", current->x, current->y, current->z);

				--sides;
				}
			while ((sides > 0) && (current->z >= boundary));

			if (current->z < boundary)
				{
				// clip edge that crosses boundary
				ZClip(current, previous,	// below, above
					  screen_width, screen_height,
					  &x, &y);
				// store boundary screen co-ordinate
				clipped_coords[resulting_sides].x = x;
				clipped_coords[resulting_sides].y = y;
				clipped_coords[resulting_sides].z = boundary;
				++resulting_sides;

				//fprintf(out, "Above, ZClip gave (%d,%d), resulting sides %d\n",
				//											x, y, resulting_sides);
				}

			below = TRUE;
			}
		}
	while (sides > 0);


	// clipping finished, draw resulting polygon if visible
	if (resulting_sides == 0)
		{
		//fprintf(out, "PolygonZClipped - zero resulting sides\n");

		return(FALSE);
		}

	//fprintf(out, "PolygonZClipped - resulting sides %d\n", resulting_sides);


	// copy from COORD_3D to POINT structure, as required by DrawPolygon
	POINT points[MAX_POLY_SIDES+1];
	for (i = 0; i < resulting_sides; i++)
		{
		points[i].x = clipped_coords[i].x;
		points[i].y = clipped_coords[i].y;

		TEMPZ[i] = clipped_coords[i].z;
		}


	// perform orientation test
	long x1, y1, x2, y2, x3, y3, visible;

	// - if there are any sides then there must be atleast 3
	x1 = points[0].x; y1 = points[0].y;
	x2 = points[1].x; y2 = points[1].y;
	x3 = points[2].x; y3 = points[2].y;
	visible = (((x1 - x2) * (y3 - y2)) - ((x3 - x2) * (y1 - y2))) < 0;


//	Currently check orientation only if required, as it meant that closest
//  road surfaces were not always drawn when they could have been
	if (check_orientation == FALSE)
		{
		DrawPolygon(points, resulting_sides);
		return(visible);
		}


	if (visible)
		{
		//fprintf(out, "PolygonZClipped about to DrawPolygon\n");
		DrawPolygon(points, resulting_sides);
		return(visible);
		}
	else
		{
		//fprintf(out, "PolygonZClipped failed orientation test, %d\n", temp);
		return(visible);
		}
	}

/*	======================================================================================= */
/*	Function:		LineZClipped															*/
/*																							*/
/*	Description:	Clip the line to the boundary z = Z_CLIP_BOUNDARY						*/
/*					Draw the resulting line to the required buffer							*/
/*	======================================================================================= */

void LineZClipped( long c1,			// co-ordinate offset for line, point 1
				   long c2 )		// co-ordinate offset for line, point 2
	{
	long boundary = Z_CLIP_BOUNDARY << LOG_PRECISION;
	long point1_below,
		 point2_below;		// indicating if co-ordinates are below/above z boundary
	long screen_width, screen_height;
	COORD_3D *point1, *point2;
	long x1, y1, x2, y2, i, sides = 2;
    D3DTLVERTEX TLVertices[2];
    HRESULT err;

	//fprintf(out, "LineZClipped\n");

	GetScreenDimensions(&screen_width, &screen_height);

	point1 = &Transformed_Coords[c1];
	point2 = &Transformed_Coords[c2];

	//fprintf(out, "Point1 (%d,%d,%d), Point2 (%d,%d,%d)\n", point1->x, point1->y, point1->z,
	//													   point2->x, point2->y, point2->z);

	point1_below = (point1->z < boundary ? TRUE : FALSE);
	point2_below = (point2->z < boundary ? TRUE : FALSE);

	//fprintf(out, "Point1 below %d, Point2 below %d\n", point1_below, point2_below);

	// finish if both points below boundary
	if (point1_below && point2_below)
		return;

	// check point 1
	if (point1_below)
		{
		// clip edge that crosses boundary
		ZClip(point1, point2,	// below, above
			  screen_width, screen_height,
			  &x1, &y1);
		}
	else
		{
		// store current screen co-ordinate (because it is above boundary)
		x1 = Screen_Coords[c1].x;
		y1 = Screen_Coords[c1].y;
		}

	// check point 2
	if (point2_below)
		{
		// clip edge that crosses boundary
		ZClip(point2, point1,	// below, above
			  screen_width, screen_height,
			  &x2, &y2);
		}
	else
		{
		// store current screen co-ordinate (because it is above boundary)
		x2 = Screen_Coords[c2].x;
		y2 = Screen_Coords[c2].y;
		}

    TLVertices[0].sx = (float)x1;      // screen x
    TLVertices[0].sy = (float)y1;      // screen y

    TLVertices[1].sx = (float)x2;      // screen x
    TLVertices[1].sy = (float)y2;      // screen y

    for (i = 0; i < sides; i++)
        {
        TLVertices[i].sz = (float)300.0;	// not needed unless Z buffering
        TLVertices[i].rhw = (float)1.0;		// shouldn't be texture mapping a line

        TLVertices[i].color = Line_Colour;
        TLVertices[i].specular = RGB_MAKE(0,0,0);
        }

	// texture vectors not needed, as again, shouldn't be texture mapping a line
    TLVertices[0].tu = 0.0f; TLVertices[0].tv = 1.0f;
    TLVertices[1].tu = 0.0f; TLVertices[1].tv = 0.0f;

    //*** Use DrawPrimitive to draw the face
    err = d3dDevice->DrawPrimitive(D3DPT_LINELIST, D3DVT_TLVERTEX, TLVertices, sides, D3DDP_WAIT);
	}

/*	======================================================================================= */
/*	Function:		ZClip																	*/
/*																							*/
/*	Description:	Clip an edge to the boundary z = Z_CLIP_BOUNDARY						*/
/*					The output is the clipped co-ordinate (i.e. on boundary)				*/
/*	======================================================================================= */

void ZClip( COORD_3D *below,	// transformed co-ordinate below boundary (i.e. nearest one)
			COORD_3D *above,	// transformed co-ordinate above boundary (i.e. furthest one)
			long screen_width,
			long screen_height,
			long *x,			// clipped x
			long *y )			// clipped y
	{
	long xoff, xon;
	long yoff, yon;
	long zoff, zon;
	long screenx, screeny;

	// remove PRECISION from transformed co-ordinates
	// so that the clipping calculations won't overflow
	xoff = below->x >> LOG_PRECISION;
	xon = above->x >> LOG_PRECISION;

	yoff = below->y >> LOG_PRECISION;
	yon = above->y >> LOG_PRECISION;

	zoff = below->z >> LOG_PRECISION;
	zon = above->z >> LOG_PRECISION;

	// clip to boundary z = Z_CLIP_BOUNDARY
	if ((zoff - zon) == 0)
		{
		fprintf(out, "6.  Preventing division by zero\n");
		//Sleep(10);

		++zoff;
		}

	screenx = (((xon - xoff) * (zoff - Z_CLIP_BOUNDARY)) / (zoff - zon)) + xoff;
	screeny = (((yon - yoff) * (zoff - Z_CLIP_BOUNDARY)) / (zoff - zon)) + yoff;

	// perspective projection
	// assumes Z_CLIP_BOUNDARY is atleast 1 so divide by zero is not possible
	screenx = ((screenx * FOCUS) / Z_CLIP_BOUNDARY) + screen_width/2;
	screeny = ((screeny * FOCUS) / Z_CLIP_BOUNDARY) + screen_height/2;

	*x = screenx;
	*y = screeny;
	}
#endif
/*	======================================================================================= */
/*	Function:		LockViewpointToTarget													*/
/*																							*/
/*	Description:	Calculate x/y angles required to place target within centre of view     */
/*	======================================================================================= */

void LockViewpointToTarget( long viewpoint_x,
							long viewpoint_y,
							long viewpoint_z,
							long target_x,
							long target_y,
							long target_z,
							long *viewpoint_x_angle,
							long *viewpoint_y_angle )
	{
	long opp, adj;
	double a, b, h;

	// y angle
	opp = target_x - viewpoint_x;
	adj = target_z - viewpoint_z;
	*viewpoint_y_angle = LockAngle(opp, adj, FALSE);

	// x angle
	a = (double)((target_x - viewpoint_x) >> LOG_PRECISION);
	b = (double)((target_z - viewpoint_z) >> LOG_PRECISION);
	h = sqrt((a*a) + (b*b));
	adj = (long)(h * PRECISION);
	opp = target_y - viewpoint_y;
	*viewpoint_x_angle = LockAngle(opp, adj, FALSE);

	return;
	}


static long LockAngle( long opposite,
					   long adjacent,
					   long clockwise )
	{
	long viewpoint_angle;
	double o, a, radians, angle;

	o = (double)opposite;
	a = (double)adjacent;

	// use inverse tan to calculate basic angle in radians
	if (a == 0)		// prevent division by zero
		radians = (double)PI / (double)2;	// 90 degrees
	else
		radians = atan(o/a);	// inverse tan

	// convert radians to internal angle (also round up)
	angle = ((radians * (double)MAX_ANGLE) / ((double)2 * (double)PI));
	// convert to absolute and round up as follows (because abs() isn't for doubles)
	if (angle > 0)
		viewpoint_angle = (long)(angle + (double)0.5);
	else
		viewpoint_angle = (long)((double)0.5 - angle);

	// convert angle from first quadrant to full range
	if (o >= 0)
		{
		if (a >= 0)
			{
			// first quadrant
			viewpoint_angle = (long)angle;
			}
		else
			{
			// second quadrant
			viewpoint_angle = (long)angle + _180_DEGREES;
			}
		}
	else
		{
		if (a <= 0)
			{
			// third quadrant
			viewpoint_angle = (long)angle + _180_DEGREES;
			}
		else
			{
			// fourth quadrant
			viewpoint_angle = (long)angle + _360_DEGREES;
			}
		}

	// default is anti-clockwise, so convert to clockwise if necessary
	if (clockwise)
		{
		viewpoint_angle = (-viewpoint_angle) & (MAX_ANGLE-1);
		}

	return(viewpoint_angle);
	}

/*	======================================================================================= */
/*	Function:		CreatePolygonVertexBuffer,												*/
/*					FreePolygonVertexBuffer,												*/
/*					DrawPolygon,															*/
/*					DrawFilledRectangle														*/
/*																							*/
/*	Description:	Functions to draw polygon and filled rectangle using Direct3D			*/
/*	======================================================================================= */

struct TRANSFORMEDVERTEX
{
    FLOAT x, y, z, rhw; // The transformed position for the vertex.
    DWORD color;        // The vertex color.
};
#define D3DFVF_TRANSFORMEDVERTEX (D3DFVF_XYZRHW|D3DFVF_DIFFUSE)

#ifndef linux
static IDirect3DVertexBuffer9 *pPolygonVB = NULL;

HRESULT CreatePolygonVertexBuffer (IDirect3DDevice9 *pd3dDevice)
{
	if (pPolygonVB == NULL)
	{
		if( FAILED( pd3dDevice->CreateVertexBuffer( MAX_POLY_SIDES*sizeof(TRANSFORMEDVERTEX),
				D3DUSAGE_WRITEONLY, D3DFVF_TRANSFORMEDVERTEX, D3DPOOL_DEFAULT, &pPolygonVB, NULL ) ) )
			return E_FAIL;
	}

	return S_OK;
}


void FreePolygonVertexBuffer (void)
{
	if (pPolygonVB) pPolygonVB->Release(), pPolygonVB = NULL;
}
#endif

// Draw flat polygon (no z information)
void DrawPolygon( POINT *pptr,
				  long sides)
{
long i;
#ifndef linux
IDirect3DDevice9 *pd3dDevice = DXUTGetD3DDevice();
#endif
TRANSFORMEDVERTEX *pVertices;

	// finish if too many sides
	if (sides > MAX_POLY_SIDES)
		return;

#ifdef linux
#ifdef HAVE_GLES
	pVertices = (TRANSFORMEDVERTEX*)malloc(sides*sizeof(TRANSFORMEDVERTEX));
	if (!pVertices)
		return;
#else
	glBegin(GL_TRIANGLE_FAN);
#endif
#else
	if( FAILED( pPolygonVB->Lock( 0, sides*sizeof(TRANSFORMEDVERTEX), (void**)&pVertices, 0 ) ) )
		return;
#endif
    for (i = 0; i < sides; i++)
        {
#if defined(linux) && !defined(HAVE_GLES)
		glColor4ubv((GLubyte*)&Fill_Colour);
		glVertex2f((float)pptr[i].x, (float)pptr[i].y);
#else
		pVertices[i].x = (float)pptr[i].x;      // screen x
		pVertices[i].y = (float)pptr[i].y;      // screen y
		pVertices[i].z = (float)0.5f;			// not needed unless Z buffering
		pVertices[i].rhw = (float)1.0f;
		pVertices[i].color = Fill_Colour;
#endif
        }
	#ifdef linux
	#ifdef HAVE_GLES
	// setup arrays
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glColorPointer(4, GL_UNSIGNED_BYTE, sizeof(TRANSFORMEDVERTEX), &pVertices[0].color);
	glVertexPointer(4, GL_FLOAT, sizeof(TRANSFORMEDVERTEX), &pVertices[0].x);
	glDrawArrays(GL_TRIANGLE_FAN, 0, sides-2);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
	#else
	glEnd();
	#endif
	#else
	pPolygonVB->Unlock();

	pd3dDevice->SetStreamSource( 0, pPolygonVB, 0, sizeof(TRANSFORMEDVERTEX) );
	pd3dDevice->SetFVF( D3DFVF_TRANSFORMEDVERTEX );
	pd3dDevice->DrawPrimitive( D3DPT_TRIANGLEFAN, 0, sides-2 );
	#endif
	return;
	}


void DrawFilledRectangle( long x1, long y1, long x2, long y2, DWORD colour )
{
#ifdef linux
#ifdef HAVE_GLES
	float vtx[4*2] = {
		x1, y1,
		x1, y2,
		x2, y2,
		x2, y1
	};
	glColor4ubv((GLubyte*)&colour);
	glEnableClientState(GL_VERTEX_ARRAY);
	glVertexPointer(4, GL_FLOAT, 0, vtx);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
	glDisableClientState(GL_VERTEX_ARRAY);
#else
	glColor4ubv((GLubyte*)&colour);
	glBegin(GL_TRIANGLE_FAN);
		glVertex2i(x1, y1);
		glVertex2i(x1, y2);
		glVertex2i(x2, y2);
		glVertex2i(x2, y1);
	glEnd();
#endif
#else
HRESULT hr;
D3DRECT rect;
IDirect3DDevice9 *pd3dDevice = DXUTGetD3DDevice();

	rect.x1 = x1;
	rect.y1 = y1;
	// note that Clear fills up to, but not including, the right/bottom points of the rectangle
	rect.x2 = x2+1;
	rect.y2 = y2+1;
	V( pd3dDevice->Clear(1, &rect, D3DCLEAR_TARGET, colour, 0, 0) );
#endif
	return;
}
