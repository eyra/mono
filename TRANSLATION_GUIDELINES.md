# Translation Guidelines

Next is used by researchers and participants in different countries. English is the primary language for signed-in researchers. Shared authentication screens may be shown in the user’s browser language. Participant-facing interfaces are available in multiple languages to support participants in their own language.

These guidelines help keep participant-facing translations consistent, clear, and friendly across languages.

## General guidelines

When adding or updating translations:

- Use clear language at approximately B1 level where possible.
- Keep sentences short and easy to understand.
- Use a friendly, calm, and natural tone.
- Prefer common words over technical or formal terminology.
- Write copy that helps the user understand what to do next.
- Keep terminology consistent throughout a user journey.
- Translate naturally rather than word for word.
- Only include information relevant at that point in the user journey.
- Make error messages human and actionable; where possible, tell the user how to resolve the problem.

## Keep translations concise

Translations should be approximately the same length as the English or Dutch source copy where possible.

Do not translate literally when this makes copy substantially longer. Use a concise, natural formulation that preserves the meaning, tone, and function of the original.

This is particularly important for:

- Titles
- Buttons
- Labels

- Error messages
- Other copy displayed in space-constrained UI components

| Language | Recommended title |
| --- | --- |
| Dutch | `Start met je e-mail` |
| English | `Start with your email` |
| German | `E-Mail-Adresse eingeben` |

For German, `E-Mail-Adresse eingeben` is concise, clear, and natural in an interface, while avoiding the longer `Starten Sie mit Ihrer E-Mail-Adresse`.

Translations do not need the same grammatical structure. Prefer the formulation that sounds natural in each language while preserving meaning, tone, and function.

For example, German participant-facing copy uses a more formal tone than Dutch or English. `E-Mail-Adresse eingeben` is concise, clear, and natural in a German interface, while avoiding the longer `Starten Sie mit Ihrer E-Mail-Adresse`.

## Supported languages

English is the default language and should be configured as the fallback language.

| Language | Code | Form of address |
| --- | --- | --- |
| English | `en` | Neutral: `you` / `your` |
| Dutch | `nl` | Informal: `je` / `jij` / `jouw` |
| German | `de` | Formal: `Sie` / `Ihr` |
| Spanish | `es` | Informal: `tú` / `tu` |
| Italian | `it` | Informal: `tu` / `tuo` |
| Lithuanian | `lt` | Prefer neutral, natural UI formulations where possible |
| Romanian | `ro` | Formal/polite: `dumneavoastră` and corresponding polite forms |

## Language-specific guidance

### English

Use clear and neutral English. Avoid unnecessary formality and technical terminology. Keep copy concise and natural for an international audience.

### Dutch

Use the informal `je`, `jij`, `jou`, and `jouw`. Do not use the formal `u` form in participant-facing copy. Keep the tone friendly, direct, and accessible.

### German

Use the formal `Sie` form when addressing the user. German participant-facing copy may be slightly more formal and precise than Dutch or English, but prefer concise and natural UI formulations. It is not necessary to explicitly address the user in every string.

### Spanish

Use the informal `tú` form. Prefer natural, contemporary interface language over formal or literal translations. Keep the tone friendly and direct.

### Italian

Use the informal `tu` form. Prefer short and natural interface language and avoid unnecessary formality. Keep the tone friendly and direct.

### Lithuanian

Prefer neutral and natural UI formulations where possible. Avoid adding a formal personal form of address when the same instruction can be expressed naturally without one. Prioritize concise formulations that fit naturally within the interface.

### Romanian

Use the formal/polite `dumneavoastră` form and the corresponding polite verb forms. Keep copy concise, friendly, and accessible; formality should not make it unnecessarily complex. Where possible, use natural UI formulations that avoid explicitly addressing the user.

## Consistency

Review translations in the context of the complete user journey, not as isolated strings.

Use the same terminology for the same concept throughout a flow. For example, if a login code has a particular name on the email screen, use the same term on the code-entry screen and in related error messages.

When an existing translation conflicts with these guidelines, prefer these guidelines when updating the relevant user journey.

## Review and feedback

Developers apply these rules while writing code, so user-facing copy starts at the expected quality level.

Quality engineering double-checks the final copy in context. Iris contacts Business only when the guidelines do not resolve a copy decision.

Business reviews copy in the production end result. Adrienne records Business feedback by updating this document and/or changing `.po` files directly.
