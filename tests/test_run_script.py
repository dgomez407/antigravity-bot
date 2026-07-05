from pathlib import Path
import os
import shutil
import subprocess

import pytest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "run.sh"
GIT_BASH = Path(os.environ.get("ProgramFiles", r"C:\Program Files")) / "Git/bin/bash.exe"
BASH = str(GIT_BASH) if GIT_BASH.exists() else shutil.which("bash")


def run_script(*args: str) -> subprocess.CompletedProcess[str]:
    assert BASH is not None
    return subprocess.run(
        [BASH, "./run.sh", *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=10,
        check=False,
    )


@pytest.mark.skipif(BASH is None, reason="Git Bash is required")
def test_script_has_valid_bash_syntax() -> None:
    result = subprocess.run(
        [BASH, "-n", "./run.sh"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=10,
        check=False,
    )
    assert result.returncode == 0, result.stderr


@pytest.mark.skipif(BASH is None, reason="Git Bash is required")
def test_no_arguments_show_help_instead_of_starting() -> None:
    result = run_script()
    assert result.returncode == 0
    assert "Usage:" in result.stdout
    assert "./run.sh <command> [option]" in result.stdout


@pytest.mark.skipif(BASH is None, reason="Git Bash is required")
def test_help_lists_lifecycle_commands() -> None:
    result = run_script("--help")
    assert result.returncode == 0
    for command in ("start", "stop", "status", "repair-sessions", "build-lazygravity", "doctor", "cdp-status"):
        assert command in result.stdout


@pytest.mark.skipif(BASH is None, reason="Git Bash is required")
def test_unknown_command_fails_with_usage_hint() -> None:
    result = run_script("launch")
    assert result.returncode == 2
    assert "Unknown option: launch" in result.stderr
    assert "./run.sh --help" in result.stderr


def test_start_removes_independently_verified_stale_lazygravity_lock() -> None:
    source = SCRIPT.read_text(encoding="utf-8")
    stale_check = 'if [[ -f "$LAZY_GRAVITY_LOCK_FILE" ]]; then'
    lock_removal = 'rm -f "$LAZY_GRAVITY_LOCK_FILE"'

    assert stale_check in source
    assert lock_removal in source
    assert source.index(stale_check) < source.index(lock_removal)


def test_start_adopts_lazygravity_lock_pid_instead_of_wrapper_pid() -> None:
    source = SCRIPT.read_text(encoding="utf-8")

    assert 'if lazy_gravity_is_running; then' in source
    assert 'pid="$(read_lazy_gravity_pid)"' in source
    assert 'LazyGravity did not publish a live lock PID' in source


def test_launcher_targets_lazygravity_compatible_antigravity_ide() -> None:
    source = SCRIPT.read_text(encoding="utf-8")
    env_file = ROOT / ".env"
    if not env_file.exists():
        env_file = ROOT / ".env.example"
    env_source = env_file.read_text(encoding="utf-8")

    assert "Programs/Antigravity IDE/Antigravity IDE.exe" in source
    assert "Antigravity IDE/Antigravity IDE.exe" in env_source
    assert 'workbench/workbench.html' in source


def test_session_repair_is_scoped_and_backed_up() -> None:
    source = SCRIPT.read_text(encoding="utf-8")

    assert "local backup_file='antigravity.db.backup'" in source
    assert "is_renamed=1 and conversation_id is null" in source
    assert "update chat_sessions set display_name=null, is_renamed=0" in source


def test_start_builds_and_runs_local_lazygravity_submodule() -> None:
    source = SCRIPT.read_text(encoding="utf-8")

    assert "build_lazy_gravity" in source
    assert "vendor/LazyGravity" in source
    assert 'node "$LAZY_GRAVITY_CLI" --verbose start' in source
