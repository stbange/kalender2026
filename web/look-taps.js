"use strict";

// Distances use CSS pixels. Event timestamps preserve the player's timing through a slow render frame.
const maxTapMs = 250,
  maxTapTravelPx = 14;
const doubleTapGapMs = 320,
  doubleTapRadiusPx = 32;

class LookTaps {
  constructor() {
    this.reset();
  }

  reset() {
    this.start = null;
    this.last = null;
  }

  down(e) {
    const last = this.last;
    this.reset();
    if (
      last &&
      e.timeStamp - last.time <= doubleTapGapMs &&
      Math.hypot(e.clientX - last.x, e.clientY - last.y) <= doubleTapRadiusPx
    )
      return true;
    this.start = { x: e.clientX, y: e.clientY, time: e.timeStamp };
    return false;
  }

  move(e) {
    if (this.start && Math.hypot(e.clientX - this.start.x, e.clientY - this.start.y) > maxTapTravelPx)
      this.start = null;
  }

  up(e) {
    this.move(e);
    if (this.start && e.timeStamp - this.start.time <= maxTapMs)
      this.last = { x: e.clientX, y: e.clientY, time: e.timeStamp };
    this.start = null;
  }
}

if (typeof module !== "undefined") module.exports = LookTaps;
