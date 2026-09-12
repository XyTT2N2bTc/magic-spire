extends SceneTree

# Deliberately never quits; only tools/check.ps1 -VerifyRunner starts this probe.
func _initialize() -> void:
 print("TIMEOUT PROBE: waiting for runner termination")
