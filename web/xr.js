"use strict";
window.installHallXR = async function () {
  if (!navigator.xr || !(await navigator.xr.isSessionSupported("immersive-vr").catch(() => false))) return;
  const button = document.getElementById("vr");
  button.hidden = false;
  let session = null;
  button.onclick = async () => {
    if (session) {
      await session.end();
      return;
    }
    try {
      session = await navigator.xr.requestSession("immersive-vr", { optionalFeatures: ["local-floor"] });
      const gl = Module.canvas.getContext("webgl2");
      await gl.makeXRCompatible();
      const layer = new XRWebGLLayer(session, gl);
      session.updateRenderState({ baseLayer: layer });
      const space = await session
        .requestReferenceSpace("local-floor")
        .catch(() => session.requestReferenceSpace("local"));
      const id = Module.GL.getNewId(Module.GL.framebuffers);
      Module.GL.framebuffers[id] = layer.framebuffer;
      const matrices = Module._malloc(256),
        viewport = Module._malloc(32),
        input = Module._malloc(56);
      let actuator = null;
      const stopPulse = () => {
        if (actuator) {
          try {
            const p = actuator.reset ? actuator.reset() : actuator.pulse?.(0, 0);
            p?.catch?.(() => {});
          } catch {}
        }
        actuator = null;
      };
      let lastTurn = 0,
        grip = false,
        use = false,
        bell = false;
      button.textContent = "Exit VR";
      session.addEventListener("end", () => {
        stopPulse();
        Module._hall_xr_end();
        Module.GL.framebuffers[id] = null;
        for (const p of [matrices, viewport, input]) Module._free(p);
        button.textContent = "Enter VR";
        session = null;
      });
      const update = (time, frame) => {
        if (!session) return;
        session.requestAnimationFrame(update);
        const pose = frame.getViewerPose(space);
        if (!pose || pose.views.length !== 2) return;
        pose.views.forEach((v, i) => {
          const r = layer.getViewport(v);
          Module.HEAPF32.set(v.transform.inverse.matrix, (matrices >> 2) + 32 * i);
          Module.HEAPF32.set(v.projectionMatrix, (matrices >> 2) + 32 * i + 16);
          Module.HEAP32.set([r.x, r.y, r.width, r.height], (viewport >> 2) + 4 * i);
        });
        const a = [0, 1.4, 0, 0, 0, -1, 0, 0, 0, 0, 0];
        const hm = pose.transform.matrix;
        a.push(hm[12], hm[13], hm[14]);
        let right = null;
        a[9] = (Math.atan2(hm[8], hm[10]) * 180) / Math.PI;
        for (const s of session.inputSources) {
          const gp = s.gamepad;
          if (!gp) continue;
          const x = gp.axes[2] || gp.axes[0] || 0,
            y = gp.axes[3] || gp.axes[1] || 0;
          if (s.handedness === "left") {
            a[6] = Math.abs(x) > 0.12 ? x : 0;
            a[7] = Math.abs(y) > 0.12 ? y : 0;
          }
          if (s.handedness !== "right") continue;
          right = gp.hapticActuators?.[0] || gp.vibrationActuator;
          const hand = frame.getPose(s.targetRaySpace, space);
          if (hand) {
            const m = hand.transform.matrix;
            a.splice(0, 6, m[12], m[13], m[14], -m[8], -m[9], -m[10]);
          }
          if (Math.abs(x) > 0.75 && !lastTurn) a[8] = -Math.sign(x) * 30;
          lastTurn = Math.abs(x) > 0.45 ? 1 : 0;
          a[10] = gp.buttons[0]?.value || 0;
          const g = !!gp.buttons[1]?.pressed,
            u = !!gp.buttons[4]?.pressed,
            b = !!gp.buttons[5]?.pressed;
          if (g && !grip) Module._hall_choose(0);
          if (u !== use) action("interact", u);
          if (b !== bell) action("practice", b);
          grip = g;
          use = u;
          bell = b;
        }
        Module.HEAPF32.set(a, input >> 2);
        Module._hall_xr_frame(id, matrices, viewport, input);
        if (right !== actuator) {
          stopPulse();
          actuator = right;
        }
        const pulse = Module._hall_pulse();
        if (pulse && actuator) {
          const ms = Math.floor(pulse / 1000),
            strength = (pulse % 1000) / 100;
          try {
            const result = actuator.pulse
              ? actuator.pulse(strength, ms)
              : actuator.playEffect?.("dual-rumble", {
                  duration: ms,
                  strongMagnitude: strength,
                  weakMagnitude: strength,
                });
            result?.catch?.(() => {});
          } catch {}
        }
      };
      session.requestAnimationFrame(update);
    } catch (e) {
      if (session) await session.end();
      console.warn("VR session", e);
    }
  };
};
