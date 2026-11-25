#include "hall.h"
#include <SDL3/SDL_timer.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>

static volatile sig_atomic_t running = 1;
static void stop(int sig)
{
    (void)sig;
    running = 0;
}

int hall_serve(eng_runtime_t *rt, unsigned port, time_t fixture_clock)
{
    eng_net_peer_t *server = eng_net_host(ENG_NET_WEBSOCKET, NULL, (uint16_t)port);
    if (!server) {
        fprintf(stderr, "Could not listen on port %u\n", port);
        return 1;
    }
    running = 1;
    signal(SIGINT, stop);
    signal(SIGTERM, stop);
    printf("Lantern room listening on %u\n", eng_net_bound_port(server));
    fflush(stdout);
    uint64_t last = SDL_GetTicks(), next_snapshot = 0;
    while (running) {
        uint64_t now = SDL_GetTicks();
        time_t utc = fixture_clock ? fixture_clock : time(NULL);
        char code[2400], reply[24576];
        snprintf(code, sizeof(code), "Service.step(%.5f,%lld)", (now - last) / 1000.0, (long long)utc);
        hall_eval(rt, code, NULL, 0);
        last = now;

        eng_net_event_t event;
        char command[513];
        while (eng_net_poll_event(server, &event, command, sizeof(command))) {
            if (event.type == ENG_NET_EVT_DISCONNECT) {
                snprintf(code, sizeof(code), "Service.disconnect(%u)", (unsigned)event.client_id);
                hall_eval(rt, code, NULL, 0);
            } else if (event.type == ENG_NET_EVT_MESSAGE && event.len < sizeof(command)) {
                char literal[2120];
                if (hall_string(literal, sizeof(literal), command, event.len)) {
                    snprintf(code, sizeof(code), "return Service.receive(%u,%s,%lld)",
                             (unsigned)event.client_id, literal, (long long)utc);
                    if (hall_eval(rt, code, reply, sizeof(reply)) && *reply)
                        eng_net_send_to(server, event.client_id, ENG_CHAN_RELIABLE, reply, strlen(reply));
                }
            }
        }
        if (now >= next_snapshot) {
            uint32_t ids[ENG_NET_MAX_CLIENTS];
            size_t count = eng_net_client_ids(server, ids, ENG_NET_MAX_CLIENTS);
            for (size_t i = 0; i < count; i++) {
                snprintf(code, sizeof(code), "return Service.snapshot(%u)", (unsigned)ids[i]);
                if (hall_eval(rt, code, reply, sizeof(reply)) && *reply)
                    eng_net_send_to(server, ids[i], ENG_CHAN_UNRELIABLE, reply, strlen(reply));
            }
            next_snapshot = now + 65;
        }
        SDL_Delay(5);
    }
    eng_net_destroy(server);
    return 0;
}
