# Dynamic Window Resizing

This document describes the resizable-window support shared by the Windows DirectX and Linux/Emscripten SDL builds.

### Overview
All builds support fully resizable game windows with intelligent scaling of all UI elements.

### Features

#### 1. Resizable Window with Aspect Ratio Lock
- Window can be freely resized by dragging edges or corners
- Aspect ratio automatically maintained during resize:
  - **Widescreen mode**: 800:480 ratio
  - **Standard mode**: 4:3 ratio (640:480)
- Implemented via the Win32 `WM_SIZING` handler on Windows and SDL2 window resize events on Linux/Emscripten

#### 2. Dynamic Font Scaling
- All fonts scale proportionally with window size
- Two font sizes automatically adjusted:
  - Small font: Base 15pt
  - Large font: Base 25pt
- Fonts recreated in `OnResetDevice()` (Windows) or `OnWindowResized()` (Linux/Emscripten) when the window resizes
- Scaling factor calculated by `GetTextScale()` helper function

#### 3. Dynamic Cockpit Scaling
- Cockpit overlay (wheels, dashboard, panels) scales with window
- Maintains proper proportions at any resolution
- Implementation in `Car.cpp::DrawCockpit()`
- Uses separate X and Y scale factors for accurate rendering

#### 4. Intelligent UI Positioning
- All text elements maintain proper screen positions
- Dashboard elements (boost, distance, lap time) scale correctly
- Base coordinate system allows consistent positioning across resolutions
- Speedbar dynamically adjusts length and position

### Implementation Details

#### Base Resolutions
```cpp
#define BASE_WIDTH_WIDESCREEN   800
#define BASE_WIDTH_STANDARD     640
#define BASE_HEIGHT             480
```

#### Scaling Calculation
```cpp
float GetTextScale() {
    long current_width, current_height;
    GetScreenDimensions(&current_width, &current_height);
    float base_width = wideScreen ? BASE_WIDTH_WIDESCREEN : BASE_WIDTH_STANDARD;
    return current_width / base_width;
}
```

#### Screen Dimensions
- **Windows**: Retrieved from the DirectX backbuffer (`D3DSURFACE_DESC`)
- **Linux/Emscripten**: Retrieved from the current OpenGL drawable size and tracked in `g_screenWidth`/`g_screenHeight`

### Code Organization

**Modified Files:**
- `StuntCarRacer.cpp`: Window resize handling, font scaling, text positioning
- `StuntCarRacer.h`: Base resolution constants
- `Car.cpp`: Cockpit scaling implementation
- `Car.h`: Cockpit rendering constants

**Key Functions:**
- `GetScreenDimensions()`: Returns current screen width/height
- `GetTextScale()`: Calculates scaling factor for fonts/text
- `MsgProc()`: Handles `WM_SIZING` messages to preserve aspect ratio on Windows
- `ConstrainWindowAspect()`: Preserves the aspect ratio on SDL2 window resizes
- `ApplyScreenSize()`: Updates the viewport, 2D projection and 3D aspect ratio
- `OnResetDevice()` / `OnWindowResized()`: Recreate fonts at the correct scaled sizes
- `DrawCockpit()`: Scales cockpit overlay based on resolution

### Platform Compatibility

#### Windows (DirectX)
✅ Fully functional
- Window resizing works
- All scaling features active
- Uses DirectX backbuffer dimensions

#### Linux / Emscripten (OpenGL/SDL2)
✅ Fully functional
- Resizable window with aspect ratio preservation
- `GetScreenDimensions()` returns the current drawable size
- Fonts and cockpit scale dynamically with the window
- OpenGL viewport and projection updated on resize

## DirectX Error Handling

### Overview
Enhanced error logging for DirectX operations to aid debugging.

### Implementation
- All DirectX resource creation calls checked for failures
- Vertex buffer lock operations validated
- Texture loading verified
- Errors logged via `OutputDebugStringW()` for debugging

**Examples:**
```cpp
if (FAILED(CreatePolygonVertexBuffer(pd3dDevice))) {
    OutputDebugStringW(L"ERROR: Failed to create polygon vertex buffer\n");
    return hr;
}
```

### Platform Compatibility
- **Windows**: Active - provides debugging information
- **Linux**: N/A - code not compiled (DirectX-specific)

## Summary

These features enhance the Windows DirectX and Linux/Emscripten SDL builds:
- ✅ Shared scaling codebase
- ✅ Consistent resizing behavior across platforms
- ✅ Proper platform guards (`#ifndef linux`)
- ✅ Code quality improvements benefit both platforms
