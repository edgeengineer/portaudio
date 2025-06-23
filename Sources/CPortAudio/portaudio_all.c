// This file includes all necessary PortAudio source files for compilation
// This approach allows us to compile PortAudio as part of our Swift package

// Common sources
#include "../../portaudio/src/common/pa_allocation.c"
#include "../../portaudio/src/common/pa_converters.c"
#include "../../portaudio/src/common/pa_cpuload.c"
#include "../../portaudio/src/common/pa_debugprint.c"
#include "../../portaudio/src/common/pa_dither.c"
#include "../../portaudio/src/common/pa_front.c"
#include "../../portaudio/src/common/pa_process.c"
#include "../../portaudio/src/common/pa_ringbuffer.c"
#include "../../portaudio/src/common/pa_stream.c"
#include "../../portaudio/src/common/pa_trace.c"

// Platform-specific implementations
#ifdef __APPLE__
// macOS/CoreAudio specific
#include "../../portaudio/src/hostapi/coreaudio/pa_mac_core.c"
#include "../../portaudio/src/hostapi/coreaudio/pa_mac_core_blocking.c"
#include "../../portaudio/src/hostapi/coreaudio/pa_mac_core_utilities.c"
#elif __linux__
// Linux/ALSA specific
#include "../../portaudio/src/hostapi/alsa/pa_linux_alsa.c"
#endif

// Unix utilities (shared between macOS and Linux)
#include "../../portaudio/src/os/unix/pa_unix_hostapis.c"
#include "../../portaudio/src/os/unix/pa_unix_util.c"
#include "../../portaudio/src/os/unix/pa_pthread_util.c"