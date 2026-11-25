#include "feedback_audio.h"
#include <SDL3/SDL.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void hall_mix_load(hall_mix *mix, eng_runtime_t *rt, eng_audio_t *audio)
{
    memset(mix, 0, sizeof(*mix));
    char list[2048];
    hall_eval(rt, "return table.concat(Feedback.sources,' ')", list, sizeof(list));
    for (char *name = strtok(list, " "); name && mix->count < 64; name = strtok(NULL, " ")) {
        size_t len = strlen(name);
        if (len >= sizeof(mix->clips[0].name) ||
            strspn(name, "abcdefghijklmnopqrstuvwxyz0123456789_-") != len)
            continue;
        char path[80];
        snprintf(path, sizeof(path), "assets/%s.wav", name);
        size_t bytes = 0;
        void *data = eng_vfs_read_all(eng_runtime_vfs(rt), path, &bytes);
        if (!data)
            continue;
        SDL_AudioSpec spec;
        Uint8 *pcm = NULL;
        Uint32 size = 0;
        if (SDL_LoadWAV_IO(SDL_IOFromConstMem(data, bytes), true, &spec, &pcm, &size)) {
            hall_clip *c = &mix->clips[mix->count++];
            memcpy(c->name, name, len + 1);
            c->id = eng_audio_load_wav_mem(audio, data, bytes);
            c->seconds = (float)size / ((float)spec.freq * SDL_AUDIO_FRAMESIZE(spec));
            SDL_free(pcm);
        }
        free(data);
    }
}

static void play(hall_mix *m, eng_audio_t *audio, eng_vec3_t listener, const char *line)
{
    char name[32];
    float gain, pitch, x, y, z, far;
    int priority, spatial;
    if (sscanf(line, "%31s %f %f %d %d %f %f %f %f", name, &gain, &pitch, &priority, &spatial, &x, &y, &z,
               &far) != 9 ||
        !(pitch > 0 && pitch <= 4) || !(gain > 0 && gain <= 2))
        return;
    size_t i = 0;
    while (i < m->count && strcmp(name, m->clips[i].name))
        i++;
    if (i == m->count || !m->clips[i].id)
        return;
    float dx = x - listener.x, dz = z - listener.z;
    float rank = 1000.0f * priority - (spatial ? sqrtf(dx * dx + dz * dz) : 0);
    int slot = -1;
    for (int j = (priority >= 3 ? 7 : 5); j >= 0; j--) {
        if (m->voices[j].remaining <= 0) {
            slot = j;
            break;
        }
        if (m->voices[j].rank < rank && (slot < 0 || m->voices[j].rank < m->voices[slot].rank))
            slot = j;
    }
    if (slot < 0) {
        m->dropped++;
        return;
    }
    if (m->voices[slot].remaining > 0)
        eng_audio_stop(audio, m->voices[slot].id);
    eng_voice_desc_t v = eng_voice_default_desc(m->clips[i].id);
    v.spatial_3d = spatial != 0;
    v.pos = eng_v3(x, y, z);
    v.pitch = pitch;
    v.gain = gain;
    v.min_dist = 1.5f;
    v.max_dist = far;
    m->voices[slot].id = eng_audio_play(audio, &v);
    m->voices[slot].remaining = m->clips[i].seconds / pitch;
    m->voices[slot].rank = rank;
    m->played++;
}

void hall_mix_frame(hall_mix *m, eng_runtime_t *rt, eng_audio_t *audio, float dt)
{
    for (int i = 0; i < 8; i++)
        m->voices[i].remaining -= dt;
    const eng_camera_t *cam = eng_runtime_camera(rt);
    char buffer[1200];
    eng_vec3_t pos = cam->pos;
    eng_quat_t rot = cam->rot;
    if (eng_xr_is_active(eng_runtime_xr(rt))) {
        float x, y, z, yaw;
        hall_eval(rt,
                  "local g=game.state; return string.format('%f %f %f %f',g.x+(g.eyeX or 0),g.eyeY or "
                  "1.55,g.z+(g.eyeZ or 0),g.headYaw or g.yaw)",
                  buffer, sizeof(buffer));
        if (sscanf(buffer, "%f %f %f %f", &x, &y, &z, &yaw) == 4) {
            pos = eng_v3(x, y, z);
            rot = eng_quat_from_euler_deg(eng_v3(0, yaw, 0));
        }
    }
    eng_audio_set_listener(audio, cam->pocket_id, pos, eng_v3(0, 0, 0), rot);
    hall_eval(rt, "return host_sound()", buffer, sizeof(buffer));
    for (char *line = strtok(buffer, "\n"); line; line = strtok(NULL, "\n"))
        play(m, audio, pos, line);
    unsigned active = 0;
    for (int i = 0; i < 8; i++)
        active += m->voices[i].remaining > 0;
    if (active > m->peak)
        m->peak = active;
    eng_audio_update(audio, eng_runtime_scene(rt), eng_runtime_portals(rt), dt);
}
