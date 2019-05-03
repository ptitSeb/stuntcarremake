#ifdef linux

#include "dx_linux.h"
#ifdef USE_SDL2
#include <SDL2/SDL.h>
#else
#include <SDL/SDL.h>
#endif
#include <AL/al.h>
#include <AL/alc.h>
#include <math.h>

bool Sound3D = false; // enable 3d sound

struct {
	int buffers;
	int sources;
	int playing;
} stats;

struct sound_buffer_t {
	ALuint id;
	int freq;
};

struct sound_source_t {
	ALuint id;
	ALuint buffer;
	sound_buffer_t* buff;
	bool playing;
};

//
// sound system load / unload
//

static ALCdevice* Device = NULL;
static ALCcontext* Context = NULL;
int sound_minimum_volume;

static void print_info ( void ) 
{
	ALint version_major, version_minor;
	ALenum error;
	ALCdevice *device;

	printf("openal: info start\n");

	// Check for EAX 2.0 support
	printf("EAX2.0 support = %s\n",
		alIsExtensionPresent("EAX2.0")?"true":"false");

	if(alcIsExtensionPresent(NULL, "ALC_ENUMERATION_EXT") == AL_TRUE) 
	{
		printf("default playback: %s\n",alcGetString(NULL, ALC_DEFAULT_DEVICE_SPECIFIER));
		printf("default capture: %s\n",alcGetString(NULL, ALC_CAPTURE_DEFAULT_DEVICE_SPECIFIER));
		{	
			// print all playback devices
			const char * s = alcGetString(NULL, ALC_DEVICE_SPECIFIER);
			while(s && *s != '\0')
			{
				printf("playback: %s\n", s); 
				s += strlen(s)+1;
			}
			// print all capture devices
			s = alcGetString(NULL, ALC_CAPTURE_DEVICE_SPECIFIER);
			while(s && *s != '\0')
			{ 
				printf("capture: %s\n", s); 
				s += strlen(s)+1;
			}
		}
	} 
	else 
		printf("No device enumeration available\n");

	printf("Default device: %s\n", alcGetString(NULL, ALC_DEFAULT_DEVICE_SPECIFIER));
	printf("Default capture device: %s\n", (alcGetString(NULL, ALC_CAPTURE_DEFAULT_DEVICE_SPECIFIER)));

	device = alcGetContextsDevice(alcGetCurrentContext());

	if ((error = alGetError()) != AL_NO_ERROR)
		printf("error:  :%s\n", alGetString(error));

	alcGetIntegerv(device, ALC_MAJOR_VERSION, 1, &version_major);
	alcGetIntegerv(device, ALC_MINOR_VERSION, 1, &version_minor);
	
	if ((error = alGetError()) != AL_NO_ERROR)
		printf("error:  :%s\n", alGetString(error));

	printf("ALC version: %d.%d\n", (int)version_major, (int)version_minor);
	printf("ALC extensions: %s\n", alcGetString(device, ALC_EXTENSIONS));

	if ((error = alGetError()) != AL_NO_ERROR)
		printf("error:  :%s\n", alGetString(error));

	printf("OpenAL vendor string: %s\n", alGetString(AL_VENDOR));
	printf("OpenAL renderer string: %s\n", alGetString(AL_RENDERER));
	printf("OpenAL version string: %s\n", alGetString(AL_VERSION));
	printf("OpenAL extensions: %s\n", alGetString(AL_EXTENSIONS));

	if ((error = alGetError()) != AL_NO_ERROR)
		printf("error:  :%s\n", alGetString(error));

	printf("openal: info end\n");
}

bool sound_init( void )
{
	// TODO - disabling the ability to re-init sound system
	// on ubuntu using "drivers = pulse" will handle in alcOpenDevice
	// is there really even a reason we need to re-init sound?
	static int initialized = 0;
	if(initialized)
		return true;
	initialized = 1;

	Device = alcOpenDevice(NULL); // preferred device
	if(!Device)
		return false;

	Context = alcCreateContext(Device,NULL);
	if(!Context)
		return false;

	alcMakeContextCurrent(Context);

	// since the game was based around dsound
	// it performs some volume calculations using this value
	// dsound defines DSBVOLUME_MIN as -10000
	// and forsaken defined min volume as 1/3 of that
	sound_minimum_volume = -10000 / 3;

	// global listener sound set to 50% to reduce crackling
	// TODO - we should probably have a global sound level setting
	alListenerf(AL_GAIN, 0.5f);

	{
		ALfloat f;
		ALfloat pos[3];
		alGetListenerf(AL_GAIN,&f);
		printf("listener gain: %f\n",f);
		alGetListenerfv(AL_POSITION,pos);
		printf("listener position: %f %f %f\n",pos[0],pos[1],pos[2]);
	}

	print_info();

	return true;
}

void sound_destroy( void )
{
	ALCcontext * Context = alcGetCurrentContext();
	ALCdevice * Device = alcGetContextsDevice(Context);
	alcMakeContextCurrent(NULL);
	alcDestroyContext(Context);
	alcCloseDevice(Device);
}

//
// 3d routines
//

bool sound_listener_position( float x, float y, float z )
{
	alListener3f(AL_POSITION, x, y, -z);
	return true;
}

bool sound_listener_velocity( float x, float y, float z )
{
	alListener3f(AL_VELOCITY, x, y, -z);
	return true;
}

bool sound_listener_orientation( 
	float fx, float fy, float fz, // forward vector
	float ux, float uy, float uz  // up vector
)
{
	float vector[6] = {fx,fy,-fz,ux,uy,-uz};
	alListenerfv(AL_ORIENTATION, &vector[0]);
	return true;
}

// TODO - we'll want to set velocity as well
void sound_position( sound_source_t * source, float x, float y, float z, float min, float max )
{
	alSource3f(source->id, AL_POSITION, x, y, -z);
	alSourcef(source->id, AL_MAX_DISTANCE, max);
	alSourcef(source->id, AL_REFERENCE_DISTANCE, min); // is this right?
}

//
// 2d routines
//

void sound_set_pitch( sound_source_t * source, float pitch )
{
	ALfloat f = pitch ? pitch : 1.0f ; // 1.0f is default
	alSourcef( source->id, AL_PITCH, f );
	//printf("sound_pitch: %f\n",f);
}

void sound_set_frequency( sound_source_t * source, long frequency )
{
	ALfloat f = (float)frequency/source->buff->freq ; // 1.0f is default
	alSourcef( source->id, AL_PITCH, f );
	//printf("sound_pitch: %f\n",f);
}

void sound_volume( sound_source_t * source, long millibels )
{
	ALfloat f;
	millibels = ( millibels > 0 ) ? 0 : millibels;
	// gain is scaled to (silence) 0.0f through (no change) 1.0f
	// millibels = hundredths of decibels (dB)
	// defined in Dsound.h as (no change) 0 and (silence) -10,000
	f = (ALfloat) pow(10.0, millibels/2000.0);
	alSourcef(source->id, AL_GAIN, f);
	//printf("sound_volume: %ld\n",millibels);
}

void sound_pan( sound_source_t * source, long _pan )
{
	// where pan is -1 (left) to +1 (right)
	// must be scaled from -1 <-> +1
	// probably need to scale down by 10,000, since dsound goes from -10000 to +10000
	// so:
	float pan = (float) _pan / 10000.0f;
	float pan2 = (float) sqrt(1 - pan*pan);
	//printf("sound_pan: %f - %f\n",pan,pan2);
	alSource3f(source->id, AL_POSITION, pan, pan2, 0.0f);
}

//
//  play / stop
//

void sound_play( sound_source_t * source )
{
	if(!source->playing)
		stats.playing++;
	source->playing = true;
	//
	alSourcePlay( source->id );
	//
	//printf("sound_play: playing sound='%s' count=%d source=%d\n",
	//	source->path, stats.playing, source);
}

void sound_play_looping( sound_source_t * source )
{
	if(!source->playing)
		stats.playing++;
	source->playing = true;
	//
	alSourcei( source->id, AL_LOOPING, AL_TRUE );
	sound_play( source );
	//
	//printf("sound_play_looping: playing %d\n",stats.playing);
}

void sound_stop( sound_source_t * source )
{
	if(source->playing)
		stats.playing--;
	source->playing = false;
	//
	alSourceStop( source->id );
	//
	//printf("sound_stop: playing %d\n",stats.playing);
}

bool sound_is_playing( sound_source_t * source )
{
	ALint state;
	alGetSourcei( source->id, AL_SOURCE_STATE, &state );
	return (state == AL_PLAYING);
}

void sound_set_position( sound_source_t * source, long newpos )
{
    alSourcei( source->id, AL_BYTE_OFFSET, newpos );
}

long sound_get_position( sound_source_t * source )
{
    ALint offset;
    alGetSourcei( source->id, AL_BYTE_OFFSET, &offset);
    return offset;
}

//
// load resources
//

sound_buffer_t * sound_load(void* data, int size, int bits, int sign, int channels, int freq)
{
	ALenum error;
	ALenum format;
	u_int8_t *wav_buffer;
	sound_buffer_t * buffer;

	// create the buffer
    buffer = (sound_buffer_t*)malloc(sizeof(sound_buffer_t));
	if(!buffer)
	{
		printf("sound_load: failed to malloc buffer\n");
		return 0;
	}

	// clear error code
	alGetError();

	// Generate Buffers
	alGenBuffers(1, &(buffer->id));
	if ((error = alGetError()) != AL_NO_ERROR)
	{
		printf("alGenBuffers: %s\n", alGetString(error));
		free(buffer);
		return NULL;
	}

    wav_buffer = (u_int8_t*)data;

    if(bits == 8) // 8 bit
	{
		// openal only supports unsigned 8bit
		if(sign)
		{
			int i;
			for(i = 0; i < (int) size; i++)
				wav_buffer[i] ^= 0x80; // converts S8 to U8
			printf("sound_buffer: converted s8 to u8\n");
		}
		if(channels == 1)
			format = AL_FORMAT_MONO8;
		else
			format = AL_FORMAT_STEREO8;
		printf("sound_buffer: format = %s\n",
			format == AL_FORMAT_MONO8 ? "mono8" : "stereo8" );
	}
	else // 16 bit
	{
		// openal only supports signed 16bit
		if(!sign)
		{
			int i;
			for(i = 0;i < (int) size/2;i++)
				((u_int16_t*)wav_buffer)[i] ^= 0x8000; // converts U16 to S16
			printf("sound_buffer: converted u16 to s16\n");
		}
		if(channels == 1)
			format = AL_FORMAT_MONO16;
		else
			format = AL_FORMAT_STEREO16;
		//printf("sound_buffer: format = %s\n",
		//	format == AL_FORMAT_MONO16 ? "mono16" : "stereo16" );
	}

	// Copy data into AL Buffer 0
	alBufferData(buffer->id,format,wav_buffer,size,freq);
	if ((error = alGetError()) != AL_NO_ERROR)
	{
		printf("alBufferData: %s\n", alGetString(error));
		alDeleteBuffers(1, &buffer->id);
		free(buffer);
		SDL_FreeWAV(wav_buffer);
		return NULL;
	}

	stats.buffers++;
	//printf("sound_load: buffers %d sources %d playing %d buffer %d\n",
	//			stats.buffers,stats.sources,stats.playing,buffer);

	buffer->freq = freq;
	return buffer;
}

sound_source_t * sound_source( sound_buffer_t * buffer )
{
	ALenum error;
	sound_source_t * source;

	if(!buffer)
	{
		printf("sound_source: null buffer given\n");
		return 0;
	}

    source = (sound_source_t*)malloc(sizeof(sound_source_t));
	if(!source)
	{
		printf("sound_source: failed to malloc source\n");
		return 0;
	}
	source->playing = false;
	source->buffer = buffer->id;
	source->buff = buffer;

	// clear errors
	alGetError();

	// generate a new source id
	alGenSources(1,&source->id);
	if ((error = alGetError()) != AL_NO_ERROR)
	{
		printf("alGenSources: %s\n", alGetString(error));
		free(source);
		source = NULL;
		return NULL;
	}

	// attach the buffer to the source
	alSourcei(source->id, AL_BUFFER, source->buffer);
	if ((error = alGetError()) != AL_NO_ERROR)
	{
		printf("alSourcei AL_BUFFER: %s\n", alGetString(error));
		alDeleteSources(1,&source->id);
		free(source);
		source = NULL;
		return NULL;
	}

	alSourcei(source->id,AL_SOURCE_RELATIVE,
		Sound3D ? AL_FALSE : AL_TRUE);

	stats.sources++;
	//printf("sound_source: sources %d buffers %d playing %d source %d\n",
	//			stats.sources,stats.buffers,stats.playing,source);

	return source;
}

//
//  release resources
//

void sound_release_source( sound_source_t * source )
{
	if(!source)
		return;
	if(source->playing)
		stats.playing--;
	source->playing = false;
	// deleting source implicitly detaches buffer
	alDeleteSources( 1, &source->id );
	// clean up resources
	free(source);
	// show stats
	stats.sources--;
	//printf("sound_release_source: buffers %d sources %d playing %d source %d\n",
	//			stats.buffers,stats.sources,stats.playing,source);
	source = NULL;
}

void sound_release_buffer( sound_buffer_t * buffer )
{
	if(!buffer)
		return;
	// buffers will not delete if they are attached to other sources
	alGetError(); // clear error so we can see if buffer is attached elsewhere
	alDeleteBuffers( 1, &buffer->id );
	// if buffer attached elsewhere than error is generated
	if(alGetError() == AL_NO_ERROR)
		stats.buffers--;
	else
		printf("sound_release_buffer: error buffer %d still attached to a source.\n",
			buffer->id);
	// clean up resources
	free(buffer);
	buffer = NULL;
	// show stats
	//printf("sound_release_buffer: buffers %d sources %d playing %d\n",
	//			stats.buffers,stats.sources,stats.playing);
}

#endif // SOUND_OPENAL