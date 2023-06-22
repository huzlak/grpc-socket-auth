openssl genpkey -algorithm RSA -out server.key
cat > server.cnf << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = test

[v3_req]
subjectAltName = DNS:*.test,DNS:localhost
EOF
openssl req -x509 -new -key server.key -out server.crt -days 365 -config server.cnf -addext "subjectAltName = DNS:localhost,DNS:*.test"
kubectl create secret tls gateway-tls   --namespace='gloo-system'   --key='server.key'   --cert='server.crt'
