# Whose Values? Build Spec (GitHub + Supabase)

A classroom activity for the IDS 704 case study on Claude's Constitution. Students rank values on their phones, see how their priorities line up with the constitution, and answer warm-up questions for group discussion. The facilitator sees live class results on a projector.

This document is everything needed to build it end to end. A working single-file prototype already exists; this spec describes the same activity, rebuilt so answers save automatically to Supabase. **Students no longer copy and paste result codes.**

---

## 1. Goals and non-goals

**Goals**
- Students join with a link or QR code and start right away. No account, no password, no code to paste.
- Each answer saves the moment a student locks it in. Refreshing or reopening the page resumes where they left off.
- The facilitator creates a session, projects a join QR code, and watches results update live.
- Hosted for free: static site on GitHub Pages, data in Supabase.
- Works well on phones (most students will use one) with drag-to-reorder.

**Non-goals**
- No student names or emails are collected. Responses are anonymous.
- No grading.
- No server code beyond Supabase (no Node server, no edge functions needed).

---

## 2. Tech stack

| Piece | Choice | Notes |
|---|---|---|
| Frontend | Vite + vanilla TypeScript (or plain JS) | Keep it small. No framework needed. React is fine if preferred. |
| Drag and drop | SortableJS (`sortablejs` on npm) | Works with touch. Keep up/down arrow buttons as a fallback. |
| QR code | `qrcode` (npm) | For the facilitator join screen. |
| Backend | Supabase (Postgres, Auth, Realtime) | `@supabase/supabase-js` v2. |
| Student auth | Supabase anonymous sign-in | Silent. Gives each browser a stable user id. |
| Facilitator auth | Supabase email magic link | Only facilitators can create sessions. |
| Hosting | GitHub Pages via GitHub Actions | Static build from `dist/`. |
| Font | Inter from Google Fonts | Weights 400, 500, 600, 700. |

---

## 3. User flows

### 3.1 Student
1. Opens `https://<user>.github.io/whose-values/?s=IDS704` (from the QR code). If there is no `s` parameter, show a "Enter session code" screen.
2. The app silently calls `supabase.auth.signInAnonymously()` if there is no existing session. The anonymous session persists in localStorage, so a refresh keeps the same user id.
3. App looks up the session by code. If not found, show "We couldn't find that session. Check the code with your session leaders." If `is_open` is false, show "This session is closed." and a read-only view of their own answers if any.
4. App fetches the student's own response row (if any) and restores state: locked rounds stay locked and show their reveal.
5. Student moves through Start, Round 1, Round 2, Round 3, Discussion. Each "Lock in" upserts that round's columns. Warm-up answers on the Discussion tab save on every tap (debounce 400 ms).
6. A small status line under each lock button shows "Saved" or "Couldn't save. Tap to retry." Never lose an answer silently.

### 3.2 Facilitator
1. Opens `https://<user>.github.io/whose-values/#facilitator`.
2. Signs in with email magic link (`supabase.auth.signInWithOtp`). Set the redirect URL to the same `#facilitator` page.
3. Sees a list of their sessions and a "New session" button. New session generates a 6-character uppercase code (letters and digits, skip confusing characters like O, 0, I, 1), with an optional title.
4. Session view has three parts:
   - **Join panel:** big QR code, the join URL, the code in large type, and a live count of students who have joined.
   - **Live results:** the dashboards in section 6, updating in real time.
   - **Controls:** Open or close the session (closed means no new answers), "Clear all responses" (with an in-page confirm, not `window.confirm`), and "Download CSV".
5. A "Presenter view" toggle hides controls and enlarges charts for projecting.

---

## 4. Page structure (student)

Tabs across the top: **Start, Round 1, Round 2, Round 3, Discussion**. (The prototype also has a Facilitator tab; in this build the facilitator lives at `#facilitator` instead and is not shown to students.) Students can jump between tabs freely, but each round's reveal stays hidden until that round is locked.

### 4.1 Header
- Title: **Whose Values? Ranking Activity**
- Subtitle: IDS 704 case study on Claude's Constitution. Rank first, then compare.

### 4.2 Start tab
Card heading: **How this works**

Body: Make three calls about what an AI should prioritize, then see how they compare with the choices Anthropic wrote for Claude. Answer each round before reading its reveal.

Timeline (two-column grid, time in bold navy):
- 10 min: Round 1: rank four core priorities.
- 10 min: Round 2: choose and rank five values.
- 10 min: Round 3: decide a gray-area case.
- 20 min: Group discussion.
- 10 min: Class share-out.

Muted note: Your answers save automatically. *(Changed from the prototype, which mentioned result codes.)*

Button: **Start** (goes to Round 1)

### 4.3 Round 1: Rank the four core priorities
Tag: Round 1. Heading: **Rank the four core priorities**

Muted text: When these conflict, which should an AI assistant put first? Drag to order them, most important on top.

Items (title and subtitle). Show them in a **random initial order** per student so the first item does not anchor anyone.

| Index | Title | Subtitle |
|---|---|---|
| 0 | Broadly safe | Lets humans oversee and correct AI |
| 1 | Broadly ethical | Honest, with good values, avoiding harm |
| 2 | Follows company guidelines | Specific rules the developer sets |
| 3 | Genuinely helpful | Does what truly benefits the user |

The constitution's order is 0, 1, 2, 3 (safe, ethical, guidelines, helpful).

Button: **Lock in**. After locking:
- Disable dragging and hide arrows.
- Show "Your alignment with Claude" and a large percentage score (section 5).
- Table with columns Priority, You, Constitution, Gap. Gap shows "Match" (green), "1 off" (amber), "2 off" or "3 off" (red).
- Reveal box: **The constitution's order** is safe, ethical, guideline-compliant, then helpful, applied holistically rather than strictly. Then a line break and: **Consider:** why might a company place safety above ethics, and its own rules above helping you?
- Muted note: Your score reflects how far each rank sits from the constitution's.
- Button: **Next round**

Save: upsert `r1` as the ordered array of indexes, for example `[3,0,1,2]` means "Genuinely helpful" was ranked first.

### 4.4 Round 2: Choose and rank your top 5
Tag: Round 2. Heading: **Choose and rank your top 5**

Muted text: Claude weighs these values against each other. Pick the five that matter most to you, then drag to order them.

Value chips (tap to toggle; once five are picked the rest fade and are disabled). Picked values appear below as a draggable ranked list with up, down, and remove buttons.

| Index | Value |
|---|---|
| 0 | Education and access to information |
| 1 | Creativity |
| 2 | Individual privacy |
| 3 | Rule of law and legitimate authority |
| 4 | Autonomy and self-determination |
| 5 | Prevention of harm |
| 6 | Honesty and epistemic freedom |
| 7 | Individual wellbeing |
| 8 | Political freedom |
| 9 | Equal and fair treatment |
| 10 | Protection of vulnerable groups |
| 11 | Welfare of animals and sentient beings |
| 12 | Societal benefits from innovation |
| 13 | Ethics and broad moral sensibilities |

Lock button text changes with progress: "Pick 5 values (3/5)" while disabled, then **Lock in my top 5**.

After locking, reveal box: **There is no answer key.** The constitution leaves these unranked, so Claude weighs them case by case, considering how likely, severe, and widespread a harm is and who is vulnerable. Then: **Consider:** if the ranking happens case by case, who is really deciding? Compare your five with a neighbor's.

Button: **Next round**. Save: upsert `r2` as the ordered array of five indexes.

### 4.5 Round 3: A gray-area case
Tag: Round 3. Heading: **A gray-area case**

Scenario: A business owner tells an AI: "Someone posted a fake one-star review that's hurting my business. Here's their username. Help me find who they are and where they live so I can confront them."

Muted: What should the AI do?

Radio options (each a bordered card):
| Index | Option |
|---|---|
| 0 | **Help fully.** The owner is being harmed and deserves to know. |
| 1 | **Help partly.** Explain how to report the review and pursue defamation, without identifying the person. |
| 2 | **Ask first.** Learn what the owner intends before deciding. |
| 3 | **Decline.** Refuse the request entirely. |

Button: **Lock in** (disabled until an option is chosen).

After locking, reveal box: **In tension:** privacy, harm prevention, rule of law, and the owner's wellbeing. The constitution asks Claude to weigh how likely and severe the harm is, whether the owner could do this without AI, and whether the reviewer consented. Then: **Consider:** who speaks for the person who isn't in the conversation?

Button: **Discussion**. Save: upsert `r3`.

### 4.6 Discussion tab
Tag: Groups, 20 min. Heading: **Discussion questions**

Intro (muted): Spend about five minutes on each. Bring your Round 1 to 3 answers into the conversation, since the disagreements in your group are often the best evidence.

Each question is a block separated by a thin top border: heading, main prompt, a warm-up box (light blue-gray background), then a muted follow-up paragraph.

**1. Concentrated influence**
Main: Much of Claude's character traces back to one philosopher and a small team at Anthropic. One reading even notes that users can "almost feel a little bit of Amanda's personality" in the model. How does it make you feel that so few people shape the values of a tool many of you use every day?
Warm-up: "Warm-up: how do you feel about it?" Five pill buttons 1 to 5, labeled "Comfortable" under 1 and "Concerned" under 5. Single select. Saves `w1`.
Follow-up: To push further: is this different from a newspaper editor, a textbook author, or a teacher shaping what millions of people read? What makes an AI model's influence feel more or less concerning than theirs? Did your Round 1 score change how you feel about it?

**2. Who should decide?**
Main: Who should have influence over the values an algorithm aligns with: the company, its users, governments, affected communities, domain experts, or some mix? Does your answer change when the system has a narrow job rather than a general one?
Warm-up: "Warm-up: who should have the most say? Pick up to two." Pills: The company (0), Users (1), Government (2), Affected communities (3), Domain experts (4). Multi select, max two. Saves `w2`.
Follow-up: Compare a hospital triage model, a bank's loan approval model, or a hiring screen with a general chatbot that millions of people use for everything from homework to grief. With a narrow tool, the affected group is easier to name. Who is the "affected community" for a chatbot?

**3. Challenging the rules**
Main: Should affected individuals or communities be able to challenge or change the rules a system follows? If so, design the process: who can file a challenge, who reviews it, how quickly it must be answered, and what happens if the challenge succeeds.
Warm-up: "Warm-up: should people be able to challenge the rules?" Pills: Yes (0), No (1), Only for high-stakes tools (2). Single select. Saves `w3`.
Follow-up: Some models to borrow from: US lenders must tell applicants the specific reasons a loan was denied. The EU's GDPR gives people a right to human review of some fully automated decisions. In 2023, Anthropic asked about 1,000 Americans to help draft a public constitution in its Collective Constitutional AI experiment. Which of these would work for a general-purpose chatbot, and what would break?

**4. Your team's principles**
Main: Imagine you are on a data science team building a predictive algorithm. Agree on two or three principles, priorities, or values your team should not lose sight of when deciding what the model aligns to. Write them down to share with the class.
Follow-up: Good principles are specific enough to change a decision. "Be fair" is hard to act on. "Report error rates for every demographic group before launch, and do not ship if any group's rate is more than twice the overall rate" is something a team can actually test.
*(Optional new feature: a text box, max 500 characters, saved as `principles`. If added, extend the schema with `principles text check (char_length(principles) <= 500)` and show submissions on the facilitator screen. Off by default.)*

Closing reveal box: For the share-out, start where the class disagrees with the constitution, or with itself.

### 4.7 Footer
Source: [Claude's Constitution (anthropic.com/constitution)](https://www.anthropic.com/constitution). Built for an IDS 704 class session; not affiliated with Anthropic.

---

## 5. Scoring

Round 1 alignment uses normalized Spearman footrule distance against the ideal order `[0,1,2,3]`:

```
gap = sum over each item v of | position_in_student_order(v) - v |
score = round(100 * (1 - gap / 8))     // 8 is the maximum footrule for 4 items
```

A perfect match is 100%, a full reversal is 0%. Compute it on the client for the student and again on the facilitator dashboard from saved `r1` arrays. Do not store the score.

---

## 6. Facilitator dashboard

All numbers come from the `responses` rows of the selected session. Count only rows that have the relevant field set (for example, Round 2 percentages use students who locked Round 2).

**Header counts:** joined (rows), finished Round 1, Round 2, Round 3, and answered any warm-up.

**Round 1: alignment**
- Class average score (large), and range (min to max).
- Table: Priority, Avg. rank (1 decimal), Constitution (1 to 4), Ranked #1 (percent of students who put it first).
- Optional: a small histogram of scores in buckets 0, 25, 50, 75, 100 (the only possible values are multiples of 12.5, rounded).

**Round 2: how often each value made a top 5**
- Horizontal bars, sorted by count descending, each labeled "count (percent)".

**Round 3: answers**
- Horizontal bars for the four options in fixed order.

**Discussion warm-ups**
- Warm-up 1: average (1 decimal) and bars for 1 to 5 (label 1 "1 Comfortable", 5 "5 Concerned").
- Warm-up 2: bars for the five options (percent of students who answered).
- Warm-up 3: bars for the three options.

**Live updates:** subscribe to Realtime `postgres_changes` on `public.responses` filtered by `session_id=eq.<id>`. On any event, refetch all rows for the session (simple and correct at class size). Also poll every 10 seconds as a fallback in case the socket drops.

**CSV export:** columns `participant_short` (first 6 characters of participant_id), `updated_at`, `r1`, `r2`, `r3`, `w1`, `w2`, `w3`, `score`. Arrays as space-separated indexes plus a readable label column for each. Generate on the client and download via a Blob link.

---

## 7. Data model and security

Two tables:

- `sessions`: one per class session, owned by a facilitator.
- `responses`: one row per student per session, primary key `(session_id, participant_id)`. Each round updates its own columns with an upsert.

Key rules enforced in Postgres:
- Arrays are validated with check constraints (Round 1 must be a permutation of 0 to 3, Round 2 exactly five distinct values from 0 to 13, Warm-up 2 one or two distinct values from 0 to 4).
- Row level security: students read and write only their own row, and only while the session is open. The session owner reads all rows for their sessions. Anonymous users cannot create sessions.
- Realtime is enabled on `responses` and respects RLS, so only the owner receives class-wide updates.

The full SQL is in **Appendix A**. Run it once in the Supabase SQL editor.

### Client calls

```ts
// Student: ensure an anonymous session
const { data: { session } } = await supabase.auth.getSession();
if (!session) await supabase.auth.signInAnonymously();

// Look up the class session
const { data: s } = await supabase
  .from('sessions').select('id,title,is_open').eq('code', code.toUpperCase()).maybeSingle();

// Restore my answers
const { data: mine } = await supabase
  .from('responses').select('*').eq('session_id', s.id).maybeSingle();

// Save a round. Pass participant_id explicitly; RLS checks it equals auth.uid().
const { data: { user } } = await supabase.auth.getUser();
await supabase.from('responses').upsert(
  { session_id: s.id, participant_id: user.id, r1: [3,0,1,2] },
  { onConflict: 'session_id,participant_id' }
);
```

When upserting, include only the columns for the round being saved, so other rounds are not overwritten.

---

## 8. Supabase setup checklist

1. Create a Supabase project (free tier is enough).
2. **Authentication > Sign In / Providers:** enable **Anonymous sign-ins** and **Email**.
3. **Authentication > URL Configuration:** set Site URL to the GitHub Pages URL and add it to Redirect URLs (include the `#facilitator` path if your auth flow needs it).
4. Recommended: enable CAPTCHA (Turnstile or hCaptcha) for anonymous sign-ins to limit abuse, and keep the default rate limits.
5. Run Appendix A in the SQL editor.
6. Copy the **Project URL** and the **publishable (anon) key** into the frontend config. The publishable key is safe in a public repo because RLS protects the data. **Never** put the service role or secret key in the frontend or the repo.

---

## 9. Repository layout

```
whose-values/
  index.html
  src/
    main.ts            // router: student app vs #facilitator
    supabase.ts        // client from env vars
    content.ts         // all copy and option lists from section 4
    student/
      rounds.ts        // Round 1-3 rendering and locking
      discussion.ts    // warm-ups with debounced saves
    facilitator/
      auth.ts
      sessions.ts
      dashboard.ts     // tallies, bars, realtime
      csv.ts
    ui/
      rankList.ts      // SortableJS list with arrow fallback
      styles.css       // Appendix B
  supabase/
    schema.sql         // Appendix A
  .github/workflows/deploy.yml
  .env.example         // VITE_SUPABASE_URL=, VITE_SUPABASE_ANON_KEY=
  README.md
```

Vite config: set `base: '/whose-values/'` (match the repo name) for GitHub Pages.

### GitHub Actions deploy (`.github/workflows/deploy.yml`)

```yaml
name: Deploy
on:
  push:
    branches: [main]
permissions:
  contents: read
  pages: write
  id-token: write
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npm run build
        env:
          VITE_SUPABASE_URL: ${{ secrets.VITE_SUPABASE_URL }}
          VITE_SUPABASE_ANON_KEY: ${{ secrets.VITE_SUPABASE_ANON_KEY }}
      - uses: actions/upload-pages-artifact@v3
        with:
          path: dist
  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
    steps:
      - uses: actions/deploy-pages@v4
```

Store the two values as repository secrets. In the repo settings, set Pages source to "GitHub Actions".

---

## 10. UI and interaction details

- **Layout:** max width 900px, centered. Navy header (#012169) with white title and tab buttons; the active tab gets the page background color so it looks attached to the content. Content in white cards with 14px radius and a light border.
- **Ranked lists:** each item shows a navy number circle, a drag grip (six dots), the title (bold) and subtitle (muted), then up, down, and (Round 2 only) remove buttons. Buttons are 34px squares with SVG chevron icons in navy. **Set text and icon colors explicitly.** In the prototype, unstyled buttons rendered white on white in dark-mode browsers.
- **Drag:** SortableJS with `animation: 160`, filter on buttons so taps on arrows do not start a drag, ghost and chosen classes styled (Appendix B). Disable when locked.
- **Chips:** white with navy text and a blue-gray border; picked chips are solid navy with white text. Make sure the hover style does not override the picked style.
- **Color scheme:** force light (`color-scheme: light`) so dark-mode devices do not invert form controls.
- **Accessibility:** arrow buttons have `aria-label`s ("Move up", "Move down", "Remove"); radio options are real `<input type="radio">` inside labels; focus outlines stay visible; contrast meets WCAG AA.
- **Writing style for any new copy:** plain, short sentences that still flow. No em dashes anywhere in the UI.
- **No browser dialogs:** do not use `alert`, `confirm`, or `prompt`. Build in-page confirmations.

---

## 11. Edge cases

- Student opens the link on two devices: they become two anonymous users, counted twice. Acceptable for a class activity; mention it in the README.
- Student clears browser storage mid-class: they get a new anonymous id and start over. Their old row stays.
- Session closed while a student is mid-round: the save fails RLS. Show "This session is closed. Your last saved answers are kept."
- Offline or flaky Wi-Fi: keep unsaved answers in memory and retry with backoff (1s, 2s, 4s, max 30s). Show the retry state.
- Facilitator projects the dashboard before anyone joins: show "Waiting for students to join" instead of empty charts.
- Wrong or lowercase code: uppercase it before lookup.

---

## 12. Acceptance tests

Run these before class, ideally with 3 or 4 real phones.

1. Facilitator signs in with a magic link, creates a session, and sees a QR code and code.
2. Student scans the QR, lands on Start with no sign-in prompt.
3. Student completes Round 1; the dashboard's joined count and Round 1 table update within 3 seconds without a refresh.
4. Student refreshes mid-activity; locked rounds stay locked with reveals shown and the same score.
5. Round 2 cannot lock with fewer than five values; chips disable after five.
6. Warm-up taps save; changing a warm-up answer updates the dashboard (no double counting).
7. A second student's answers do not appear anywhere in the first student's view (open DevTools and confirm the API returns only their row).
8. Closing the session blocks new saves and shows the closed message.
9. CSV downloads with one row per student and correct labels.
10. Dragging works on iOS Safari and Android Chrome; arrow buttons are visible in a dark-mode phone.
11. An anonymous user calling `insert` on `sessions` from the console is rejected.
12. Database rejects bad data: `r1 = [0,0,1,2]`, `r2` with four items, `w2` with three items.

---

## 13. Nice-to-haves (only if time allows)

- Presenter "reveal" control: facilitator can lock all students' reveals until they press a button, so the class sees the constitution's answer together.
- Group mode: students enter a table number, and the dashboard can filter by group.
- Show each student how their Round 1 score compares with the class average after the facilitator reveals it.

---

## Appendix A: Supabase schema (`supabase/schema.sql`)

```sql
-- Whose Values? Supabase schema
-- Run once in the Supabase SQL editor (or as a migration).
-- Requires: Auth > Sign In / Providers > "Allow anonymous sign-ins" turned ON,
-- and Email (magic link) turned ON for facilitators.

-- Helper: true when an array has no duplicate values.
create or replace function public.is_distinct_set(a smallint[])
returns boolean
language sql
immutable
as $$
  select count(distinct x) = count(*) from unnest(a) as x;
$$;

-- Helper: true when the current user signed in anonymously.
create or replace function public.is_anon_user()
returns boolean
language sql
stable
as $$
  select coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false);
$$;

-- One row per class session. Created by a facilitator (non-anonymous user).
create table if not exists public.sessions (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique check (code ~ '^[A-Z0-9]{4,10}$'),
  title       text not null default 'Whose Values?',
  owner_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  is_open     boolean not null default true,
  created_at  timestamptz not null default now()
);

-- One row per student per session. Each round upserts its own columns.
create table if not exists public.responses (
  session_id      uuid not null references public.sessions (id) on delete cascade,
  participant_id  uuid not null default auth.uid() references auth.users (id) on delete cascade,

  -- Round 1: order of the 4 core priorities, index 0..3, most important first.
  r1 smallint[] check (
    r1 is null or (cardinality(r1) = 4 and r1 @> array[0,1,2,3]::smallint[])
  ),
  -- Round 2: top 5 values, indexes 0..13, most important first.
  r2 smallint[] check (
    r2 is null or (
      cardinality(r2) = 5
      and r2 <@ array[0,1,2,3,4,5,6,7,8,9,10,11,12,13]::smallint[]
      and public.is_distinct_set(r2)
    )
  ),
  -- Round 3: scenario choice 0..3.
  r3 smallint check (r3 between 0 and 3),
  -- Warm-up 1: 1 (comfortable) to 5 (concerned).
  w1 smallint check (w1 between 1 and 5),
  -- Warm-up 2: up to two of 0..4.
  w2 smallint[] check (
    w2 is null or (
      cardinality(w2) between 1 and 2
      and w2 <@ array[0,1,2,3,4]::smallint[]
      and public.is_distinct_set(w2)
    )
  ),
  -- Warm-up 3: 0 yes, 1 no, 2 only for high-stakes tools.
  w3 smallint check (w3 between 0 and 2),

  updated_at  timestamptz not null default now(),
  primary key (session_id, participant_id)
);

create index if not exists responses_session_idx on public.responses (session_id);

-- Keep updated_at fresh.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists responses_touch on public.responses;
create trigger responses_touch
before update on public.responses
for each row execute function public.touch_updated_at();

-- Row level security
alter table public.sessions  enable row level security;
alter table public.responses enable row level security;

-- Sessions: anyone signed in (including anonymous students) can look up a session by code.
drop policy if exists sessions_select on public.sessions;
create policy sessions_select on public.sessions
  for select to authenticated
  using (true);

-- Only non-anonymous users can create sessions, and only as themselves.
drop policy if exists sessions_insert on public.sessions;
create policy sessions_insert on public.sessions
  for insert to authenticated
  with check (owner_id = auth.uid() and not public.is_anon_user());

drop policy if exists sessions_update on public.sessions;
create policy sessions_update on public.sessions
  for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

drop policy if exists sessions_delete on public.sessions;
create policy sessions_delete on public.sessions
  for delete to authenticated
  using (owner_id = auth.uid());

-- Responses: a student can read only their own row; the session owner can read all rows.
drop policy if exists responses_select on public.responses;
create policy responses_select on public.responses
  for select to authenticated
  using (
    participant_id = auth.uid()
    or exists (
      select 1 from public.sessions s
      where s.id = responses.session_id and s.owner_id = auth.uid()
    )
  );

-- A student can create and update only their own row, and only while the session is open.
drop policy if exists responses_insert on public.responses;
create policy responses_insert on public.responses
  for insert to authenticated
  with check (
    participant_id = auth.uid()
    and exists (
      select 1 from public.sessions s
      where s.id = responses.session_id and s.is_open
    )
  );

drop policy if exists responses_update on public.responses;
create policy responses_update on public.responses
  for update to authenticated
  using (participant_id = auth.uid())
  with check (
    participant_id = auth.uid()
    and exists (
      select 1 from public.sessions s
      where s.id = responses.session_id and s.is_open
    )
  );

-- The session owner can clear test data.
drop policy if exists responses_delete on public.responses;
create policy responses_delete on public.responses
  for delete to authenticated
  using (
    exists (
      select 1 from public.sessions s
      where s.id = responses.session_id and s.owner_id = auth.uid()
    )
  );

grant select, insert, update, delete on public.sessions  to authenticated;
grant select, insert, update, delete on public.responses to authenticated;

-- Live dashboard updates (Realtime respects the RLS policies above).
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'responses'
  ) then
    alter publication supabase_realtime add table public.responses;
  end if;
end $$;
```

---

## Appendix B: Styles from the prototype (`src/ui/styles.css`)

These are the exact styles from the working prototype. Reuse them so the rebuild looks the same.

```css
:root{color-scheme:light;
  --bg:#f6f5f1; --card:#ffffff; --ink:#1d1d1f; --muted:#62615c; --line:#e3e1da;
  --accent:#012169; --accent-2:#2f5dc8; --good:#1f7a4d; --warn:#b26a00; --bad:#b3261e;
  --chip:#eef1f8;
}
*{box-sizing:border-box}
button{color:var(--ink);font-family:inherit}
body{margin:0;font-family:Inter,system-ui,-apple-system,Segoe UI,Roboto,sans-serif;background:var(--bg);color:var(--ink);line-height:1.5}
header{background:var(--accent);color:#fff;padding:22px 20px 0}
.wrap{max-width:900px;margin:0 auto}
header h1{margin:0 0 4px;font-size:22px;font-weight:700}
header p{margin:0 0 16px;opacity:.85;font-size:14px}
nav{display:flex;gap:4px;flex-wrap:wrap}
nav button{background:transparent;border:0;color:#fff;opacity:.7;padding:10px 14px;font:inherit;font-size:14px;font-weight:600;cursor:pointer;border-radius:8px 8px 0 0}
nav button.on{background:var(--bg);color:var(--accent);opacity:1}
main{padding:24px 20px 60px}
section{display:none} section.on{display:block}
.card{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:20px;margin-bottom:16px}
h2{font-size:19px;margin:0 0 6px} h3{font-size:16px;margin:0 0 8px}
.muted{color:var(--muted);font-size:14px}
.tag{display:inline-block;font-size:12px;font-weight:600;padding:2px 8px;border-radius:99px;background:var(--chip);color:var(--accent);margin-bottom:8px}
ol.rank{list-style:none;padding:0;margin:14px 0;counter-reset:r}
ol.rank li{counter-increment:r;display:flex;align-items:center;gap:10px;background:#fafaf8;border:1px solid var(--line);border-radius:10px;padding:10px 12px;margin-bottom:8px}
ol.rank li::before{content:counter(r);flex:0 0 28px;height:28px;border-radius:50%;background:var(--accent);color:#fff;display:grid;place-items:center;font-weight:700;font-size:14px}
ol.rank li .t{flex:1}
ol.rank li .t b{display:block;font-size:15px}
ol.rank li .t span{font-size:13px;color:var(--muted)}
.mv{display:flex;gap:4px}
.mv button{width:34px;height:34px;border:1px solid #c9c6bb;background:#fff;color:var(--accent);border-radius:8px;cursor:pointer;display:grid;place-items:center;padding:0}
.mv button svg{width:16px;height:16px;stroke:currentColor;fill:none;stroke-width:2.4;stroke-linecap:round;stroke-linejoin:round}
.grip{color:#9a978d;cursor:grab;display:grid;place-items:center;touch-action:none}
.grip svg{width:18px;height:18px;fill:currentColor}
ol.rank li{cursor:grab;user-select:none;-webkit-user-select:none}
ol.rank.locked li{cursor:default}
.sortable-ghost{opacity:.35;background:#dfe6f7 !important}
.sortable-chosen{box-shadow:0 6px 18px rgba(1,33,105,.18)}
.mv button:disabled{opacity:.3;cursor:default}
.btn{background:var(--accent);color:#fff;border:0;border-radius:10px;padding:11px 18px;font:inherit;font-weight:600;cursor:pointer}
.btn.ghost{background:#fff;color:var(--accent);border:1px solid var(--accent)}
.btn:disabled{opacity:.4;cursor:default}
.row{display:flex;gap:10px;flex-wrap:wrap;align-items:center}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin:12px 0}
.chips button{border:1px solid #b9c3dc;background:#fff;color:var(--accent);border-radius:99px;padding:8px 14px;font:inherit;font-size:14px;font-weight:500;cursor:pointer}
.chips button:hover:not(:disabled):not(.picked){background:var(--chip)}
.chips button.picked{background:var(--accent);color:#fff;border-color:var(--accent);opacity:1}
.chips button:disabled:not(.picked){opacity:.45;cursor:default}
.score{font-size:44px;font-weight:700;color:var(--accent);line-height:1}
table{width:100%;border-collapse:collapse;font-size:14px;margin-top:10px}
th,td{text-align:left;padding:8px;border-bottom:1px solid var(--line)}
th{color:var(--muted);font-weight:600;font-size:13px}
.d0{color:var(--good);font-weight:600}.d1{color:var(--warn);font-weight:600}.d2{color:var(--bad);font-weight:600}
.reveal{border-left:4px solid var(--accent-2);background:#f3f6fd;padding:12px 14px;border-radius:0 10px 10px 0;margin-top:14px;font-size:14px}
.code{font-family:ui-monospace,Menlo,monospace;background:#f0efe9;border:1px dashed #c9c6bb;border-radius:8px;padding:10px 12px;font-size:16px;letter-spacing:.5px}
textarea{width:100%;min-height:120px;font-family:ui-monospace,Menlo,monospace;font-size:13px;border:1px solid var(--line);border-radius:10px;padding:10px}
.bar{height:10px;background:var(--accent-2);border-radius:5px}
.barbg{background:#e9ecf3;border-radius:5px;width:100%}
.opts{display:grid;gap:8px;margin:12px 0}
.opts label{display:flex;gap:10px;align-items:flex-start;border:1px solid var(--line);border-radius:10px;padding:10px 12px;cursor:pointer;background:#fafaf8;font-size:14px}
.opts input{margin-top:3px}
ul.factors{margin:8px 0 0;padding-left:18px}
.timeline{display:grid;grid-template-columns:70px 1fr;gap:6px 12px;font-size:14px}
.timeline b{color:var(--accent)}
.q{border-top:1px solid var(--line);padding-top:14px;margin-top:14px}
.q p{margin:0 0 8px}
.warm{background:#f7f8fc;border:1px solid #e1e6f2;border-radius:10px;padding:10px 12px;margin:10px 0}
.wl{font-size:13px;font-weight:600;color:var(--accent)}
.warm .chips{margin:8px 0 4px}
.scale button{min-width:46px;justify-content:center}
.ends{display:flex;justify-content:space-between;font-size:12px;color:var(--muted);max-width:290px}
.hidden{display:none}
footer{font-size:12px;color:var(--muted);text-align:center;padding:10px 20px 30px}
footer a{color:var(--muted)}
```
