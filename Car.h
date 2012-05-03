
#ifndef	_CAR
#define	_CAR

/*	========= */
/*	Constants */
/*	========= */
// VCAR is short for VISIBLE_CAR
#define	VCAR_WIDTH	162		// ((width 27+27 * segment width 384) / surface factor 256) * PC_FACTOR
#define	VCAR_LENGTH	256		// ((length 128 * segment length 256) / surface factor 256) * PC_FACTOR
#define	VCAR_HEIGHT	162		// chosen to look ok with the above

/*	===================== */
/*	Structure definitions */
/*	===================== */

/*	============================== */
/*	External function declarations */
/*	============================== */
extern HRESULT CreateCarVertexBuffer (IDirect3DDevice9 *pd3dDevice);

extern void FreeCarVertexBuffer (void);

extern void DrawCar (IDirect3DDevice9 *pd3dDevice);

#endif	/* _CAR */
