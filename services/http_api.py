"""Local Sonic HTTP API backed by the shared runtime service layer."""

from __future__ import annotations

import argparse
import json
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

try:
    from services.runtime_service import SonicService
except ImportError:  # pragma: no cover - direct execution fallback
    import sys
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from services.runtime_service import SonicService


class SonicApiHandler(BaseHTTPRequestHandler):
    service: SonicService

    def do_OPTIONS(self) -> None:  # noqa: N802
        self.send_response(HTTPStatus.NO_CONTENT)
        self._write_headers()
        self.end_headers()

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        query = parse_qs(parsed.query)

        if parsed.path in {"/api/sonic/health", "/api/platform/sonic/health"}:
            return self._write_json(self.service.get_health())
        if parsed.path in {"/api/sonic/gui/summary", "/api/platform/sonic/gui/summary"}:
            return self._write_json(self.service.get_gui_summary())
        if parsed.path in {"/api/sonic/devices", "/api/platform/sonic/device/recommendations"}:
            return self._write_json(
                self.service.list_devices(
                    vendor=self._first(query, "vendor"),
                    reflash_potential=self._first(query, "reflash_potential"),
                    usb_boot=self._first(query, "usb_boot"),
                    uefi_native=self._first(query, "uefi_native"),
                    limit=self._int_arg(query, "limit", 100),
                    offset=self._int_arg(query, "offset", 0),
                )
            )
        if parsed.path in {"/api/sonic/schema", "/api/platform/sonic/schema"}:
            return self._write_json(self.service.get_schema())
        if parsed.path in {"/api/sonic/db/status", "/api/platform/sonic/db/status"}:
            return self._write_json(self.service.get_db_status())
        if parsed.path in {"/api/sonic/db/export", "/api/platform/sonic/db/export"}:
            return self._write_json(self.service.export_db())
        if parsed.path in {"/api/sonic/manifest/verify", "/api/platform/sonic/manifest/verify"}:
            return self._write_json(self.service.get_manifest_status(self._first(query, "path")))
        return self._write_json({"ok": False, "error": "not found", "path": parsed.path}, status=HTTPStatus.NOT_FOUND)

    def do_POST(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        payload = self._read_json_body()

        if parsed.path in {"/api/sonic/db/rebuild", "/api/platform/sonic/db/rebuild"}:
            return self._write_json(self.service.rebuild_db())
        if parsed.path in {"/api/sonic/bootstrap/current", "/api/platform/sonic/bootstrap/current"}:
            return self._write_json(self.service.bootstrap_current_machine())
        if parsed.path in {"/api/sonic/plan", "/api/platform/sonic/plan"}:
            try:
                result = self.service.build_plan(
                    usb_device=str(payload.get("usb_device") or "/dev/sdb"),
                    dry_run=bool(payload.get("dry_run", False)),
                    layout_file=payload.get("layout_file") or "config/sonic-layout.json",
                    out=payload.get("out"),
                    payloads_dir=payload.get("payloads_dir"),
                    format_mode=payload.get("format_mode"),
                )
            except ValueError as exc:
                return self._write_json({"ok": False, "error": str(exc)}, status=HTTPStatus.BAD_REQUEST)
            return self._write_json(result)

        return self._write_json({"ok": False, "error": "not found", "path": parsed.path}, status=HTTPStatus.NOT_FOUND)

    def log_message(self, format: str, *args: object) -> None:
        return

    def _write_json(self, payload: dict, *, status: HTTPStatus = HTTPStatus.OK) -> None:
        body = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(status)
        self._write_headers(content_length=len(body))
        self.end_headers()
        self.wfile.write(body)

    def _write_headers(self, *, content_length: int | None = None) -> None:
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        if content_length is not None:
            self.send_header("Content-Length", str(content_length))

    def _read_json_body(self) -> dict:
        length = int(self.headers.get("Content-Length", "0") or 0)
        if length <= 0:
            return {}
        raw = self.rfile.read(length)
        if not raw:
            return {}
        try:
            return json.loads(raw.decode("utf-8"))
        except json.JSONDecodeError:
            return {}

    @staticmethod
    def _first(query: dict[str, list[str]], key: str) -> str | None:
        values = query.get(key)
        return values[0] if values else None

    @staticmethod
    def _int_arg(query: dict[str, list[str]], key: str, default: int) -> int:
        value = SonicApiHandler._first(query, key)
        if value is None:
            return default
        try:
            return int(value)
        except ValueError:
            return default


def serve(*, host: str = "127.0.0.1", port: int = 8991, repo_root: Path | None = None) -> int:
    service = SonicService(repo_root=repo_root)

    class BoundSonicApiHandler(SonicApiHandler):
        pass

    BoundSonicApiHandler.service = service
    server = ThreadingHTTPServer((host, port), BoundSonicApiHandler)
    print(f"Sonic API listening on http://{host}:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Serve the Sonic HTTP API")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8991)
    parser.add_argument("--repo-root", default=str(Path(__file__).resolve().parents[1]))
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    return serve(host=args.host, port=args.port, repo_root=Path(args.repo_root))


if __name__ == "__main__":
    raise SystemExit(main())
