# 🔒 Security Guidelines

## Environment Variables & Secrets Management

### Files to NEVER commit to git:
- `.env.local` - Contains your actual AWS account info and potentially API keys
- `.env` - Any environment files with actual secrets
- `.env.production` - Production environment variables
- Any files containing API keys, passwords, or AWS credentials

### Safe Practice:
1. **Use `.env.example`** - Template file that's safe to commit (no real secrets)
2. **Copy to `.env.local`** - Your actual configuration (ignored by git)
3. **Use AWS Secrets Manager** - For production API keys and sensitive data
4. **Use AWS SSO/IAM roles** - For AWS authentication instead of access keys

### Environment File Priority:
1. Environment variables from your shell
2. `.env.local` (your personal config)
3. `.env.example` (defaults and documentation)

### Production Deployment:
- **Never put secrets in CDK code** - Use AWS Secrets Manager
- **Use IAM roles** - Don't use long-lived access keys
- **Rotate credentials regularly** - Follow AWS security best practices
- **Enable CloudTrail** - Audit all AWS API calls

### Development Setup:
```bash
# 1. Copy template
cp .env.example .env.local

# 2. Edit with your settings (file is ignored by git)
nano .env.local

# 3. Verify git ignores it
git status  # .env.local should not appear
```

## File Security Checklist

Before committing code, always check:
- [ ] No API keys in code
- [ ] No hardcoded AWS account IDs (use environment variables)
- [ ] No database passwords or connection strings
- [ ] `.env.local` is not staged for commit
- [ ] All secrets use AWS Secrets Manager in production
- [ ] IAM permissions follow least-privilege principle

## Incident Response

If you accidentally commit secrets:
1. **Immediately rotate the exposed credentials**
2. **Remove from git history** (`git filter-branch` or BFG Repo-Cleaner)
3. **Force push to overwrite history** (coordinate with team)
4. **Review access logs** for unauthorized usage
5. **Update security procedures** to prevent recurrence

## AWS Security Best Practices

1. **Enable MFA** on all AWS accounts
2. **Use AWS SSO** for centralized identity management
3. **Enable GuardDuty** for threat detection
4. **Enable Config** for compliance monitoring
5. **Enable CloudTrail** for API logging
6. **Regular security audits** with AWS Security Hub
7. **Use VPC endpoints** for private AWS service access
8. **Encrypt all data** at rest and in transit
