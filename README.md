# stuntcarremake

[![stuntcarremake Linux build status](https://travis-ci.org/ptitSeb/stuntcarremake.svg?branch=master)](https://travis-ci.org/ptitSeb/stuntcarremake "stuntcarremake Linux build status") [![stuntcarremake Windows build status](https://ci.appveyor.com/api/projects/status/3b9bd69a4vsy0eu6/branch/master?svg=true)](https://ci.appveyor.com/project/ptitSeb/stuntcarremake/branch/master "stuntcarremake Windows Build status")

This is a port to Linux & OpenPandora of Stunt Car Racer Remake, a windows remake of the old Stunt Car Racer from the AtariST/Amiga time.

## Building

The game is built with CMake. Select the target platform with the
`STUNT_PLATFORM` cache variable: `LINUX` (default on desktop), `PANDORA`,
`PYRA`, `ODROID`, `ODROIDN1` or `CHIP`.

### Linux

```sh
cmake -S . -B build -DSTUNT_PLATFORM=LINUX -DSTUNT_SDL2=ON
cmake --build build -j
```

Useful options:

- `STUNT_SDL2=ON` uses SDL2 instead of SDL 1.2 (default: SDL 1.2)
- `STUNT_GLES=ON` uses OpenGL ES instead of desktop OpenGL
- `STUNT_32BIT=ON` builds a 32-bit executable
- `-DCMAKE_BUILD_TYPE=Debug|Release|Profile` selects the build configuration
  (default: `Release`)

### Windows (Visual Studio)

```sh
cmake -S . -B build -G "Visual Studio 17 2022" -A Win32
cmake --build build --config Release
```

Use `-A x64` for a 64-bit build. The Microsoft DirectX SDK (June 2010) is
required. If CMake cannot find it, set `-DSTUNT_DXSDK_DIR=<sdk root>`. The
generated Visual Studio solution provides `Debug`, `Release` and `Profile`
configurations.

### Emscripten

```sh
emcmake cmake -S . -B build-emscripten -DSTUNT_PLATFORM=EMSCRIPTEN
cmake --build build-emscripten
```

The web build is written to `docs/index.html`. gl4es is expected at `../gl4es`;
override this with `-DSTUNT_GL4ES_DIR=<path>`.

You can play the Emscripten version, built using
[gl4es](https://github.com/ptitSeb/gl4es) here:
[Web version](http://ptitseb.github.io/stuntcarremake/)

Some code (the OpenAL part) come from Forsaken/ProjectX port by chino.

## Windows-Specific Features 

The Windows build includes additional features not available on Linux:

### Dynamic Window Resizing
- **Resizable window** with automatic aspect ratio preservation (16:10 for widescreen, 4:3 for standard)
- **Dynamic font scaling** - fonts and UI text scale based on window size
- **Dynamic cockpit scaling** - cockpit overlay scales proportionally with window resolution
- **Intelligent positioning** - UI elements maintain proper positioning at any resolution

**Technical Details:**
- Implemented via Win32 `WM_SIZING` message handler
- Uses DirectX backbuffer dimensions for accurate scaling calculations
- Base resolutions: 800x480 (widescreen) or 640x480 (standard)
- All scaling factors calculated dynamically from current vs base resolution

**Linux Status:** Linux builds use fixed resolution (800x480 or 640x480) as the SDL implementation does not currently support dynamic resizing. The scaling code is present but inactive (returns 1.0x scale) to maintain compatibility.

**Contributors:** Windows enhancements by omenoid <akaunist@gmail.com> (2025-11-30)

## Controls

Controls are:
On Linux / Windows
 4 Arrows for Turning / Accelerate / Brake
 Space for Boost

On Pandora
 DPad Left/Right for turning
 (X) Accelerate
 (B) Brake
 (R) Boost

[![Play on Youtube](https://img.youtube.com/vi/qKTFntQtG6E/0.jpg)](https://www.youtube.com/watch?v=qKTFntQtG6E)

Here is a video on StuntCarRemake running on the OpenPandora

Original project is here: http://sourceforge.net/projects/stuntcarremake/
