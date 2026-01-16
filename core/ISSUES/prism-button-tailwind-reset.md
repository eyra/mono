# Prism Button Background Override for Tailwind

## Problem

When using Prism UI component classes (e.g., `prism-btn-primary`) on `<button>` elements with Tailwind CSS, the button background color may appear transparent instead of the expected color.

This happens because Tailwind's base/preflight layer includes a reset rule:

```css
button, [type="button"], [type="reset"], [type="submit"] {
  background-color: transparent;
}
```

This rule has higher specificity than `.prism-btn-primary` when applied to button elements, causing the Prism styles to be overridden.

## Why mono/core Works

In mono/core, the `tailwind.config.js` defines colors at the root `theme` level (not `theme.extend`), which replaces Tailwind's entire color palette. This side effect somehow affects how the base reset interacts with other styles.

## Solution

Add explicit overrides at the end of `app.css` with higher specificity:

```css
/* Override Tailwind base button reset for Prism buttons */
button.prism-btn-primary {
  background-color: #4272ef;
  color: #ffffff;
}

button.prism-btn-success {
  background-color: #52ba12;
  color: #ffffff;
}

button.prism-btn-warning {
  background-color: #f28d15;
  color: #ffffff;
}

button.prism-btn-danger,
button.prism-btn-delete {
  background-color: #db1e1e;
  color: #ffffff;
}
```

## Alternative Solution

Update the Prism package itself to use higher specificity selectors like `button.prism-btn-primary` instead of just `.prism-btn-primary`.

## Discovered In

Flux MCP Server UI project (2025-01-07)
