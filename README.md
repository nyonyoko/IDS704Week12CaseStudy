# Whose Values? Ranking Activity

A mobile-friendly, live classroom activity for IDS 704 on Claude's Constitution. Students join anonymously with a QR code, complete three rounds, and respond to three discussion warm-ups. Facilitators create sessions, view results live, download CSV, and close sessions. Plain static HTML/CSS/JavaScript + Supabase.

This implementation follows `whose-values-build-spec.md` and preserves its activity wording, options, colors, ranking logic, and scoring.

## What YOU must do (15–30 minutes, depending on authentication email delivery)

### A. Create the database (Supabase)

1. Visit [supabase.com/dashboard](https://supabase.com/dashboard), sign in, and select **New project**. Choose a project name such as `whose-values-ids704`, a database password, and a nearby region. Free tier is sufficient for this class.
2. In **Authentication > Sign In / Providers**, enable **Anonymous sign-ins** and **Email** sign-in. Use email magic-link/OTP for the facilitator; no student logins are shown. For a private, temporary activity, rate limits are usually enough, but consider CAPTCHA against abuse if the site will remain public after class.
3. In **SQL Editor > New query**, paste all of `supabase/schema.sql` and click **Run**. This creates two tables, validates answers, enforces row-level security, and turns on Realtime for responses.
4. In **Project Settings > API Keys** (location and names may change), copy the **Project URL** and **publishable key** (`sb_publishable_...` or legacy `anon` public key). Do NOT copy a `secret` or `service_role` key.
5. Open `config.js` and replace the two placeholder values with the actual Project URL and publishable key. These are publicly safe to distribute **only because RLS is enabled**. Run the SQL before sharing the student link.

### B. Deploy to GitHub Pages

1. Create a GitHub repository called `whose-values`. Add/upload **all root files** (`index.html`, `styles.css`, `app.js`, `config.js`) and the `supabase/` folder. No Node, npm, or build step required.
2. In GitHub repository **Settings > Pages**, choose **Deploy from a branch**, branch **main**, folder **/(root)**, and Save.
3. Your address should be `https://YOUR_GITHUB_USERNAME.github.io/whose-values/`. Open it. GitHub Pages sometimes takes a few minutes to publish changes.
4. In Supabase **Authentication > URL Configuration**, set **Site URL** to that address and add `https://YOUR_GITHUB_USERNAME.github.io/whose-values/?facilitator=1` as an allowed redirect URL. If the provider requires wildcard matching, explicitly add the appropriate URL pattern. You can also add `http://localhost:8000/**` during local testing.

### C. Start a session

1. Visit `https://YOUR_GITHUB_USERNAME.github.io/whose-values/#facilitator`.
2. Type your email, select **Email me a sign-in link**, and open the email link **in the same browser**. If your mail provider opens a different browser, copy/paste the link into the original one.
3. Create a new class session. It gets a six-character code and a QR code. Project this page for classmates.
4. Students scan the QR code. They will silently receive an anonymous Supabase account and are able to resume a saved answer after refreshing in the same browser.
5. Show the dashboard on the projector. It refreshes via Supabase Realtime and checks every 10 seconds as a fallback. Use **Presenter view** to enlarge results and hide most controls.

**Facilitator testing tip:** Use a private/incognito window on a phone (or a different browser) for the student view. Facilitator and student logins should not share the same browser auth storage.

## On the day of class

- Do a dry run with 2–3 phones. Finish all three rounds, then test refresh/resume and warm-up votes.
- Verify the average Round 1 score, Round 2 bars, Round 3 counts, and discussion response charts.
- Use **Download CSV** as a backup before closing or clearing the session.
- After testing, select **Clear all responses** (with the confirmation screen), or create a fresh session for class.
- If Wi-Fi becomes unstable, students see a save status and the client retries. Do not assume an answer was received until **Saved** appears.
- Leave the database active until the activity is finished; after class, you can export results and close the session.

## Security / privacy

- No student names or emails are collected. Supabase anonymous authentication creates a random account ID per browser. A different browser/device counts as a different participant.
- Only the facilitator who owns the session can read all responses. Students can read only their own responses. SQL RLS policies enforce these restrictions, not merely the interface.
- A session owner can create, open/close and delete responses; anonymous students cannot create sessions.
- Students can change answers only where the frontend permits it, but the database intentionally does not cryptographically enforce irreversible locking. This is an informal discussion activity, not an exam or voting system.
- An authenticated user may read session metadata (including other session codes) under the supplied specification's permissive `sessions_select` policy. For an informal activity this is acceptable, but do not use the app for confidential votes or high-stakes elections.
- Published frontend code and `config.js` are public. **NEVER put a Supabase secret key, service-role key, database password, or facilitator password in them.**
- The stored response data is associated with pseudonymous account IDs, but it remains sensitive classroom feedback; delete the Supabase project when no longer needed.

## Files

- `index.html` — website shell and CDN libraries.
- `styles.css` — the supplied visual system, plus responsive/accessibility additions.
- `app.js` — student flow, ranking, scoring, Supabase read/write, facilitator auth, dashboard, CSV export.
- `config.js` — public Supabase configuration that you fill in.
- `supabase/schema.sql` — full database setup, including validation and RLS.

## Troubleshooting

- **Setup needed:** check `config.js`; the URL must resemble `https://...supabase.co`.
- **Anonymous sign-ins disabled:** enable them in Supabase Auth settings.
- **Could not find session:** check the 6-character code and whether you created a session.
- **Magic link opens student view:** check Supabase Site URL and Redirect URLs; facilitator link must include `?facilitator=1`.
- **Email never arrives:** check Supabase Auth email delivery limitations and spam folder; wait for the link to arrive instead of repeatedly retrying.
- **Failed to save (RLS):** confirm the schema was executed in the correct project and the session is open.
- **No live updates:** the dashboard also polls every 10 seconds; verify the `responses` table is in the `supabase_realtime` publication.
- **CDN blocked on classroom Wi-Fi:** the site requires internet access to jsDelivr, Google Fonts (optional), and Supabase. Test in the actual classroom or on cellular data.

## Source / attribution

Activity developed for IDS 704, inspired by [Claude's Constitution](https://www.anthropic.com/constitution). Not affiliated with Anthropic.
