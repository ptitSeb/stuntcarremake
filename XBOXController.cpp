#include "dxstdafx.h"

#include "XBOXController.h"

// ctor - playerNumber 1<>4
CXBOXController::CXBOXController(const int playerNumber)
{
	// Set the Controller Number
	_controllerNum = playerNumber - 1;
}

XINPUT_STATE CXBOXController::GetState()
{
	// Zeroise the state
	ZeroMemory(&_controllerState, sizeof(XINPUT_STATE));

	// Get the state
	#ifdef linux
#warning TODO...
	_controllerState = 0;
	#else
	XInputGetState(_controllerNum, &_controllerState);
	#endif

	return _controllerState;
}

bool CXBOXController::IsConnected()
{
	// Zeroise the state
	ZeroMemory(&_controllerState, sizeof(XINPUT_STATE));

	// Get the state
	#ifdef linux
#warning TODO
	DWORD Result = 0xFFFF;
	#else
	DWORD Result = XInputGetState(_controllerNum, &_controllerState);
	#endif

	if(Result == ERROR_SUCCESS)
	{
		return true;
	}
	else
	{
		return false;
	}
}

void CXBOXController::Vibrate(const unsigned short leftVal, const unsigned short rightVal)
{
	#ifdef linux
#warning TODO
	#else
	// Create a Vibraton State
	XINPUT_VIBRATION Vibration;

	// Zeroise the Vibration
	ZeroMemory(&Vibration, sizeof(XINPUT_VIBRATION));

	// Set the Vibration Values
	Vibration.wLeftMotorSpeed = leftVal;
	Vibration.wRightMotorSpeed = rightVal;

	// Vibrate the controller
	XInputSetState(_controllerNum, &Vibration);
	#endif
}
