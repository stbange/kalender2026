#include "hall.h"
#include <SDL3/SDL.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char *next_arg(int *i, int argc, char **argv) { return *i + 1 < argc ? argv[++*i] : ""; }

int hall_run(int argc, char **argv)
{
    hall_options o = {0};
#if defined(SIGPIPE) && !defined(__EMSCRIPTEN__)
    /* A departing friend may close a socket while the next snapshot is in flight. */
    signal(SIGPIPE, SIG_IGN);
#endif
    o.root = SDL_GetBasePath();
    o.port = 8787;
#ifdef __EMSCRIPTEN__
    o.root = "/";
    o.save = "/profile";
#endif
    for (int i = 1; i < argc; i++) {
        const char *a = argv[i];
        if (!strcmp(a, "--serve"))
            o.serve = o.headless = true;
        else if (!strcmp(a, "--headless"))
            o.headless = true;
        else if (!strcmp(a, "--doctor"))
            o.doctor = true;
        else if (!strcmp(a, "--root"))
            o.root = next_arg(&i, argc, argv);
        else if (!strcmp(a, "--save"))
            o.save = next_arg(&i, argc, argv);
        else if (!strcmp(a, "--endpoint"))
            o.endpoint = next_arg(&i, argc, argv);
        else if (!strcmp(a, "--room"))
            o.room = next_arg(&i, argc, argv);
        else if (!strcmp(a, "--fixture"))
            o.fixture = next_arg(&i, argc, argv);
        else if (!strcmp(a, "--test-clock"))
            o.fixture_clock = (time_t)strtoll(next_arg(&i, argc, argv), NULL, 10);
        else if (!strcmp(a, "--ca"))
            o.ca = next_arg(&i, argc, argv);
        else if (!strcmp(a, "--test"))
            o.test = next_arg(&i, argc, argv);
        else if (!strcmp(a, "--frames"))
            o.frames = (unsigned)strtoul(next_arg(&i, argc, argv), NULL, 10);
        else if (!strcmp(a, "--port"))
            o.port = (unsigned)strtoul(next_arg(&i, argc, argv), NULL, 10);
        else {
            fprintf(stderr, "Unknown option %s\n", a);
            return 2;
        }
    }
    if (!o.root || !o.port || o.port > 65535 || (o.fixture_clock && !o.fixture))
        return 2;
    char engine[1024], game[1024], ca[1024];
    snprintf(engine, sizeof(engine), "%s/engine", o.root);
    snprintf(game, sizeof(game), "%s/games/kalender2026", o.root);
    o.game = game;
    char *prefs = NULL;
    if (!o.save && !o.serve) {
        prefs = SDL_GetPrefPath("Kalender", "LanternHall");
        o.save = prefs;
    }
    eng_runtime_cfg_t cfg = eng_runtime_default_cfg();
    cfg.repo_root = engine;
    cfg.game_dir = game;
    cfg.headless = o.headless;
    cfg.width = 1280;
    cfg.height = 720;
    eng_runtime_t *rt = eng_runtime_create(&cfg);
    if (!rt || !hall_load(rt, &o)) {
        eng_runtime_destroy(rt);
        SDL_free(prefs);
        return 1;
    }
    bqws_pt_init_opts net = {0};
#ifndef __EMSCRIPTEN__
    snprintf(ca, sizeof(ca), "%s/cacert.pem", o.root);
    if (!o.ca && SDL_GetPathInfo(ca, NULL))
        o.ca = ca;
#if defined(__linux__)
    if (!o.ca)
        o.ca = "/etc/ssl/certs/ca-certificates.crt";
#endif
    net.ca_filename = o.ca;
#endif
    if (!bqws_pt_init(&net)) {
        fprintf(stderr, "Could not initialize networking or CA file\n");
        eng_runtime_destroy(rt);
        SDL_free(prefs);
        return 1;
    }
    int status = 0;
    if (o.doctor) {
        eng_doctor_report_t report;
        status = eng_doctor_audit(rt, &report) ? 0 : 1;
        fputs(report.summary, stdout);
    }
    if (!status && o.test) {
        char error[1024] = {0};
        status = eng_runtime_run_playtest(rt, o.test, 4800, error, sizeof(error)) ? 0 : 1;
        printf("Playtest %s %s\n", status ? "FAILED" : "passed", error);
    } else if (!status && !o.doctor) {
#ifndef __EMSCRIPTEN__
        if (o.serve)
            status = hall_serve(rt, o.port, o.fixture_clock);
        else
#endif
            status = hall_client(rt, &o);
    }
    bqws_pt_shutdown();
    eng_runtime_destroy(rt);
    SDL_free(prefs);
    return status;
}
