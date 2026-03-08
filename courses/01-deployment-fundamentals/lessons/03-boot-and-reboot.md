# Lesson 03 - Boot And Reboot Model

Sonic deployments need a predictable boot story.

The older lesson docs describe a simple priority model:

1. primary Linux environment
2. Windows gaming surface
3. auxiliary orchestration or recovery surface

The exact targets may vary by profile, but the teaching point is stable:

- boot targets must be explicit
- reboot routing must be reviewable
- GRUB or EFI handoff logic should never feel magical

When Sonic plans a deployment, boot targets and surface metadata should appear
in the manifest so the learner can inspect them before any destructive step.
