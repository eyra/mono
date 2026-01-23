# Docker Support

The project can be built as a Docker container:

    docker build --build-arg VERSION=X.Y --build-arg BUNDLE=next . -t core:latest

Several environment variables are required for proper functioning:

    BUNDLE_DOMAIN=<domain name>
    DB_USER=<db-credentials>
    DB_PASS=<db-credentials>
    DB_HOST=<db-host>
    DB_NAME=<db-name>
    UPLOAD_PATH=/static/uploads
    FELDSPAR_DATA_DONATION_PATH=/static/donations
    SECRET_KEY_BASE=<a-random-sequence-of-letters-and-numbers>
