"""uDOS-sonic manifest utilities."""

import json
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional

ALLOWED_BOOT_MODES = {"uefi-native"}
ALLOWED_FORMAT_MODES = {"full", "skip"}


@dataclass
class PartitionSpec:
    name: str
    label: str
    fs: str
    size_gb: Optional[float] = None
    remainder: bool = False
    mount: Optional[str] = None
    format: bool = True
    flags: List[str] = field(default_factory=list)
    role: Optional[str] = None
    scalable: bool = False
    min_size_gb: Optional[float] = None
    max_size_gb: Optional[float] = None
    image: Optional[str] = None
    payload_dir: Optional[str] = None


@dataclass
class ControllerMappingSpec:
    id: str
    driver: str
    profile: str
    buttons: Dict[str, str] = field(default_factory=dict)
    notes: str = ""


@dataclass
class NavigationModuleSpec:
    id: str
    name: str
    shell: str
    entrypoint: str
    controller_mapping: str
    source_path: Optional[str] = None
    install_target: Optional[str] = None
    mode: str = "console"
    components: List[str] = field(default_factory=list)
    description: str = ""


@dataclass
class SurfaceSpec:
    id: str
    name: str
    os: str
    kind: str
    boot_target: str
    controller_mapping: str
    partition_refs: List[str] = field(default_factory=list)
    navigation_modules: List[str] = field(default_factory=list)
    default_shell: Optional[str] = None
    description: str = ""
    features: List[str] = field(default_factory=list)


@dataclass
class BootTargetSpec:
    id: str
    name: str
    surface_id: str
    os: str
    bootloader: str
    chain: str
    default: bool = False
    description: str = ""
    controller_mapping: Optional[str] = None
    entry_partition: Optional[str] = None
    features: List[str] = field(default_factory=list)


@dataclass
class SonicManifest:
    usb_device: str
    boot_mode: str
    repo_root: str
    payload_dir: str
    iso_dir: str
    flash_label: str = "FLASH"
    sonic_label: str = "SONIC"
    esp_label: str = "ESP"
    dry_run: bool = False
    format_mode: str = "full"
    auto_scale: bool = False
    install_profile: str = "uhome-steam-windows10-dualboot"
    profile_mode: str = "dual-boot"
    partitions: List[PartitionSpec] = field(default_factory=list)
    controller_mappings: List[ControllerMappingSpec] = field(default_factory=list)
    navigation_modules: List[NavigationModuleSpec] = field(default_factory=list)
    surfaces: List[SurfaceSpec] = field(default_factory=list)
    boot_targets: List[BootTargetSpec] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


def write_manifest(path: Path, manifest: SonicManifest) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(manifest.to_dict(), indent=2))


def read_manifest(path: Path) -> Optional[Dict[str, Any]]:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError:
        return None


def _resolve_manifest_path(base: Path, value: str) -> Path:
    candidate = Path(value)
    if candidate.is_absolute():
        return candidate
    return base / candidate


def _default_partitions() -> List[PartitionSpec]:
    return [
        PartitionSpec(
            name="esp",
            label="ESP",
            fs="fat32",
            size_gb=0.5,
            flags=["boot", "esp"],
            role="efi",
            payload_dir="efi",
        ),
        PartitionSpec(
            name="udos_ro",
            label="UDOS_RO",
            fs="squashfs",
            size_gb=8,
            role="udos",
            image="udos/udos.squashfs",
        ),
        PartitionSpec(
            name="udos_rw",
            label="UDOS_RW",
            fs="ext4",
            size_gb=8,
            mount="/mnt/udos",
            role="udos",
            scalable=True,
            min_size_gb=4,
            payload_dir="udos/rw",
        ),
        PartitionSpec(name="swap", label="SWAP", fs="swap", size_gb=8, role="swap"),
        PartitionSpec(
            name="uhome",
            label="UHOME",
            fs="ext4",
            size_gb=20,
            mount="/mnt/uhome",
            role="uhome",
            scalable=True,
            min_size_gb=12,
            payload_dir="uhome/system",
        ),
        PartitionSpec(
            name="win10",
            label="WIN10",
            fs="ntfs",
            size_gb=64,
            role="windows",
            scalable=True,
            min_size_gb=40,
            payload_dir="windows",
        ),
        PartitionSpec(
            name="media",
            label="MEDIA",
            fs="exfat",
            size_gb=32,
            mount="/mnt/media",
            role="media",
            scalable=True,
            min_size_gb=16,
            payload_dir="media",
        ),
        PartitionSpec(
            name="cache",
            label="CACHE",
            fs="ext4",
            remainder=True,
            mount="/mnt/cache",
            role="cache",
            scalable=True,
            min_size_gb=8,
            payload_dir="cache",
        ),
    ]


def _default_controller_mappings() -> List[ControllerMappingSpec]:
    return [
        ControllerMappingSpec(
            id="steam-xinput-hybrid",
            driver="steam-input",
            profile="steam-console",
            buttons={
                "a": "select",
                "b": "back",
                "x": "context",
                "y": "search",
                "lb": "previous-module",
                "rb": "next-module",
                "guide": "open-system-shell",
            },
            notes="Primary mapping for the uHOME Steam-side server surface.",
        ),
        ControllerMappingSpec(
            id="windows-xinput-console",
            driver="xinput",
            profile="windows-console",
            buttons={
                "a": "select",
                "b": "back",
                "x": "actions",
                "y": "launcher",
                "lb": "previous-tab",
                "rb": "next-tab",
                "guide": "open-overlay",
            },
            notes="Primary mapping for the Windows 10 gaming shell.",
        ),
    ]


def _default_navigation_modules() -> List[NavigationModuleSpec]:
    return [
        NavigationModuleSpec(
            id="uhome-home",
            name="uHOME Home",
            shell="steam-big-picture",
            entrypoint="/opt/uhome/bin/uhome-console --module home",
            controller_mapping="steam-xinput-hybrid",
            source_path="distribution/launchers/uhome/uhome-console.sh",
            install_target="/opt/uhome/bin/uhome-console",
            components=["uhome-kiosk", "jellyfin", "steam"],
            description="Primary controller-first home screen for the uHOME Steam server lane.",
        ),
        NavigationModuleSpec(
            id="uhome-library",
            name="uHOME Library",
            shell="steam-big-picture",
            entrypoint="/opt/uhome/bin/uhome-console --module library",
            controller_mapping="steam-xinput-hybrid",
            source_path="distribution/launchers/uhome/uhome-console.sh",
            install_target="/opt/uhome/bin/uhome-console",
            components=["jellyfin", "media-index", "steam"],
            description="Shared media and local content browser surfaced through the Steam shell.",
        ),
        NavigationModuleSpec(
            id="uhome-settings",
            name="uHOME Settings",
            shell="steam-big-picture",
            entrypoint="/opt/uhome/bin/uhome-console --module settings",
            controller_mapping="steam-xinput-hybrid",
            source_path="distribution/launchers/uhome/uhome-console.sh",
            install_target="/opt/uhome/bin/uhome-console",
            components=["network", "storage", "controllers"],
            description="Console-safe settings for the Linux/uHOME side.",
        ),
        NavigationModuleSpec(
            id="windows-home",
            name="Windows Home",
            shell="playnite-fullscreen",
            entrypoint="C:\\ProgramData\\Sonic\\Navigation\\WindowsHome.cmd",
            controller_mapping="windows-xinput-console",
            source_path="distribution/launchers/windows/WindowsHome.cmd",
            install_target="C:\\ProgramData\\Sonic\\Navigation\\WindowsHome.cmd",
            components=["playnite", "steam", "epic"],
            description="Primary gaming launcher shell on the Windows side.",
        ),
        NavigationModuleSpec(
            id="windows-library",
            name="Windows Library",
            shell="playnite-fullscreen",
            entrypoint="C:\\ProgramData\\Sonic\\Navigation\\WindowsLibrary.cmd",
            controller_mapping="windows-xinput-console",
            source_path="distribution/launchers/windows/WindowsLibrary.cmd",
            install_target="C:\\ProgramData\\Sonic\\Navigation\\WindowsLibrary.cmd",
            components=["steam", "playnite", "game-pass"],
            description="Game library browser and resume surface for Windows.",
        ),
        NavigationModuleSpec(
            id="windows-settings",
            name="Windows Settings",
            shell="playnite-fullscreen",
            entrypoint="C:\\ProgramData\\Sonic\\Navigation\\WindowsSettings.cmd",
            controller_mapping="windows-xinput-console",
            source_path="distribution/launchers/windows/WindowsSettings.cmd",
            install_target="C:\\ProgramData\\Sonic\\Navigation\\WindowsSettings.cmd",
            components=["display", "audio", "controller-calibration"],
            description="Controller-safe maintenance/settings shell for Windows 10 gaming mode.",
        ),
    ]


def _default_surfaces() -> List[SurfaceSpec]:
    return [
        SurfaceSpec(
            id="uhome-steam-server",
            name="uHOME Steam Server",
            os="linux",
            kind="uhome-server",
            boot_target="uhome-steam-console",
            controller_mapping="steam-xinput-hybrid",
            partition_refs=["udos_ro", "udos_rw", "uhome", "media", "cache"],
            navigation_modules=["uhome-home", "uhome-library", "uhome-settings"],
            default_shell="steam-big-picture",
            description="Linux-side uHOME server surface with a controller-first Steam shell.",
            features=["controller-first", "steam-console", "jellyfin-dvr", "media-server"],
        ),
        SurfaceSpec(
            id="windows10-gaming",
            name="Windows 10 Gaming Surface",
            os="windows",
            kind="gaming-console",
            boot_target="windows10-gaming-console",
            controller_mapping="windows-xinput-console",
            partition_refs=["win10", "media"],
            navigation_modules=["windows-home", "windows-library", "windows-settings"],
            default_shell="playnite-fullscreen",
            description="Windows 10 gaming shell with controller-first modular navigation.",
            features=["controller-first", "gaming", "launcher-shell", "windows10-ltsc"],
        ),
    ]


def _default_boot_targets() -> List[BootTargetSpec]:
    return [
        BootTargetSpec(
            id="uhome-steam-console",
            name="uHOME Steam Server",
            surface_id="uhome-steam-server",
            os="linux",
            bootloader="grub",
            chain="linux-efi",
            default=True,
            description="Default Linux-side boot target for the uHOME Steam server surface.",
            controller_mapping="steam-xinput-hybrid",
            entry_partition="esp",
            features=["default", "steam-console", "uhome-server"],
        ),
        BootTargetSpec(
            id="windows10-gaming-console",
            name="Windows 10 Gaming",
            surface_id="windows10-gaming",
            os="windows",
            bootloader="grub",
            chain="windows-efi",
            default=False,
            description="Chainloaded Windows 10 target for the gaming surface.",
            controller_mapping="windows-xinput-console",
            entry_partition="win10",
            features=["chainload", "gaming", "xinput"],
        ),
    ]


def validate_partitions(partitions: List[PartitionSpec]) -> None:
    remainder_count = sum(1 for p in partitions if p.remainder)
    if remainder_count > 1:
        raise ValueError("Only one remainder partition is allowed.")
    for p in partitions:
        if p.remainder:
            continue
        if p.size_gb is None or p.size_gb <= 0:
            raise ValueError(f"Partition '{p.name}' must define a positive size_gb.")


def _load_partitions(layout_path: Optional[Path]) -> List[PartitionSpec]:
    if not layout_path or not layout_path.exists():
        return _default_partitions()
    try:
        data = json.loads(layout_path.read_text())
    except json.JSONDecodeError:
        return _default_partitions()
    partitions = []
    for item in data.get("partitions", []):
        partitions.append(
            PartitionSpec(
                name=item.get("name", ""),
                label=item.get("label", ""),
                fs=item.get("fs", ""),
                size_gb=item.get("size_gb"),
                remainder=item.get("remainder", False),
                mount=item.get("mount"),
                format=item.get("format", True),
                flags=item.get("flags", []),
                role=item.get("role"),
                scalable=item.get("scalable", False),
                min_size_gb=item.get("min_size_gb"),
                max_size_gb=item.get("max_size_gb"),
                image=item.get("image"),
                payload_dir=item.get("payload_dir"),
            )
        )
    return partitions or _default_partitions()


def _load_format_mode(layout_path: Optional[Path]) -> Optional[str]:
    if not layout_path or not layout_path.exists():
        return None
    try:
        data = json.loads(layout_path.read_text())
    except json.JSONDecodeError:
        return None
    mode = data.get("format_mode")
    if mode in ALLOWED_FORMAT_MODES:
        return mode
    return None


def _load_auto_scale(layout_path: Optional[Path]) -> Optional[bool]:
    if not layout_path or not layout_path.exists():
        return None
    try:
        data = json.loads(layout_path.read_text())
    except json.JSONDecodeError:
        return None
    if "auto_scale" in data:
        return bool(data.get("auto_scale"))
    return None


def _load_text_field(layout_path: Optional[Path], key: str) -> Optional[str]:
    if not layout_path or not layout_path.exists():
        return None
    try:
        data = json.loads(layout_path.read_text())
    except json.JSONDecodeError:
        return None
    value = str(data.get(key) or "").strip()
    return value or None


def _load_controller_mappings(layout_path: Optional[Path]) -> List[ControllerMappingSpec]:
    if not layout_path or not layout_path.exists():
        return _default_controller_mappings()
    try:
        data = json.loads(layout_path.read_text())
    except json.JSONDecodeError:
        return _default_controller_mappings()
    items = data.get("controller_mappings")
    if not isinstance(items, list) or not items:
        return _default_controller_mappings()
    mappings: List[ControllerMappingSpec] = []
    for item in items:
        mappings.append(
            ControllerMappingSpec(
                id=str(item.get("id", "")),
                driver=str(item.get("driver", "")),
                profile=str(item.get("profile", "")),
                buttons=dict(item.get("buttons") or {}),
                notes=str(item.get("notes", "")),
            )
        )
    return mappings or _default_controller_mappings()


def _load_navigation_modules(layout_path: Optional[Path]) -> List[NavigationModuleSpec]:
    if not layout_path or not layout_path.exists():
        return _default_navigation_modules()
    try:
        data = json.loads(layout_path.read_text())
    except json.JSONDecodeError:
        return _default_navigation_modules()
    items = data.get("navigation_modules")
    if not isinstance(items, list) or not items:
        return _default_navigation_modules()
    modules: List[NavigationModuleSpec] = []
    for item in items:
        modules.append(
            NavigationModuleSpec(
                id=str(item.get("id", "")),
                name=str(item.get("name", "")),
                shell=str(item.get("shell", "")),
                entrypoint=str(item.get("entrypoint", "")),
                controller_mapping=str(item.get("controller_mapping", "")),
                source_path=item.get("source_path"),
                install_target=item.get("install_target"),
                mode=str(item.get("mode", "console")),
                components=[str(value) for value in (item.get("components") or [])],
                description=str(item.get("description", "")),
            )
        )
    return modules or _default_navigation_modules()


def _load_surfaces(layout_path: Optional[Path]) -> List[SurfaceSpec]:
    if not layout_path or not layout_path.exists():
        return _default_surfaces()
    try:
        data = json.loads(layout_path.read_text())
    except json.JSONDecodeError:
        return _default_surfaces()
    items = data.get("surfaces")
    if not isinstance(items, list) or not items:
        return _default_surfaces()
    surfaces: List[SurfaceSpec] = []
    for item in items:
        surfaces.append(
            SurfaceSpec(
                id=str(item.get("id", "")),
                name=str(item.get("name", "")),
                os=str(item.get("os", "")),
                kind=str(item.get("kind", "")),
                boot_target=str(item.get("boot_target", "")),
                controller_mapping=str(item.get("controller_mapping", "")),
                partition_refs=[str(value) for value in (item.get("partition_refs") or [])],
                navigation_modules=[str(value) for value in (item.get("navigation_modules") or [])],
                default_shell=item.get("default_shell"),
                description=str(item.get("description", "")),
                features=[str(value) for value in (item.get("features") or [])],
            )
        )
    return surfaces or _default_surfaces()


def _load_boot_targets(layout_path: Optional[Path]) -> List[BootTargetSpec]:
    if not layout_path or not layout_path.exists():
        return _default_boot_targets()
    try:
        data = json.loads(layout_path.read_text())
    except json.JSONDecodeError:
        return _default_boot_targets()
    items = data.get("boot_targets")
    if not isinstance(items, list) or not items:
        return _default_boot_targets()
    targets: List[BootTargetSpec] = []
    for item in items:
        targets.append(
            BootTargetSpec(
                id=str(item.get("id", "")),
                name=str(item.get("name", "")),
                surface_id=str(item.get("surface_id", "")),
                os=str(item.get("os", "")),
                bootloader=str(item.get("bootloader", "")),
                chain=str(item.get("chain", "")),
                default=bool(item.get("default", False)),
                description=str(item.get("description", "")),
                controller_mapping=item.get("controller_mapping"),
                entry_partition=item.get("entry_partition"),
                features=[str(value) for value in (item.get("features") or [])],
            )
        )
    return targets or _default_boot_targets()


def default_manifest(
    repo_root: Path,
    usb_device: str,
    dry_run: bool,
    layout_path: Optional[Path] = None,
    format_mode: Optional[str] = None,
    payload_dir: Optional[Path] = None,
) -> SonicManifest:
    runtime_root = repo_root / "memory" / "sonic"
    resolved_payload_dir = payload_dir or (runtime_root / "artifacts" / "payloads")
    iso_dir = runtime_root / "artifacts" / "images"
    resolved_format = format_mode or _load_format_mode(layout_path) or "full"
    resolved_auto_scale = _load_auto_scale(layout_path) or False
    partitions = _load_partitions(layout_path)
    validate_partitions(partitions)
    return SonicManifest(
        usb_device=usb_device,
        boot_mode="uefi-native",
        repo_root=str(repo_root),
        payload_dir=str(resolved_payload_dir),
        iso_dir=str(iso_dir),
        dry_run=dry_run,
        format_mode=resolved_format,
        auto_scale=resolved_auto_scale,
        install_profile=_load_text_field(layout_path, "install_profile") or "uhome-steam-windows10-dualboot",
        profile_mode=_load_text_field(layout_path, "profile_mode") or "dual-boot",
        partitions=partitions,
        controller_mappings=_load_controller_mappings(layout_path),
        navigation_modules=_load_navigation_modules(layout_path),
        surfaces=_load_surfaces(layout_path),
        boot_targets=_load_boot_targets(layout_path),
    )


def validate_manifest_data(manifest: Dict[str, Any], manifest_path: Optional[Path] = None) -> Dict[str, Any]:
    errors: List[str] = []
    warnings: List[str] = []
    required_keys = ["usb_device", "boot_mode", "repo_root", "payload_dir", "iso_dir", "partitions"]
    missing_keys = [key for key in required_keys if key not in manifest]
    if missing_keys:
        errors.append(f"missing required manifest keys: {', '.join(sorted(missing_keys))}")

    partitions_raw = manifest.get("partitions")
    partition_summaries: List[Dict[str, Any]] = []
    surface_summaries: List[Dict[str, Any]] = []
    boot_target_summaries: List[Dict[str, Any]] = []
    if not isinstance(partitions_raw, list) or not partitions_raw:
        errors.append("manifest must define at least one partition")
        partitions_raw = []

    boot_mode = manifest.get("boot_mode")
    if boot_mode and boot_mode not in ALLOWED_BOOT_MODES:
        errors.append(f"unsupported boot_mode '{boot_mode}'")

    format_mode = manifest.get("format_mode", "full")
    if format_mode not in ALLOWED_FORMAT_MODES:
        errors.append(f"unsupported format_mode '{format_mode}'")

    usb_device = str(manifest.get("usb_device", "")).strip()
    if usb_device and not usb_device.startswith("/dev/"):
        warnings.append(f"usb_device '{usb_device}' is not a Linux block-device path")

    repo_root_raw = str(manifest.get("repo_root", "")).strip()
    manifest_base = manifest_path.parent if manifest_path else Path.cwd()
    repo_root = _resolve_manifest_path(manifest_base, repo_root_raw) if repo_root_raw else None
    if repo_root is None:
        errors.append("manifest repo_root is required")
    elif not repo_root.exists():
        warnings.append(f"repo_root does not exist: {repo_root}")

    payload_dir_raw = str(manifest.get("payload_dir", "")).strip()
    iso_dir_raw = str(manifest.get("iso_dir", "")).strip()
    payload_dir = None
    iso_dir = None
    if repo_root is not None:
        if payload_dir_raw:
            payload_dir = _resolve_manifest_path(repo_root, payload_dir_raw)
            if not payload_dir.exists():
                warnings.append(f"payload_dir does not exist: {payload_dir}")
        else:
            errors.append("manifest payload_dir is required")
        if iso_dir_raw:
            iso_dir = _resolve_manifest_path(repo_root, iso_dir_raw)
            if not iso_dir.exists():
                warnings.append(f"iso_dir does not exist: {iso_dir}")
        else:
            errors.append("manifest iso_dir is required")

    seen_names: set[str] = set()
    seen_labels: set[str] = set()
    partition_names: set[str] = set()
    remainder_count = 0
    missing_payload_refs: List[str] = []

    for index, item in enumerate(partitions_raw):
        if not isinstance(item, dict):
            errors.append(f"partition #{index + 1} must be an object")
            continue
        name = str(item.get("name", "")).strip()
        label = str(item.get("label", "")).strip()
        fs = str(item.get("fs", "")).strip()
        remainder = bool(item.get("remainder", False))
        size_gb = item.get("size_gb")

        if not name:
            errors.append(f"partition #{index + 1} is missing name")
        elif name in seen_names:
            errors.append(f"duplicate partition name '{name}'")
        else:
            seen_names.add(name)
            partition_names.add(name)

        if not label:
            errors.append(f"partition '{name or index + 1}' is missing label")
        elif label in seen_labels:
            errors.append(f"duplicate partition label '{label}'")
        else:
            seen_labels.add(label)

        if not fs:
            errors.append(f"partition '{name or index + 1}' is missing fs")
        if remainder:
            remainder_count += 1
        elif not isinstance(size_gb, (int, float)) or float(size_gb) <= 0:
            errors.append(f"partition '{name or index + 1}' must define a positive size_gb")

        partition_summary = {
            "name": name,
            "label": label,
            "fs": fs,
            "remainder": remainder,
            "size_gb": size_gb,
            "role": item.get("role"),
        }

        for key in ("image", "payload_dir"):
            raw_ref = item.get(key)
            if not raw_ref:
                continue
            resolved_ref = None
            if payload_dir is not None:
                resolved_ref = _resolve_manifest_path(payload_dir, str(raw_ref))
                if not resolved_ref.exists():
                    missing_payload_refs.append(f"{name}:{key}:{resolved_ref}")
            partition_summary[f"{key}_path"] = str(resolved_ref) if resolved_ref else str(raw_ref)

        partition_summaries.append(partition_summary)

    if remainder_count > 1:
        errors.append("only one remainder partition is allowed")
    for ref in missing_payload_refs:
        warnings.append(f"missing payload reference: {ref}")

    controller_mappings_raw = manifest.get("controller_mappings", [])
    if controller_mappings_raw and not isinstance(controller_mappings_raw, list):
        errors.append("controller_mappings must be a list")
        controller_mappings_raw = []
    mapping_ids: set[str] = set()
    for index, item in enumerate(controller_mappings_raw):
        if not isinstance(item, dict):
            errors.append(f"controller mapping #{index + 1} must be an object")
            continue
        mapping_id = str(item.get("id", "")).strip()
        if not mapping_id:
            errors.append(f"controller mapping #{index + 1} is missing id")
            continue
        if mapping_id in mapping_ids:
            errors.append(f"duplicate controller mapping '{mapping_id}'")
            continue
        mapping_ids.add(mapping_id)

    modules_raw = manifest.get("navigation_modules", [])
    if modules_raw and not isinstance(modules_raw, list):
        errors.append("navigation_modules must be a list")
        modules_raw = []
    module_ids: set[str] = set()
    for index, item in enumerate(modules_raw):
        if not isinstance(item, dict):
            errors.append(f"navigation module #{index + 1} must be an object")
            continue
        module_id = str(item.get("id", "")).strip()
        if not module_id:
            errors.append(f"navigation module #{index + 1} is missing id")
            continue
        if module_id in module_ids:
            errors.append(f"duplicate navigation module '{module_id}'")
            continue
        module_ids.add(module_id)
        mapping_id = str(item.get("controller_mapping", "")).strip()
        if mapping_id and mapping_id not in mapping_ids:
            errors.append(f"navigation module '{module_id}' references unknown controller mapping '{mapping_id}'")
        source_path = str(item.get("source_path", "")).strip()
        if source_path and repo_root is not None:
            resolved_source = _resolve_manifest_path(repo_root, source_path)
            if not resolved_source.exists():
                errors.append(f"navigation module '{module_id}' references missing source_path '{resolved_source}'")

    surfaces_raw = manifest.get("surfaces", [])
    if surfaces_raw and not isinstance(surfaces_raw, list):
        errors.append("surfaces must be a list")
        surfaces_raw = []
    surface_ids: set[str] = set()
    for index, item in enumerate(surfaces_raw):
        if not isinstance(item, dict):
            errors.append(f"surface #{index + 1} must be an object")
            continue
        surface_id = str(item.get("id", "")).strip()
        if not surface_id:
            errors.append(f"surface #{index + 1} is missing id")
            continue
        if surface_id in surface_ids:
            errors.append(f"duplicate surface '{surface_id}'")
            continue
        surface_ids.add(surface_id)
        mapping_id = str(item.get("controller_mapping", "")).strip()
        if mapping_id and mapping_id not in mapping_ids:
            errors.append(f"surface '{surface_id}' references unknown controller mapping '{mapping_id}'")
        refs = item.get("partition_refs") or []
        if not isinstance(refs, list) or not refs:
            errors.append(f"surface '{surface_id}' must define partition_refs")
            refs = []
        for ref in refs:
            if str(ref) not in partition_names:
                errors.append(f"surface '{surface_id}' references unknown partition '{ref}'")
        nav_ids = item.get("navigation_modules") or []
        if not isinstance(nav_ids, list) or not nav_ids:
            errors.append(f"surface '{surface_id}' must define navigation_modules")
            nav_ids = []
        for module_id in nav_ids:
            if str(module_id) not in module_ids:
                errors.append(f"surface '{surface_id}' references unknown navigation module '{module_id}'")
        surface_summaries.append(
            {
                "id": surface_id,
                "name": item.get("name"),
                "os": item.get("os"),
                "kind": item.get("kind"),
                "boot_target": item.get("boot_target"),
                "partition_refs": refs,
                "navigation_modules": nav_ids,
            }
        )

    boot_targets_raw = manifest.get("boot_targets", [])
    if boot_targets_raw and not isinstance(boot_targets_raw, list):
        errors.append("boot_targets must be a list")
        boot_targets_raw = []
    default_boot_targets = 0
    seen_boot_target_ids: set[str] = set()
    for index, item in enumerate(boot_targets_raw):
        if not isinstance(item, dict):
            errors.append(f"boot target #{index + 1} must be an object")
            continue
        target_id = str(item.get("id", "")).strip()
        if not target_id:
            errors.append(f"boot target #{index + 1} is missing id")
            continue
        if target_id in seen_boot_target_ids:
            errors.append(f"duplicate boot target '{target_id}'")
            continue
        seen_boot_target_ids.add(target_id)
        surface_id = str(item.get("surface_id", "")).strip()
        if surface_id and surface_id not in surface_ids:
            errors.append(f"boot target '{target_id}' references unknown surface '{surface_id}'")
        mapping_id = str(item.get("controller_mapping", "")).strip()
        if mapping_id and mapping_id not in mapping_ids:
            errors.append(f"boot target '{target_id}' references unknown controller mapping '{mapping_id}'")
        entry_partition = str(item.get("entry_partition", "")).strip()
        if entry_partition and entry_partition not in partition_names:
            errors.append(f"boot target '{target_id}' references unknown entry_partition '{entry_partition}'")
        if bool(item.get("default", False)):
            default_boot_targets += 1
        boot_target_summaries.append(
            {
                "id": target_id,
                "name": item.get("name"),
                "surface_id": surface_id,
                "os": item.get("os"),
                "default": bool(item.get("default", False)),
                "entry_partition": item.get("entry_partition"),
            }
        )

    if default_boot_targets > 1:
        errors.append("only one boot target may be marked default")

    return {
        "ok": not errors,
        "errors": errors,
        "warnings": warnings,
        "required_keys": required_keys,
        "paths": {
            "manifest": str(manifest_path) if manifest_path else None,
            "repo_root": str(repo_root) if repo_root else repo_root_raw,
            "payload_dir": str(payload_dir) if payload_dir else payload_dir_raw,
            "iso_dir": str(iso_dir) if iso_dir else iso_dir_raw,
        },
        "summary": {
            "partition_count": len(partition_summaries),
            "remainder_partitions": remainder_count,
            "missing_payload_references": len(missing_payload_refs),
            "surface_count": len(surface_summaries),
            "boot_target_count": len(boot_target_summaries),
        },
        "partitions": partition_summaries,
        "surfaces": surface_summaries,
        "boot_targets": boot_target_summaries,
    }


def verify_manifest_path(path: Path) -> Dict[str, Any]:
    payload = read_manifest(path)
    if payload is None:
        return {
            "ok": False,
            "errors": [f"unable to read manifest: {path}"],
            "warnings": [],
            "paths": {"manifest": str(path)},
            "summary": {
                "partition_count": 0,
                "remainder_partitions": 0,
                "missing_payload_references": 0,
                "surface_count": 0,
                "boot_target_count": 0,
            },
            "partitions": [],
            "surfaces": [],
            "boot_targets": [],
        }
    return validate_manifest_data(payload, manifest_path=path)
