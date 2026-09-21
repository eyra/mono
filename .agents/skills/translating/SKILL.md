---
name: translating
description: Apply Next's translation policy while developing code that adds or changes user-facing copy, Gettext strings, or locale files.
triggers:
  - /translating
  - translating copy
  - translation
  - translations
  - gettext
  - participant-facing copy
---

# Translating

Use this skill whenever a change creates or modifies user-facing copy, including code that introduces Gettext strings, updates `.po` files, or changes a participant-facing flow.

## Source of truth

Read `TRANSLATION_GUIDELINES.md` before writing or updating copy.

## Development workflow

1. Identify the audience and surface:
   - Signed-in researcher interfaces use English as their primary language.
   - Shared authentication screens follow the browser language.
   - Participant-facing interfaces must support the configured participant languages.
2. Follow the repository's existing Gettext conventions. Do not add user-facing copy as an untracked hard-coded string when the surrounding surface is translated.
3. Preserve interpolation placeholders and their meaning across every locale.
4. Keep copy concise, natural, and actionable. Translate for meaning and function, not word-for-word structure.
5. Apply the language-specific form of address and terminology rules in `TRANSLATION_GUIDELINES.md`.
6. Review the complete user journey so the same concept uses the same term in each related screen, validation message, and error.

## Review and feedback

1. Apply this skill while developing the code, not only while reviewing completed translations.
2. Quality engineering double-checks final copy in context. Iris contacts Business only when the policy does not resolve a copy decision.
3. Business reviews copy in the production end result. Adrienne records Business feedback by updating `TRANSLATION_GUIDELINES.md` and/or changing `.po` files directly.

## Verification

When translation strings or locale files change:

1. Run `mix i18n` from `core/` to extract and compile translations.
2. Run the focused tests for the changed flow.
3. For a user-facing UI change, inspect the rendered surface in each changed locale where practical.
