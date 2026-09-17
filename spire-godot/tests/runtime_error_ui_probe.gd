extends RefCounted

# Deliberate negative fixture, only loaded by ui_smoke.gd under
# --probe-module-runtime-error. It errors after an await inside its own run(), so
# the probe proves that a script error inside the awaited module coroutine returns
# control to the host (the alternative would hang the module). Not a *_cases.gd
# file on purpose: it is not a registered suite and has no owner.
static func run(t) -> void:
 await t.frames()
 var missing: Dictionary={}
 print(missing["deliberate_missing_test_key"])
