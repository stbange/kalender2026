#include "hall.h"
#include "settings.h"
#include "feedback_audio.h"
#include <SDL3/SDL.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#define WEB_EXPORT EMSCRIPTEN_KEEPALIVE
#else
#define WEB_EXPORT
#endif

static struct {
    eng_runtime_t *rt;
    eng_ui_t *ui;
    eng_audio_t *audio;
    hall_mix mix;
    bool preferences;
    int preference_row;
    eng_net_peer_t *peer;
    const char *ca_pem;
    uint64_t join_deadline;
    char hello[128];
    char active_endpoint[384], active_room[33];
    bool headless, failed, xr;
    time_t utc;
    float look_x, look_y;
    hall_settings settings;
} app;
static const char *actions[] = {"left", "right", "up", "down", "fire", "interact", "practice"};
static bool held[7], pulse[7], injected[7];

WEB_EXPORT void hall_action(const char *name, int down)
{
    for (size_t i = 0; i < 7; i++)
        if (!strcmp(name, actions[i])) {
            if (down && !held[i])
                pulse[i] = true;
            held[i] = down != 0;
        }
}
WEB_EXPORT void hall_look(float x, float y)
{
    app.look_x += x;
    app.look_y += y;
}
WEB_EXPORT void hall_choose(int number)
{
    char code[48];
    if (number < 0 || number > 5)
        return;
    if (number)
        snprintf(code, sizeof(code), "host_weapon(%d)", number);
    else
        snprintf(code, sizeof(code), "host_weapon()");
    hall_eval(app.rt, code, NULL, 0);
}
WEB_EXPORT void hall_menu(int show)
{
    hall_eval(app.rt, show ? "game.state.menu=true;Feedback.endBurst(game.state)" : "game.state.menu=false",
              NULL, 0);
}
WEB_EXPORT void hall_resize(int width, int height)
{
    eng_platform_set_size(eng_runtime_platform(app.rt), width, height);
}
WEB_EXPORT void hall_lock(int state)
{
    eng_platform_sync_mouse_lock(eng_runtime_platform(app.rt), state != 0);
}
static void disconnect_room(void)
{
    if (eng_net_is_connected(app.peer))
        eng_net_send(app.peer, ENG_CHAN_RELIABLE, "BYE", 3);
    eng_net_destroy(app.peer);
    app.peer = NULL;
    app.join_deadline = 0;
}

WEB_EXPORT int hall_connect(const char *endpoint, const char *room)
{
    if (!hall_valid_address(endpoint, room))
        return 0;
    if (app.peer && !strcmp(endpoint, app.active_endpoint) && !strcmp(room, app.active_room))
        return 1;
    if (app.peer) {
        disconnect_room();
        hall_eval(app.rt, "host_receive('DISCONNECTED')", NULL, 0);
    }
    if (!*endpoint)
        return 1;
    char version[64];
    if (!hall_eval(app.rt, "return Hall.version", version, sizeof(version)))
        return 0;
    snprintf(app.hello, sizeof(app.hello), "HELLO3 %s %s", version, room);
    snprintf(app.active_endpoint, sizeof(app.active_endpoint), "%s", endpoint);
    snprintf(app.active_room, sizeof(app.active_room), "%s", room);
    app.peer = eng_net_create(ENG_NET_WEBSOCKET, 0);
    if (!app.peer || !eng_net_set_ca_pem(app.peer, app.ca_pem) ||
        !eng_net_connect_remote(app.peer, endpoint, 0)) {
        disconnect_room();
        hall_eval(app.rt, "host_receive('ERROR Could not connect. Check the room address.')", NULL, 0);
        return 0;
    }
    app.join_deadline = SDL_GetTicks() + 8000;
    hall_eval(app.rt, "game.state.connection='Joining room'", NULL, 0);
    return 1;
}

static void network(void)
{
    if (!app.peer)
        return;
    eng_net_event_t event;
    char data[24000];
    while (eng_net_poll_event(app.peer, &event, data, sizeof(data))) {
        if (event.type == ENG_NET_EVT_DISCONNECT) {
            hall_eval(app.rt,
                      app.join_deadline
                          ? "host_receive('ERROR Could not join. Check the address and server version.')"
                          : "host_receive('DISCONNECTED')",
                      NULL, 0);
            disconnect_room();
            return;
        }
        if (event.type == ENG_NET_EVT_CONNECT) {
            eng_net_send(app.peer, ENG_CHAN_RELIABLE, app.hello, strlen(app.hello));
        } else if (event.type == ENG_NET_EVT_MESSAGE && event.len < sizeof(data)) {
            char literal[35000], code[35100];
            if (hall_string(literal, sizeof(literal), data, event.len)) {
                snprintf(code, sizeof(code), "host_receive(%s)", literal);
                hall_eval(app.rt, code, NULL, 0);
                if (event.len >= 6 && !memcmp(data, "ERROR ", 6)) {
                    disconnect_room();
                    return;
                }
                if (event.len >= 8 && !memcmp(data, "WELCOME ", 8))
                    app.join_deadline = 0;
            }
        }
    }
    if (app.join_deadline) {
        if (SDL_GetTicks() >= app.join_deadline) {
            disconnect_room();
            hall_eval(
                app.rt,
                "host_receive('ERROR Join timed out. Check the address and use the matching room server.')",
                NULL, 0);
        }
        return;
    }
    char outgoing[3000];
    if (hall_eval(app.rt, "return host_drain()", outgoing, sizeof(outgoing)))
        for (char *line = strtok(outgoing, "\n"); line; line = strtok(NULL, "\n"))
            eng_net_send(app.peer, ENG_CHAN_RELIABLE, line, strlen(line));
}

static void audio_frame(float dt) { hall_mix_frame(&app.mix, app.rt, app.audio, dt); }

WEB_EXPORT int hall_tune(int row, int value)
{
    char code[96], result[32];
    snprintf(code, sizeof(code), "return host_tune(%d,%d)", row, value);
    int current = hall_eval(app.rt, code, result, sizeof(result)) ? atoi(result) : 0;
    if (row == 3 && app.audio)
        eng_audio_set_bus_gain(app.audio, ENG_BUS_SFX, current / 100.f);
    return current;
}
/* Sampled by the repeatable Web performance route after a rendered frame. */
WEB_EXPORT unsigned hall_mix_stat(int stat)
{
    if (stat == 0)
        return app.mix.peak;
    if (stat == 1)
        return app.mix.played;
    return app.mix.dropped;
}

WEB_EXPORT int hall_pulse(void)
{
    char result[40];
    return hall_eval(app.rt, "return host_pulse()", result, sizeof(result)) ? atoi(result) : 0;
}
WEB_EXPORT void hall_device(int touch, int resume)
{
    hall_eval(app.rt, touch ? "TouchHall=true" : "TouchHall=false", NULL, 0);
    if (resume)
        hall_eval(app.rt, "game.state.feedback.resume=true", NULL, 0);
}
#ifndef __EMSCRIPTEN__
static const char *preference_names[] = {"Motion",    "Detail",   "Sounds",        "Haptics",
                                         "Hit marks", "Captions", "High contrast", "Reduced motion"};
static bool SDLCALL settings_event(void *unused, SDL_Event *event)
{
    (void)unused;
    hall_settings *s = &app.settings;
    if (event->type == SDL_EVENT_KEY_DOWN && !s->open) {
        SDL_Scancode key = event->key.scancode;
        if ((key == SDL_SCANCODE_F3 && !event->key.repeat) ||
            (key == SDL_SCANCODE_ESCAPE && app.preferences)) {
            app.preferences = !app.preferences;
            eng_platform_set_mouse_lock(eng_runtime_platform(app.rt), !app.preferences);
            return true;
        }
        if (app.preferences) {
            if (key == SDL_SCANCODE_UP || key == SDL_SCANCODE_DOWN || key == SDL_SCANCODE_TAB)
                app.preference_row = (app.preference_row + (key == SDL_SCANCODE_UP ? 7 : 1)) % 8;
            if (key == SDL_SCANCODE_LEFT || key == SDL_SCANCODE_RIGHT || key == SDL_SCANCODE_RETURN) {
                int row = app.preference_row + 1, old = hall_tune(row, -1);
                int value = row <= 4 ? SDL_clamp(old + (key == SDL_SCANCODE_LEFT ? -10 : 10), 0, 100) : !old;
                hall_tune(row, value);
            }
            return true;
        }
    }
    if (event->type == SDL_EVENT_KEY_DOWN && event->key.scancode == SDL_SCANCODE_F2 && !event->key.repeat) {
        s->open = !s->open;
        SDL_Window *window = SDL_GetKeyboardFocus();
        if (window) {
            if (s->open)
                SDL_StartTextInput(window);
            else
                SDL_StopTextInput(window);
        }
        eng_platform_set_mouse_lock(eng_runtime_platform(app.rt), !s->open);
    } else if (s->open && event->type == SDL_EVENT_TEXT_INPUT)
        hall_settings_text(s, event->text.text);
    else if (s->open && event->type == SDL_EVENT_KEY_DOWN) {
        switch (event->key.scancode) {
        case SDL_SCANCODE_TAB:
            s->field = !s->field;
            break;
        case SDL_SCANCODE_BACKSPACE:
            hall_settings_erase(s);
            break;
        case SDL_SCANCODE_V:
            if (event->key.mod & SDL_KMOD_CTRL) {
                char *clip = SDL_GetClipboardText();
                if (clip)
                    hall_settings_text(s, clip);
                SDL_free(clip);
            }
            break;
        case SDL_SCANCODE_RETURN:
            s->submit = true;
            break;
        default:
            break;
        }
    }
    return true;
}
#endif

static void frame(void)
{
    eng_platform_t *plat = eng_runtime_platform(app.rt);
    eng_input_t *input = eng_runtime_input(app.rt);
    float dt = eng_platform_begin_frame(plat);
#ifdef __EMSCRIPTEN__
    /* A slow GPU frame may take over 100 ms. Keep gameplay moving at a bounded step. */
    static double previous_ms;
    double now_ms = emscripten_get_now();
    if (previous_ms > 0)
        dt = (float)fmin(0.1, (now_ms - previous_ms) * 0.001);
    previous_ms = now_ms;
#endif
    eng_input_begin_frame(input, dt);
    eng_input_poll_sdl(input, plat);
#ifdef __EMSCRIPTEN__
    /* The Web shell supplies locked mouse and touch deltas. SDL also synthesizes motion from menu clicks. */
    eng_vec2_t browser_mouse = eng_input_mouse_delta(input);
    eng_input_inject_mouse_delta(input, -browser_mouse.x, -browser_mouse.y);
#else
    if (app.settings.submit) {
        app.settings.submit = false;
        if (hall_connect(app.settings.endpoint, app.settings.room)) {
            hall_settings_save(&app.settings, app.rt);
            app.settings.open = false;
            SDL_Window *window = SDL_GetKeyboardFocus();
            if (window)
                SDL_StopTextInput(window);
            eng_platform_set_mouse_lock(plat, true);
        }
    }
#endif
    for (size_t i = 0; i < 7; i++) {
        bool on = held[i] || pulse[i];
        if (on != injected[i]) {
            eng_input_inject_action(input, actions[i], on);
            injected[i] = on;
        }
        pulse[i] = false;
    }
    if (app.look_x || app.look_y) {
        eng_input_inject_mouse_delta(input, app.look_x, app.look_y);
        app.look_x = app.look_y = 0;
    }
    time_t now = time(NULL);
    if (now != app.utc) {
        app.utc = now;
        hall_utc(app.rt, now);
    }
    network();
    char error[512] = {0};
    if (!app.settings.open && !app.preferences && !eng_runtime_step(app.rt, dt, error, sizeof(error))) {
        fprintf(stderr, "Simulation: %s\n", error);
        app.failed = true;
        return;
    }
    audio_frame(dt);
    int width, height, pw, ph;
    eng_platform_get_size(plat, &width, &height);
    eng_platform_get_pixel_size(plat, &pw, &ph);
    if (!app.xr)
        eng_renderer_resize(eng_runtime_renderer(app.rt), pw, ph);
    else {
        eng_camera_t *cam = eng_runtime_camera(app.rt);
        eng_xr_sync_frame(eng_runtime_xr(app.rt), cam->pos, cam->rot, NULL);
    }
    if (!eng_runtime_render(app.rt, error, sizeof(error))) {
        fprintf(stderr, "Render: %s\n", error);
        app.failed = true;
        return;
    }
#ifdef __EMSCRIPTEN__
    char request[12];
    if (hall_eval(app.rt, "return host_pack_request()", request, sizeof(request)) && atoi(request) > 0)
        EM_ASM({ Module.fetchHallPack($0); }, atoi(request));
    char info[500];
    if (hall_eval(app.rt, "return host_hud()", info, sizeof(info))) {
        EM_ASM(
            {
                if (Module.hallHUD)
                    Module.hallHUD(UTF8ToString($0));
            },
            info);
    }
#else
    eng_ui_begin_frame(app.ui, width, height, 0, 0, false, 0);
    eng_ui_set_fb_size(app.ui, pw, ph);
    for (size_t i = 0; i < eng_runtime_hud_text_count(app.rt); i++) {
        float x, y;
        const char *s = eng_runtime_hud_text_get(app.rt, i, &x, &y);
        char name[24];
        snprintf(name, sizeof(name), "status%u", (unsigned)i);
        eng_ui_hud_label(app.ui, name, ENG_UI_TOP_LEFT, x, y, 640, 26, s);
    }
    if (!app.settings.open && !app.preferences)
        hall_feedback_overlay(app.rt, app.ui, width, height);
    if (app.preferences) {
        eng_ui_hud_label(app.ui, "feedback", ENG_UI_CENTER, 0, -144, 410, 28,
                         "Feedback    Arrows: adjust   Esc: close");
        for (int i = 0; i < 8; i++) {
            char label[128];
            int value = hall_tune(i + 1, -1);
            if (i < 4)
                snprintf(label, sizeof(label), "%c %s   %d%%", app.preference_row == i ? '>' : ' ',
                         preference_names[i], value);
            else
                snprintf(label, sizeof(label), "%c %s   %s", app.preference_row == i ? '>' : ' ',
                         preference_names[i], value ? "On" : "Off");
            eng_ui_hud_label(app.ui, preference_names[i], ENG_UI_CENTER, 0, -110 + 28 * i, 410, 28, label);
        }
    } else if (app.settings.open) {
        char e[455], r[90];
        snprintf(e, sizeof(e), "%c Service: %s", app.settings.field ? ' ' : '>', app.settings.endpoint);
        snprintf(r, sizeof(r), "%c Room: %s", app.settings.field ? '>' : ' ', app.settings.room);
        eng_ui_hud_label(app.ui, "edit", ENG_UI_CENTER, -260, -80, 550, 30,
                         "Join friends    Tab: switch field   Enter: connect   F2: close");
        eng_ui_hud_label(app.ui, "endpoint", ENG_UI_CENTER, -260, -44, 550, 30, e);
        eng_ui_hud_label(app.ui, "room", ENG_UI_CENTER, -260, -10, 550, 30, r);
    } else
        eng_ui_hud_label(
            app.ui, "controls", ENG_UI_BOTTOM_LEFT, 12, 12, 850, 26,
            "WASD move   Mouse fire   1-5 / Q snowcasters   R practice   F2 join friends   F3 feedback");
    eng_ui_render(app.ui);
#endif
    if (!app.xr)
        eng_platform_swap(plat);
}
#ifdef __EMSCRIPTEN__
static void flat_frame(void)
{
    if (!app.xr && !app.failed)
        frame();
}
#endif
WEB_EXPORT void hall_pack_ready(int day, int ok)
{
    if (day < 1 || day > 24)
        return;
    char code[64];
    snprintf(code, sizeof(code), "host_pack_ready(%d,%s)", day, ok ? "true" : "false");
    hall_eval(app.rt, code, NULL, 0);
}
WEB_EXPORT void hall_xr_end(void)
{
    app.xr = false;
    hall_pulse();
    eng_xr_end_session(eng_runtime_xr(app.rt));
    hall_eval(app.rt, "host_xr(false);game.state.headYaw=nil;HostMoveX=0;HostMoveZ=0", NULL, 0);
    hall_action("fire", 0);
    hall_action("interact", 0);
    hall_action("practice", 0);
}
WEB_EXPORT void hall_xr_frame(int fbo, const float *mat, const int *vp, const float *aim)
{
    app.xr = true;
    eng_xr_eye_t eyes[2] = {0};
    for (int i = 0; i < 2; i++) {
        memcpy(eyes[i].view.m, mat + i * 32, 64);
        memcpy(eyes[i].proj.m, mat + i * 32 + 16, 64);
        memcpy(eyes[i].viewport, vp + i * 4, 4 * sizeof(int));
    }
    eng_xr_submit_frame_state(eng_runtime_xr(app.rt), (uint32_t)fbo, NULL, eyes, NULL);
    char code[512];
    snprintf(code, sizeof(code),
             "host_xr(true,%f,%f,%f,%f,%f,%f,%f);"
             "local g=game.state;local b=math.rad(g.yaw);g.eyeX=%f*math.cos(b)+%f*math.sin(b);"
             "g.eyeY=%f;g.eyeZ=-%f*math.sin(b)+%f*math.cos(b);g.headYaw=g.yaw+%f;"
             "local a=math.rad(g.headYaw);HostMoveX=%f*math.cos(a)+%f*math.sin(a);"
             "HostMoveZ=-%f*math.sin(a)+%f*math.cos(a)",
             aim[0], aim[1] - 1.55, aim[2], aim[3], aim[4], aim[5], aim[8], aim[11], aim[13], aim[12],
             aim[11], aim[13], aim[9], aim[6], aim[7], aim[6], aim[7]);
    hall_eval(app.rt, code, NULL, 0);
    hall_action("fire", aim[10] > .5f);
    if (!app.failed)
        frame();
}
int hall_client(eng_runtime_t *rt, const hall_options *opts)
{
    app.rt = rt;
    app.headless = opts->headless;
    app.ca_pem = opts->ca_pem;
    app.preferences = false;
    app.preference_row = 0;
    eng_input_t *input = eng_runtime_input(rt);
#ifdef __EMSCRIPTEN__
    /* The Web shell owns touch sticks, aiming and firing. A finger can also synthesize a left click. */
    SDL_SetEventEnabled(SDL_EVENT_FINGER_DOWN, false);
    SDL_SetEventEnabled(SDL_EVENT_FINGER_MOTION, false);
    SDL_SetEventEnabled(SDL_EVENT_FINGER_UP, false);
    SDL_SetEventEnabled(SDL_EVENT_FINGER_CANCELED, false);
    eng_input_bind_mouse_button(input, "fire", 0);
#endif
    for (int i = 0; i < 5; i++) {
        char action[8];
        snprintf(action, sizeof(action), "tool%d", i + 1);
        eng_input_bind_key(input, action, (SDL_Scancode)(SDL_SCANCODE_1 + i));
    }
    eng_input_bind_key(input, "cycle", SDL_SCANCODE_Q);
    eng_input_bind_key(input, "practice", SDL_SCANCODE_R);
    eng_xr_set_mode(eng_runtime_xr(rt), ENG_XR_FIRST_PERSON);
    app.audio = eng_audio_create(opts->headless);
    hall_mix_load(&app.mix, rt, app.audio);
    hall_tune(3, -1);
    hall_settings_read(&app.settings, rt, opts);
    if (*app.settings.endpoint)
        hall_connect(app.settings.endpoint, app.settings.room);
#ifdef __EMSCRIPTEN__
    hall_eval(rt, "HostWeb=true", NULL, 0);
    emscripten_set_main_loop(flat_frame, 0, 1);
#else
    app.ui = eng_ui_create();
    SDL_AddEventWatch(settings_event, NULL);
    unsigned frames = 0;
    while (!eng_platform_should_quit(eng_runtime_platform(rt)) && !app.failed) {
        frame();
        if (opts->frames && ++frames >= opts->frames)
            break;
        if (opts->headless && opts->endpoint)
            SDL_Delay(16);
    }
    eng_ui_destroy(app.ui);
    SDL_RemoveEventWatch(settings_event, NULL);
#endif
    disconnect_room();
    eng_audio_destroy(app.audio);
    return app.failed ? 1 : 0;
}
