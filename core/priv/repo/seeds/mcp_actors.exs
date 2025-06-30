# MCP Actor Seeds
# Run with: mix run priv/repo/seeds_mcp_actors.exs

alias Core.Authentication.Actor
alias Systems.MCP.TokenManager
alias Core.Repo

# Create system actor for internal MCP operations
case TokenManager.create_mcp_actor_with_token(
  "System MCP Agent",
  "Internal system actor for MCP server operations",
  "System MCP Token",
  :system
) do
  {:ok, %{actor: actor, token: token}} ->
    IO.puts("✓ Created system MCP actor: #{actor.name}")
    IO.puts("  Token: #{token}")
    IO.puts("  Usage: Authorization: Bearer #{token}")
  
  {:error, changeset} ->
    IO.puts("✗ Failed to create system MCP actor:")
    IO.inspect(changeset.errors)
end

# Create agent actor for AI agents like Claude
case TokenManager.create_mcp_actor_with_token(
  "Claude AI Agent", 
  "Claude AI agent for concept extraction and knowledge operations",
  "Claude MCP Token",
  :agent
) do
  {:ok, %{actor: actor, token: token}} ->
    IO.puts("✓ Created Claude AI actor: #{actor.name}")
    IO.puts("  Token: #{token}")
    IO.puts("  Usage: Authorization: Bearer #{token}")
  
  {:error, changeset} ->
    IO.puts("✗ Failed to create Claude AI actor:")
    IO.inspect(changeset.errors)
end

# Create general purpose agent actor
case TokenManager.create_mcp_actor_with_token(
  "General AI Agent",
  "General purpose AI agent for external integrations", 
  "General MCP Token",
  :agent
) do
  {:ok, %{actor: actor, token: token}} ->
    IO.puts("✓ Created general AI actor: #{actor.name}")
    IO.puts("  Token: #{token}")
    IO.puts("  Usage: Authorization: Bearer #{token}")
  
  {:error, changeset} ->
    IO.puts("✗ Failed to create general AI actor:")
    IO.inspect(changeset.errors)
end

IO.puts("\n📋 Summary:")
IO.puts("- System MCP Agent: For internal operations")
IO.puts("- Claude AI Agent: For Claude-specific access")  
IO.puts("- General AI Agent: For other AI systems")
IO.puts("\n🔐 Security Notes:")
IO.puts("- Store tokens securely")
IO.puts("- Rotate tokens regularly using TokenManager.rotate_token/3")
IO.puts("- Monitor usage with TokenManager.get_token_usage_stats/0")