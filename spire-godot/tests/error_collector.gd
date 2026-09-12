extends Logger

# Engine errors can abort a case without aborting its caller. Count them before any PASS.
var mutex=Mutex.new()
var errors=0

func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
 if error_type==Logger.ERROR_TYPE_WARNING: return
 mutex.lock();errors+=1;mutex.unlock()

func count() -> int:
 mutex.lock();var result=errors;mutex.unlock()
 return result
