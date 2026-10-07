-- churn-check.sql — prompt-cache churn (cache-write tokens NOT explained by new
-- content growth) for opencode-go/qwen, split by era:
--   1-preDCP  (before 2026-06-21, DCP not yet installed)
--   2-DCP-V1  (2026-06-21 → 2026-09-26, DCP under V1)
--   3-V2      (2026-09-26 → , DCP under V2)
-- Run:  sqlite3 ~/.local/share/opencode/opencode.db < ~/.config/opencode/tool/churn-check.sql
-- churn = write - (ctx_growth). Steady-state only (pos>=11), prefix >20K.
-- Baselines measured 2026-10-07 (avg churn/turn): preDCP 7.2K | DCP-V1 3.8K | V2 7.3K
-- Apples-to-apples (last-30d of V1 vs V2 era, same model+provider): 0.8K → 7.3K (x8.9)
-- GOAL after DCP manualMode (re-measure ~1 week post `opencode service restart`):
--   3-V2 avg_churn should collapse toward <=2.5K. If it does NOT, culprit is the
--   V2 instructions-notice re-injection (Fix 2/3), not DCP.
.headers on
.mode column
WITH base AS (
  SELECT session_id, seq, time_created,
         json_extract(data,'$.tokens.cache.write') AS cw,
         json_extract(data,'$.tokens.cache.read')  AS cr
  FROM session_message
  WHERE type='assistant'
    AND json_extract(data,'$.model.providerID')='opencode-go'
    AND json_extract(data,'$.model.id') LIKE '%qwen%'
),
ranked AS (
  SELECT *,
         row_number() OVER (PARTITION BY session_id ORDER BY seq) AS pos,
         lag(cr+cw)   OVER (PARTITION BY session_id ORDER BY seq) AS prev_ctx,
         lag(cr)      OVER (PARTITION BY session_id ORDER BY seq) AS prev_cr
  FROM base
  WHERE cr IS NOT NULL AND cw IS NOT NULL
),
churn AS (
  SELECT cw, cr, prev_cr,
         cw - ((cr+cw) - prev_ctx) AS churn,
         CASE WHEN time_created >= 1790373600000 THEN '3-V2'
              WHEN time_created >= 1781992800000 THEN '2-DCP-V1'
              ELSE '1-preDCP' END AS era
  FROM ranked
  WHERE pos >= 11 AND prev_ctx >= 20000
)
SELECT era,
       count(*)                                        AS turns,
       round(avg(churn))                               AS avg_churn,
       round(avg(cw))                                  AS avg_write,
       round(avg(cr))                                  AS avg_read,
       sum(churn > 20000)                              AS explode_turns,
       sum(cr < prev_cr*0.5)                           AS full_miss_turns
FROM churn GROUP BY era ORDER BY era;
