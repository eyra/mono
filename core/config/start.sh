 #!/bin/bash
eval "$(infisical export --env=local --format=dotenv-export)"
exec iex -S mix phx.server
