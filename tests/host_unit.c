/* Test the host's SDL events, frame, C/Lua boundary and command-line entry point. */
#ifdef NDEBUG
#undef NDEBUG
#endif
#include "../src/client.c"
#include <assert.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void hall_test_tls(const char *cert, Uint16 port);

static void key(SDL_Scancode scancode, SDL_Keymod modifier)
{
    SDL_Event event;
    SDL_zero(event);
    event.key.type = SDL_EVENT_KEY_DOWN;
    event.key.repeat = false;
    event.key.scancode = scancode;
    event.key.mod = modifier;
    settings_event(NULL, &event);
}

static int run(int n, char **args) { return hall_run(n, args); }

typedef struct {
    eng_runtime_t *rt;
    unsigned port;
} test_room;
static int SDLCALL run_room(void *data)
{
    test_room *room = data;
    return hall_serve(room->rt, room->port, 1798066800);
}

static void test_engine_loopback(eng_runtime_t *rt)
{
    app.rt = rt;
    eng_net_peer_t *server = eng_net_host(ENG_NET_LOOPBACK, NULL, 0);
    app.peer = eng_net_create(ENG_NET_LOOPBACK, 0);
    assert(server && app.peer && eng_net_connect_loopback(app.peer, server));
    strcpy(app.hello, "HELLO3 lantern-2 friends");
    app.join_deadline = SDL_GetTicks() + 8000;
    network();
    eng_net_event_t e;
    char data[128] = {0};
    assert(eng_net_poll_event(server, &e, data, sizeof(data)) && e.type == ENG_NET_EVT_CONNECT);
    assert(eng_net_poll_event(server, &e, data, sizeof(data)) && e.type == ENG_NET_EVT_MESSAGE);
    assert(e.chan == ENG_CHAN_RELIABLE && e.len == strlen(app.hello) && !memcmp(data, app.hello, e.len));
    assert(eng_net_send_to(server, e.client_id, ENG_CHAN_RELIABLE, "WELCOME 1", 9));
    network();
    assert(!app.join_deadline);
    eng_net_destroy(server);
    network();
    assert(!app.peer && hall_eval(rt, "return game.state.connection", data, sizeof(data)) &&
           strstr(data, "Disconnected"));
    app.peer = eng_net_create(ENG_NET_LOOPBACK, 0);
    app.join_deadline = 1;
    network();
    assert(!app.peer && hall_eval(rt, "return game.state.connection", data, sizeof(data)) &&
           strstr(data, "timed out"));
}

static void test_service(eng_runtime_t *server_rt, eng_runtime_t *client_rt)
{
    test_room room = {server_rt, 22000u + (unsigned)(SDL_GetPerformanceCounter() % 24000u)};
    SDL_Thread *thread = SDL_CreateThread(run_room, "room-unit", &room);
    assert(thread);
    SDL_Delay(80);
    char url[64];
    snprintf(url, sizeof(url), "ws://127.0.0.1:%u", room.port);
    app.rt = client_rt;
    app.peer = NULL;
    assert(hall_connect(url, "ctest"));
    char state[64] = {0};
    for (int i = 0; i < 200 && strcmp(state, "Live room"); i++) {
        network();
        SDL_Delay(5);
        hall_eval(client_rt, "return game.state.connection", state, sizeof(state));
    }
    assert(!strcmp(state, "Live room"));
    eng_net_peer_t *original_socket = app.peer;
    assert(hall_connect(url, "ctest") && app.peer == original_socket);
    hall_eval(client_rt, "game.state.outbox={'BELL','P 0 17 0'}", NULL, 0);
    for (int i = 0; i < 24; i++) {
        network();
        SDL_Delay(5);
    }
    assert(hall_connect("", "ctest"));
    SDL_Delay(30);
    assert(hall_eval(client_rt, "old_revision=Hall.version; Hall.version='old-protocol'", NULL, 0));
    assert(hall_connect(url, "ctest"));
    for (int i = 0; i < 200 && app.peer; i++) {
        network();
        SDL_Delay(5);
    }
    assert(!app.peer);
    assert(hall_eval(client_rt, "Hall.version=old_revision", NULL, 0));
    assert(hall_connect(url, "ctest"));
    network();
    raise(SIGINT);
    int status;
    SDL_WaitThread(thread, &status);
    assert(status == 0);
    for (int i = 0; i < 150 && app.peer; i++) {
        network();
        SDL_Delay(5);
    }
    if (app.peer) {
        eng_net_destroy(app.peer);
        app.peer = NULL;
    }
}

int main(int argc, char **argv)
{
    assert(argc == 5);
    hall_test_tls(argv[3], (Uint16)strtoul(argv[4], NULL, 10));
    char *root = argv[1], *tmp = argv[2];
    SDL_CreateDirectory(tmp);
    char engine_dir[1200], game_dir[1200], fixture[1200], catalog_dir[1200], catalog[1250];
    snprintf(engine_dir, sizeof(engine_dir), "%s/engine", root);
    snprintf(game_dir, sizeof(game_dir), "%s/games/kalender2026", root);
    snprintf(fixture, sizeof(fixture), "%s/tests/fixture", root);
    snprintf(catalog_dir, sizeof(catalog_dir), "%s/missions", tmp);
    snprintf(catalog, sizeof(catalog), "%s/catalog.json", catalog_dir);
    SDL_CreateDirectory(catalog_dir);
    SDL_RemovePath(catalog);
    char *bad[] = {"hall", "--bad"}, *port[] = {"hall", "--port"}, *clock[] = {"hall", "--test-clock", "7"};
    assert(run(2, bad) == 2 && run(2, port) == 2 && run(3, clock) == 2);
    char *cli[] = {"hall",     "--headless", "--root",         root,     "--fixture", fixture,
                   "--doctor", "--test",     "tests/hall.lua", "--save", tmp};
    assert(run(11, cli) == 0);
    char *client[] = {"hall",   "--root", root,         "--headless", "--frames", "1",
                      "--room", "cli",    "--endpoint", "",           "--save",   tmp};
    assert(run(12, client) == 0);
    client[5] = "3";
    client[9] = "ws://127.0.0.1:1";
    assert(run(12, client) == 0);
    char *absent[] = {"hall", "--root", tmp, "--serve"};
    assert(run(4, absent) == 1);
    char *netfail[] = {"hall",     "--root", root, "--headless", "--ca", "/missing-calendar-ca.pem",
                       "--frames", "1"};
    assert(run(8, netfail) == 1);

    eng_runtime_cfg_t cfg = eng_runtime_default_cfg();
    cfg.repo_root = engine_dir;
    cfg.game_dir = game_dir;
    cfg.headless = true;
    eng_runtime_t *rt = eng_runtime_create(&cfg);
    assert(rt);
    hall_options opts = {.root = root, .headless = true, .fixture = fixture, .save = tmp};
    assert(hall_load(rt, &opts));
    char output[128];
    assert(hall_string(output, sizeof(output), "\"\\\n\001z", 5));
    assert(!strcmp(output, "\"\\034\\092\\010\\001z\""));
    assert(!hall_string(output, 1, "", 0) && !hall_string(output, 3, "x", 1));
    assert(!hall_eval(rt, "error('expected unit test error')", output, sizeof(output)));
    assert(hall_eval(rt, "return Hall.due(1796079600)", output, sizeof(output)) && !strcmp(output, "1"));

    hall_settings s = {0}, retrieved = {0};
    assert(!hall_valid_address(NULL, "r") && !hall_valid_address("ws://a", "two words"));
    assert(hall_valid_address("", "friends") && !hall_valid_address("https://a", "r"));
    assert(hall_valid_address("ws://a", "r") && hall_valid_address("wss://a", "r"));
    assert(!hall_valid_address("wss://", "r") && !hall_valid_address("ws://a b", "r"));
    hall_settings_text(&s, "wss://one \n");
    hall_settings_erase(&s);
    s.field = 1;
    hall_settings_erase(&s);
    hall_settings_text(&s, "family!");
    hall_settings_erase(&s);
    assert(!strcmp(s.endpoint, "wss://on") && !strcmp(s.room, "family"));
    hall_settings_save(&s, rt);
    hall_settings_read(&retrieved, rt, &opts);
    assert(!strcmp(s.endpoint, retrieved.endpoint) && !strcmp(s.room, retrieved.room));
    opts.endpoint = "";
    opts.room = "override";
    hall_settings_read(&retrieved, rt, &opts);
    assert(!*retrieved.endpoint && !strcmp(retrieved.room, "override"));

    memset(&app, 0, sizeof(app));
    app.rt = rt;
    app.ui = eng_ui_create();
    app.audio = eng_audio_create(true);
    hall_mix_load(&app.mix, rt, app.audio);
    assert(app.mix.count >= 24 && app.mix.clips[0].seconds > 0.03f);
    assert(hall_tune(3, 60) == 60 && eng_audio_get_bus_gain(app.audio, ENG_BUS_SFX) > .59f);
    assert(hall_tune(3, 100) == 100);
    hall_device(1, 1);
    hall_device(0, 0);
    key(SDL_SCANCODE_F3, 0);
    assert(app.preferences);
    frame();
    key(SDL_SCANCODE_LEFT, 0);
    assert(hall_tune(1, -1) == 90);
    key(SDL_SCANCODE_RIGHT, 0);
    key(SDL_SCANCODE_UP, 0);
    key(SDL_SCANCODE_RETURN, 0);
    assert(hall_tune(8, -1) == 1);
    key(SDL_SCANCODE_RETURN, 0);
    key(SDL_SCANCODE_DOWN, 0);
    key(SDL_SCANCODE_TAB, 0);
    key(SDL_SCANCODE_ESCAPE, 0);
    assert(!app.preferences && hall_tune(1, -1) == 100);
    assert(hall_eval(rt,
                     "local f=game.state.feedback; f.mark='ticks';f.markUntil=99;f.slow=true;f.tallyUntil=99",
                     NULL, 0));
    eng_ui_begin_frame(app.ui, 640, 480, 0, 0, false, 0);
    hall_feedback_overlay(rt, app.ui, 640, 480);
    eng_ui_render(app.ui);
    assert(hall_eval(rt, "game.state.feedback.mark='finish'", NULL, 0));
    eng_ui_begin_frame(app.ui, 960, 540, 0, 0, false, 0);
    hall_feedback_overlay(rt, app.ui, 960, 540);
    eng_ui_render(app.ui);
    hall_settings_text(&app.settings, "ws://127.0.0.1:1");
    hall_action("up", 1);
    hall_look(1, 2);
    hall_choose(0);
    hall_choose(2);
    hall_choose(9);
    hall_menu(1);
    hall_menu(0);
    hall_resize(640, 480);
    hall_lock(1);
    hall_lock(0);
    assert(!hall_connect("bad", "r") && hall_connect("", "r"));
    hall_connect("ws://127.0.0.1:1", "r");
    frame();
    hall_connect("", "r");
    assert(hall_eval(
        rt, "local g=game.state;host_sound();for i=1,8 do Feedback.sound(g,'gear',.5,1,1,g.x,1,g.z) end",
        NULL, 0));
    audio_frame(1);
    assert(app.mix.played >= 6 && app.mix.dropped >= 2);
    assert(hall_eval(rt,
                     "for i=1,3 do Feedback.sound(game.state,'bell',.6,1,3,0,1,0,18) end; "
                     "Feedback.sound(game.state,'missing',1,1,2)",
                     NULL, 0));
    audio_frame(.001f);
    assert(hall_mix_stat(0) == 8 && hall_mix_stat(1) >= 9 && hall_mix_stat(2) >= 2);
    assert(hall_eval(rt, "orig_sound=host_sound;host_sound=function() return 'broken' end", NULL, 0));
    audio_frame(.001f);
    assert(hall_eval(rt, "host_sound=orig_sound", NULL, 0));
    assert(hall_pulse() == 0);
    key(SDL_SCANCODE_F2, 0);
    assert(app.settings.open);
    frame();
    key(SDL_SCANCODE_TAB, 0);
    assert(app.settings.field);
    SDL_Event input = {0};
    input.type = SDL_EVENT_TEXT_INPUT;
    input.text.text = "room";
    settings_event(NULL, &input);
    key(SDL_SCANCODE_BACKSPACE, 0);
    key(SDL_SCANCODE_V, SDL_KMOD_CTRL);
    key(SDL_SCANCODE_A, 0);
    snprintf(app.settings.room, sizeof(app.settings.room), "unit");
    app.settings.endpoint[0] = 0;
    key(SDL_SCANCODE_RETURN, 0);
    frame();
    assert(!app.settings.open);
    hall_action("up", 0);
    frame();
    key(SDL_SCANCODE_F2, 0);
    key(SDL_SCANCODE_F2, 0);
    hall_pack_ready(0, 0);
    hall_pack_ready(1, 0);
    hall_pack_ready(1, 1);
    float eyes[64] = {0};
    int views[8] = {0, 0, 320, 480, 320, 0, 320, 480};
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 4; j++)
            eyes[i * 16 + j * 5] = 1;
    float aim[14] = {0, 1.55f, 0, 0, 0, -1, 0, 0, 30, 0, 1};
    hall_xr_frame(0, eyes, views, aim);
    assert(eng_xr_is_active(eng_runtime_xr(rt)));
    hall_xr_end();
    assert(!eng_xr_is_active(eng_runtime_xr(rt)));
    assert(hall_eval(rt, "unit_update=update; update=function() error('unit update failure') end", NULL, 0));
    frame();
    assert(app.failed);
    app.failed = false;
    assert(hall_eval(rt, "update=unit_update; unit_draw=draw; draw=function() error('unit draw failure') end",
                     NULL, 0));
    frame();
    assert(app.failed);
    app.failed = false;
    assert(hall_eval(rt, "draw=unit_draw", NULL, 0));
    eng_audio_destroy(app.audio);
    eng_ui_destroy(app.ui);
    eng_runtime_t *server_rt = eng_runtime_create(&cfg);
    opts.serve = true;
    assert(server_rt && hall_load(server_rt, &opts));
    test_engine_loopback(rt);
    test_service(server_rt, rt);
    eng_runtime_destroy(server_rt);
    eng_runtime_destroy(rt);

    rt = eng_runtime_create(&cfg);
    opts.fixture = tmp;
    opts.serve = true;
    const char *invalid[] = {
        "{}", "{\"revision\":\"bad'\",\"missions\":[]}", "{\"revision\":\"r\",\"missions\":[{\"day\":25}]}",
        "{\"revision\":\"r\",\"missions\":[{\"day\":1,\"script\":\"missions/../out.lua\"}]}"};
    for (size_t i = 0; i < sizeof(invalid) / sizeof(*invalid); i++) {
        assert(SDL_SaveFile(catalog, invalid[i], strlen(invalid[i])));
        assert(!hall_load(rt, &opts));
    }
    SDL_RemovePath(catalog);
    assert(hall_load(rt, &opts));
    const char *missing =
        "{\"revision\":\"r\",\"missions\":[{\"day\":1,\"script\":\"missions/missing.lua\"}]}";
    assert(SDL_SaveFile(catalog, missing, strlen(missing)) && hall_load(rt, &opts));
    assert(hall_eval(rt, "return type(MissionPacks[1])", output, sizeof(output)) && !strcmp(output, "nil"));
    SDL_RemovePath(catalog);
    eng_runtime_destroy(rt);
    puts("Host C units passed.");
    return 0;
}
