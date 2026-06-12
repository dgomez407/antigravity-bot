import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_pylint() -> None:
    """Run pylint to check code quality."""
    result = subprocess.run(
        [sys.executable, "-m", "pylint", "tests"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == 0, f"pylint failed:\n{result.stdout}\n{result.stderr}"
