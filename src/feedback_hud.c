#include "hall.h"
#include <stdio.h>
#define NK_INCLUDE_FIXED_TYPES
#define NK_INCLUDE_STANDARD_IO
#define NK_INCLUDE_STANDARD_VARARGS
#define NK_INCLUDE_DEFAULT_ALLOCATOR
#define NK_INCLUDE_VERTEX_BUFFER_OUTPUT
#define NK_INCLUDE_FONT_BAKING
#define NK_INCLUDE_DEFAULT_FONT
#include "nuklear.h"

/* Screen-space marks only. The Lua world submits the equivalent cues to either eye in XR. */
void hall_feedback_overlay(eng_runtime_t *rt, eng_ui_t *ui, int width, int height)
{
    char values[96];
    int mark = 0, contrast = 0, slowed = 0, tally = 0, bells = 0;
    hall_eval(rt, "return host_flat_marks()", values, sizeof(values));
    if (sscanf(values, "%d %d %d %d %d", &mark, &contrast, &slowed, &tally, &bells) != 5)
        return;
    struct nk_context *ctx = eng_ui_nk(ui);
    struct nk_color ink = nk_rgb(22, 42, 48), cream = nk_rgb(240, 239, 209), gold = nk_rgb(255, 205, 129);
    nk_style_push_style_item(ctx, &ctx->style.window.fixed_background, nk_style_item_hide());
    if (nk_begin(ctx, "hall marks", nk_rect(0, 0, (float)width, (float)height),
                 NK_WINDOW_NO_INPUT | NK_WINDOW_NO_SCROLLBAR | NK_WINDOW_BACKGROUND)) {
        struct nk_command_buffer *c = nk_window_get_canvas(ctx);
        float cx = width * .5f, cy = height * .5f, scale = height / 540.f;
        if (scale < .75f)
            scale = .75f;
        for (int pass = 0; pass < 2; pass++) {
            float thick = scale * (pass ? 1.5f : (contrast ? 5.5f : 3.5f));
            struct nk_color color = pass ? cream : ink;
            if (mark == 2) {
                float s = 10 * scale;
                float poly[] = {cx, cy - s, cx + s, cy, cx, cy + s, cx - s, cy};
                nk_stroke_polygon(c, poly, 4, thick, color);
            } else {
                for (int i = 0; i < 4; i++) {
                    float x = (i & 1) ? 1 : -1, y = (i & 2) ? 1 : -1;
                    if (mark == 1)
                        nk_stroke_line(c, cx + x * 5 * scale, cy + y * 5 * scale, cx + x * 11 * scale,
                                       cy + y * 11 * scale, thick, color);
                }
            }
            nk_stroke_line(c, cx - 3 * scale, cy, cx + 3 * scale, cy, pass ? scale : 2 * scale, color);
            nk_stroke_line(c, cx, cy - 3 * scale, cx, cy + 3 * scale, pass ? scale : 2 * scale, color);
        }
        if (slowed) {
            float x = 14 * scale, y = 135 * scale;
            nk_fill_rect(c, nk_rect(x, y, 8 * scale, 12 * scale), 0, ink);
            nk_fill_rect(c, nk_rect(x, y + 8 * scale, 16 * scale, 6 * scale), 0, cream);
            nk_fill_rect(c, nk_rect(x, y, 7 * scale, 10 * scale), 0, cream);
        }
        if (tally) {
            char count[40];
            int n = snprintf(count, sizeof(count), "%d bells", bells);
            struct nk_rect box = nk_rect(width - 123 * scale, 18 * scale, 105 * scale, 25 * scale);
            nk_fill_rect(c, box, 2, ink);
            nk_stroke_rect(c, box, 2, 2 * scale, gold);
            nk_draw_text(c, box, count, n, ctx->style.font, ink, gold);
        }
    }
    nk_end(ctx);
    nk_style_pop_style_item(ctx);
}
