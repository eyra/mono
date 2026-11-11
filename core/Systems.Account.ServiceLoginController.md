# `Systems.Account.ServiceLoginController`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/service_login_controller.ex#L1)

# `auth_module`

# `create`

API endpoint for service account login.

POST /api/service/login
Header: X-Service-Key: <SERVICE_LOGIN_KEY env var>
Body: {"email": "...", "password": "..."}

Security layers:
1. X-Service-Key header must match SERVICE_LOGIN_KEY env var
2. Email must end with @eyra.service
3. Valid password required

Returns 200 with session cookie on success, 401/403 on failure.

# `print_auth_roles`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
