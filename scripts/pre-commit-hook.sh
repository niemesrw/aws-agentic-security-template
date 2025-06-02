#!/bin/sh

# Pre-commit hook to run security checks
# Install this by copying to .git/hooks/pre-commit and making it executable

echo "🔒 Running pre-commit security checks..."

# Run our security check script
if ! ./scripts/security-check.sh; then
    echo ""
    echo "❌ Pre-commit security check failed!"
    echo "Commit aborted to prevent committing sensitive data."
    echo ""
    echo "To fix:"
    echo "1. Review the security issues above"
    echo "2. Remove any sensitive files from staging"
    echo "3. Add patterns to .gitignore if needed"
    echo "4. Retry your commit"
    echo ""
    echo "To bypass this check (NOT recommended):"
    echo "git commit --no-verify"
    exit 1
fi

echo "✅ Pre-commit security check passed!"
exit 0
