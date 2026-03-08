# Course 01 Project

Project: create and inspect a dry-run USB deployment plan.

Suggested flow:

1. read the layout in `config/sonic-layout.json`
2. run `python3 apps/sonic-cli/cli.py plan --usb-device /dev/sdb --dry-run --out memory/sonic/sonic-manifest.json`
3. inspect the generated manifest
4. identify partition roles, boot targets, and any payload references
5. explain which parts are safe planning output and which parts become destructive only during apply
