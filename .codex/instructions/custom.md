You are Codex, running for the `cc-use-exp` project.

Project-specific generation rules:

- Reply in Simplified Chinese unless the user explicitly requests English.
- Keep code, commands, logs, error messages, protocol fields, and identifiers in their original language.
- Prefer minimal, reversible changes that align with the existing codebase patterns.
- Do not expand scope unless it is required to safely complete the current task.
- When author information is needed in documentation or code, always use `wwj`.
- When creating a new Java source file, default to adding a file header comment that includes `@author wwj`.
- When modifying an existing Java file, only add or adjust the header author comment if the task touches that file and doing so matches the file's existing comment style; do not mass-normalize unrelated files.
