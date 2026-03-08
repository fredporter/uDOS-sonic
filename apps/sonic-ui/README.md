# Sonic UI

This is the public browser UI surface for Sonic.

Current implementation now lives directly in this folder.

The UI consumes the Sonic HTTP API rather than duplicating provisioning logic
in the browser.

Educational role:

- help learners inspect plans and catalog data visually
- reinforce that the browser is a control surface, not the source of truth

## Dev

```bash
python3 ../sonic-cli/cli.py serve-api
npm install
npm run dev
```

## Build

```bash
npm run build
```
