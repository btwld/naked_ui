# Contributing to Naked UI

Thank you for your interest in contributing to Naked UI!

## Known Technical Debt

### RadioGroup Material Dependency

`NakedRadio` currently uses Material's `RadioGroup.maybeOf<T>(context)` for
group coordination. While this violates our headless architecture principle,
implementing a custom RadioGroup would require 15-25 hours of work.

If contributing to remove this dependency, see `AUDIT_FINDINGS.md` Issue 1.2
for implementation guidance.
