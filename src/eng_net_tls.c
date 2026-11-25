/* TLS for the engine's SDL3_net byte stream. WebSocket framing stays in eng_net.c. */
#include "eng_net_tls.h"
#include <openssl/err.h>
#include <openssl/ssl.h>
#include <openssl/x509v3.h>
#include <stdlib.h>

struct eng_net_tls_s {
    SSL *ssl;
    BIO_METHOD *method;
};

static int stream_read(BIO *bio, char *data, int len)
{
    BIO_clear_retry_flags(bio);
    int n = NET_ReadFromStreamSocket(BIO_get_data(bio), data, len);
    if (n == 0) {
        BIO_set_retry_read(bio);
        return -1;
    }
    return n;
}

static int stream_write(BIO *bio, const char *data, int len)
{
    BIO_clear_retry_flags(bio);
    return NET_WriteToStreamSocket(BIO_get_data(bio), data, len) ? len : -1;
}

static long stream_ctrl(BIO *bio, int cmd, long arg, void *ptr)
{
    (void)bio;
    (void)arg;
    (void)ptr;
    return cmd == BIO_CTRL_FLUSH;
}

void eng_net_tls_free(eng_net_tls_t *tls)
{
    if (!tls)
        return;
    SSL_free(tls->ssl);
    BIO_meth_free(tls->method);
    free(tls);
}

eng_net_tls_t *eng_net_tls_open(NET_StreamSocket *socket, const char *host, const char *ca_file)
{
    eng_net_tls_t *tls = calloc(1, sizeof(*tls));
    SSL_CTX *ctx = SSL_CTX_new(TLS_client_method());
    if (!ctx || !tls)
        goto fail;

    SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, NULL);
    if (!SSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION))
        goto fail;
    if (!(ca_file && *ca_file ? SSL_CTX_load_verify_locations(ctx, ca_file, NULL)
                              : SSL_CTX_set_default_verify_paths(ctx)))
        goto fail;
    SSL_CTX_set_options(ctx, SSL_OP_NO_RENEGOTIATION);
    tls->ssl = SSL_new(ctx);
    if (!tls->ssl)
        goto fail;

    /* RFC 6125 distinguishes IP subjectAltNames from DNS names and SNI. */
    ASN1_OCTET_STRING *ip = a2i_IPADDRESS(host);
    if (ip) {
        int ok = X509_VERIFY_PARAM_set1_ip(SSL_get0_param(tls->ssl), ASN1_STRING_get0_data(ip),
                                           (size_t)ASN1_STRING_length(ip));
        ASN1_OCTET_STRING_free(ip);
        if (!ok)
            goto fail;
    } else if (!SSL_set_tlsext_host_name(tls->ssl, host) || !SSL_set1_host(tls->ssl, host)) {
        goto fail;
    }

    tls->method = BIO_meth_new(BIO_TYPE_SOURCE_SINK, "SDL3_net stream");
    if (!tls->method || !BIO_meth_set_read(tls->method, stream_read) ||
        !BIO_meth_set_write(tls->method, stream_write) || !BIO_meth_set_ctrl(tls->method, stream_ctrl))
        goto fail;
    BIO *bio = BIO_new(tls->method);
    if (!bio)
        goto fail;
    BIO_set_data(bio, socket);
    BIO_set_init(bio, 1);
    SSL_set_bio(tls->ssl, bio, bio);
    SSL_set_connect_state(tls->ssl);
    SSL_CTX_free(ctx);
    return tls;
fail:
    SSL_CTX_free(ctx);
    eng_net_tls_free(tls);
    return NULL;
}

NET_Status eng_net_tls_handshake(eng_net_tls_t *tls)
{
    ERR_clear_error();
    int rc = SSL_connect(tls->ssl);
    if (rc == 1)
        return NET_SUCCESS;
    int e = SSL_get_error(tls->ssl, rc);
    return e == SSL_ERROR_WANT_READ || e == SSL_ERROR_WANT_WRITE ? NET_WAITING : NET_FAILURE;
}

int eng_net_tls_read(eng_net_tls_t *tls, void *data, int len)
{
    ERR_clear_error();
    int n = SSL_read(tls->ssl, data, len);
    if (n > 0)
        return n;
    int e = SSL_get_error(tls->ssl, n);
    return e == SSL_ERROR_WANT_READ || e == SSL_ERROR_WANT_WRITE ? 0 : -1;
}

bool eng_net_tls_write(eng_net_tls_t *tls, const void *data, int len)
{
    /* SDL_net queues complete writes. With renegotiation disabled each TLS record can drain at once. */
    ERR_clear_error();
    return SSL_write(tls->ssl, data, len) == len;
}
