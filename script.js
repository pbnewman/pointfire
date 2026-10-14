/* Pointfire Games holding page
   1. Draw the splash art onto a full-screen canvas.
   2. On click/tap/key: Game Boy palette wipe — four shades down to black, four back up.
   3. Reveal the "first game coming soon" copy and the email signup.
*/

/* ======================= CONFIG ======================= */
// Email signup endpoint. GitHub Pages is static, so a free form service
// receives the submissions. See README.md for setup (Formspree is the default).
// Example: "https://formspree.io/f/abcdwxyz"
const FORM_ENDPOINT = "https://formspree.io/f/mbgdpdkb";

// Four-shade transition palette, darkest → lightest. Default is an
// "overheated CRT" ramp: violet-black → crimson → hot orange → yellow-white.
// Other sets to try are below (classic Game Boy green, plain grey).
const GB_PALETTE = ["#1a0030", "#b8102e", "#ff7a00", "#fff0a8"];
// const GB_PALETTE = ["#0f380f", "#306230", "#8bac0f", "#9bbc0f"];
// const GB_PALETTE = ["#0a0a0a", "#4a4a4a", "#9c9c9c", "#e6e6e6"];
const GB_STEP_MS = 110;   // time per palette step
/* ====================================================== */

(function () {
  "use strict";

  const splash  = document.getElementById("splash");
  const canvas  = document.getElementById("crt");
  const img     = document.getElementById("splash-img");
  const content = document.getElementById("content");
  const ctx     = canvas.getContext("2d", { alpha: false });

  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // Offscreen copy of the composed splash frame; the effect samples from this.
  const frame = document.createElement("canvas");
  const fctx  = frame.getContext("2d", { alpha: false });

  let W = 0, H = 0, DPR = 1;
  let started = false;

  /* ---------- Composition: fit the art to any viewport ---------- */
  function composeFrame() {
    DPR = Math.min(window.devicePixelRatio || 1, 2);
    W = Math.max(1, Math.floor(window.innerWidth));
    H = Math.max(1, Math.floor(window.innerHeight));
    canvas.width = frame.width = Math.floor(W * DPR);
    canvas.height = frame.height = Math.floor(H * DPR);
    canvas.style.width = W + "px";
    canvas.style.height = H + "px";

    const iw = img.naturalWidth || 2000, ih = img.naturalHeight || 1116;
    fctx.setTransform(DPR, 0, 0, DPR, 0, 0);
    fctx.imageSmoothingEnabled = true;
    fctx.fillStyle = "#0e0e0e";
    fctx.fillRect(0, 0, W, H);

    // Backdrop: the art scaled to cover, blurred (downscale → upscale, which
    // every browser supports) and darkened, so no edge ever shows bare.
    const cover = Math.max(W / iw, H / ih);
    const tiny = document.createElement("canvas");
    tiny.width = 8; tiny.height = Math.max(1, Math.round(8 * H / W));
    const tctx = tiny.getContext("2d");
    const ts = Math.max(tiny.width / iw, tiny.height / ih);
    tctx.drawImage(img, (tiny.width - iw * ts) / 2, (tiny.height - ih * ts) / 2, iw * ts, ts * ih);
    fctx.save();
    fctx.globalAlpha = 0.3;
    fctx.imageSmoothingQuality = "high";
    fctx.drawImage(tiny, 0, 0, W, H);
    fctx.restore();

    // Foreground: cover, but never so large that the logo (middle ~52% of the
    // art) is cropped on a narrow screen.
    const logoFrac = 0.52;
    const maxForLogo = (W * 0.9) / (iw * logoFrac);
    const scale = Math.min(cover, maxForLogo);
    const dw = iw * scale, dh = ih * scale;
    fctx.drawImage(img, (W - dw) / 2, (H - dh) / 2, dw, dh);

    // Soft vignette so the fitted art blends into the backdrop.
    const g = fctx.createRadialGradient(W / 2, H / 2, Math.min(W, H) * 0.35, W / 2, H / 2, Math.max(W, H) * 0.75);
    g.addColorStop(0, "rgba(0,0,0,0)");
    g.addColorStop(1, "rgba(0,0,0,0.6)");
    fctx.fillStyle = g;
    fctx.fillRect(0, 0, W, H);

    drawIdle();
  }

  function drawIdle() {
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.drawImage(frame, 0, 0);
    drawScanlines(ctx, 0.18);
  }

  function drawScanlines(c, alpha) {
    c.save();
    c.setTransform(DPR, 0, 0, DPR, 0, 0);
    c.fillStyle = "rgba(0,0,0," + alpha + ")";
    for (let y = 0; y < H; y += 3) c.fillRect(0, y, W, 1);
    c.restore();
  }

  /* ---------- Idle ambience: faint CRT jitter ---------- */
  let idleRAF = 0, lastIdle = 0;
  function idleLoop(t) {
    if (started) return;
    if (t - lastIdle > 90) {           // ~11 fps is enough for a lazy flicker
      lastIdle = t;
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.drawImage(frame, 0, 0);
      drawScanlines(ctx, 0.14 + Math.random() * 0.08);
      if (Math.random() < 0.06) {       // occasional single-line tear
        const y = Math.random() * H, h = 2 + Math.random() * 6, dx = (Math.random() - 0.5) * 14;
        ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
        ctx.drawImage(frame, 0, y * DPR, W * DPR, h * DPR, dx, y, W, h);
      }
    }
    idleRAF = requestAnimationFrame(idleLoop);
  }

  /* ---------- The switch: a Game Boy palette wipe ----------
     Everything on screen is posterised to four shades. The splash steps down
     shade by shade to the darkest one, then the next screen steps back up.
     Done with SVG feComponentTransfer filters so the canvas and the DOM get
     exactly the same treatment. */
  function hexToRgb(h) {
    return [1, 3, 5].map(function (i) { return parseInt(h.slice(i, i + 2), 16) / 255; });
  }
  function buildPaletteFilters() {
    var pal = GB_PALETTE.map(hexToRgb);
    var defs = "";
    // Step k maps luminance bin L (0 = darkest) to palette[max(L - k, 0)].
    for (var k = 0; k < 4; k++) {
      var tables = [[], [], []];
      for (var L = 0; L < 4; L++) {
        var c = pal[Math.max(L - k, 0)];
        tables[0].push(c[0].toFixed(3)); tables[1].push(c[1].toFixed(3)); tables[2].push(c[2].toFixed(3));
      }
      defs += '<filter id="gb' + k + '" color-interpolation-filters="sRGB">' +
        '<feColorMatrix type="saturate" values="0"/>' +
        '<feComponentTransfer>' +
        '<feFuncR type="discrete" tableValues="' + tables[0].join(" ") + '"/>' +
        '<feFuncG type="discrete" tableValues="' + tables[1].join(" ") + '"/>' +
        '<feFuncB type="discrete" tableValues="' + tables[2].join(" ") + '"/>' +
        '</feComponentTransfer></filter>';
    }
    var svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    svg.setAttribute("width", "0"); svg.setAttribute("height", "0");
    svg.setAttribute("aria-hidden", "true");
    svg.style.position = "absolute";
    svg.innerHTML = "<defs>" + defs + "</defs>";
    document.body.appendChild(svg);
  }

  function runEffect() {
    buildPaletteFilters();
    var step = 0;
    // Steps 0..3: splash goes quantised, then darker, then solid darkest shade.
    // Steps 4..7: content shown, climbing back from darkest to full palette.
    // Step 8: filter removed, the real page.
    function next() {
      if (step < 4) {
        canvas.style.filter = "url(#gb" + step + ")";
      } else if (step === 4) {
        content.hidden = false;
        splash.remove();
        document.body.style.overflow = "";
        document.body.style.filter = "url(#gb3)";
      } else if (step < 8) {
        document.body.style.filter = "url(#gb" + (7 - step) + ")";
      } else {
        document.body.style.filter = "";
        document.getElementById("email").focus({ preventScroll: true });
        return;
      }
      step++;
      setTimeout(next, GB_STEP_MS);
    }
    next();
  }

  function reveal() {
    content.hidden = false;
    content.classList.add("is-on");
    splash.remove();
    document.body.style.overflow = "";
    document.getElementById("email").focus({ preventScroll: true });
  }

  function start() {
    if (started) return;
    started = true;
    cancelAnimationFrame(idleRAF);
    splash.classList.add("is-busy");
    splash.setAttribute("aria-busy", "true");
    if (reduceMotion) { reveal(); return; }
    runEffect();
  }

  /* ---------- Wire up ---------- */
  function ready() {
    composeFrame();
    document.body.style.overflow = "hidden";
    idleRAF = requestAnimationFrame(idleLoop);
  }
  if (img.complete && img.naturalWidth) ready(); else img.addEventListener("load", ready, { once: true });
  img.addEventListener("error", reveal, { once: true }); // never trap the visitor if the art fails

  let resizeT = 0;
  window.addEventListener("resize", function () {
    if (started) return;
    clearTimeout(resizeT);
    resizeT = setTimeout(composeFrame, 80);
  });

  splash.addEventListener("click", start);
  splash.addEventListener("keydown", function (e) {
    if (e.key === "Enter" || e.key === " ") { e.preventDefault(); start(); }
  });

  /* ---------- Email signup ---------- */
  const form = document.getElementById("signup");
  const emailEl = document.getElementById("email");
  const statusEl = document.getElementById("status");
  const submitBtn = document.getElementById("submit");
  document.getElementById("year").textContent = String(new Date().getFullYear());

  function setStatus(msg, isError) {
    statusEl.textContent = msg;
    statusEl.classList.toggle("is-error", !!isError);
  }

  form.addEventListener("submit", async function (e) {
    e.preventDefault();
    const email = emailEl.value.trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setStatus("That doesn't look like an email address. Check it and try again.", true);
      emailEl.focus();
      return;
    }
    if (FORM_ENDPOINT.indexOf("YOUR_FORM_ID") !== -1) {
      // Not connected yet: say so instead of pretending it worked.
      setStatus("Signup isn't connected yet (demo mode). Set FORM_ENDPOINT in script.js to go live.", true);
      return;
    }
    submitBtn.disabled = true;
    setStatus("Sending…");
    try {
      const res = await fetch(FORM_ENDPOINT, {
        method: "POST",
        headers: { "Accept": "application/json" },
        body: new FormData(form)
      });
      if (!res.ok) throw new Error("HTTP " + res.status);
      form.classList.add("is-done");
      setStatus("You're on the list. We'll email you when the game is announced.");
    } catch (err) {
      setStatus("Couldn't send right now. Please try again in a moment.", true);
      submitBtn.disabled = false;
    }
  });
})();
