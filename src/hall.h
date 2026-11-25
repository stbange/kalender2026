#ifndef HALL_H
#define HALL_H
#include <bq_websocket_platform.h>
#include <engine/engine.h>
#include <stdint.h>
#include <time.h>

typedef struct {
    const char *root, *game, *room, *endpoint, *test, *fixture, *save, *ca;
    bool headless, doctor, serve;
    unsigned port, frames;
    time_t fixture_clock;
} hall_options;
int hall_run(int argc, char **argv);

bool hall_eval(eng_runtime_t *rt, const char *code, char *result, size_t cap);
bool hall_string(char *dst, size_t cap, const char *data, size_t size);
bool hall_load(eng_runtime_t *rt, const hall_options *opts);
void hall_utc(eng_runtime_t *rt, time_t utc);
int hall_client(eng_runtime_t *rt, const hall_options *opts);
int hall_serve(eng_runtime_t *rt, unsigned port, time_t fixture_clock);
void hall_feedback_overlay(eng_runtime_t *rt, eng_ui_t *ui, int width, int height);
#endif
