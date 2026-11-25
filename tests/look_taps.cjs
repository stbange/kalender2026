const assert = require("node:assert/strict");
const test = require("node:test");
const LookTaps = require("../web/look-taps.js");

function point(timeStamp, clientX = 100, clientY = 100) {
  return { timeStamp, clientX, clientY };
}

test("a nearby second contact fires on press and consumes the first tap", () => {
  const taps = new LookTaps();
  assert.equal(taps.down(point(100)), false);
  taps.move(point(160, 114));
  taps.up(point(350, 114));
  assert.equal(taps.down(point(670, 146)), true);
  taps.move(point(700, 180, 190));
  taps.up(point(740, 180, 190));
  assert.equal(taps.down(point(800, 180, 190)), false);
});

test("a slow, distant or long tap gives the player a new first contact", () => {
  for (const [up, next] of [
    [point(200), point(521)],
    [point(200), point(240, 124, 124)],
    [point(351), point(390)],
    [point(200, 115), point(210, 115)],
  ]) {
    const taps = new LookTaps();
    assert.equal(taps.down(point(100)), false);
    taps.up(up);
    assert.equal(taps.down(next), false);
    taps.up({ ...next, timeStamp: next.timeStamp + 50 });
    assert.equal(taps.down({ ...next, timeStamp: next.timeStamp + 140 }), true);
  }
});

test("returning to the start of a swipe does not arm the next press", () => {
  const taps = new LookTaps();
  taps.down(point(100));
  taps.move(point(130, 110, 111));
  taps.move(point(155));
  taps.up(point(185));
  assert.equal(taps.down(point(240)), false);
});

test("cancel clears both unfinished touches and completed first taps", () => {
  const taps = new LookTaps();
  taps.down(point(100));
  taps.reset();
  taps.up(point(155));
  assert.equal(taps.down(point(200)), false);
  taps.up(point(245));
  taps.reset();
  assert.equal(taps.down(point(300)), false);
});
