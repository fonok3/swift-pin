# Contributing

Thanks for your interest in Pin.

## Bug reports

Open an issue with a minimal reproducing example. Include the Swift version (`swift --version`) and platform.

## Pull requests

- Open an issue first to discuss the change.
- Keep PRs focused on a single concern.
- Run `swift-format format --recursive --in-place Sources Tests` before submitting.
- Run `swift test` before submitting.

## Commit messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/).

```
<type>(<scope>): <description>
```

**Types:** `feat`, `fix`, `refactor`, `docs`, `test`, `ci`, `chore`, `perf`

**Scopes:** `macro`, `plugin`, `util`, `example`, `deps`

**Examples:**

```
feat(macro): add support for protocol dependencies
fix(plugin): resolve cycle detection false positive
docs: update README installation section
refactor!: rename AccessLevel to Visibility
```

Append `!` after the type/scope for breaking changes.

**Rules:**

- Single line only — no body or footer.
- Description (after `type(scope): `) must be 75 characters or fewer.

### Local hook setup

```bash
git config core.hooksPath .githooks
```

This enables the commit-msg hook that validates your messages locally before they reach CI.

## Questions

Use GitHub Discussions or open an issue.
