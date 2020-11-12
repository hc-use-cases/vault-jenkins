pipeline {
agent any
  environment {
      VAULT_ADDR="http://192.168.178.40:8200"
      ROLE_ID="3748cb2f-8a13-f8db-dde3-dbe69918bc8a"
      SECRET_ID=credentials("5ca6a508-62ad-5ab0-336f-c2b8f3b7ce10")
      SECRETS_PATH="secrets/creds/dev"
  }

  stages {     
    stage('Stage 0') {
        steps {
          sh """
          export PATH=/usr/local/bin:${PATH}
          # AppRole Auth request
          curl --request POST \
            --data "{ \"role_id\": \"$ROLE_ID\", \"secret_id\": \"$SECRET_ID\" }" \
            ${VAULT_ADDR}/v1/auth/approle/login > login.json

          VAULT_TOKEN=$(cat login.json | jq -r .auth.client_token)
          # Secret read request
          curl  --header "X-Vault-Token: $VAULT_TOKEN" \
            ${VAULT_ADDR}/v1/${SECRETS_PATH} | jq .
          """
        }
    }
  }
}