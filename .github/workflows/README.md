# FlashFeed GitHub Actions Workflows

## 🚀 Deployment Workflows

### **deploy.yml** (Production - Recommended)
**Main CI/CD pipeline with comprehensive features:**
- ✅ Code quality checks (flutter analyze, format)
- ✅ Automated testing with coverage
- ✅ Security scanning
- ✅ Performance testing (Lighthouse)
- ✅ Bundle size analysis
- ✅ Automatic deployment to GitHub Pages
- ✅ Build artifacts (30 days retention)

**Triggers:**
- Push to `main` branch
- Pull requests to `main`
- Tags (`v*`)
- Manual dispatch

### **pr-preview.yml** (Pull Request Previews)
**Automatic preview deployments for PRs:**
- 🔗 Unique URL for each PR
- 💬 Automatic comments with preview links
- 🧹 Auto-cleanup after merge
- 🔄 Updates on new commits

### **static.yml** (Legacy - Manual Only)
**Simple deployment workflow (kept for backwards compatibility):**
- Quick deployment without full CI/CD
- Tests only with `[test]` in commit message
- Now only available via manual trigger

## 📊 Workflow Comparison

| Feature | deploy.yml | pr-preview.yml | static.yml |
|---------|------------|----------------|------------|
| Auto-trigger on push | ✅ | ✅ (PRs) | ❌ (manual) |
| Code quality checks | ✅ | ❌ | ❌ |
| Security scanning | ✅ | ❌ | ❌ |
| Performance tests | ✅ | ❌ | ❌ |
| Preview deployments | ❌ | ✅ | ❌ |
| Production deploy | ✅ | ❌ | ✅ |
| Bundle optimization | ✅ | ❌ | ❌ |

## 🎯 When to Use Which

### Use `deploy.yml`:
- Production deployments
- Release candidates
- When you need full quality assurance

### Use `pr-preview.yml`:
- Automatically triggered for PRs
- Review features before merge
- Share work with stakeholders

### Use `static.yml`:
- Emergency hotfixes
- When CI/CD has issues
- Quick manual deployments

## 🔧 Configuration

### Fixing Code Analysis Issues
If `deploy.yml` fails due to code analysis:

1. **Fix the issues** (recommended):
   ```bash
   flutter analyze
   flutter format .
   ```

2. **Or temporarily bypass** (already configured):
   - The workflow uses `--no-fatal-warnings`
   - Has `continue-on-error: true`

### Custom Domain Setup
Both `deploy.yml` and `static.yml` support custom domains:
- Place CNAME file in `/web/` directory
- Configure DNS to point to GitHub Pages

## 📈 Monitoring

- **GitHub Actions Tab**: View all workflow runs
- **Deployments**: Check deployment history
- **Artifacts**: Download build artifacts (30 days)
- **Analytics**: Check `/web/analytics.js` for metrics

## 🚨 Troubleshooting

### Deploy fails with "flutter analyze" errors:
- Run `flutter analyze` locally
- Fix warnings/errors or adjust strictness in workflow

### Preview deployment not showing:
- Check if PR is from a fork (limited permissions)
- Verify GitHub Pages is enabled in settings

### Performance tests failing:
- Review Lighthouse scores
- Optimize bundle size and loading performance