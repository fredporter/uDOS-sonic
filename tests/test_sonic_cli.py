from __future__ import annotations

import importlib.util
from pathlib import Path


CLI_PATH = Path(__file__).resolve().parents[1] / "apps" / "sonic-cli" / "cli.py"
CLI_SPEC = importlib.util.spec_from_file_location("sonic_cli_test_module", CLI_PATH)
assert CLI_SPEC is not None
assert CLI_SPEC.loader is not None
cli = importlib.util.module_from_spec(CLI_SPEC)
CLI_SPEC.loader.exec_module(cli)


def test_plan_command_rejects_unsupported_platform(monkeypatch, capsys) -> None:
    monkeypatch.setattr(cli, "support_message", lambda: "WARN Linux only")
    monkeypatch.setattr(cli, "is_supported", lambda: False)
    monkeypatch.setattr(cli.sys, "argv", ["cli.py", "plan", "--dry-run"])

    exit_code = cli.main()

    captured = capsys.readouterr()
    assert exit_code == 1
    assert "WARN Linux only" in captured.out
    assert "ERROR Unsupported OS for build operations. Use Linux." in captured.out


def test_plan_command_writes_plan_with_repo_root(monkeypatch, tmp_path: Path, capsys) -> None:
    calls: dict[str, object] = {}

    monkeypatch.setattr(cli, "support_message", lambda: "WARN Linux only")
    monkeypatch.setattr(cli, "is_supported", lambda: True)

    def fake_write_plan(**kwargs: object) -> dict[str, object]:
        calls.update(kwargs)
        return {"ok": True}

    monkeypatch.setattr(cli, "write_plan", fake_write_plan)
    monkeypatch.setattr(
        cli.sys,
        "argv",
        [
            "cli.py",
            "plan",
            "--repo-root",
            str(tmp_path),
            "--usb-device",
            "/dev/sdz",
            "--dry-run",
            "--layout-file",
            "config/test-layout.json",
            "--out",
            "memory/sonic/test-manifest.json",
            "--payloads-dir",
            "memory/sonic/artifacts/custom",
            "--format-mode",
            "skip",
        ],
    )

    exit_code = cli.main()

    captured = capsys.readouterr()
    assert exit_code == 0
    assert "Plan written: memory/sonic/test-manifest.json" in captured.out
    assert calls["repo_root"] == tmp_path
    assert calls["usb_device"] == "/dev/sdz"
    assert calls["dry_run"] is True
    assert calls["layout_path"] == Path("config/test-layout.json")
    assert calls["out_path"] == Path("memory/sonic/test-manifest.json")
    assert calls["payload_dir"] == Path("memory/sonic/artifacts/custom")
    assert calls["format_mode"] == "skip"
