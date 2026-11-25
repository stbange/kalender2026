#ifndef HALL_FEEDBACK_AUDIO_H
#define HALL_FEEDBACK_AUDIO_H
#include "hall.h"
typedef struct {
    char name[32];
    uint32_t id;
    float seconds;
} hall_clip;
typedef struct {
    hall_clip clips[64];
    size_t count;
    struct {
        uint32_t id;
        float remaining, rank;
    } voices[8];
    unsigned played, dropped, peak;
} hall_mix;
void hall_mix_load(hall_mix *mix, eng_runtime_t *rt, eng_audio_t *audio);
void hall_mix_frame(hall_mix *mix, eng_runtime_t *rt, eng_audio_t *audio, float dt);
#endif
