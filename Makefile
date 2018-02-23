#
# General Compiler Settings
#

CC=g++
#PANDORA=1
DEBUG=1

# general compiler settings
ifeq ($(M32),1)
	FLAGS= -m32
endif
ifeq ($(PANDORA),1)
	FLAGS= -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=softfp -march=armv7-a -fsingle-precision-constant -mno-unaligned-access -fdiagnostics-color=auto -O3 -fsigned-char
	FLAGS+= -DPANDORA
	FLAGS+= -DARM
	LDFLAGS= -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=softfp
	#HAVE_GLES=1
endif
ifeq ($(ODROID),1)
        FLAGS= -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard -fsingle-precision-constant -O3 -fsigned-char
        FLAGS+= -DODROID
        FLAGS+= -DARM
        LDFLAGS= -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard
        #HAVE_GLES=1
endif
ifeq ($(ODROIDN1),1)
        FLAGS= -mcpu=cortex-a72.cortex-a53 -fsingle-precision-constant -O3 -fsigned-char -ffast-math
        FLAGS+= -DODROID
        FLAGS+= -DARM
        LDFLAGS= -mcpu=cortex-a72.cortex-a53
        #HAVE_GLES=1
endif
ifeq ($(CHIP),1)
        FLAGS= -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=hard -fsingle-precision-constant -O3 -fsigned-char
        FLAGS+= -DCHIP
        FLAGS+= -DARM
        LDFLAGS= -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=hard
        #HAVE_GLES=1
endif

FLAGS+= -pipe -fpermissive
CFLAGS=$(FLAGS) -Wno-conversion-null -Wno-write-strings -ICommon
LDFLAGS=$(FLAGS)

ifeq ($(PANDORA),1)
	PROFILE=0
else
	PROFILE=0
endif


ifeq ($(DEBUG),1)
	FLAGS+= -g
else
	CFLAGS+=-O3 -Winit-self
	LDFLAGS+=-s
endif

ifeq ($(PROFILE),1)
	ifneq ($(DEBUG),1)
		# Debug symbols needed for profiling to be useful
		FLAGS+= -g
	endif
	FLAGS+= -pg
endif

SDL=1
ifeq ($(SDL),1)
	SDL_=
	CFLAGS+=`sdl-config --cflags`
	TTF_ = SDL_ttf
	IMAGE_ = SDL_image
else
	SDL_=sdl$(SDL)
	TTF_ = SDL$(SDL)_ttf
	IMAGE_ = SDL$(SDL)_image
endif

# library headers
ifeq ($(PANDORA),1)
	CFLAGS+= `pkg-config --cflags $(SDL_) $(TTF_) $(IMAGE_) libpng zlib openal`
else
	CFLAGS+= `pkg-config --cflags $(SDL_) $(TTF_) $(IMAGE_) libpng zlib openal`
endif

# dynamic only libraries
ifeq ($(PANDORA),1)
	LIB+= `sdl-config --libs`
else
	LIB+= `pkg-config --libs $(SDL_)`
endif

LIB+= `pkg-config --libs $(TTF_) $(IMAGE_)`

ifeq ($(MINGW),1)
	LIB += -L./mingw/bin
	LIB += -lglu32 -lopengl32
	LIB += -lsocket -lws2_32 -lwsock32 -lwinmm -lOpenAL32
else
	ifeq ($(HAVE_GLES),1)
		LIB += -lGLES_CM -lEGL
		CFLAGS += -DHAVE_GLES
	else
		LIB += -lGL -lGLU
	endif
	LIB += -lopenal
endif
ifneq ($(MINGW),1)
	# apparently on some systems -ldl is explicitly required
	# perhaps this is part of the default libs on others...?
	LIB+= -ldl
endif


# specific includes
CFLAGS += -I.
CFLAGS += -DSOUND_OPENAL

ifeq ($(DEBUG),1)
	CFLAGS+= -DDEBUG_ON -DDEBUG_COMP -DDEBUG_SPOTFX_SOUND -DDEBUG_VIEWPORT
endif

BIN=stuntcarracer


INC=$(wildcard *.h)
SRC=$(wildcard *.cpp)
OBJ=$(patsubst %.cpp,%.o,$(SRC))

all: $(BIN)

$(BIN): $(OBJ)
	$(CC) -o $(BIN) $(OBJ) $(CFLAGS) $(LDFLAGS) $(LIB)

$(OBJ): $(INC)

%.o: %.cpp
	$(CC) -o $@ -c $< $(CFLAGS)

clean:
	$(RM) $(OBJ) $(BIN)

check:
	@echo
	@echo "INC = $(INC)"
	@echo
	@echo "SRC = $(SRC)"
	@echo
	@echo "OBJ = $(OBJ)"
	@echo
	@echo "DEBUG = $(DEBUG)"
	@echo "PROFILE = $(PROFILE)"
	@echo "PANDORA = $(PANDORA)"
	@echo "ODROID = $(ODROID)"
	@echo "CHIP = $(CHIP)"
	@echo "HAVE_GLES = $(HAVE_GLES)"
	@echo "SDL = $(SDL)"
	@echo "SDL_ = $(SDL_)"
	@echo
	@echo "CC = $(CC)"
	@echo "BIN = $(BIN)"
	@echo "CFLAGS = $(CFLAGS)"
	@echo "LDFLAGS = $(LDFLAGS)"
	@echo "LIB = $(LIB)"
	@echo
