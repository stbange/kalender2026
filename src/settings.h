#ifndef HALL_SETTINGS_H
#define HALL_SETTINGS_H
#include "hall.h"
typedef struct { char endpoint[384],room[33]; int field; bool open,submit; } hall_settings;
bool hall_valid_address(const char *endpoint,const char *room);
void hall_settings_read(hall_settings *s,eng_runtime_t *rt,const hall_options *opts);
void hall_settings_save(const hall_settings *s,eng_runtime_t *rt);
void hall_settings_text(hall_settings *s,const char *text);
void hall_settings_erase(hall_settings *s);
#endif
