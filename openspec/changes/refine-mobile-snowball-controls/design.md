## Touch input

A first contact aims immediately. A touch that lasts at most 250 ms and stays within 14 CSS pixels of its origin qualifies as a tap. A second contact within 320 ms of that release and within 32 CSS pixels starts the normal fire action on contact. The second finger can drag while held. Lifting it ends its contribution to firing. The Fire button contributes independently, so either finger can lift while the other continues firing.

Use event timestamps and CSS pixels across display densities. A drag, long press or canceled gesture cannot arm a fresh press. Blur, page hiding, resizing and opening the menu clear pending taps and held pointers. The Web client disables SDL’s raw finger handlers and its mouse binding for fire because the Web shell already supplies those actions. Desktop pointers and XR triggers still feed the same gameplay action.

## Verification

Run boundary tests for tap duration, interval and distance. In the packaged WebGL game, read submitted throws and camera pose while sending real browser touch events. Exercise simultaneous movement, turning and firing in Chromium, then verify taps and the dedicated button with WebKit’s iPhone profile.
