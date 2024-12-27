OUTPUT=${CERTS_OUTPUT_DIR:-.}
mkdir -p $OUTPUT

openssl req -x509 -new -nodes -days 3650 -keyout "$OUTPUT/ca.key" -out "$OUTPUT/ca.crt" -subj "/CN=example-ca"

openssl req -new -nodes -newkey rsa:2048 -keyout "$OUTPUT/server.key" -out "$OUTPUT/server.csr" -subj "/CN=db"

openssl x509 -req -in "$OUTPUT/server.csr" -CA "$OUTPUT/ca.crt" -CAkey "$OUTPUT/ca.key" -CAcreateserial -out "$OUTPUT/server.crt" -days 3650

openssl req -new -key "$OUTPUT/server.key" -out "$OUTPUT/server.csr" -config san_config.cnf

openssl x509 -req -in "$OUTPUT/server.csr" -CA "$OUTPUT/ca.crt" -CAkey "$OUTPUT/ca.key" -CAcreateserial -out "$OUTPUT/server.crt" -days 3650 -extfile san_config.cnf -extensions v3_req

rm -f "$OUTPUT/server.csr"

chmod 600 "$OUTPUT/ca.key" "$OUTPUT/server.key"
chmod 644 "$OUTPUT/ca.crt" "$OUTPUT/server.crt"
