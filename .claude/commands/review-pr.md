---
description: Review a pull request following project code standards
argument-hint: <PR_NUMBER or URL>
allowed-tools: Bash(gh:*), Read, Grep, Glob, WebFetch
---

# Code Review Command

Review pull request `$ARGUMENTS` for this Elixir/Phoenix codebase following project-specific standards and best practices.

## Review Process

### Step 1: Gather Context

1. Fetch PR details: `gh pr view <number> --json title,body,files,additions,deletions,commits`
2. Fetch PR diff: `gh pr diff <number>`
3. Read related issue if linked in PR description
4. Identify which Systems are affected

### Step 2: Systematic Review

Go through each checklist section below. For each item:
- ✅ Pass - requirement met
- ⚠️ Warning - minor issue or suggestion
- ❌ Fail - must be fixed before merge

---

## Review Checklist

### 1. Architecture Compliance

#### Systems Boundaries
- [ ] Changes respect system autonomy (no direct cross-system database access)
- [ ] Inter-system communication uses Signal framework, not direct function calls
- [ ] Public APIs are in `_public.ex` files
- [ ] Internal logic is in `_private.ex` or `_queries.ex` files

#### MVVM Pattern (ViewBuilder/LiveView)
- [ ] ViewBuilder creates block structures, not HTML
- [ ] ViewBuilder handles all `dgettext`/`dngettext` calls
- [ ] LiveView handles events and renders blocks
- [ ] No business logic in LiveView render functions
- [ ] Block data is self-contained (all needed data in block tuple)

#### Signal Usage
- [ ] Signals used for parent-child system communication
- [ ] Signal handlers in `_switch.ex` files
- [ ] Multi operations dispatch signals correctly
- [ ] Signal keys match Multi operation names

### 2. Elixir Best Practices

#### Pattern Matching (CRITICAL)
- [ ] Function heads use pattern matching, NOT dot notation access
- [ ] Guards validate types and constraints at function entry
- [ ] All guard clauses have corresponding tests

```elixir
# ✅ CORRECT
def process(%{entries: entries, status: status}, assigns) do
  # work with extracted variables
end

# ❌ WRONG
def process(data, assigns) do
  entries = data.entries  # Never do this!
end
```

#### Error Handling
- [ ] Uses standard `{:ok, result}` / `{:error, reason}` tuples
- [ ] No custom success patterns like `%{success: true}`
- [ ] Programmer errors crash (FunctionClauseError), business errors return tuples
- [ ] `with` statements used for chaining operations
- [ ] NO catch-all clauses for programmer errors - let pattern matching fail naturally

```elixir
# ✅ CORRECT - Let it crash on invalid input (programmer error)
defp deliver_with_blob(%{"blob_id" => blob_id} = args), do: ...
defp deliver_with_blob(%{"data" => data} = args), do: ...
# No catch-all! FunctionClauseError is appropriate for missing keys

# ❌ WRONG - Don't add defensive catch-alls for programmer errors
defp deliver_with_blob(args) do
  {:discard, "Missing required keys"}  # Don't do this!
end
```

#### Function Organization
- [ ] Same name/arity function clauses grouped together
- [ ] Prefer subfunctions over comments for complex logic
- [ ] No alias grouping (each alias on separate line)
- [ ] Uses `alias Systems.X` then `X.Model`, not `Systems.X.Model`

### 3. Security

#### Input Validation
- [ ] User input validated at system boundaries
- [ ] No SQL injection vulnerabilities (use Ecto parameterized queries)
- [ ] No command injection in Bash/System calls
- [ ] Path traversal prevented for file operations

#### Secrets & Credentials
- [ ] No hardcoded secrets, API keys, or passwords
- [ ] Secrets use environment variables or runtime config
- [ ] `.env` files not committed
- [ ] Sensitive data masked in logs (check `mask_sensitive_data` patterns)

#### Authorization
- [ ] GreenLight permissions checked for protected actions
- [ ] User can only access their own resources
- [ ] Role-based access properly enforced

### 4. Database & Migrations

#### Migration Safety
- [ ] Migrations are reversible (`change` function, not just `up`)
- [ ] No data loss in down migration
- [ ] Large table changes consider lock time
- [ ] Indexes added for frequently queried columns
- [ ] Foreign key constraints where appropriate

#### Ecto Usage
- [ ] Changesets validate at business logic level
- [ ] Preloads explicit (no N+1 queries)
- [ ] Transactions used for multi-step operations (`Ecto.Multi`)
- [ ] `Repo.transaction` wraps related changes atomically

### 5. Oban Jobs

#### Job Design
- [ ] Jobs are idempotent (safe to retry)
- [ ] Large data not stored in job args (use blob pattern if needed)
- [ ] Appropriate queue and priority configured
- [ ] `max_attempts` set reasonably
- [ ] Unique constraints prevent duplicate processing

#### Error Handling
- [ ] Returns `:ok` for success
- [ ] Returns `{:error, reason}` for retryable failures
- [ ] Returns `{:discard, reason}` for non-retryable failures
- [ ] Cleanup on failure (don't leave partial state)

### 6. Testing

#### Coverage
- [ ] New code has corresponding tests
- [ ] Edge cases tested (nil, empty, boundary values)
- [ ] Guard violations tested (expect FunctionClauseError)
- [ ] Error paths tested, not just happy path

#### Test Quality
- [ ] Tests are atomic (one edge case per test)
- [ ] Uses associations over foreign keys in factories
- [ ] Preloads before asserting on associations
- [ ] `async: false` for tests with signals

#### Signal Testing
- [ ] `isolate_signals()` used in setup when needed
- [ ] Aware that LiveView runs in separate process
- [ ] Tests function directly when signal isolation needed

### 7. Performance

#### Query Efficiency
- [ ] No N+1 queries (check preloads)
- [ ] Pagination for large datasets
- [ ] Indexes exist for WHERE clause columns
- [ ] `Repo.stream` for large result sets

#### Memory
- [ ] Large files/data not held in memory unnecessarily
- [ ] Binary data stored efficiently (not JSON encoded)
- [ ] Temporary data cleaned up

### 8. Code Style

#### Formatting
- [ ] Code formatted with `mix format`
- [ ] No compiler warnings (`mix compile --warnings-as-errors`)
- [ ] Credo passes (`mix credo`)

#### Naming
- [ ] Clear, descriptive function and variable names
- [ ] Follows existing naming patterns in codebase
- [ ] File naming conventions followed (*_model.ex, *_view.ex, etc.)

#### Documentation
- [ ] Public APIs have `@doc` if behavior non-obvious
- [ ] Complex business logic has context
- [ ] No excessive commenting (code should be self-documenting)

---

## Review Output Format

Structure your review as:

```markdown
## PR Review: [Title]

### Summary
[1-2 sentence overview of what the PR does]

### Architecture: ✅/⚠️/❌
[Findings related to systems, signals, MVVM]

### Code Quality: ✅/⚠️/❌
[Elixir patterns, error handling, style]

### Security: ✅/⚠️/❌
[Input validation, secrets, authorization]

### Database: ✅/⚠️/❌
[Migrations, queries, transactions]

### Testing: ✅/⚠️/❌
[Coverage, quality, edge cases]

### Performance: ✅/⚠️/❌
[Queries, memory, efficiency]

### Specific Findings

#### Must Fix (❌)
1. [Critical issue with file:line reference]

#### Should Fix (⚠️)
1. [Important suggestion with file:line reference]

#### Consider (💡)
1. [Optional improvement idea]

### Verdict
- [ ] **Approved** - Ready to merge
- [ ] **Approved with comments** - Minor issues, can merge after addressing
- [ ] **Changes requested** - Must fix issues before merge
```

---

## Project-Specific Patterns

### Pixel Components
- `data-testid` attribute supported on all components
- Button actions defined in `button_action.ex`
- Text components wrap content in outer div

### Signal Dispatch in Multi
```elixir
# Correct pattern
Multi.new()
|> Multi.update(:paper_reference_file, changeset)  # Key matches signal
|> Signal.Public.multi_dispatch({:paper_reference_file, :updated})
```

### Blob Storage Pattern
For large data in Oban jobs:
```elixir
# Store blob, pass ID to job
Multi.new()
|> Multi.insert(:pending_blob, PendingBlobModel.prepare(data))
|> Multi.run(:oban_job, fn _repo, %{pending_blob: %{id: blob_id}} ->
  %{blob_id: blob_id, ...} |> Delivery.new() |> Oban.insert()
end)
```

### ViewBuilder Block Pattern
```elixir
# ViewBuilder returns stack of blocks
def view_model(data, assigns) do
  %{
    stack: [
      {:header, %{title: dgettext("eyra-app", "title")}},
      {:content, %{items: processed_items}}
    ]
  }
end

# LiveView renders blocks
def render_block(:header, assigns) do
  ~H"""<h1>{@header.title}</h1>"""
end
```
