"""Thin MCP facade for Sonic service operations."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

try:
    from services.runtime_service import SonicService
except ImportError:  # pragma: no cover - direct execution fallback
    import sys
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from services.runtime_service import SonicService

SERVER_INFO = {"name": "sonic-mcp", "version": "1.5.5"}
PROTOCOL_VERSION = "2025-06-18"


class SonicMcpServer:
    def __init__(self, repo_root: Path | None = None) -> None:
        self.service = SonicService(repo_root=repo_root)

    def run(self) -> int:
        for line in sys.stdin:
            raw = line.strip()
            if not raw:
                continue
            try:
                request = json.loads(raw)
                response = self.handle(request)
            except Exception as exc:  # pragma: no cover
                response = {"jsonrpc": "2.0", "id": None, "error": {"code": -32603, "message": str(exc)}}
            sys.stdout.write(json.dumps(response) + "\n")
            sys.stdout.flush()
        return 0

    def handle(self, request: dict[str, Any]) -> dict[str, Any]:
        request_id = request.get("id")
        method = request.get("method")
        params = request.get("params", {})

        if method == "initialize":
            return self._result(
                request_id,
                {
                    "protocolVersion": PROTOCOL_VERSION,
                    "serverInfo": SERVER_INFO,
                    "capabilities": {"tools": {"listChanged": False}},
                },
            )
        if method == "notifications/initialized":
            return self._result(request_id, {})
        if method == "tools/list":
            return self._result(request_id, {"tools": self._tools()})
        if method == "tools/call":
            return self._call_tool(request_id, params)

        return self._error(request_id, -32601, f"method not found: {method}")

    def _call_tool(self, request_id: Any, params: dict[str, Any]) -> dict[str, Any]:
        name = params.get("name")
        arguments = params.get("arguments") or {}

        if name == "sonic_health":
            payload = self.service.get_health()
        elif name == "sonic_gui_summary":
            payload = self.service.get_gui_summary()
        elif name == "sonic_devices":
            payload = self.service.list_devices(
                vendor=arguments.get("vendor"),
                reflash_potential=arguments.get("reflash_potential"),
                usb_boot=arguments.get("usb_boot"),
                uefi_native=arguments.get("uefi_native"),
                limit=int(arguments.get("limit", 100)),
                offset=int(arguments.get("offset", 0)),
            )
        elif name == "sonic_schema":
            payload = self.service.get_schema()
        elif name == "sonic_db_status":
            payload = self.service.get_db_status()
        elif name == "sonic_db_rebuild":
            payload = self.service.rebuild_db()
        elif name == "sonic_bootstrap_current":
            payload = self.service.bootstrap_current_machine()
        elif name == "sonic_plan":
            payload = self.service.build_plan(
                usb_device=str(arguments.get("usb_device") or "/dev/sdb"),
                dry_run=bool(arguments.get("dry_run", False)),
                layout_file=arguments.get("layout_file") or "config/sonic-layout.json",
                out=arguments.get("out"),
                payloads_dir=arguments.get("payloads_dir"),
                format_mode=arguments.get("format_mode"),
            )
        elif name == "sonic_manifest_verify":
            payload = self.service.get_manifest_status(arguments.get("path"))
        else:
            return self._error(request_id, -32602, f"unknown tool: {name}")

        return self._result(
            request_id,
            {
                "content": [{"type": "text", "text": json.dumps(payload, indent=2)}],
                "structuredContent": payload,
                "isError": not bool(payload.get("ok", True)),
            },
        )

    def _tools(self) -> list[dict[str, Any]]:
        return [
            {
                "name": "sonic_health",
                "title": "Sonic Health",
                "description": "Return Sonic platform, manifest, and catalog health.",
                "inputSchema": {"type": "object", "properties": {}},
            },
            {
                "name": "sonic_gui_summary",
                "title": "Sonic GUI Summary",
                "description": "Return the browser GUI summary model for Sonic.",
                "inputSchema": {"type": "object", "properties": {}},
            },
            {
                "name": "sonic_devices",
                "title": "Sonic Devices",
                "description": "List devices from the merged Sonic catalog.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "vendor": {"type": "string"},
                        "reflash_potential": {"type": "string"},
                        "usb_boot": {"type": "string"},
                        "uefi_native": {"type": "string"},
                        "limit": {"type": "integer"},
                        "offset": {"type": "integer"},
                    },
                },
            },
            {
                "name": "sonic_db_status",
                "title": "Sonic DB Status",
                "description": "Return catalog database artifact status.",
                "inputSchema": {"type": "object", "properties": {}},
            },
            {
                "name": "sonic_schema",
                "title": "Sonic Schema",
                "description": "Return the Sonic device catalog JSON schema.",
                "inputSchema": {"type": "object", "properties": {}},
            },
            {
                "name": "sonic_db_rebuild",
                "title": "Sonic DB Rebuild",
                "description": "Rebuild the Sonic seed database from the SQL dataset.",
                "inputSchema": {"type": "object", "properties": {}},
            },
            {
                "name": "sonic_bootstrap_current",
                "title": "Sonic Bootstrap Current",
                "description": "Register the current machine in the local user catalog.",
                "inputSchema": {"type": "object", "properties": {}},
            },
            {
                "name": "sonic_plan",
                "title": "Sonic Plan",
                "description": "Generate a Sonic manifest plan.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "usb_device": {"type": "string"},
                        "dry_run": {"type": "boolean"},
                        "layout_file": {"type": "string"},
                        "out": {"type": "string"},
                        "payloads_dir": {"type": "string"},
                        "format_mode": {"type": "string", "enum": ["full", "skip"]},
                    },
                },
            },
            {
                "name": "sonic_manifest_verify",
                "title": "Sonic Manifest Verify",
                "description": "Validate a Sonic manifest file.",
                "inputSchema": {
                    "type": "object",
                    "properties": {"path": {"type": "string"}},
                },
            },
        ]

    @staticmethod
    def _result(request_id: Any, result: dict[str, Any]) -> dict[str, Any]:
        return {"jsonrpc": "2.0", "id": request_id, "result": result}

    @staticmethod
    def _error(request_id: Any, code: int, message: str) -> dict[str, Any]:
        return {"jsonrpc": "2.0", "id": request_id, "error": {"code": code, "message": message}}


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the Sonic MCP facade")
    parser.add_argument("--repo-root", default=str(Path(__file__).resolve().parents[1]))
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    return SonicMcpServer(repo_root=Path(args.repo_root)).run()


if __name__ == "__main__":
    raise SystemExit(main())
