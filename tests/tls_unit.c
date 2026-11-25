#ifdef NDEBUG
#undef NDEBUG
#endif
#include "eng_net_tls.h"
#include <SDL3/SDL.h>
#include <assert.h>
#include <string.h>

/* Exercise one encrypted SDL byte stream against the test harness's TLS echo peer. */
static void check_stream(NET_Address *address, Uint16 port, const char *name, const char *ca, bool trusted)
{
    NET_StreamSocket *socket = NET_CreateClient(address, port, 0);
    assert(socket && NET_WaitUntilConnected(socket, 3000) == NET_SUCCESS);
    eng_net_tls_t *tls = eng_net_tls_open(socket, name, ca);
    assert(tls);
    Uint64 deadline = SDL_GetTicks() + 3000;
    NET_Status status;
    while ((status = eng_net_tls_handshake(tls)) == NET_WAITING && SDL_GetTicks() < deadline)
        SDL_Delay(1);
    assert(status == (trusted ? NET_SUCCESS : NET_FAILURE));
    if (trusted) {
        char reply[4];
        assert(eng_net_tls_read(tls, reply, sizeof(reply)) == 0);
        assert(eng_net_tls_write(tls, "snow", 4));
        int received = 0;
        while (received < 4 && SDL_GetTicks() < deadline) {
            int count = eng_net_tls_read(tls, reply + received, 4 - received);
            assert(count >= 0);
            received += count;
            SDL_Delay(1);
        }
        assert(received == 4 && !memcmp(reply, "snow", 4));
    }
    eng_net_tls_free(tls);
    NET_DestroyStreamSocket(socket);
}

void hall_test_tls(const char *cert, Uint16 port)
{
    assert(NET_Init());
    NET_Address *addr = NET_ResolveHostname("127.0.0.1");
    assert(addr && NET_WaitUntilResolved(addr, 3000) == NET_SUCCESS);
    check_stream(addr, port, "localhost", cert, true);
    check_stream(addr, port, "127.0.0.1", cert, true);
    check_stream(addr, port, "wrong.invalid", cert, false);
    check_stream(addr, port, "localhost", NULL, false);
    assert(!eng_net_tls_open(NULL, "localhost", "no-such-calendar-certificate.pem"));
    eng_net_tls_free(NULL);
    NET_UnrefAddress(addr);
    NET_Quit();
}
