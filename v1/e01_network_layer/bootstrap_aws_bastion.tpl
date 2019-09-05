#!/bin/bash
mkdir ~/.ssh
cat > ~/.ssh/id_rsa <<EOF
${private_key}
EOF
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
