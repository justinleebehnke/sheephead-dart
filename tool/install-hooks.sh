#!/usr/bin/env bash
# Run once after cloning. Points git at our tracked hooks directory so the
# pre-push gate is active. (Git hooks live in .git/hooks by default, which
# isn't version-controlled; core.hooksPath lets us track them in the repo.)
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
git config core.hooksPath tool/hooks
chmod +x tool/hooks/*
echo "✓ Git hooks installed (core.hooksPath = tool/hooks)."
echo "  The pre-push gate is now active."
