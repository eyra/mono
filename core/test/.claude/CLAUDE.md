# Test Coding Rules

This document defines the testing standards and rules for the Core project. All tests should follow these guidelines to ensure consistency, maintainability, and clarity.

## Rule #1: Only Atomic Test Cases - No Mixed Edge Case Testing

### Principle
Each test must verify exactly ONE edge case or behavior. Never combine multiple edge cases in a single test.

### Why This Matters
1. **Clear Failure Diagnosis**: When a test fails, you know exactly which edge case broke
2. **Better Test Names**: Each test has a single, clear purpose
3. **Easier Maintenance**: Changes to handle one edge case don't affect other tests
4. **Documentation Value**: Each test documents exactly one behavior

### ❌ BAD Example: Mixed Edge Cases
```elixir
test "handles malicious pattern names" do
  actor = create_actor()

  malicious_patterns = [
    "../../../etc/passwd",        # Path traversal
    "'; DROP TABLE annotations;",  # SQL injection
    "<script>alert('xss')</script>", # XSS
    "{{constructor.constructor()}}", # Template injection
    "",                           # Empty string
    "nonexistent_pattern"         # Missing pattern
  ]

  Enum.each(malicious_patterns, fn pattern_name ->
    # Testing 6 different edge cases in one test!
    result = PatternManager.create_from_pattern(pattern_name, "test", [], actor)
    assert {:error, _} = result
  end)
end
```

### ✅ GOOD Example: Atomic Test Cases
```elixir
test "handles path traversal in pattern names" do
  actor = create_actor()
  result = PatternManager.create_from_pattern("../../../etc/passwd", "test", [], actor)
  assert {:error, %{error: "Pattern not found: ../../../etc/passwd"}} = result
end

test "handles SQL injection in pattern names" do
  actor = create_actor()
  result = PatternManager.create_from_pattern("'; DROP TABLE annotations;", "test", [], actor)
  assert {:error, %{error: reason}} = result
  assert String.contains?(reason, "Pattern not found")
end

test "handles empty pattern name" do
  actor = create_actor()
  result = PatternManager.create_from_pattern("", "test", [], actor)
  assert {:error, %{error: "Pattern not found: "}} = result
end

test "handles nil pattern name" do
  actor = create_actor()
  assert_raise FunctionClauseError, fn ->
    PatternManager.create_from_pattern(nil, "test", [], actor)
  end
end
```

### Edge Case Categories to Separate
Each category should have its own atomic tests:

1. **Input Type Violations**: nil, wrong type, missing required fields
2. **Boundary Violations**: empty, too long, too short
3. **Security Violations**: injection attempts, traversal attempts
4. **Constraint Violations**: uniqueness, foreign key, check constraints
5. **Concurrent Access**: race conditions, deadlocks
6. **Performance Boundaries**: timeouts, memory limits

### How to Apply This Rule
When writing tests, ask yourself:
- Does this test verify exactly ONE behavior?
- If this test fails, will I know exactly what broke?
- Can I give this test a specific, descriptive name?

If you answer "no" to any of these, split the test into multiple atomic tests.

---

## Rule #2: Crash Soon is Fine - No Graceful Exception Handling in Tests

### Principle
In Elixir environments, let functions crash on invalid inputs. Don't add defensive error handling for programmer errors. Test the crashes explicitly.

### Why This Matters
1. **Elixir Philosophy**: "Let it crash" is core to Elixir/Erlang design
2. **Clear Contracts**: Function signatures and guards define valid inputs
3. **Fail Fast**: Programmer errors should be caught during development
4. **Simpler Code**: No need for defensive programming against impossible states

### ❌ BAD Example: Defensive Error Handling
```elixir
# In the implementation
def create_from_pattern(pattern_name, statement, references, actor) do
  # BAD: Defensive nil checking
  if is_nil(pattern_name) or is_nil(statement) or is_nil(references) do
    {:error, "Invalid input parameters"}
  else
    # actual implementation
  end
end

# In the test
test "handles nil pattern name gracefully" do
  result = PatternManager.create_from_pattern(nil, "test", [], actor)
  assert {:error, "Invalid input parameters"} = result
end
```

### ✅ GOOD Example: Let It Crash + Test the Crash
```elixir
# In the implementation
def create_from_pattern(pattern_name, statement, references, %Actor{} = actor)
  when is_binary(pattern_name) and is_binary(statement) and is_list(references) do
  # Guards define the contract - no nil checking needed
  # actual implementation
end

# In the test
test "crashes on nil pattern name" do
  actor = create_actor()
  assert_raise FunctionClauseError, fn ->
    PatternManager.create_from_pattern(nil, "test statement", [], actor)
  end
end

test "crashes on string references instead of list" do
  actor = create_actor()
  assert_raise FunctionClauseError, fn ->
    PatternManager.create_from_pattern("Pattern", "test", "invalid", actor)
  end
end
```

### When to Crash vs Return Error Tuples

**Let it crash (FunctionClauseError, ArgumentError, etc.) for:**
- Programmer errors (wrong types, nil where not allowed)
- Contract violations (guards not satisfied)
- Impossible states

**Return {:error, reason} for:**
- User input validation failures
- Business rule violations
- External system failures
- Expected edge cases

### Examples from Our Codebase

```elixir
# ✅ GOOD: Crash on programmer error
test "crashes without actor" do
  assert_raise FunctionClauseError, fn ->
    PatternManager.create_from_pattern("Pattern", "text", [], nil)
  end
end

# ✅ GOOD: Error tuple for business logic
test "returns error for non-existent pattern" do
  actor = create_actor()
  assert {:error, %{error: "Pattern not found: InvalidPattern"}} =
    PatternManager.create_from_pattern("InvalidPattern", "text", [], actor)
end
```

### How to Apply This Rule
1. Use guards and pattern matching to define valid inputs
2. Don't add nil checks or type checks inside functions
3. Test that invalid inputs cause appropriate crashes
4. Reserve error tuples for expected business logic failures

---

## Rule #3: Guards Are Your First Line of Defense - Test Them First

### Principle
Function guards must validate types and basic constraints. Don't rely solely on Ecto changesets for validation. Every public function should have guards, and every guard must have a test.

### Why This Matters
1. **Fail at the Gate**: Invalid inputs should crash at function entry, not deep in business logic
2. **Clear Contracts**: Guards document and enforce the function's expectations
3. **Fast Feedback**: Type errors are caught immediately, not after database operations
4. **Separation of Concerns**: Type safety (guards) vs business rules (changesets)

### ❌ BAD Example: Validation Only in Changeset
```elixir
# In the implementation - NO GUARDS!
def create_user(attrs) do
  %User{}
  |> User.changeset(attrs)  # All validation happens here
  |> Repo.insert()
end

# In the changeset
def changeset(user, attrs) do
  user
  |> cast(attrs, [:name, :email, :age])
  |> validate_required([:name, :email])
  |> validate_format(:email, ~r/@/)
  |> validate_number(:age, greater_than: 0)
end

# In the test - only testing happy path
test "creates user with valid data" do
  assert {:ok, user} = create_user(%{name: "John", email: "john@example.com", age: 25})
end
```

### ✅ GOOD Example: Guards First, Then Business Logic
```elixir
# In the implementation - GUARDS DEFINE THE CONTRACT
def create_user(attrs) when is_map(attrs) do
  %User{}
  |> User.changeset(attrs)
  |> Repo.insert()
end

def update_user(%User{} = user, attrs) when is_map(attrs) do
  user
  |> User.changeset(attrs)
  |> Repo.update()
end

def delete_user(%User{} = user) do
  Repo.delete(user)
end

def assign_role(%User{} = user, role) when is_binary(role) and byte_size(role) > 0 do
  # implementation
end

# In the test - GUARD TESTS COME FIRST
describe "create_user/1 guards" do
  test "crashes on nil input" do
    assert_raise FunctionClauseError, fn ->
      UserManager.create_user(nil)
    end
  end

  test "crashes on string input" do
    assert_raise FunctionClauseError, fn ->
      UserManager.create_user("invalid")
    end
  end

  test "crashes on list input" do
    assert_raise FunctionClauseError, fn ->
      UserManager.create_user([name: "John"])
    end
  end
end

describe "create_user/1 business logic" do
  test "returns error for missing required fields" do
    assert {:error, changeset} = UserManager.create_user(%{})
    assert "can't be blank" in errors_on(changeset).name
  end

  test "creates user with valid data" do
    assert {:ok, user} = UserManager.create_user(%{name: "John", email: "john@example.com"})
  end
end
```

### Guard Testing Checklist

For each public function, test these guard violations:

1. **Type Guards**
   - `nil` when expecting specific type
   - Wrong primitive type (string instead of integer)
   - Wrong structure (list instead of map)

2. **Pattern Match Guards**
   - Wrong struct type (`%Actor{}` instead of `%User{}`)
   - Missing required keys in maps
   - Invalid tuple shapes

3. **Constraint Guards**
   - Empty strings when `byte_size(string) > 0`
   - Negative numbers when `number > 0`
   - Empty lists when `length(list) > 0`

### Test Organization Pattern
```elixir
defmodule MyModule.EdgeCasesTest do
  describe "function_name/arity guards" do
    # All guard-related crash tests
  end

  describe "function_name/arity business logic" do
    # Error tuple returns for valid types but invalid business rules
  end

  describe "function_name/arity success cases" do
    # Happy path tests
  end
end
```

### Developer Workflow
1. Write function with appropriate guards
2. Write tests for each guard clause
3. If guard tests fail → **Stop and fix the guards**
4. Only then proceed to business logic tests

### Examples from Our Codebase
```elixir
# ✅ GOOD: Guards prevent type confusion
def create_from_pattern(pattern_name, statement, references, %Actor{} = actor)
  when is_binary(pattern_name) and is_binary(statement) and is_list(references) do
  # implementation
end

# ✅ GOOD: Complete guard test coverage
test "crashes on nil pattern name" do
  assert_raise FunctionClauseError, fn ->
    create_from_pattern(nil, "valid", [], actor)
  end
end

test "crashes on list pattern name" do
  assert_raise FunctionClauseError, fn ->
    create_from_pattern(["invalid"], "valid", [], actor)
  end
end

test "crashes on non-Actor struct" do
  assert_raise FunctionClauseError, fn ->
    create_from_pattern("valid", "valid", [], %User{})
  end
end
```

### Red Flag: Missing Guard Tests
If a PR has a public function without guard tests, it should be flagged for review. Guards without tests are untested contracts.

---

## Rule #4: Use Standard Elixir Result Tuples - No Custom Success Patterns

### Principle
Always use Elixir's standard `{:ok, result}` and `{:error, reason}` patterns. Never introduce custom success indicators like `%{success: true}` or `%{status: "success"}`.

### Why This Matters
1. **Consistency**: The entire Elixir ecosystem uses this pattern
2. **Pattern Matching**: Elixir's pattern matching is optimized for these tuples
3. **with Statements**: Standard tuples work seamlessly with `with` constructs
4. **Cognitive Load**: Developers expect these patterns, not custom structures

### ❌ BAD Example: Custom Success Patterns
```elixir
# In the implementation - AVOID CUSTOM PATTERNS
def create_user(attrs) do
  case User.changeset(%User{}, attrs) |> Repo.insert() do
    {:ok, user} ->
      %{
        success: true,
        user: user,
        message: "User created successfully"
      }
    {:error, changeset} ->
      %{
        success: false,
        errors: changeset.errors,
        message: "Failed to create user"
      }
  end
end

# In the test - Awkward pattern matching
test "creates user successfully" do
  result = UserManager.create_user(@valid_attrs)
  assert result.success == true
  assert result.user.name == "John"
end

test "fails with invalid data" do
  result = UserManager.create_user(@invalid_attrs)
  assert result.success == false
  assert result.errors != nil
end
```

### ✅ GOOD Example: Standard Elixir Patterns
```elixir
# In the implementation - STANDARD PATTERNS
def create_user(attrs) when is_map(attrs) do
  %User{}
  |> User.changeset(attrs)
  |> Repo.insert()
end

def create_user_with_role(attrs, role) when is_map(attrs) and is_binary(role) do
  with {:ok, user} <- create_user(attrs),
       {:ok, user_with_role} <- assign_role(user, role) do
    {:ok, user_with_role}
  end
end

# In the test - Clean pattern matching
test "creates user successfully" do
  assert {:ok, user} = UserManager.create_user(@valid_attrs)
  assert user.name == "John"
end

test "returns error with invalid data" do
  assert {:error, changeset} = UserManager.create_user(@invalid_attrs)
  assert "can't be blank" in errors_on(changeset).name
end

test "handles user creation with role" do
  assert {:ok, user} = UserManager.create_user_with_role(@valid_attrs, "admin")
  assert user.role == "admin"
end
```

### Pattern Matching Benefits
```elixir
# ✅ GOOD: Easy to compose with 'with'
with {:ok, user} <- create_user(attrs),
     {:ok, profile} <- create_profile(user),
     {:ok, notification} <- send_welcome_email(user) do
  {:ok, %{user: user, profile: profile, notification: notification}}
end

# ✅ GOOD: Clean case statements
case delete_user(user) do
  {:ok, _deleted_user} ->
    redirect(conn, to: "/users")
  {:error, reason} ->
    render(conn, "error.html", error: reason)
end

# ✅ GOOD: Pipeline-friendly with pattern matching
def process_user_action(user_id) do
  user_id
  |> fetch_user()
  |> case do
    {:ok, user} -> perform_action(user)
    {:error, :not_found} -> {:error, "User not found"}
  end
end
```

### Testing Pattern Consistency
```elixir
# ✅ GOOD: Consistent error testing
describe "error handling" do
  test "returns error when user not found" do
    assert {:error, :not_found} = UserManager.get_user(999999)
  end

  test "returns error with invalid update" do
    user = insert(:user)
    assert {:error, changeset} = UserManager.update_user(user, %{email: "invalid"})
    assert "has invalid format" in errors_on(changeset).email
  end
end
```

### Acceptable Variations
```elixir
# ✅ OK: Tagged tuples for multiple success types
{:ok, {:created, user}}  # New resource
{:ok, {:updated, user}}  # Updated resource
{:ok, {:cached, user}}   # From cache

# ✅ OK: Detailed error tuples
{:error, :not_found}
{:error, {:invalid_state, "User is archived"}}
{:error, %ValidationError{field: :email, message: "invalid format"}}

# ✅ OK: Multi-step operation results
{:ok, %{user: user, email_sent: true, profile: profile}}
```

### Anti-Patterns to Avoid
```elixir
# ❌ BAD: Custom success indicators
%{success: true, data: user}
%{status: "ok", result: user}
%{ok: user}  # Looks like a tuple but isn't

# ❌ BAD: String-based status
%{status: "success", user: user}
%{status: "error", message: "Failed"}

# ❌ BAD: Boolean success flags
%{succeeded: true, user: user}
%{failed: false, data: user}
```

### How to Apply This Rule
1. Always return `{:ok, result}` for success
2. Always return `{:error, reason}` for failures
3. Use `with` statements to chain operations
4. Pattern match in tests for clean assertions
5. If you need more context, put it IN the tuple, not around it

---

## Rule #5: [To be defined]