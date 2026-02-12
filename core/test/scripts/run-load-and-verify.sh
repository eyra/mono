#!/bin/bash
# Load test script that runs Artillery and verifies files landed on the server(s)
#
# Service user credentials:
#   EMAIL: loadtest@eyra.service
#   PASSWORD: LoadTest123! (dev only - prod has different password)
#   SERVICE_KEY: (check SERVICE_LOGIN_KEY env var on target server)
#
# IMPORTANT: Password contains "!" which bash interprets as history expansion.
# Use $'...' syntax to preserve literal characters:
#   export SERVICE_PASSWORD=$'LoadTest123!'
#
# To generate a password hash for a new service user:
#   cd core
#   mix run --no-start -e 'Application.ensure_all_started(:bcrypt_elixir); IO.puts(Bcrypt.hash_pwd_salt("YourPassword!"))'
#
# Then set it in the database:
#   ssh bastion.eyra.co
#   ssh ec2-web-<env>-01
#   PGPASSWORD=<db_pass> psql -h <db_host> -U <db_user> -d <db_name> \
#     -c "UPDATE users SET password_hash = '<hash>' WHERE email = 'loadtest@eyra.service'"
#
# Usage for Fly:
#   export BASE_URL=https://eyra-next-staging.fly.dev
#   export SERVICE_EMAIL=loadtest@eyra.service
#   export SERVICE_PASSWORD=$'LoadTest123!'
#   export SERVICE_KEY=<from fly secrets>
#   export ASSIGNMENT_ID=1
#   export PLATFORM=fly
#   export FLY_APP=eyra-next-staging
#   ./run-load-and-verify.sh [quick|volume|large|xlarge]
#
# Usage for AWS (dev - hosts auto-discovered from bastion):
#   export BASE_URL=https://next.dev.eyra.co
#   export SERVICE_EMAIL=loadtest@eyra.service
#   export SERVICE_PASSWORD=$'LoadTest123!'
#   export SERVICE_KEY='4q9GgiQw+nB9WDe6vqpUf3a7xLYkGOYCMHWJeq0YzHs='
#   export ASSIGNMENT_ID=458
#   export PLATFORM=aws
#   ./run-load-and-verify.sh [quick|volume|large|xlarge]
#
# Usage for AWS (prod - hosts auto-discovered from bastion):
#   export BASE_URL=https://next.eyra.co
#   export SERVICE_EMAIL=loadtest@eyra.service
#   export SERVICE_PASSWORD=$'LoadTest123!'
#   export SERVICE_KEY=<from prod server>
#   export ASSIGNMENT_ID=...
#   export PLATFORM=aws
#   ./run-load-and-verify.sh [quick|volume|large|xlarge]
#
# Note: AWS hosts are fetched from bastion via 'get_web_servers <env>'
# You can override with: export SSH_HOSTS="host1 host2"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_SCRIPT="$SCRIPT_DIR/verify-donations.sh"

PLATFORM="${PLATFORM:-fly}"
TEST_ENV="${1:-quick}"
FILE_SIZE_MB="${FILE_SIZE_MB:-1}"

echo "=== Load Test: $TEST_ENV on $PLATFORM ==="
echo "BASE_URL: $BASE_URL"
echo "ASSIGNMENT_ID: $ASSIGNMENT_ID"
echo "FILE_SIZE_MB: $FILE_SIZE_MB"
echo ""

# Count files before
echo "=== Files BEFORE test ==="
$VERIFY_SCRIPT before
echo ""

# Run Artillery (from load directory)
echo "=== Running Artillery ($TEST_ENV) ==="
export FILE_SIZE_MB
cd "$SCRIPT_DIR/../load"
case "$TEST_ENV" in
    quick)   npm run test:quick ;;
    volume)  npm run test:volume ;;
    large)   npm run test:large ;;
    xlarge)  npm run test:xlarge ;;
    *)       npm test ;;
esac
cd - > /dev/null
echo ""

# Wait for async processing
echo "Waiting 5s for async processing..."
sleep 5

# Count files after and show summary
echo "=== Files AFTER test ==="
$VERIFY_SCRIPT after
