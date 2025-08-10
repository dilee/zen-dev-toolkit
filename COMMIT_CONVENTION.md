# Commit Message Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages. This leads to more readable messages that are easy to follow when looking through the project history and enables automatic generation of the changelog.

## Commit Message Format

Each commit message consists of a **header**, a **body**, and a **footer**:

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

### Header
The header is mandatory and must conform to the following format:

```
<type>(<scope>): <subject>
```

#### Type
Must be one of the following:

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to our CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit

#### Scope
The scope should be the name of the module/tool affected (as perceived by the person reading the changelog):

- **json**: JSON formatter tool
- **base64**: Base64 encoder/decoder tool
- **url**: URL encoder/decoder tool
- **hash**: Hash generator tool
- **uuid**: UUID generator tool
- **ui**: General UI changes
- **menu**: Menu bar related changes
- **core**: Core app functionality
- **deps**: Dependencies
- **config**: Configuration changes

#### Subject
The subject contains a succinct description of the change:

- Use the imperative, present tense: "change" not "changed" nor "changes"
- Don't capitalize the first letter
- No dot (.) at the end
- Limit to 50 characters

### Body
The body should include the motivation for the change and contrast this with previous behavior:

- Use the imperative, present tense
- Should wrap at 72 characters
- Can use multiple paragraphs

### Footer
The footer should contain any information about **Breaking Changes** and is also the place to reference GitHub issues:

- Breaking changes should start with `BREAKING CHANGE:`
- Reference issues like `Closes #123` or `Fixes #456`

## Examples

### Simple feature addition
```
feat(json): add syntax highlighting for JSON output

Implement syntax highlighting using NSAttributedString to improve
readability of formatted JSON output.

Closes #23
```

### Bug fix with breaking change
```
fix(ui): correct resizing behavior for popover window

Previously, the window could be resized beyond screen bounds. This fix
constrains the window to reasonable dimensions.

BREAKING CHANGE: Minimum window size changed from 300x350 to 320x400

Fixes #42
```

### Documentation update
```
docs: update README with installation instructions

Add detailed steps for building from source and installing via
Mac App Store when available.
```

### Performance improvement
```
perf(json): optimize large JSON file processing

Implement streaming parser for files over 1MB to reduce memory usage
and improve response time by 60%.
```

### Simple refactor
```
refactor(core): extract tool protocol for better modularity
```

## Commit Message Template

You can set up a commit message template by creating `.gitmessage` in the project root and configuring git:

```bash
git config commit.template .gitmessage
```

## Validation

We recommend using [commitlint](https://github.com/conventional-changelog/commitlint) or similar tools to validate commit messages in CI/CD pipelines.

## Benefits

Following this convention provides several benefits:

1. **Automatic CHANGELOG generation**: Tools can automatically generate changelogs from commits
2. **Simple navigation**: Developers can easily navigate through commit history
3. **Automated versioning**: Tools can determine version bumps based on commit types
4. **Better collaboration**: Clear communication about changes
5. **CI/CD integration**: Automated workflows based on commit types

## Quick Reference

```
feat:     New feature                 | Minor version bump
fix:      Bug fix                      | Patch version bump
docs:     Documentation only           | No version bump
style:    Code style changes           | No version bump
refactor: Code refactoring            | No version bump
perf:     Performance improvement      | Patch version bump
test:     Test changes                | No version bump
build:    Build system changes        | No version bump
ci:       CI/CD changes               | No version bump
chore:    Maintenance                 | No version bump
revert:   Revert previous commit      | Variable bump

BREAKING CHANGE in footer = Major version bump
```