# Implementer report: keyword_ids stable IDs

Domain: `data/card_text.gd::keyword_ids` extracted from the existing `keywords()` TERMS-key collection; `keywords()` calls it then looks up `TERMS`. HEAD started at `0f8eea0`. Worktree `C:\1\magic-spire-wt-keyword-deps` only. `keyword_ids` landed.

## Extraction
Landed. Same SPECS / face / trait walk as today's `keywords()`, then first-occurrence unique TERMS keys. `keywords()` does not walk SPECS again. No `id` on `face_keywords` or TERMS entries. `TERMS` name/detail strings unchanged. `const TERMS` became `static var TERMS` so the Gherkin can mutate `.name` and restore (Godot 4.7 freezes `const` dictionaries). Slots still `SPECS.get("target_slots", [])`; mode still `Rules.face_mode`. No `card_facts` / `game.gd` walk / UI change.

## Commits (no push)
- `d921ab6` checkpoint(implementer): extract keyword_ids from keywords
- (this) `spire-godot/build/implementer-report.md`

## Check
- Command: `spire-godot/` `$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'; & tools/check.ps1 -Suite card_power -TimeoutSeconds 600`
- Exit: 0
- `SUITE RESULT: card_power PASS`
- `PASS: 2295 assertions`
- Summary: `spire-godot/build/checks/20260925T064606091-5292/summary.json`
- summary.status: `passed` (before==after fingerprint; not `source_changed`)
- docs: PASS (35 docs, 2412 refs)

First import-only attempt failed (`20260925T064205022-12076`, font `.fontdata` missing in a fresh worktree `.godot`). After engine import, `*.import` restored and two untracked `*.uid` files deleted; they were not committed. A TERMS-const mutate parse/runtime fail (`20260925T064327924-39996`, `20260925T064452659-31440`) is not a pass.

## Gherkin
`tests/card_text_cases.gd::card_keyword_deps_stable_ids` (registered in `run`): `Game.new(42)` `B.CARD_TRAITS`; pins `strain` / `slip` / `crossed_legs` / `strong_elbow` / `magic_hand` / `pot_of_greed` / `mana_search`. ids are TERMS keys in `keywords()` order; no `id` on keyword dicts; strain bound has `"strain"`, no slots, mode `"strain"`; crossed_legs slots `FOLLOW_THROUGH_REGIONS.legs`; strong_elbow `["upper_arm","forearm"]`; magic_hand bound has `"follow_through"` with display `超级顺延`; pot both faces `"exhaust"` and `face_keywords==[Text.TERMS.exhaust]`; mana_search `"search"`. After TERMS name mutate, ids/slots/mode unchanged; snapshot/rng frozen. Oracle does not use `term.name` / `requirements()` / `SLOT_NAMES` as ids. Existing TERMS/COPY assertions stayed green in the same card_power PASS.

## Unverified
- Not run: architecture / UI / hardener mutations
- Not this slice: `docs/spec`, `card_facts` consuming `keyword_ids`, T4/T5/delta
- Not claimed clean or hardened
- Size and ESM: not in project AGENTS.md. Touched counts: `data/card_text.gd` 176 lines; `tests/card_text_cases.gd` 176 lines
