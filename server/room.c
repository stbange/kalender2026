#include "hall.h"
#include <SDL3/SDL_timer.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static volatile sig_atomic_t running = 1;
static void stop(int sig)
{
    (void)sig;
    running = 0;
}

int hall_serve(eng_runtime_t *rt, unsigned port, time_t fixture_clock)
{
    enum { CAPACITY = 48 };
    bqws_socket *peers[CAPACITY] = {0};
    bqws_pt_listen_opts listen = {0};
    listen.port = (uint16_t)port;
    bqws_pt_server *server = bqws_pt_listen(&listen);
    if (!server) {
        fprintf(stderr, "Could not listen on port %u\n", port);
        return 1;
    }
    running = 1;
    signal(SIGINT, stop);
    signal(SIGTERM, stop);
    printf("Lantern room listening on %u\n", port);
    fflush(stdout);
    uint64_t last = SDL_GetTicks(), next_snapshot = 0;
    while (running) {
        bqws_opts limits = {0};
        limits.limits.max_recv_msg_size = 512;
        limits.limits.max_recv_queue_messages = 32;
        bqws_socket *incoming = bqws_pt_accept(server, &limits, NULL);
        if (incoming) {
            size_t j = 0;
            while (j < CAPACITY && peers[j])
                j++;
            if (j < CAPACITY) {
                bqws_server_accept(incoming, NULL);
                peers[j] = incoming;
            } else
                bqws_free_socket(incoming);
        }
        uint64_t now = SDL_GetTicks();
        bool broadcast = now >= next_snapshot;
        if (broadcast)
            next_snapshot = now + 65;
        char code[2400], reply[24576];
        time_t utc = fixture_clock ? fixture_clock : time(NULL);
        snprintf(code, sizeof(code), "Service.step(%.5f,%lld)", (now - last) / 1000.0, (long long)utc);
        hall_eval(rt, code, NULL, 0);
        last = now;
        for (size_t i = 0; i < CAPACITY; i++) {
            bqws_socket *ws = peers[i];
            if (!ws)
                continue;
            bqws_update(ws);
            bqws_msg *msg;
            while ((msg = bqws_recv(ws))) {
                char literal[2120];
                if (msg->type == BQWS_MSG_TEXT &&
                    hall_string(literal, sizeof(literal), msg->data, msg->size)) {
                    snprintf(code, sizeof(code), "return Service.receive(%u,%s,%lld)", (unsigned)i, literal,
                             (long long)utc);
                    if (hall_eval(rt, code, reply, sizeof(reply)) && *reply)
                        bqws_send_text(ws, reply);
                }
                bqws_free_msg(msg);
            }
            if (bqws_is_closed(ws)) {
                snprintf(code, sizeof(code), "Service.disconnect(%u)", (unsigned)i);
                hall_eval(rt, code, NULL, 0);
                bqws_free_socket(ws);
                peers[i] = NULL;
            } else if (broadcast) {
                snprintf(code, sizeof(code), "return Service.snapshot(%u)", (unsigned)i);
                if (hall_eval(rt, code, reply, sizeof(reply)) && *reply)
                    bqws_send_text(ws, reply);
            }
        }
        SDL_Delay(5);
    }
    for (size_t i = 0; i < CAPACITY; i++)
        if (peers[i])
            bqws_free_socket(peers[i]);
    bqws_pt_free_server(server);
    return 0;
}
