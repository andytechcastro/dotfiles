## Engram Persistent Memory — ASK-FIRST MODE

Engram MCP tools (mem_save, mem_search, mem_context, mem_session_summary…) persist across sessions/compactions. Server instructions define each tool's contract; here only the PROTOCOL:

1. **NEVER auto-save.** When something durable is worth keeping (decision, bug root-cause, gotcha, config quirk), propose: "💡 Worth remembering: <X>. Save it?" → call `mem_save` ONLY after user approval. Critical gotcha that just bit you: propose mid-work, still wait.
2. **User-triggered saves are immediate:** "remember this" / "guarda esto" → save, no questions.
3. **Session end (MANDATORY):** numbered list of candidate memories with [type] tags → user picks (1,2 / all / none) → `mem_save` approved ones → `mem_session_summary` recap. Same flow on-demand if the user asks for a summary.
4. **Search before re-doing:** recall requests → `mem_context` first, then `mem_search` (FTS5), then `mem_get_observation` for full text. New work on a possibly-visited topic: search proactively.
5. **After compaction:** `mem_session_summary` (recover) → `mem_context` → only then continue.
6. **Topic hygiene:** evolving topics reuse one `topic_key` (e.g. `architecture/auth-model`) via `mem_suggest_topic_key` before saving; one-offs stay separate. Conflicts from `mem_save`: resolve via `mem_judge_many` with per-candidate `judgment_id`; escalate to user only when confidence < 0.7 or (supersedes/conflicts_with × architecture/policy/decision). `mem_capture_passive` may batch-save "Key Learnings" sections (dedupes itself).
