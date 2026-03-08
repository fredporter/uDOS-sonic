# Boot & Reboot Model

Status: migration source
Primary learning destination: `courses/01-deployment-fundamentals/lessons/03-boot-and-reboot.md`

## Boot Priority
1. uDOS Alpine (default)
2. Windows Gaming
3. Ubuntu Wizard

## Reboot Commands

```bash
reboot-to-windows
reboot-to-udos
reboot-to-wizard
```

Implemented via GRUB and EFI boot order manipulation.
