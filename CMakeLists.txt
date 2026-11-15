cmake_minimum_required(VERSION 3.20)

project(StuntCarRacer VERSION 0.0.3 LANGUAGES CXX)

if(POLICY CMP0091)
    cmake_policy(SET CMP0091 NEW)
endif()

get_property(STUNT_MULTI_CONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

set(STUNT_BUILD_CONFIGURATIONS Debug Release Profile)
if(STUNT_MULTI_CONFIG)
    set(CMAKE_CONFIGURATION_TYPES "${STUNT_BUILD_CONFIGURATIONS}" CACHE STRING "Available build configurations" FORCE)
else()
    if(NOT CMAKE_BUILD_TYPE)
        set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
    endif()
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS ${STUNT_BUILD_CONFIGURATIONS})
endif()

if(MSVC)
    set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}" CACHE STRING "Flags used by Profile builds")
    set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}" CACHE STRING "Linker flags used by Profile builds")
else()
    set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE} -g -pg" CACHE STRING "Flags used by Profile builds")
    set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} -pg" CACHE STRING "Linker flags used by Profile builds")
endif()

if(WIN32)
    set(_stunt_default_platform WINDOWS)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
    set(_stunt_default_platform EMSCRIPTEN)
else()
    set(_stunt_default_platform LINUX)
endif()

set(STUNT_PLATFORM "${_stunt_default_platform}" CACHE STRING "Target platform")
set_property(CACHE STUNT_PLATFORM PROPERTY STRINGS
    LINUX PANDORA PYRA ODROID ODROIDN1 CHIP EMSCRIPTEN WINDOWS)

set(STUNT_LINUX_PLATFORMS LINUX PANDORA PYRA ODROID ODROIDN1 CHIP)

if(STUNT_PLATFORM STREQUAL "WINDOWS")
    if(NOT WIN32)
        message(FATAL_ERROR "STUNT_PLATFORM=WINDOWS requires a Windows toolchain")
    endif()
elseif(STUNT_PLATFORM STREQUAL "EMSCRIPTEN")
    if(NOT CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
        message(FATAL_ERROR "STUNT_PLATFORM=EMSCRIPTEN requires the Emscripten toolchain file")
    endif()
elseif(STUNT_PLATFORM IN_LIST STUNT_LINUX_PLATFORMS)
    if(WIN32 OR CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
        message(FATAL_ERROR "STUNT_PLATFORM=${STUNT_PLATFORM} requires a Linux/Unix toolchain")
    endif()
else()
    message(FATAL_ERROR "Unknown STUNT_PLATFORM '${STUNT_PLATFORM}'")
endif()

option(STUNT_SDL2 "Use SDL 2 instead of SDL 1.2" OFF)
option(STUNT_GLES "Use OpenGL ES 1.x instead of desktop OpenGL" OFF)
option(STUNT_32BIT "Build a 32-bit executable (non-Windows toolchains)" OFF)
set(STUNT_GL4ES_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../gl4es" CACHE PATH "gl4es root directory for Emscripten builds")
set(STUNT_GLM_DIR "" CACHE PATH "Optional GLM include directory hint")
set(STUNT_DXSDK_DIR "" CACHE PATH "Microsoft DirectX SDK (June 2010) root directory")

if(STUNT_PLATFORM STREQUAL "EMSCRIPTEN")
    set(STUNT_SDL2 ON CACHE BOOL "Use SDL 2 instead of SDL 1.2" FORCE)
endif()

set(STUNT_SOURCES
    3D_Engine.cpp
    Atlas.cpp
    Backdrop.cpp
    Car.cpp
    Car_Behaviour.cpp
    Opponent_Behaviour.cpp
    StuntCarRacer.cpp
    Track.cpp
    wavefunctions.cpp
    XBOXController.cpp
)

set(STUNT_HEADERS
    3D_Engine.h
    Atlas.h
    Backdrop.h
    Car.h
    Car_Behaviour.h
    Opponent_Behaviour.h
    StuntCarRacer.h
    Track.h
    wavefunctions.h
    XBOXController.h
    resource.h
    version.h
    stb_image.h
    Common/dxstdafx.h
)

if(STUNT_PLATFORM STREQUAL "WINDOWS")
    enable_language(RC)
    list(APPEND STUNT_SOURCES
        Common/dxstdafx.cpp
        Common/DXUT.cpp
        Common/DXUTenum.cpp
        Common/DXUTmisc.cpp
        Common/DXUTRes.cpp
        StuntCarRacer.rc
    )
    list(APPEND STUNT_HEADERS
        Common/DXUT.h
        Common/DXUTenum.h
        Common/DXUTmisc.h
        Common/DXUTRes.h
    )
else()
    list(APPEND STUNT_SOURCES
        dx_linux.cpp
        sound_openal.cpp
    )
    list(APPEND STUNT_HEADERS
        dx_linux.h
    )
endif()

if(STUNT_PLATFORM STREQUAL "WINDOWS")
    add_executable(stuntcarracer WIN32 ${STUNT_SOURCES} ${STUNT_HEADERS})
    set_target_properties(stuntcarracer PROPERTIES OUTPUT_NAME StuntCarRacer)
else()
    add_executable(stuntcarracer ${STUNT_SOURCES} ${STUNT_HEADERS})
endif()

set_target_properties(stuntcarracer PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED YES
    CXX_EXTENSIONS YES
)

target_include_directories(stuntcarracer PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/Common"
)

if(STUNT_PLATFORM STREQUAL "WINDOWS")
    target_compile_definitions(stuntcarracer PRIVATE
        WIN32
        _WINDOWS
        $<$<CONFIG:Debug>:DEBUG>
        $<$<CONFIG:Debug>:_DEBUG>
        $<$<OR:$<CONFIG:Debug>,$<CONFIG:Profile>>:PROFILE>
    )
endif()

set(STUNT_PLATFORM_DEFINITIONS)
set(STUNT_PLATFORM_COMPILE_OPTIONS)
set(STUNT_PLATFORM_LINK_OPTIONS)

if(STUNT_PLATFORM STREQUAL "LINUX")
    list(APPEND STUNT_PLATFORM_DEFINITIONS linux SOUND_OPENAL)
elseif(STUNT_PLATFORM STREQUAL "PANDORA")
    list(APPEND STUNT_PLATFORM_DEFINITIONS linux ARM PANDORA SOUND_OPENAL)
    list(APPEND STUNT_PLATFORM_COMPILE_OPTIONS
        -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=softfp -march=armv7-a
        -fsingle-precision-constant -mno-unaligned-access -O3 -fsigned-char)
    list(APPEND STUNT_PLATFORM_LINK_OPTIONS -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=softfp)
elseif(STUNT_PLATFORM STREQUAL "PYRA")
    list(APPEND STUNT_PLATFORM_DEFINITIONS linux ARM PYRA SOUND_OPENAL)
    list(APPEND STUNT_PLATFORM_COMPILE_OPTIONS
        -mcpu=cortex-a15 -mfpu=neon -mfloat-abi=hard -fsingle-precision-constant)
    list(APPEND STUNT_PLATFORM_LINK_OPTIONS -mcpu=cortex-a15 -mfpu=neon -mfloat-abi=hard)
elseif(STUNT_PLATFORM STREQUAL "ODROID")
    list(APPEND STUNT_PLATFORM_DEFINITIONS linux ARM ODROID SOUND_OPENAL)
    list(APPEND STUNT_PLATFORM_COMPILE_OPTIONS
        -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard -fsingle-precision-constant
        -O3 -fsigned-char)
    list(APPEND STUNT_PLATFORM_LINK_OPTIONS -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard)
elseif(STUNT_PLATFORM STREQUAL "ODROIDN1")
    list(APPEND STUNT_PLATFORM_DEFINITIONS linux ARM ODROID SOUND_OPENAL)
    list(APPEND STUNT_PLATFORM_COMPILE_OPTIONS
        -mcpu=cortex-a72.cortex-a53 -fsingle-precision-constant -O3
        -fsigned-char -ffast-math)
    list(APPEND STUNT_PLATFORM_LINK_OPTIONS -mcpu=cortex-a72.cortex-a53)
elseif(STUNT_PLATFORM STREQUAL "CHIP")
    list(APPEND STUNT_PLATFORM_DEFINITIONS linux ARM CHIP SOUND_OPENAL)
    list(APPEND STUNT_PLATFORM_COMPILE_OPTIONS
        -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=hard -fsingle-precision-constant
        -O3 -fsigned-char)
    list(APPEND STUNT_PLATFORM_LINK_OPTIONS -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=hard)
elseif(STUNT_PLATFORM STREQUAL "EMSCRIPTEN")
    list(APPEND STUNT_PLATFORM_DEFINITIONS linux USE_SDL2 SOUND_OPENAL)
endif()

if(NOT STUNT_PLATFORM STREQUAL "WINDOWS" AND NOT STUNT_PLATFORM STREQUAL "EMSCRIPTEN")
    if(STUNT_SDL2)
        list(APPEND STUNT_PLATFORM_DEFINITIONS USE_SDL2)
    endif()
    if(STUNT_GLES)
        list(APPEND STUNT_PLATFORM_DEFINITIONS HAVE_GLES)
    endif()
endif()

list(REMOVE_DUPLICATES STUNT_PLATFORM_DEFINITIONS)
if(STUNT_PLATFORM_DEFINITIONS)
    target_compile_definitions(stuntcarracer PRIVATE ${STUNT_PLATFORM_DEFINITIONS})
endif()

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(stuntcarracer PRIVATE
        -pipe
        -Wno-conversion-null
        -Wno-write-strings
    )
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_compile_options(stuntcarracer PRIVATE -fpermissive)
    endif()
    target_compile_options(stuntcarracer PRIVATE $<$<CONFIG:Release>:-Winit-self>)
endif()

if(STUNT_32BIT)
    if(MSVC)
        message(WARNING "STUNT_32BIT is ignored for Visual Studio generators; use -A Win32")
    elseif(STUNT_PLATFORM STREQUAL "EMSCRIPTEN")
        message(WARNING "STUNT_32BIT is ignored for Emscripten builds")
    else()
        target_compile_options(stuntcarracer PRIVATE -m32)
        target_link_options(stuntcarracer PRIVATE -m32)
    endif()
endif()

if(STUNT_PLATFORM_COMPILE_OPTIONS)
    target_compile_options(stuntcarracer PRIVATE ${STUNT_PLATFORM_COMPILE_OPTIONS})
endif()
if(STUNT_PLATFORM_LINK_OPTIONS)
    target_link_options(stuntcarracer PRIVATE ${STUNT_PLATFORM_LINK_OPTIONS})
endif()

if(STUNT_PLATFORM STREQUAL "WINDOWS")
    if(NOT STUNT_DXSDK_DIR AND DEFINED ENV{DXSDK_DIR})
        set(STUNT_DXSDK_DIR "$ENV{DXSDK_DIR}" CACHE PATH "Microsoft DirectX SDK (June 2010) root directory" FORCE)
    endif()

    set(_stunt_dxsdk_hints)
    if(STUNT_DXSDK_DIR)
        list(APPEND _stunt_dxsdk_hints "${STUNT_DXSDK_DIR}")
    endif()
    if(DEFINED ENV{DXSDK_DIR})
        list(APPEND _stunt_dxsdk_hints "$ENV{DXSDK_DIR}")
    endif()
    list(APPEND _stunt_dxsdk_hints "C:/Program Files (x86)/Microsoft DirectX SDK (June 2010)")

    find_path(STUNT_DXSDK_INCLUDE_DIR NAMES d3dx9.h HINTS ${_stunt_dxsdk_hints} PATH_SUFFIXES Include)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(_stunt_dxsdk_arch x64)
    else()
        set(_stunt_dxsdk_arch x86)
    endif()
    find_path(STUNT_DXSDK_LIBRARY_DIR NAMES d3dx9.lib HINTS ${_stunt_dxsdk_hints} PATH_SUFFIXES "Lib/${_stunt_dxsdk_arch}" Lib)

    if(NOT STUNT_DXSDK_INCLUDE_DIR OR NOT STUNT_DXSDK_LIBRARY_DIR)
        message(FATAL_ERROR
            "Microsoft DirectX SDK (June 2010) was not found. "
            "Set STUNT_DXSDK_DIR to the SDK root directory.")
    endif()

    target_include_directories(stuntcarracer PRIVATE "${STUNT_DXSDK_INCLUDE_DIR}")
    target_link_directories(stuntcarracer PRIVATE "${STUNT_DXSDK_LIBRARY_DIR}")
    target_link_libraries(stuntcarracer PRIVATE
        dxerr
        dxguid
        d3d9
        dsound
        winmm
        comctl32
        legacy_stdio_definitions
        $<$<CONFIG:Debug>:d3dx9d>
        $<$<NOT:$<CONFIG:Debug>>:d3dx9>
    )

    if(MSVC)
        set_property(TARGET stuntcarracer PROPERTY
            MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
        target_compile_options(stuntcarracer PRIVATE /W4)
        target_link_options(stuntcarracer PRIVATE /IGNORE:4089 /MANIFEST:NO)
    endif()
elseif(STUNT_PLATFORM STREQUAL "EMSCRIPTEN")
    find_path(GLM_INCLUDE_DIR NAMES glm/glm.hpp HINTS ${STUNT_GLM_DIR})
    if(GLM_INCLUDE_DIR)
        target_include_directories(stuntcarracer PRIVATE "${GLM_INCLUDE_DIR}" "${GLM_INCLUDE_DIR}/glm")
    else()
        message(FATAL_ERROR "GLM headers not found. Set STUNT_GLM_DIR to the GLM include directory.")
    endif()

    if(EXISTS "${STUNT_GL4ES_DIR}/include")
        target_include_directories(stuntcarracer PRIVATE "${STUNT_GL4ES_DIR}/include")
    else()
        message(WARNING "gl4es includes not found at ${STUNT_GL4ES_DIR}/include")
    endif()

    if(EXISTS "${STUNT_GL4ES_DIR}/lib/libGL.a")
        set(STUNT_GL4ES_LIBRARY "${STUNT_GL4ES_DIR}/lib/libGL.a")
    else()
        message(FATAL_ERROR "gl4es library not found at ${STUNT_GL4ES_DIR}/lib/libGL.a")
    endif()

    target_link_libraries(stuntcarracer PRIVATE openal "${STUNT_GL4ES_LIBRARY}")
    target_link_options(stuntcarracer PRIVATE
        -sFULL_ES2=1
        -sUSE_SDL=2
        -sUSE_SDL_TTF=2
        --emrun
        --preload-file "${CMAKE_CURRENT_SOURCE_DIR}/Tracks"
        --preload-file "${CMAKE_CURRENT_SOURCE_DIR}/Sounds"
        --preload-file "${CMAKE_CURRENT_SOURCE_DIR}/Bitmap"
        --embed-file "${CMAKE_CURRENT_SOURCE_DIR}/DejaVuSans-Bold.ttf"
        --shell-file "${CMAKE_CURRENT_SOURCE_DIR}/template.html"
    )
    set_target_properties(stuntcarracer PROPERTIES
        OUTPUT_NAME index
        SUFFIX ".html"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/docs"
    )
else()
    find_package(OpenGL REQUIRED)
    find_package(PkgConfig REQUIRED)

    if(STUNT_SDL2)
        pkg_check_modules(STUNT_SDL REQUIRED IMPORTED_TARGET sdl2)
        pkg_check_modules(STUNT_SDL_TTF REQUIRED IMPORTED_TARGET SDL2_ttf)
    else()
        pkg_check_modules(STUNT_SDL REQUIRED IMPORTED_TARGET sdl)
        pkg_check_modules(STUNT_SDL_TTF REQUIRED IMPORTED_TARGET SDL_ttf)
    endif()
    pkg_check_modules(STUNT_OPENAL REQUIRED IMPORTED_TARGET openal)

    if(STUNT_GLES)
        pkg_check_modules(STUNT_GLES REQUIRED IMPORTED_TARGET glesv1_cm)
        pkg_check_modules(STUNT_EGL REQUIRED IMPORTED_TARGET egl)
        target_link_libraries(stuntcarracer PRIVATE
            PkgConfig::STUNT_GLES
            PkgConfig::STUNT_EGL
        )
    else()
        target_link_libraries(stuntcarracer PRIVATE OpenGL::GL)
        if(TARGET OpenGL::GLU)
            target_link_libraries(stuntcarracer PRIVATE OpenGL::GLU)
        endif()
    endif()

    find_package(glm QUIET)
    if(TARGET glm::glm)
        target_link_libraries(stuntcarracer PRIVATE glm::glm)
    else()
        find_path(GLM_INCLUDE_DIR NAMES glm/glm.hpp HINTS ${STUNT_GLM_DIR})
        if(NOT GLM_INCLUDE_DIR)
            message(FATAL_ERROR "GLM headers not found. Set STUNT_GLM_DIR to the GLM include directory.")
        endif()
        target_include_directories(stuntcarracer PRIVATE "${GLM_INCLUDE_DIR}" "${GLM_INCLUDE_DIR}/glm")
    endif()

    target_link_libraries(stuntcarracer PRIVATE
        PkgConfig::STUNT_SDL
        PkgConfig::STUNT_SDL_TTF
        PkgConfig::STUNT_OPENAL
        ${CMAKE_DL_LIBS}
    )
endif()

install(TARGETS stuntcarracer RUNTIME DESTINATION bin)
