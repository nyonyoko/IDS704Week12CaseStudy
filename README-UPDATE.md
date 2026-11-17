# Whose Values? Write-in "Add" button and facilitator display fix

## Replace files in GitHub

Replace `app.js` and `styles.css` in the root of your existing GitHub Pages repository. Commit and wait for the website to publish. Hard refresh once (Ctrl+Shift+R), including on the facilitator device.

No new SQL migration is needed **if you already ran** `supabase/migrate-add-other.sql` from the preceding release. The existing `r2_other` and `w2_other` columns are reused. If you did not run it, run the included migration first.

## New student behavior

- **Round 2:** Type a custom value under **Add another value**, click **Add to ranking**, then rank the inserted item like any other. It occupies one of the five slots. Click **Lock in my top 5** to save the whole ranking and its custom text together. An empty custom value cannot be added.
- **Discussion question 2:** Type a stakeholder and click **Add option**. This inserts it as a selected choice and saves the selection plus custom text **together**, counting as one of the maximum two choices. Tap the selected custom chip to remove it.

## Facilitator

- **Round 2 tab:** The standard **Other** count remains in the bar chart. Below the chart, **Other values suggested** lists every saved custom value.
- **Discussion tab:** Under question 2, **Other stakeholders suggested** lists every saved custom stakeholder.
- Both lists are visible even with zero responses. If old submissions selected Other but have no stored text, a notice indicates how many such responses exist. These entries cannot be reconstructed automatically.
- CSV export includes both text columns and uses `Other: <text>` in readable label fields.

## Test before class

1. In a student browser that is not signed in as facilitator, join a fresh session.
2. Round 2: pick four standard values, type `Cultural sensitivity`, click **Add to ranking**, and lock the five. Verify the facilitator Round 2 page lists **Cultural sensitivity**.
3. Discussion question 2: choose one standard stakeholder, type `Teachers`, click **Add option**, and verify **Teachers** appears under facilitator Discussion question 2.
4. Refresh both pages and confirm results persist.
5. Check the Supabase Table Editor: `public.responses` should contain nonempty `r2_other` and `w2_other` fields on the test row.

If **Other** is counted but a typed value does not appear, inspect that response row in Supabase Table Editor. If the `*_other` fields are empty/null, the old interface did not save the text; the facilitator cannot display missing data. If the database contains text but the facilitator does not display it, hard refresh the facilitator site to load the new `app.js`.
