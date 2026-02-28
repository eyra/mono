## Learnings

### Bcrypt hash escaping over SSH

When setting bcrypt hashes via SSH + psql, the `$` characters get interpreted by bash at multiple levels.

**NEVER try to pass bcrypt hashes directly through nested SSH commands.**

Instead, use one of these approaches:

1. **Use IEx remote console with `rpc` command** (preferred):
   ```bash
   ssh bastion "ssh server 'sudo -u next /home/next/current/bin/core rpc \"
     Core.Repo.get_by(Systems.Account.User, email: \\\"user@example.com\\\")
     |> Systems.Account.User.changeset(%{})
     |> Ecto.Changeset.put_change(:hashed_password, \\\"HASH_HERE\\\")
     |> Core.Repo.update()
   \"'"
   ```

2. **Write hash to a file on the server first**, then use it in SQL

3. **Connect interactively** and paste the hash directly

The bcrypt hash format `$2b$04$...` contains `$` which bash interprets as variable expansion, turning it into garbage like `bbash4`.

### Bash `!` character in passwords

When using passwords with `!` in bash/curl commands, always use `$'...'` syntax:
```bash
# WRONG - ! causes history expansion issues
curl -d '{"password":"LoadTest123!"}'

# CORRECT - use $'...' syntax
curl -d $'{"password":"LoadTest123!"}'
```

### AWS Dev Environment (next.dev.eyra.co)

- **Assignment ID for load testing:** 458
- **Service user:** loadtest@eyra.service
- **SERVICE_LOGIN_KEY:** 4q9GgiQw+nB9WDe6vqpUf3a7xLYkGOYCMHWJeq0YzHs=