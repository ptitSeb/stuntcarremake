#ifndef _XBOX_CONTROLLER_H_
#define _XBOX_CONTROLLER_H_

// No MFC
#define WIN32_LEAN_AND_MEAN

// We need the Windows Header and the XInput Header
#ifdef linux
#ifdef USE_SDL2
#include <SDL2/SDL.h>
#else
#include <SDL/SDL.h>
#endif
#define XINPUT_STATE int
#else
#include <windows.h>
#include <XInput.h>
#endif

// Now, the XInput Library
// NOTE: COMMENT THIS OUT IF YOU ARE NOT USING A COMPILER THAT SUPPORTS THIS METHOD OF LINKING LIBRARIES
#pragma comment(lib, "XInput.lib")

// XBOX Controller Class Definition
class CXBOXController
{
private:
	XINPUT_STATE _controllerState;
	int _controllerNum;
public:
	// ctor - playerNumber 1<>4
	CXBOXController(const int playerNumber);
	XINPUT_STATE GetState();
	bool IsConnected();
	void Vibrate(const unsigned short leftVal = 0, const unsigned short rightVal = 0);
};

#endif
