// Stub implementation for PortAudio API
// This is a minimal implementation for demonstration purposes
// In a real implementation, you would link against the actual PortAudio library

#include <stddef.h>
#include "portaudio.h"

int Pa_Initialize(void) { return paNoError; }
int Pa_Terminate(void) { return paNoError; }
int Pa_GetVersion(void) { return 19070000; }
const char* Pa_GetVersionText(void) { return "PortAudio V19.7.0-devel (compiled " __DATE__ " " __TIME__ ")"; }

int Pa_GetDeviceCount(void) { 
    return 2; // Return at least 2 devices for demo
}

PaDeviceIndex Pa_GetDefaultInputDevice(void) { return 0; }
PaDeviceIndex Pa_GetDefaultOutputDevice(void) { return 1; }

const PaDeviceInfo* Pa_GetDeviceInfo(PaDeviceIndex device) {
    static PaDeviceInfo inputDevice = {
        .structVersion = 2,
        .name = "Default Input Device",
        .hostApi = 0,
        .maxInputChannels = 2,
        .maxOutputChannels = 0,
        .defaultLowInputLatency = 0.01,
        .defaultLowOutputLatency = 0.0,
        .defaultHighInputLatency = 0.1,
        .defaultHighOutputLatency = 0.0,
        .defaultSampleRate = 44100.0
    };
    
    static PaDeviceInfo outputDevice = {
        .structVersion = 2,
        .name = "Default Output Device",
        .hostApi = 0,
        .maxInputChannels = 0,
        .maxOutputChannels = 2,
        .defaultLowInputLatency = 0.0,
        .defaultLowOutputLatency = 0.01,
        .defaultHighInputLatency = 0.0,
        .defaultHighOutputLatency = 0.1,
        .defaultSampleRate = 44100.0
    };
    
    if (device == 0) return &inputDevice;
    if (device == 1) return &outputDevice;
    return NULL;
}

PaError Pa_OpenStream(PaStream** stream,
                     const PaStreamParameters* inputParameters,
                     const PaStreamParameters* outputParameters,
                     double sampleRate,
                     unsigned long framesPerBuffer,
                     PaStreamFlags streamFlags,
                     PaStreamCallback* streamCallback,
                     void* userData) {
    if (streamCallback != NULL) {
        // Callback mode not supported in stub
        return paInternalError;
    }
    *stream = (PaStream*)1; // Dummy non-null pointer
    return paNoError;
}

PaError Pa_CloseStream(PaStream* stream) { return paNoError; }
PaError Pa_StartStream(PaStream* stream) { return paNoError; }
PaError Pa_StopStream(PaStream* stream) { return paNoError; }
PaError Pa_AbortStream(PaStream* stream) { return paNoError; }
PaError Pa_IsStreamStopped(PaStream* stream) { return 1; }
PaError Pa_IsStreamActive(PaStream* stream) { return 0; }
PaError Pa_ReadStream(PaStream* stream, void* buffer, unsigned long frames) { 
    return paNoError; // Stub implementation always succeeds
}
PaError Pa_WriteStream(PaStream* stream, const void* buffer, unsigned long frames) { 
    return paNoError; // Stub implementation always succeeds
}