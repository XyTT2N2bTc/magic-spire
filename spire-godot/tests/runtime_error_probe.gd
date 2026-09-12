extends RefCounted

# Deliberate negative fixture, only invoked by --probe-runtime-error.
static func run() -> void:
 var missing: Dictionary={}
 print(missing["deliberate_missing_test_key"])
