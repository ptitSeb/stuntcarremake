
/*	============= */
/*	Include files */
/*	============= */
#include "dxstdafx.h"

#include "wavefunctions.h"

/*********************************************************************************
/
/	Function:	MakeSoundBuffer
/
/	Description:	Returns a DirectSound buffer for the sample specified.
/
*********************************************************************************/

IDirectSoundBuffer8* MakeSoundBuffer(IDirectSound8 *ds, LPCWSTR lpSampleName)
	{
	IDirectSoundBuffer8		*TempBuffer;
	DSBUFFERDESC			dsbd;
	LPBYTE					lpWaveData;
	HRESULT					err;
	void					*pRIFFBytes;

    ZeroMemory(&dsbd, sizeof(dsbd));

	if ((pRIFFBytes = GetWAVRes(NULL,lpSampleName)) != NULL)
		{
		UnpackWAVChunk(pRIFFBytes,&dsbd.lpwfxFormat,&lpWaveData,&dsbd.dwBufferBytes);

		dsbd.dwSize = sizeof(dsbd);
//	    dsbd.dwFlags = /*DSBCAPS_CTRLDEFAULT |*/ DSBCAPS_STATIC;
	    dsbd.dwFlags = DSBCAPS_CTRLFREQUENCY | DSBCAPS_CTRLPAN | DSBCAPS_CTRLVOLUME;// | DSBCAPS_CTRLPOSITIONNOTIFY;

		err = ds->CreateSoundBuffer(&dsbd, (LPDIRECTSOUNDBUFFER *)&TempBuffer, NULL);

		if (err == DS_OK)
			WriteWAVData( TempBuffer, lpWaveData, dsbd.dwBufferBytes);
		else
			return NULL;

		}
	else
		{
		return NULL;
		}

	return (IDirectSoundBuffer8 *) TempBuffer;
	}

/*********************************************************************************
/
/	Function:	GetWAVRes
/
/	Description:	Locates and loads into global memory the requested sample.
/
*********************************************************************************/

void* GetWAVRes(HMODULE hModule, LPCWSTR lpResName)
	{
	void		*pRIFFBytes;
#ifdef linux
const WCHAR* resname[] = {L"TICKOVER", L"ENGINEPITCH2", L"ENGINEPITCH3", L"ENGINEPITCH4", L"ENGINEPITCH5", L"ENGINEPITCH6", L"ENGINEPITCH7", L"ENGINEPITCH8", L"GROUNDED", L"SMASH", L"CREAK", L"OFFROAD", L"WRECK", L"HITCAR", 0};
const char* filename[] = {"Sounds/TickOver.wav", "Sounds/EnginePitch2.wav", "Sounds/EnginePitch3.wav", "Sounds/EnginePitch4.wav", "Sounds/EnginePitch5.wav", "Sounds/EnginePitch6.wav", "Sounds/EnginePitch7.wav", "Sounds/EnginePitch8.wav", "Sounds/Grounded.wav", "Sounds/Smash.wav", "Sounds/Creak.wav", "Sounds/OffRoad.wav", "Sounds/Wreck.wav", "Sounds/HitCar.wav"};
	int i = 0;
	while(resname[i] && wcscasecmp(resname[i], lpResName)) i++;
	if(!resname[i]) return NULL;
	// file found, get size, alloc size and read binary file
	FILE* f = fopen(filename[i], "rb");
	if(!f) return NULL;
	fseek(f, 0, SEEK_END);
	int fsize = ftell(f);
	fseek(f, 0, SEEK_SET);
	if (fsize<=0) { fclose(f); return NULL;}
	pRIFFBytes = malloc(fsize);
	fread(pRIFFBytes, 1, fsize, f);
	fclose(f);
#else
	HRSRC		hResInfo;
	HGLOBAL		hResData;

	if ((hResInfo = FindResource(hModule, lpResName, L"WAVE")) == NULL)
		return NULL;

	if ((hResData= LoadResource(hModule, hResInfo)) == NULL)
		return NULL;

	if	((pRIFFBytes = LockResource(hResData))==NULL)
		return NULL;

#endif
	return (void*)pRIFFBytes;
	}


/***********************************************************************************
/
/	Function:	WriteWAVData
/
/	Description:	Copies the sample data from global memory into the soundbuffer.
/
***********************************************************************************/

BOOL WriteWAVData( LPDIRECTSOUNDBUFFER8 lpDSB, LPBYTE lpWaveData, DWORD dwWriteBytes )
	{
	HRESULT dsval;

	if (lpDSB && lpWaveData && dwWriteBytes)
		{
		LPVOID lpAudioPtr1, lpAudioPtr2;
		DWORD dwAudioBytes1, dwAudioBytes2;

		dsval = lpDSB->Lock(0, dwWriteBytes, &lpAudioPtr1, &dwAudioBytes1, &lpAudioPtr2, &dwAudioBytes2, 0);

		if (dsval == DS_OK)
			{
			CopyMemory(lpAudioPtr1, lpWaveData, dwAudioBytes1);

			if( dwAudioBytes2 != 0)
				CopyMemory(lpAudioPtr2, lpWaveData + dwAudioBytes1, dwAudioBytes2);

			lpDSB->Unlock(lpAudioPtr1, dwAudioBytes1, lpAudioPtr2, dwAudioBytes2);
			return TRUE;
			}
		}

	return FALSE;
	}

/*********************************************************************************
/
/	Function:	UnpackWAVChunk
/
/	Description:	Uncompacts the wave sample into raw data for DirectSound.
/
*********************************************************************************/

BOOL UnpackWAVChunk( void *pRIFFBytes, LPWAVEFORMATEX *lpwfmx, LPBYTE *lpChunkData, DWORD *lpCkSize )
	{
	DWORD *dwChunkBitsPtr;	// current data being referenced
	DWORD *dwChunkTailPtr;  // points to end of chunk
	DWORD dwChunkID;        // four byte chunk ID
	DWORD dwType;           // form type
	DWORD dwLength;         // size of data in chunk

	// initialize the LPWAVEFORMATEX pointer
	if (lpwfmx)
		*lpwfmx = NULL;

	// initialize the ckData pointer
	if (lpChunkData)
		*lpChunkData=NULL;

	// initialize the ckSize pointer
	if (lpCkSize)
		*lpCkSize=0;

	// reference the WAVE resource buffer
	dwChunkBitsPtr = (DWORD*)pRIFFBytes;

	// unpack the chunk ID
	dwChunkID = *dwChunkBitsPtr++;	

	// unpack the size field
	dwLength = *dwChunkBitsPtr++;

	// unpack the Form type
	dwType = *dwChunkBitsPtr++;

	// read the 4 byte identifier (FOURCC )

	if (dwChunkID!=mmioFOURCC('R','I','F','F'))
		return FALSE; // not a RIFF

	if (dwType!=mmioFOURCC('W','A','V','E'))
		return FALSE; // not a WAV

	dwChunkTailPtr = (DWORD*)((BYTE*)dwChunkBitsPtr + dwLength-4);

//	while(1)
	for (;;)
		{

		// unpack the Form Type
		dwType = *dwChunkBitsPtr++;

		// unpack the size
		dwLength = *dwChunkBitsPtr++;

		switch(dwType)
			{
			case mmioFOURCC('f','m','t',' '):

			if (lpwfmx && !*lpwfmx)
				{
				if (dwLength < sizeof(WAVEFORMAT))
					return FALSE; // not WAV

				*lpwfmx = (LPWAVEFORMATEX)dwChunkBitsPtr;

				if ( (!lpChunkData || *lpChunkData) && (!lpCkSize || *lpCkSize))
					return TRUE;

				} // if lpwfmx
			break;  // case 'fmt '

			case mmioFOURCC('d','a','t','a'):

			if ((lpChunkData && !*lpChunkData) || (lpCkSize && !*lpCkSize))
				{
				if (lpChunkData)
					*lpChunkData = (LPBYTE)dwChunkBitsPtr;

				if (lpCkSize)
					*lpCkSize = dwLength;

				if (!lpwfmx || *lpwfmx)
					return TRUE;
				} // if lpChunkData
			break;
			} // switch dwType

		dwChunkBitsPtr = (DWORD*)((BYTE*)dwChunkBitsPtr + ((dwLength+1)&~1));

		if (dwChunkBitsPtr >= dwChunkTailPtr)
			break;

		} // while dwChunkBitsPtr
	return FALSE;
	}
