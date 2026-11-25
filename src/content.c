#include "hall.h"
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

bool hall_eval(eng_runtime_t *rt, const char *code, char *result, size_t cap)
{
    char scratch[512];
    if (!result) {
        result = scratch;
        cap = sizeof(scratch);
    }
    if (cap) result[0] = '\0';
    if (eng_runtime_exec_lua(rt, "calendar host", code, result, cap))
        return true;
    fprintf(stderr, "Lua: %s\n", result);
    return false;
}

/* Pass wire data as a Lua string literal. The public engine API accepts chunks. */
bool hall_string(char *dst, size_t cap, const char *data, size_t size)
{
    size_t used = 0;
    if (cap < 3)
        return false;
    dst[used++] = '"';
    for (size_t i = 0; i < size; i++) {
        unsigned ch = (unsigned char)data[i];
        if (used + 6 > cap)
            return false;
        if (ch < 32 || ch >= 127 || ch == '"' || ch == '\\') {
            used += (size_t)snprintf(dst + used, cap - used, "\\%03u", ch);
        } else
            dst[used++] = (char)ch;
    }
    dst[used++] = '"';
    dst[used] = 0;
    return true;
}

void hall_utc(eng_runtime_t *rt, time_t utc)
{
    char code[80];
    snprintf(code, sizeof(code), "HostUTC=%lld", (long long)utc);
    hall_eval(rt, code, NULL, 0);
}

static bool script(eng_runtime_t *rt, const char *path)
{
    char *source = eng_vfs_read_all(eng_runtime_vfs(rt), path, NULL);
    char error[512] = {0};
    bool ok = source && eng_runtime_exec_lua(rt, path, source, error, sizeof(error));
    if (!ok)
        fprintf(stderr, "Could not load %s: %s\n", path, error);
    free(source);
    return ok;
}

static bool mission_catalog(eng_runtime_t *rt)
{
    char *text = eng_vfs_read_all(eng_runtime_vfs(rt), "missions/catalog.json", NULL);
    if (!text)
        return false;
    eng_arena_t arena;
    char error[256] = {0}, code[200];
    eng_arena_init(&arena, 128 * 1024);
    eng_json_val_t *doc = eng_json_parse(&arena, text, error, sizeof(error));
    const eng_json_val_t *entries = doc ? eng_json_get(doc, "missions") : NULL;
    const char *rev = doc ? eng_json_get_str(doc, "revision", "") : "";
    bool ok = entries && entries->type == ENG_JSON_ARR && entries->u.arr.len <= 24 && *rev &&
              strlen(rev) <= 48 &&
              strspn(rev, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.") == strlen(rev);
    unsigned days = 0;
    if (ok) {
        snprintf(code, sizeof(code), "MissionPacks={} Hall.version='%s'", rev);
        ok = hall_eval(rt, code, NULL, 0);
    }
    for (size_t i = 0; ok && i < entries->u.arr.len; i++) {
        const eng_json_val_t *entry = entries->u.arr.items[i];
        double day = eng_json_get_num(entry, "day", 0);
        const char *path = eng_json_get_str(entry, "script", "");
        if (!(day >= 1 && day <= 24) || day != (int)day || days & (1u << ((int)day - 1)) ||
            strncmp(path, "missions/", 9) || strstr(path, "..") || strchr(path, '\\')) {
            ok = false;
            break;
        }
        snprintf(
            code, sizeof(code),
            "return tostring(type(MissionPacks[%d])=='table' and type(MissionPacks[%d].act)=='function')",
            (int)day, (int)day);
        if (!script(rt, path) || !hall_eval(rt, code, error, sizeof(error)) || strcmp(error, "true")) {
            snprintf(code, sizeof(code), "MissionPacks[%d]=nil", (int)day);
            hall_eval(rt, code, NULL, 0);
            fprintf(stderr, "Door %d is awaiting a working pack.\n", (int)day);
        }
        days |= 1u << ((int)day - 1);
    }
    if (!ok)
        fprintf(stderr, "Invalid mission catalog: %s\n", error);
    eng_arena_destroy(&arena);
    free(text);
    return ok;
}

bool hall_load(eng_runtime_t *rt, const hall_options *opts)
{
    if (opts->fixture)
        eng_vfs_mount(eng_runtime_vfs(rt), opts->fixture, 30, false);
    if (opts->save)
        eng_vfs_mount(eng_runtime_vfs(rt), opts->save, 40, true);
    hall_utc(rt, time(NULL));
    if (!script(rt, "scripts/rules.lua") || !script(rt, "scripts/network.lua") || !mission_catalog(rt))
        return false;
    if (opts->serve)
        return true;
    char error[512] = {0};
    if (script(rt, "scripts/feedback.lua") && script(rt, "scripts/visitors.lua") &&
        script(rt, "scripts/world.lua") && eng_runtime_boot_game(rt, error, sizeof(error)))
        return true;
    fprintf(stderr, "Hall boot failed: %s\n", error);
    return false;
}
