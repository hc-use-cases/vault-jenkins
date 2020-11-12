# vault-jenkins
Vault + Jenkins

This is an example of Jenkins - Vault Approle integration which use `curl` for authentication. This allows Jenkins to authenticate to Vault and use token to retrieve secrets. This example doesn't rely on [Jenkins Vault Plugin](https://plugins.jenkins.io/hashicorp-vault-plugin/)

AppRole authentication relies on `ROLE_ID` and `SECRET_ID` to login adn retrieve a Vault token

# How to consume

> pre-configure networking in `Vagrantfile`

```bash
git clone git@github.com:hc-use-cases/vault-jenkins.git
cd vault-jenkins
vagrant up
```

result will look similar to this

```vagrant
$ vagrant status
Current machine states:

consul1                   running (virtualbox)
consul2                   running (virtualbox)
consul3                   running (virtualbox)
vault                     running (virtualbox)
jenkins                   running (virtualbox)
```

this example use Vault + Consul as backend. once the infrastructure will be up `Vault` will be unsealed

check root token and unseal key 

```bash
cat /vagrant/init.txt
```

## Vault

example below will configure AppRole Auth method. Define AppRole, get `ROLE_ID` and `SECRET_ID`

```
vagrant ssh vault
vault secrets enable -path=secrets kv
vault write secrets/creds/dev username=dev password=legos
cat <<EOF > jenkins-policy.hcl
path "secrets/creds/dev" {
 capabilities = ["read"]
}
EOF
vault policy write jenkins jenkins-policy.hcl
vault auth enable approle
vault write auth/approle/role/jenkins-role \
    secret_id_ttl=24h \
    token_num_uses=5 \
    token_ttl=20m \
    token_max_ttl=30m \
    secret_id_num_uses=40 \
    policies="jenkins"

# Use .data.role_id in role.json file as the ROLE_ID for Jenkins setup
vault read -format=json auth/approle/role/jenkins-role/role-id > role.json

# Use .data.secret_id in secretid.json file as the SECRET_ID for Jenkins credential
vault write -format=json -f auth/approle/role/jenkins-role/secret-id > secretid.json
```

## Jenkins
configure Jenkins 

get the admin password for Jenkins configuration

```bash
vagrant ssh jenkins
cat /var/lib/jenkins/secrets/initialAdminPassword
```

continue the configuration `http://192.168.178.60:8080`

Example of Jenkins pipeline in `Jenkinsfile`

Environment variables need to be adjusted (from previous step)

- VAULT_ADDR - Vault server
- ROLE_ID - `cat role.json | jq -r .data.role_id`
- SECRET_ID - `cat secretid.json | jq -r .data.secret_id`

```groovy
pipeline {
agent any
  environment {
      VAULT_ADDR="http://192.168.178.40:8200"
      ROLE_ID="3748cb2f-8a13-f8db-dde3-dbe69918bc8a"
      SECRET_ID="5ca6a508-62ad-5ab0-336f-c2b8f3b7ce10"
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
```

## Result should look similar - `cli`

- Authentication 

```bash
curl --request POST \
--data "{ \"role_id\": \"$ROLE_ID\", \"secret_id\": \"$SECRET_ID\" }" \
${VAULT_ADDR}/v1/auth/approle/login > login.json
```

- Read the secret

```bash
VAULT_TOKEN=$(cat login.json | jq -r .auth.client_token)
curl  --header "X-Vault-Token: $VAULT_TOKEN" \
${VAULT_ADDR}/v1/${SECRETS_PATH} | jq .
```

- Result

```json
{
  "request_id": "2c987293-09b6-738a-66cf-ca0b4e0f678d",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 604800,
  "data": {
    "password": "legos",
    "username": "dev"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```
