# Update: "Other" choices in Round 2 and Discussion Question 2

This update is based on the **tabbed facilitator version** of Whose Values?. It preserves the previous 14 Round 2 options and five Discussion Q2 stakeholder options, and appends Other as a new choice. Students can optionally explain their answer in a 160-character text field.

## Required deployment order (existing Supabase project)

1. Open **Supabase > SQL Editor** for the project connected to the website.
2. Copy and execute **`supabase/migrate-add-other.sql`**. This adds the two optional write-in fields and updates the allowed choice indexes without deleting responses. **Do this before deploying the new JavaScript.**
3. In the GitHub Pages repository, replace **`app.js`** and **`styles.css`** with the files in `whose-values-site/`. Commit them. Keep the existing configured `config.js` unchanged.
4. Wait for GitHub Pages to publish. Hard refresh the website (Ctrl+Shift+R).
5. Test using a NEW class session or a fresh anonymous browser. Existing locked Round 2 answers remain locked, by design.

## Behavior

- Round 2: **Other** is choice index `14`, counts as one of the five ranked values. When selected, an optional "Specify your other value" field appears. Its text is saved with the locked ranking.
- Discussion question 2: **Other** is choice index `5`, counts toward the maximum of two selections. When selected, an optional "Specify who else" field appears; its text autosaves after a short pause.
- Facilitator: Round 2 and Discussion tabs show the Other vote counts in the existing bar charts, plus the write-in descriptions beneath each chart.
- CSV: includes `r2_other` and `w2_other` fields.

## Quick checks

- Round 2: choose Other + four items, type a description, lock; verify Round 2 shows Other on facilitator and the description appears beneath the bar chart.
- Discussion Q2: choose Other, type a description, and verify it appears in the Discussion tab.
- Check that a second user's responses are not accessible to a student account.
- Refresh a locked Round 2 and confirm the other description remains.
- Confirm the exported CSV includes both new columns.

No new sign-in or website configuration is required. Do not run the full original `schema.sql` against existing data; use the migration above.
