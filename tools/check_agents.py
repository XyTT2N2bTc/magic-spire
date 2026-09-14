"""Check active AGENTS.md files without scanning ignored dependencies."""

from pathlib import Path
import subprocess
import sys


def validate(path: str, data: bytes) -> list[str]:
    errors = []
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        return [f"{path}: expected UTF-8"]
    lines = text.splitlines()
    if len(lines) > 500:
        errors.append(f"{path}: {len(lines)} lines exceeds 500")
    if path == "AGENTS.md" and len(lines) < 200:
        errors.append(f"{path}: root requires at least 200 lines")
    if len(data) >= 10_000:
        errors.append(f"{path}: {len(data)} bytes must be below 10000")
    if not text.endswith("\n"):
        errors.append(f"{path}: missing final newline")
    for number, line in enumerate(lines, 1):
        if line.rstrip() != line or "\t" in line:
            errors.append(f"{path}:{number}: tab or trailing whitespace")
    return errors


def discover(root: Path) -> list[str]:
    output = subprocess.check_output(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
        cwd=root,
    )
    return sorted({
        name for name in output.decode("utf-8").split("\0")
        if name and Path(name).name.casefold() == "agents.md"
        and (root / name).is_file()
    })


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    try:
        paths = discover(root)
        errors = [] if "AGENTS.md" in paths else ["Root AGENTS.md is missing or ignored"]
        for path in paths:
            data = (root / path).read_bytes()
            errors.extend(validate(path, data))
            print(f"{path}: {len(data.splitlines())} lines, {len(data)} bytes")
    except (OSError, UnicodeError, subprocess.CalledProcessError) as error:
        print(f"AGENTS check failed: {error}", file=sys.stderr)
        return 1
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"PASS: {len(paths)} instruction files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
