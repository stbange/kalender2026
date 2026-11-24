// A two-eye headset fixture for the browser test. The game still renders into a real GL framebuffer.
(() => {
  const matrix = new Float32Array([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
  const transform = { matrix, inverse: { matrix } };
  window.stereoFrames = 0;
  window.XRWebGLLayer = class {
    constructor(session, gl) {
      this.framebuffer = gl.createFramebuffer();
      this.texture = gl.createTexture();
      gl.bindTexture(gl.TEXTURE_2D, this.texture);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 512, 256, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
      gl.bindFramebuffer(gl.FRAMEBUFFER, this.framebuffer);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, this.texture, 0);
      gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    }
    getViewport(view) {
      return { x: view.eye === "left" ? 0 : 256, y: 0, width: 256, height: 256 };
    }
  };
  WebGL2RenderingContext.prototype.makeXRCompatible = async () => {};
  const xr = {
    isSessionSupported: async () => true,
    requestSession: async () => {
      const s = new EventTarget();
      window.testSession = s;
      s.active = true;
      s.inputSources = [
        {
          handedness: "right",
          targetRaySpace: {},
          gamepad: {
            axes: [0, 0, 0, 0],
            buttons: [{ value: 1 }, { pressed: false }, {}, {}, { pressed: false }, { pressed: false }],
          },
        },
      ];
      s.updateRenderState = () => {};
      s.requestReferenceSpace = async () => ({});
      s.requestAnimationFrame = (fn) =>
        requestAnimationFrame((t) => {
          if (!s.active) return;
          window.stereoFrames++;
          fn(t, {
            getViewerPose: () => ({
              transform,
              views: ["left", "right"].map((eye) => ({ eye, transform, projectionMatrix: matrix })),
            }),
            getPose: () => ({ transform }),
          });
        });
      s.end = async () => {
        s.active = false;
        s.dispatchEvent(new Event("end"));
      };
      return s;
    },
  };
  Object.defineProperty(navigator, "xr", { configurable: true, value: xr });
})();
