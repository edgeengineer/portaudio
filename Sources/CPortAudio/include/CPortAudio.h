#ifndef CPORTAUDIO_H
#define CPORTAUDIO_H

#include "portaudio.h"

#ifdef __APPLE__
#include "pa_mac_core.h"
#endif

#ifdef __linux__
#include "pa_linux_alsa.h"
#endif

#endif // CPORTAUDIO_H