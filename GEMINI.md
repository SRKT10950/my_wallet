# Project Rules — My Wallet

## Default Language
- **Dart** (Flutter)

## Git Branching Strategy

### Branches
| Branch | Purpose | Direct Push |
|--------|---------|-------------|
| `main` | Production-stable | ❌ Never — PR only |
| `uat`  | Testing & active dev | ✅ Yes |

### Rules
- All development changes go to `uat` first
- Test all changes on `uat` before promoting
- Merge to `main` **only via approved PR**
- No direct commits or force pushes to `main`

### Workflow
```
feature work → uat → [test & validate] → PR (uat → main) → [PR approved] → merge main
```
