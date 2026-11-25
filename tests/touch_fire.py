"""Check mobile gestures against the camera and snowballs in the shipping WebGL game."""

import argparse
import shutil
import time
from pathlib import Path
from typing import NamedTuple

from playwright.sync_api import sync_playwright
from browser_smoke import open_game, website

# Expose observations after the ordinary simulation update. Use the game's actual throw sequence.
PROBE = """
local hud=host_hud
function host_hud()
    local g=game.state
    return hud()..string.format("|%.3f,%d,%.3f,%.3f,%.3f,%.3f",g.clock,g.seq,g.yaw,g.pitch,g.x,g.z)
end
"""
STATE = "hudText.split('|').at(-1).split(',').map(Number)"


class Frame(NamedTuple):
    clock: float
    throws: int
    yaw: float
    pitch: float
    x: float
    z: float


def enter(page, url):
    def observe(route):
        script = route.fetch()
        route.fulfill(response=script, body=script.text() + PROBE)

    page.route("**/games/kalender2026/scripts/main.lua", observe)
    open_game(page, url)
    page.locator("#enter").tap()
    page.wait_for_function(STATE + ".length===6")


def frame(page):
    return Frame(*page.evaluate(STATE))


def advance(page, seconds=0.40):
    page.wait_for_function("end=>(" + STATE + ")[0]>=end", arg=frame(page).clock + seconds)
    return frame(page)


def check_gestures(browser, url):
    context = browser.new_context(has_touch=True, is_mobile=True, viewport={"width": 390, "height": 700})
    page = context.new_page()
    enter(page, url)
    cdp = context.new_cdp_session(page)
    contacts = {}
    stamp = time.time()

    # Event timestamps separate real finger timing from the speed of the host's software GPU.
    def send(kind, points, ms):
        nonlocal stamp
        stamp += ms / 1000
        cdp.send("Input.dispatchTouchEvent", dict(type=kind, timestamp=stamp, touchPoints=list(points)))

    def down(finger, pos, ms=40):
        contacts[finger] = dict(id=finger, x=pos[0], y=pos[1])
        send("touchStart", contacts.values(), ms)

    def move(finger, pos):
        contacts[finger].update(x=pos[0], y=pos[1])
        send("touchMove", contacts.values(), 30)

    def up(finger, ms=40):
        send("touchEnd", [contacts.pop(finger)], ms)

    def tap(pos, gap=40, duration=45):
        down(1, pos, gap)
        up(1, duration)

    # This point used to be inside SDL's invisible virtual fire button.
    aim = (319, 421)
    away = (262, 387)
    assert page.evaluate("document.elementFromPoint(319,421)===canvas")
    initial = frame(page)
    down(1, aim)
    move(1, away)
    aimed = advance(page)
    assert aimed.throws == initial.throws, "Dragging the camera fired a snowball"
    assert aimed.yaw != initial.yaw and aimed.pitch != initial.pitch
    assert (aimed.x, aimed.z) == (initial.x, initial.z)
    move(1, aim)
    up(1)
    tap(aim)
    assert advance(page).throws == 0, "A drag that returned to its starting point armed a shot"

    tap(aim, gap=500)
    tap(aim, gap=500)
    tap(away)
    tap(aim, gap=500, duration=410)
    tap(aim)
    assert advance(page).throws == 0, "Distant, late or long taps armed a shot"

    down(1, aim, 500)
    down(4, away)
    up(4)
    up(1)
    tap(aim)
    assert advance(page).throws == 0, "Two simultaneous look fingers were counted as a double-tap"

    tap(aim, gap=500)
    tap((aim[0] + 5, aim[1] + 4), gap=160)
    assert advance(page).throws == 1, "A quick double-tap should fire once"
    assert advance(page).throws == 1, "Firing continued after the second tap was lifted"

    stick = page.locator("#stick").bounding_box()
    forward = (stick["x"] + stick["width"] * 0.5, stick["y"] + stick["height"] * 0.20)
    button = page.locator("#fire").bounding_box()
    fire = (button["x"] + button["width"] * 0.5, button["y"] + button["height"] * 0.5)

    before = frame(page)
    down(2, forward, 500)
    tap(aim)
    down(1, aim, 120)
    move(1, away)
    walking = advance(page, 0.81)
    assert walking.throws >= before.throws + 2 and walking.yaw != before.yaw
    assert (walking.x, walking.z) != (before.x, before.z), "Could not move, aim and fire together"
    down(3, fire)
    up(1)
    assert advance(page, 0.75).throws > walking.throws, (
        "Lifting the look finger stopped the held Fire button"
    )
    up(3)
    up(2)
    stopped = advance(page)
    assert advance(page).throws == stopped.throws

    down(3, fire, 500)
    pressed = advance(page, 0.19)
    assert pressed.throws > stopped.throws, "The Fire button did not fire on first press"
    tap(aim)
    down(1, aim)
    up(3)
    assert advance(page, 0.72).throws > pressed.throws, "Releasing Fire stopped a held double-tap"
    send("touchCancel", [], 40)
    contacts.clear()
    canceled = advance(page)
    assert advance(page).throws == canceled.throws
    down(1, aim, 500)
    send("touchCancel", [], 40)
    contacts.clear()
    tap(aim)
    assert advance(page).throws == canceled.throws, "A canceled touch armed the next tap"

    page.locator("#menu").tap()
    page.locator("#enter").tap()
    tap(aim)
    assert advance(page).throws == canceled.throws, "A tap before the menu was paired with a tap after it"
    common = (260, 155)
    tap(common, gap=500)
    page.set_viewport_size({"width": 700, "height": 390})
    page.wait_for_function("canvas.width === 700 && canvas.height === 390")
    tap(common)
    assert advance(page).throws == canceled.throws, "Rotation retained the pending first tap"
    context.close()
    print("First touches aim. Double-tap, hold-and-drag, three-finger play, release and cancel passed.")


def check_iphone_taps(browser, device, url):
    context = browser.new_context(**device)
    page = context.new_page()
    enter(page, url)
    x, y = page.viewport_size["width"] * 0.82, page.viewport_size["height"] * 0.62
    assert page.evaluate("([x,y])=>document.elementFromPoint(x,y)===canvas", [x, y])
    page.touchscreen.tap(x, y)
    assert advance(page, 0.5).throws == 0, "A single iPhone tap fired a snowball"
    page.touchscreen.tap(x, y)
    page.touchscreen.tap(x + 2, y + 2)
    assert advance(page).throws == 1, "The iPhone double-tap did not fire once"
    page.locator("#fire").tap()
    assert advance(page).throws == 2, "The iPhone Fire button did not fire immediately"
    context.close()
    print("iPhone WebKit single tap, double-tap and dedicated Fire passed.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--site", type=Path, required=True)
    args = parser.parse_args()
    with website(args.site.resolve()) as url, sync_playwright() as pw:
        with pw.chromium.launch(
            executable_path=shutil.which("chromium"),
            args=["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
        ) as browser:
            check_gestures(browser, url)
        with pw.webkit.launch() as browser:
            check_iphone_taps(browser, pw.devices["iPhone 13"], url)
