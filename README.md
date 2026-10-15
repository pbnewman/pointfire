# Pointfire Games — holding page

A single static page: the Pointfire splash art fills the screen, a click (or tap, or Enter) runs a
Game Boy style palette wipe in overheated CRT colours (four shades down to dark, four back up), and the visitor lands on a short "our first game is coming"
message with an email signup.

No build step. Plain HTML, CSS and JavaScript, so it runs on GitHub Pages as-is.

## Files

| Path | Purpose |
| --- | --- |
| `index.html` | Page markup |
| `style.css` | Styles (dark, monochrome, CRT scanlines) |
| `script.js` | Canvas CRT effect + signup form. **Edit `FORM_ENDPOINT` here.** |
| `assets/splash-bg.jpg` | Logo-free background plate, cropped to cover any screen shape |
| `assets/logo.png` | The logo on a transparent layer, drawn on top of the plate |
| `assets/splash.jpg` | Original splash art, used only for the social-share preview image |
| `assets/icon.png` | Keyed-out arrow icon used on the content screen |
| `assets/favicon.png`, `assets/apple-touch-icon.png` | Tab / home-screen icons |
| `assets/brand-sheet.jpg` | Reference only, not used by the page |
| `.nojekyll` | Tells GitHub Pages to serve files exactly as they are |

## Deploy to GitHub Pages

1. Create a repository, e.g. `pointfire-games/pointfire-games.github.io`
   (that exact name gives you `https://pointfire-games.github.io/` with no sub-path).
   Any other repo name works too; the site then lives at `https://<user>.github.io/<repo>/`.
2. Push these files to the `main` branch.
3. In the repo: **Settings → Pages → Build and deployment → Source: Deploy from a branch**,
   branch `main`, folder `/ (root)`. Save.
4. Wait a minute, then open the URL GitHub shows on that settings page.
5. Custom domain (optional): add it under **Settings → Pages → Custom domain**, point your DNS
   at GitHub per the instructions there, and tick **Enforce HTTPS**.

## Connect the email signup

GitHub Pages only serves files; it cannot receive form submissions. The form posts to a
third-party endpoint instead. The page is wired for **Formspree** (free tier: 50 submissions/month,
no card needed), but any service that accepts a plain `POST` with an `email` field works.

**Formspree**
1. Sign up at <https://formspree.io>, create a form, copy its endpoint
   (looks like `https://formspree.io/f/abcdwxyz`).
2. In `script.js`, replace `YOUR_FORM_ID` in `FORM_ENDPOINT` with your form's ID.
3. Commit and push. Submissions appear in your Formspree dashboard and can be exported as CSV
   or forwarded to Mailchimp, Google Sheets, etc. from there.

**Alternatives**
- **Buttondown** (newsletter tool with a free tier): set `FORM_ENDPOINT` to
  `https://buttondown.com/api/emails/embed-subscribe/<your-username>` and change the request in
  `script.js` to send `Content-Type: application/x-www-form-urlencoded`.
- **Mailchimp / MailerLite / Kit (ConvertKit)**: each gives you a hosted form or a POST URL for an
  embedded form; drop that URL into `FORM_ENDPOINT` and keep the `email` field name.
- **Google Forms**: free, but the visitor leaves your page; link to it instead of using the inline form.

Until `FORM_ENDPOINT` is set, submitting the form shows a "demo mode" notice rather than a fake success.

A hidden `_gotcha` honeypot field is included; Formspree drops any submission where it is filled.

## Customising

- **Copy**: edit the headline, paragraph and fine print in `index.html`.
- **Transition palette and speed**: `GB_PALETTE` and `GB_STEP_MS` at the top of `script.js`. The default is a violet → crimson → orange → yellow heat ramp; the classic Game Boy green and a grey set are included as alternatives.
- **Splash art**: the page draws `assets/splash-bg.jpg` to cover the screen and `assets/logo.png`
  centred on top, scaled to fit within 90% of the width and 70% of the height. Replace either file
  to change the look; the plate can be any size, the logo any transparent PNG.
- **Reduced motion**: visitors with "reduce motion" enabled skip the effect and get a simple fade.

## Test locally

Any static server works, e.g.

```
python3 -m http.server 8080
```

then open <http://localhost:8080>. Opening `index.html` directly as a file also works in most browsers.
