"""Offline source inventory, not a translator or a proof of UI coverage.

Only writes the generated report under build/. Candidate hashes are review
identifiers, never production message IDs. Requires Python 3.10+, stdlib only.
"""
from collections import Counter
from hashlib import sha256
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
CATALOGS = ROOT / "assets/localization"
CJK = re.compile(r"[\u3400-\u9fff]")
KEY = re.compile(r"[a-z_][a-z_0-9]*(?:\.[a-z_][a-z_0-9]*)*\Z")
CALL = re.compile(r'(?<!\w)_text\(\s*"([a-z_0-9.]+)"\s*,\s*$')
ESCAPES = {"n": "\n", "r": "\r", "t": "\t", "b": "\b", "f": "\f"}


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"),
                      object_pairs_hook=unique_object)


def parameters(text):
    """Match runtime brace escaping and repeated named parameter counts."""
    counts = Counter()
    i = 0
    while i < len(text):
        ch = text[i]
        if ch in "{}" and text[i:i + 2] == ch * 2:
            i += 2
            continue
        if ch == "}":
            raise ValueError("unmatched closing brace")
        if ch != "{":
            i += 1
            continue
        end = text.find("}", i + 1)
        key = text[i + 1:end] if end >= 0 else ""
        if not KEY.fullmatch(key) or "." in key:
            raise ValueError("invalid named parameter")
        counts[key] += 1
        i = end + 1
    return dict(counts)


def strings(source):
    """GDScript/config string literals; skip comments, decode simple escapes.

    Preserve source positions for review, including repeated identical strings.
    This is a lexical inventory, not a semantic GDScript parser.
    """
    i = 0
    while i < len(source):
        if source[i] == "#":
            end = source.find("\n", i)
            i = len(source) if end < 0 else end + 1
            continue
        if source[i] not in "\"'":
            i += 1
            continue
        start = i
        quote = source[i]
        delimiter = quote * 3 if source[i:i + 3] == quote * 3 else quote
        i += len(delimiter)
        parts = []
        raw = start > 0 and source[start - 1] == "r"
        while i < len(source):
            if source.startswith(delimiter, i):
                i += len(delimiter)
                yield start, "".join(parts)
                break
            if source[i] == "\\" and i + 1 < len(source):
                nxt = source[i + 1]
                if raw:
                    parts.append(source[i:i + 2])
                elif nxt in ESCAPES:
                    parts.append(ESCAPES[nxt])
                elif nxt in ("\\", "\"", "'"):
                    parts.append(nxt)
                elif nxt == "\n":
                    pass
                else:
                    parts.append(source[i:i + 2])
                i += 2
            else:
                parts.append(source[i])
                i += 1
        else:
            raise ValueError(f"unterminated string at offset {start}")


def json_strings(value, pointer=""):
    if isinstance(value, str):
        yield pointer, value
    elif isinstance(value, dict):
        for key, item in value.items():
            escaped = key.replace("~", "~0").replace("/", "~1")
            yield from json_strings(item, pointer + "/" + escaped)
    elif isinstance(value, list):
        for i, item in enumerate(value):
            yield from json_strings(item, pointer + "/" + str(i))


def catalogs():
    base = read_json(CATALOGS / "zh_CN.json")
    assert set(base) == {"schema_version", "locale", "messages"}
    assert base["schema_version"] == 1 and base["locale"] == "zh_CN"
    messages = base["messages"]
    assert isinstance(messages, dict) and messages
    for key, entry in messages.items():
        assert KEY.fullmatch(key) and set(entry) == {"text", "context"}, key
        assert all(isinstance(value, str) and value.strip() for value in entry.values()), key
        parameters(entry["text"])
    coverage = {}
    for path in sorted(CATALOGS.glob("*.json")):
        if path.stem == "zh_CN":
            continue
        doc = read_json(path)
        assert set(doc) == {"schema_version", "locale", "messages"}, path.name
        assert doc["schema_version"] == 1 and doc["locale"] == path.stem, path.name
        assert isinstance(doc["messages"], dict), path.name
        count = 0
        for key, entry in doc["messages"].items():
            assert key in messages and set(entry) == {"source", "text"}, key
            assert entry["source"] == messages[key]["text"] and isinstance(entry["text"], str), key
            if entry["text"].strip():
                assert parameters(entry["text"]) == parameters(entry["source"]), key
                count += 1
        coverage[path.stem] = {"registered": len(messages), "translated": count,
                               "missing": len(messages) - count}
    return messages, coverage


def collect(messages):
    entries = []
    paths = {ROOT / "project.godot", *ROOT.glob("*.tscn")}
    for directory in ("core", "data", "ui", "content/packs"):
        paths.update(path for path in (ROOT / directory).rglob("*")
                     if path.suffix in (".gd", ".json", ".tscn", ".tres"))
    for path in sorted(paths):
        if path.name in ("chinese_collation.gd", "localization.gd"):
            continue
        relative = path.relative_to(ROOT).as_posix()
        source = path.read_text(encoding="utf-8-sig")
        values = json_strings(read_json(path)) if path.suffix == ".json" else strings(source)
        for location, text in values:
            if not CJK.search(text):
                continue
            entry = {"source": relative, "text": text, "status": "needs_review"}
            if isinstance(location, str):
                entry["pointer"] = location
            else:
                entry["line"] = source.count("\n", 0, location) + 1
                entry["column"] = location - source.rfind("\n", 0, location)
                call = CALL.search(source[max(0, location - 200):location])
                if call:
                    key = call.group(1)
                    assert key in messages and messages[key]["text"] == text, f"stale call: {relative}:{entry['line']} {key}"
                    entry.update(status="connected_static_call", key=key)
            # Stable within the same file/text, occurrence positions remain separate.
            entry["review_id"] = "review." + sha256((relative + "\0" + text).encode()).hexdigest()[:20]
            entry["legacy_format"] = bool(re.search(r"%[-+0-9.]*[sdf]|\{", text))
            entries.append(entry)
    return entries


def sanity_checks():
    assert list(strings('# "忽略"\nvar x="甲\\n乙" # "跳过"')) == [(13, "甲\n乙")]
    assert [v for _, v in strings("var a='甲';var b=\"\"\"乙\n丙\"\"\"")] == ["甲", "乙\n丙"]
    assert parameters("{{标签}}{name}{count}{name}") == {"name": 2, "count": 1}
    assert list(json_strings({"a/b": ["中文"]})) == [("/a~1b/0", "中文")]


def main():
    sanity_checks()
    messages, coverage = catalogs()
    entries = collect(messages)
    report = {"schema_version": 1,
              "notice": "Review candidates only; not full UI coverage. Dynamic calls and concatenated fragments require manual review. review_id is not a production message ID.",
              "scope": ["project.godot", "*.tscn", "core", "data", "ui", "content/packs"],
              "excluded": ["comments", "tests", "docs", "chinese_collation.gd", "localization.gd diagnostics", "embedded image text"],
              "catalog": messages, "coverage": coverage,
              "counts": dict(Counter(item["status"] for item in entries)), "entries": entries}
    output = ROOT / "build/localization/inventory.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(output), "counts": report["counts"], "coverage": coverage}, ensure_ascii=False))


if __name__ == "__main__":
    main()
