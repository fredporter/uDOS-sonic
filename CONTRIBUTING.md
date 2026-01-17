# Contributing to Sonic Stick

All contributions welcome! Here's how to help:

## 🐛 Report a Bug

1. Open an issue on [GitHub](https://github.com/fredporter/sonic-stick/issues)
2. Include: your USB device model, ISO being booted, BIOS/firmware version
3. Attach logs from `/mnt/sonic/LOGS/boot.log` if relevant

## 💡 Suggest a Feature

1. Check [existing issues](https://github.com/fredporter/sonic-stick/issues)
2. Open a new issue with: use case, expected behavior, alternative approaches considered

## 🔧 Submit Code

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit with clear messages: `git commit -am "Add feature X"`
4. Test on an actual USB stick (seriously!)
5. Push: `git push origin feature/your-feature`
6. Open a Pull Request with a description

## 📖 Documentation

- Improve [docs/](docs/) with clarity, examples, or corrections
- Update [README.md](README.md) if adding features
- Test all instructions on a fresh system

## ✅ Testing Checklist

Before submitting a PR:
- [ ] Scripts run without errors
- [ ] ISOs boot from Ventoy menu
- [ ] Persistence/logging works
- [ ] Documentation is clear
- [ ] Commit messages are descriptive

## 📝 License

All contributions must be MIT-licensed (same as project).

Thanks for making Sonic Stick better! 🚀
