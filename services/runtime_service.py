"""Canonical Sonic runtime service layer for CLI, HTTP, and MCP surfaces."""

from __future__ import annotations

import json
import os
import platform
import sqlite3
import sys
from dataclasses import asdict
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:  # pragma: no cover - direct script execution
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from services.os_limits import detect_platform, is_supported, os_capabilities, support_message
from services.manifest import default_manifest, read_manifest, validate_manifest_data
from services.planner import write_plan


class SonicService:
    """Expose Sonic operations through the canonical USB installer backend."""

    def __init__(self, repo_root: Path | None = None) -> None:
        self.repo_root = (repo_root or Path(__file__).resolve().parents[1]).resolve()
        self.runtime_root = self.repo_root / "memory" / "sonic"
        self.manifest_path = self.runtime_root / "sonic-manifest.json"
        self.seed_sql_path = self.repo_root / "datasets" / "sonic-devices.sql"
        self.seed_db_path = self.runtime_root / "seed" / "sonic-devices.seed.db"
        self.user_db_path = self.runtime_root / "user" / "sonic-devices.user.db"
        self.legacy_db_path = self.runtime_root / "sonic-devices.db"

    def build_plan(
        self,
        *,
        usb_device: str = "/dev/sdb",
        dry_run: bool = False,
        layout_file: str | None = "config/sonic-layout.json",
        out: str | None = None,
        payloads_dir: str | None = None,
        format_mode: str | None = None,
    ) -> dict[str, Any]:
        if not is_supported():
            raise ValueError("Unsupported OS for build operations. Use Linux.")
        out_path = self._resolve_repo_path(out) if out else self.manifest_path
        layout_path = self._resolve_repo_path(layout_file) if layout_file else None
        payload_dir = self._resolve_repo_path(payloads_dir) if payloads_dir else None
        plan = write_plan(
            repo_root=self.repo_root,
            usb_device=usb_device,
            dry_run=dry_run,
            layout_path=layout_path,
            format_mode=format_mode,
            payload_dir=payload_dir,
            out_path=out_path,
        )
        return {
            "ok": True,
            "message": "plan written",
            "manifest_path": str(out_path),
            "plan": plan,
        }

    def get_manifest_status(self, manifest_path: str | None = None) -> dict[str, Any]:
        path = self._resolve_repo_path(manifest_path) if manifest_path else self.manifest_path
        manifest = read_manifest(path)
        if manifest is None:
            return {
                "ok": False,
                "errors": [f"unable to read manifest: {path}"],
                "warnings": [],
                "paths": {"manifest": str(path)},
                "summary": {"partition_count": 0, "remainder_partitions": 0, "missing_payload_references": 0},
                "partitions": [],
            }
        return validate_manifest_data(manifest, manifest_path=path)

    def get_health(self) -> dict[str, Any]:
        db_status = self.get_db_status()
        manifest_status = self.get_manifest_status()
        payload_dir = self.runtime_root / "artifacts" / "payloads"
        return {
            "ok": is_supported(),
            "platform": detect_platform(),
            "capabilities": os_capabilities(),
            "message": support_message(),
            "paths": {
                "repo_root": str(self.repo_root),
                "runtime_root": str(self.runtime_root),
                "payload_dir": str(payload_dir),
                "manifest": str(self.manifest_path),
            },
            "artifacts": {
                "manifest_present": self.manifest_path.exists(),
                "payload_dir_present": payload_dir.exists(),
            },
            "db": db_status,
            "manifest": {
                "ok": manifest_status["ok"],
                "warnings": manifest_status.get("warnings", []),
                "errors": manifest_status.get("errors", []),
            },
        }

    def get_gui_summary(self) -> dict[str, Any]:
        db_status = self.get_db_status()
        manifest_status = self.get_manifest_status()
        default_layout = default_manifest(
            repo_root=self.repo_root,
            usb_device="/dev/sdX",
            dry_run=True,
            layout_path=self.repo_root / "config" / "sonic-layout.json",
        )
        boot_modes = [
            {
                "name": surface.name,
                "role": surface.kind,
                "detail": surface.description,
                "status": "default"
                if any(target.surface_id == surface.id and target.default for target in default_layout.boot_targets)
                else "secondary",
            }
            for surface in default_layout.surfaces
        ]
        build_pulse = [
            f"Profile: {default_layout.install_profile}",
            "Stage 1: Partition table (UEFI dual-boot)",
            "Stage 2: uDOS base image + persistence",
            "Stage 3: uHOME Steam server surface",
            "Stage 4: Windows 10 gaming surface",
            "Stage 5: GRUB boot target registration",
        ]
        return {
            "ok": True,
            "headline": "Dual-boot disk for uHOME Steam Server and Windows 10 Gaming.",
            "summary": {
                "platform": detect_platform(),
                "supported": is_supported(),
                "manifest_ok": manifest_status["ok"],
                "device_records": db_status["summary"]["device_count"],
                "install_profile": default_layout.install_profile,
                "profile_mode": default_layout.profile_mode,
            },
            "boot_modes": boot_modes,
            "partitions": [asdict(partition) for partition in default_layout.partitions],
            "surfaces": [asdict(surface) for surface in default_layout.surfaces],
            "boot_targets": [asdict(target) for target in default_layout.boot_targets],
            "controller_mappings": [asdict(mapping) for mapping in default_layout.controller_mappings],
            "navigation_modules": [asdict(module) for module in default_layout.navigation_modules],
            "build_pulse": build_pulse,
            "db": db_status,
            "manifest": manifest_status,
        }

    def get_db_status(self) -> dict[str, Any]:
        self._ensure_seed_catalog()
        devices = self.list_devices(limit=1000)
        return {
            "ok": True,
            "paths": {
                "seed_sql": str(self.seed_sql_path),
                "seed_db": str(self.seed_db_path),
                "user_db": str(self.user_db_path),
                "legacy_db": str(self.legacy_db_path),
            },
            "artifacts": {
                "seed_sql_present": self.seed_sql_path.exists(),
                "seed_db_present": self.seed_db_path.exists(),
                "user_db_present": self.user_db_path.exists(),
                "legacy_db_present": self.legacy_db_path.exists(),
            },
            "summary": {
                "device_count": len(devices["items"]),
                "seed_db_size_bytes": self.seed_db_path.stat().st_size if self.seed_db_path.exists() else 0,
            },
        }

    def rebuild_db(self) -> dict[str, Any]:
        self._ensure_seed_catalog(force=True)
        return self.get_db_status()

    def export_db(self) -> dict[str, Any]:
        devices = self.list_devices(limit=1000)
        return {
            "ok": True,
            "count": len(devices["items"]),
            "items": devices["items"],
        }

    def get_schema(self) -> dict[str, Any]:
        schema_path = self.repo_root / "datasets" / "sonic-devices.schema.json"
        if not schema_path.exists():
            return {"ok": False, "error": f"schema missing: {schema_path}"}
        return {"ok": True, "schema": json.loads(schema_path.read_text(encoding="utf-8"))}

    def bootstrap_current_machine(self) -> dict[str, Any]:
        self._ensure_seed_catalog()
        self._ensure_user_catalog()
        record = {
            "id": f"current-{platform.node().lower().replace(' ', '-') or 'machine'}",
            "vendor": platform.system(),
            "model": platform.machine(),
            "variant": "current-machine",
            "year": 2026,
            "cpu": platform.processor() or "unknown",
            "gpu": "unknown",
            "ram_gb": 0,
            "storage_gb": 0,
            "bios": "unknown",
            "secure_boot": "unknown",
            "tpm": "unknown",
            "usb_boot": "unknown",
            "uefi_native": "unknown",
            "reflash_potential": "unknown",
            "methods": json.dumps(["sonic_usb"]),
            "notes": "Bootstrapped from local Sonic service.",
            "sources": json.dumps([]),
            "last_seen": "2026-03-07",
            "windows10_boot": "unknown",
            "media_mode": "unknown",
            "udos_launcher": "unknown",
            "wizard_profile": None,
            "media_launcher": None,
            "settings_template_md": None,
            "installers_template_md": None,
            "containers_template_md": None,
            "drivers_template_md": None,
        }
        columns = list(record.keys())
        placeholders = ", ".join("?" for _ in columns)
        sql = f"INSERT OR REPLACE INTO devices ({', '.join(columns)}) VALUES ({placeholders})"
        connection = sqlite3.connect(self.user_db_path)
        try:
            connection.execute(sql, [record[column] for column in columns])
            connection.commit()
        finally:
            connection.close()
        return {"ok": True, "record": record}

    def list_devices(
        self,
        *,
        vendor: str | None = None,
        reflash_potential: str | None = None,
        usb_boot: str | None = None,
        uefi_native: str | None = None,
        limit: int = 100,
        offset: int = 0,
    ) -> dict[str, Any]:
        self._ensure_seed_catalog()
        devices = self._load_device_rows(self.seed_db_path)
        user_rows = self._load_device_rows(self.user_db_path)

        merged: dict[str, dict[str, Any]] = {row["id"]: row for row in devices if row.get("id")}
        for row in user_rows:
            row_id = row.get("id")
            if row_id:
                merged[row_id] = row

        filtered = list(merged.values())
        filtered.sort(key=lambda item: item.get("id", ""))

        for key, value in (
            ("vendor", vendor),
            ("reflash_potential", reflash_potential),
            ("usb_boot", usb_boot),
            ("uefi_native", uefi_native),
        ):
            if value:
                needle = value.strip().lower()
                filtered = [item for item in filtered if str(item.get(key, "")).lower() == needle]

        total = len(filtered)
        page = filtered[offset : offset + max(limit, 0)]
        return {"ok": True, "items": page, "total": total, "limit": limit, "offset": offset}

    def _ensure_seed_catalog(self, *, force: bool = False) -> None:
        if not self.seed_sql_path.exists():
            return
        if self.seed_db_path.exists() and not force:
            return
        self.seed_db_path.parent.mkdir(parents=True, exist_ok=True)
        connection = sqlite3.connect(self.seed_db_path)
        try:
            connection.executescript(self.seed_sql_path.read_text(encoding="utf-8"))
            connection.commit()
        finally:
            connection.close()
        self._mirror_seed_catalog()

    def _ensure_user_catalog(self) -> None:
        if self.user_db_path.exists() and self._db_has_devices_table(self.user_db_path):
            return
        self.user_db_path.parent.mkdir(parents=True, exist_ok=True)
        connection = sqlite3.connect(self.user_db_path)
        try:
            connection.executescript(self.seed_sql_path.read_text(encoding="utf-8"))
            connection.commit()
        finally:
            connection.close()

    def _mirror_seed_catalog(self) -> None:
        if not self.seed_db_path.exists():
            return
        self.legacy_db_path.parent.mkdir(parents=True, exist_ok=True)
        self.legacy_db_path.write_bytes(self.seed_db_path.read_bytes())

    def _load_device_rows(self, db_path: Path) -> list[dict[str, Any]]:
        if not db_path.exists():
            return []
        connection = sqlite3.connect(db_path)
        connection.row_factory = sqlite3.Row
        try:
            rows = connection.execute("SELECT * FROM devices").fetchall()
        except sqlite3.OperationalError:
            return []
        finally:
            connection.close()
        items: list[dict[str, Any]] = []
        for row in rows:
            item = dict(row)
            for field in ("methods", "sources"):
                raw = item.get(field)
                if isinstance(raw, str):
                    try:
                        item[field] = json.loads(raw)
                    except json.JSONDecodeError:
                        item[field] = raw
            item["windows"] = item.get("windows10_boot")
            item["media"] = item.get("media_mode")
            item["boot"] = item.get("uefi_native")
            items.append(item)
        return items

    def _db_has_devices_table(self, db_path: Path) -> bool:
        if not db_path.exists():
            return False
        connection = sqlite3.connect(db_path)
        try:
            row = connection.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'devices'"
            ).fetchone()
        finally:
            connection.close()
        return bool(row)

    def _resolve_repo_path(self, value: str | os.PathLike[str]) -> Path:
        candidate = Path(value)
        if candidate.is_absolute():
            return candidate
        return self.repo_root / candidate
