#ifndef ENG_NET_TLS_H
#define ENG_NET_TLS_H

#include <SDL3_net/SDL_net.h>

typedef struct eng_net_tls_s eng_net_tls_t;
eng_net_tls_t *eng_net_tls_open(NET_StreamSocket *socket, const char *host, const char *ca_file);
NET_Status eng_net_tls_handshake(eng_net_tls_t *tls);
int eng_net_tls_read(eng_net_tls_t *tls, void *data, int len);
bool eng_net_tls_write(eng_net_tls_t *tls, const void *data, int len);
void eng_net_tls_free(eng_net_tls_t *tls);
#endif
