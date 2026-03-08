from __future__ import annotations

from pathlib import Path

import pytest

from services import runtime_service


def test_build_plan_rejects_unsupported_platform(monkeypatch: pytest.MonkeyPatch) -> None:
    service = runtime_service.SonicService(repo_root=Path("/tmp/sonic"))
    monkeypatch.setattr(runtime_service, "is_supported", lambda: False)

    with pytest.raises(ValueError, match="Unsupported OS for build operations. Use Linux."):
        service.build_plan(dry_run=True)


def test_build_plan_resolves_repo_relative_paths(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    service = runtime_service.SonicService(repo_root=tmp_path)
    calls: dict[str, object] = {}

    monkeypatch.setattr(runtime_service, "is_supported", lambda: True)

    def fake_write_plan(**kwargs: object) -> dict[str, object]:
        calls.update(kwargs)
        return {"usb_device": kwargs["usb_device"], "dry_run": kwargs["dry_run"]}

    monkeypatch.setattr(runtime_service, "write_plan", fake_write_plan)

    result = service.build_plan(
        usb_device="/dev/sdz",
        dry_run=True,
        layout_file="config/custom-layout.json",
        out="memory/sonic/custom-manifest.json",
        payloads_dir="memory/sonic/artifacts/custom",
        format_mode="skip",
    )

    assert result["ok"] is True
    assert result["manifest_path"] == str(tmp_path / "memory" / "sonic" / "custom-manifest.json")
    assert calls["repo_root"] == tmp_path
    assert calls["layout_path"] == tmp_path / "config" / "custom-layout.json"
    assert calls["out_path"] == tmp_path / "memory" / "sonic" / "custom-manifest.json"
    assert calls["payload_dir"] == tmp_path / "memory" / "sonic" / "artifacts" / "custom"
    assert calls["format_mode"] == "skip"

