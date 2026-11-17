-- Run ONCE in Supabase SQL Editor against the EXISTING Whose Values? database.
-- Preserves existing sessions and student responses.
begin;

alter table public.responses
  add column if not exists r2_other text,
  add column if not exists w2_other text;

-- Round 2 has values 0..13 plus Other = 14.
alter table public.responses drop constraint if exists responses_r2_check;
alter table public.responses
  add constraint responses_r2_check check (
    r2 is null or (
      cardinality(r2) = 5
      and r2 <@ array[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14]::smallint[]
      and public.is_distinct_set(r2)
    )
  );

-- Discussion question 2 has choices 0..4 plus Other = 5.
alter table public.responses drop constraint if exists responses_w2_check;
alter table public.responses
  add constraint responses_w2_check check (
    w2 is null or (
      cardinality(w2) between 1 and 2
      and w2 <@ array[0,1,2,3,4,5]::smallint[]
      and public.is_distinct_set(w2)
    )
  );

alter table public.responses drop constraint if exists responses_r2_other_check;
alter table public.responses add constraint responses_r2_other_check
  check (r2_other is null or char_length(r2_other) <= 160);
alter table public.responses drop constraint if exists responses_w2_other_check;
alter table public.responses add constraint responses_w2_other_check
  check (w2_other is null or char_length(w2_other) <= 160);

commit;
