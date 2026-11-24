#include "settings.h"
#include <SDL3/SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

bool hall_valid_address(const char *url,const char *room)
{
    if(!url || !room || !*room || strlen(room)>32 || strlen(url)>=384) return false;
    if(strspn(room,"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")!=strlen(room)) return false;
    if(!*url) return true;
    size_t prefix=!strncmp(url,"wss://",6)?6:(!strncmp(url,"ws://",5)?5:0);
    return prefix && url[prefix] && !strpbrk(url," \t\r\n");
}
void hall_settings_text(hall_settings *s,const char *text)
{
    char *dst=s->field?s->room:s->endpoint;
    size_t len=strlen(dst),cap=s->field?sizeof(s->room):sizeof(s->endpoint);
    for(const unsigned char *p=(const unsigned char *)text;*p && len+1<cap;p++)
        if(*p>32 && *p<127) dst[len++]=(char)*p;
    dst[len]=0;
}
void hall_settings_erase(hall_settings *s)
{
    char *dst=s->field?s->room:s->endpoint;
    size_t n=strlen(dst);
    if(n) dst[n-1]=0;
}
void hall_settings_read(hall_settings *s,eng_runtime_t *rt,const hall_options *opts)
{
    char path[1200]; size_t len=0;
    snprintf(path,sizeof(path),"%s/server.json",opts->root);
    char *json=SDL_LoadFile(path,NULL);
    snprintf(s->room,sizeof(s->room),"friends");
    if(json) {
        eng_arena_t arena; eng_arena_init(&arena,8192);
        eng_json_val_t *doc=eng_json_parse(&arena,json,NULL,0);
        if(doc) {
            const char *endpoint=eng_json_get_str(doc,"endpoint","");
            const char *room=eng_json_get_str(doc,"room","friends");
            if(hall_valid_address(endpoint,room)) {
                snprintf(s->endpoint,sizeof(s->endpoint),"%s",endpoint);
                snprintf(s->room,sizeof(s->room),"%s",room);
            }
        }
        eng_arena_destroy(&arena); SDL_free(json);
    }
    char *stored=eng_save_read(eng_runtime_vfs(rt),"connection",1,&len);
    if(stored && len && stored[len-1]==0) {
        char *room=strchr(stored,'\n');
        if(room) {
            *room++=0;
            if(hall_valid_address(stored,room)) {
                snprintf(s->endpoint,sizeof(s->endpoint),"%s",stored);
                snprintf(s->room,sizeof(s->room),"%s",room);
            }
        }
    }
    free(stored);
    if(opts->endpoint) snprintf(s->endpoint,sizeof(s->endpoint),"%s",opts->endpoint);
    if(opts->room) snprintf(s->room,sizeof(s->room),"%s",opts->room);
}
void hall_settings_save(const hall_settings *s,eng_runtime_t *rt)
{
    char data[450];
    int n=snprintf(data,sizeof(data),"%s\n%s",s->endpoint,s->room);
    eng_save_write(eng_runtime_vfs(rt),"connection",1,data,(size_t)n+1);
}
