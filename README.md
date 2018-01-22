verify if vault is initialized:
curl http://127.0.0.1:8200/v1/sys/init
response:
{"initialized":false}
To init vault:
curl -H "Content-Type: application/json" --request PUT --data @init.json http://127.0.0.1:8200/v1/sys/init
bastion vagrant # cat init.json
{
  "secret_shares": 1,
  "secret_threshold": 1
}
Verify is Vault is sealed:
curl http://127.0.0.1:8200/v1/sys/health
{"initialized":true,"sealed":true,"standby":true,"server_time_utc":1511628772,"version":"0.8.1"}


curl -H "Content-Type: application/json" --request POST -d "{ \"key\": \"$key\" }" http://127.0.0.1:8200/v1/sys/unseal
{"sealed":false,"t":1,"n":1,"progress":0,"nonce":"","version":"0.8.1","cluster_name":"vault-cluster-c619ab10","cluster_id":"a581c2c6-6c27-88cb-db38-59b8da9c68f3"}
the key is the keys output of the init

curl http://127.0.0.1:8200/v1/sys/health
{"initialized":true,"sealed":false,"standby":false,"server_time_utc":1511629215,"version":"0.8.1","cluster_name":"vault-cluster-c619ab10","cluster_id":"a581c2c6-6c27-88cb-db38-59b8da9c68f3"}


Mount backend for certs:
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @mount.json http://0.0.0.0:8200/v1/sys/mounts/vault
bastion vagrant # cat mount.json
{
    "type": "pki",
    "config": {
      "default_lease_ttl": "3600",
      "max_lease_ttl": "7200"
    }
}

curl -H "X-Vault-Token: $root_token" http://127.0.0.1:8200/v1/sys/mounts
{"etcd/":{"accessor":"pki_16702728","config":{"default_lease_ttl":3600,"force_no_cache":false,"max_lease_ttl":7200},"description":"","local":false,"type":"pki"},"secret/":{"accessor":"generic_b86c4ed7","config":{"default_lease_ttl":0,"force_no_cache":false,"max_lease_ttl":0},"description":"generic secret storage","local":false,"type":"generic"},"sys/":{"accessor":"system_e4d7aa28","config":{"default_lease_ttl":0,"force_no_cache":false,"max_lease_ttl":0},"description":"system endpoints used for control, policy and debugging","local":false,"type":"system"},"cubbyhole/":{"accessor":"cubbyhole_d998293e","config":{"default_lease_ttl":0,"force_no_cache":false,"max_lease_ttl":0},"description":"per-token private secret storage","local":true,"type":"cubbyhole"},"vault/":{"accessor":"pki_1c8f046e","config":{"default_lease_ttl":3600,"force_no_cache":false,"max_lease_ttl":7200},"description":"","local":false,"type":"pki"},"request_id":"9e14e215-504d-7b50-7bf8-25fe4099aa31","lease_id":"","renewable":false,"lease_duration":0,"data":{"cubbyhole/":{"accessor":"cubbyhole_d998293e","config":{"default_lease_ttl":0,"force_no_cache":false,"max_lease_ttl":0},"description":"per-token private secret storage","local":true,"type":"cubbyhole"},"etcd/":{"accessor":"pki_16702728","config":{"default_lease_ttl":3600,"force_no_cache":false,"max_lease_ttl":7200},"description":"","local":false,"type":"pki"},"secret/":{"accessor":"generic_b86c4ed7","config":{"default_lease_ttl":0,"force_no_cache":false,"max_lease_ttl":0},"description":"generic secret storage","local":false,"type":"generic"},"sys/":{"accessor":"system_e4d7aa28","config":{"default_lease_ttl":0,"force_no_cache":false,"max_lease_ttl":0},"description":"system endpoints used for control, policy and debugging","local":false,"type":"system"},"vault/":{"accessor":"pki_1c8f046e","config":{"default_lease_ttl":3600,"force_no_cache":false,"max_lease_ttl":7200},"description":"","local":false,"type":"pki"}},"wrap_info":null,"warnings":null,"auth":null}


generate certificates:
{
    "common_name": "vault",
    "format": "pem",
    "ttl": "3600",
    "exclude_cn_from_sans": "true",
    "alt_names": "vault.kube-system.svc.cluster.local, vault.kube-system.svc, vault.kube-system, vault"
}
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @genCertVault.json http://0.0.0.0:8200/v1/vault/root/generate/exported
{"request_id":"349c3009-9454-8361-88d5-e65b032cd606","lease_id":"","renewable":false,"lease_duration":0,"data":{"certificate":"-----BEGIN CERTIFICATE-----\nMIIDUzCCAjugAwIBAgIUD5mI+hfDFBCfRr5+UlTfsAZN/7EwDQYJKoZIhvcNAQEL\nBQAwEDEOMAwGA1UEAxMFdmF1bHQwHhcNMTcxMTI1MjIzNjMwWhcNMTcxMTI1MjMz\nNzAwWjAQMQ4wDAYDVQQDEwV2YXVsdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC\nAQoCggEBAMndqYWZCCKEA2u2bcRUJOIiXKLDWXISHYzniAa6IlXbxMcA5LB+xVvS\n1jDnSWMr68m8LCHmb4OEMXbIAh1gZeN/olHnwB+SWuhLA2lNOLqA+hF1j6h/ozXJ\nojTzf6mEAwoOwDro5DaMZ3Pk3G+FxMXF9GxpBeE7/Yff65H0cCzgQP5D4OOdhq+T\nOWUYdr//N6R35ub2Uj11VKAO7OL7sobGR33UFPZvVaaIDLXBuDhpH4FydUHqxvYu\n9Xj9PZxoLTAxQFpXfLUERoMlj1F6DbmVVaGn90Q8lIfmE3iq2Y673nrWl+WIrhqp\nzGu/2Iga9UBCmMc4cgV9fUVcYG1TNikCAwEAAaOBpDCBoTAOBgNVHQ8BAf8EBAMC\nAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUXr9pBNynx0D9fPyVA4akYyPY\njkQwXwYDVR0RBFgwVoIFdmF1bHSCEXZhdWx0Lmt1YmUtc3lzdGVtghV2YXVsdC5r\ndWJlLXN5c3RlbS5zdmOCI3ZhdWx0Lmt1YmUtc3lzdGVtLnN2Yy5jbHVzdGVyLmxv\nY2FsMA0GCSqGSIb3DQEBCwUAA4IBAQAcYVaDmacCL4CQEsQd1PHfWJK/1B+idTHo\nQzyMHpSS+PteiVGZsr2VZJuUZuRKn0DP4z8dxOov7Z/fGrwF32CL+PMW4vqPVuQ8\ny5XmnjMAShNKBJVPKygMiRgsIzSIx1kmduV7KMtis7189mrim9FNcc9S17cel8ci\njab1ejElVK4rLaZPpM6HaMnoQqaAmQIL5myUf+bbvtCj/061vwy+OKA1+xNunsm6\nir/tPSZcxwnS9wVR+Waf9zwI/iiu/AQj0sx+GzYKTD97cs5AaMt91XuaWem7+VVR\nxIYGj8phHH/5wcuoGh0GUa5YcC8hTQ6KTKpKnhpLxkDFdsQVy5ra\n-----END CERTIFICATE-----","expiration":1511653020,"issuing_ca":"-----BEGIN CERTIFICATE-----\nMIIDUzCCAjugAwIBAgIUD5mI+hfDFBCfRr5+UlTfsAZN/7EwDQYJKoZIhvcNAQEL\nBQAwEDEOMAwGA1UEAxMFdmF1bHQwHhcNMTcxMTI1MjIzNjMwWhcNMTcxMTI1MjMz\nNzAwWjAQMQ4wDAYDVQQDEwV2YXVsdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC\nAQoCggEBAMndqYWZCCKEA2u2bcRUJOIiXKLDWXISHYzniAa6IlXbxMcA5LB+xVvS\n1jDnSWMr68m8LCHmb4OEMXbIAh1gZeN/olHnwB+SWuhLA2lNOLqA+hF1j6h/ozXJ\nojTzf6mEAwoOwDro5DaMZ3Pk3G+FxMXF9GxpBeE7/Yff65H0cCzgQP5D4OOdhq+T\nOWUYdr//N6R35ub2Uj11VKAO7OL7sobGR33UFPZvVaaIDLXBuDhpH4FydUHqxvYu\n9Xj9PZxoLTAxQFpXfLUERoMlj1F6DbmVVaGn90Q8lIfmE3iq2Y673nrWl+WIrhqp\nzGu/2Iga9UBCmMc4cgV9fUVcYG1TNikCAwEAAaOBpDCBoTAOBgNVHQ8BAf8EBAMC\nAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUXr9pBNynx0D9fPyVA4akYyPY\njkQwXwYDVR0RBFgwVoIFdmF1bHSCEXZhdWx0Lmt1YmUtc3lzdGVtghV2YXVsdC5r\ndWJlLXN5c3RlbS5zdmOCI3ZhdWx0Lmt1YmUtc3lzdGVtLnN2Yy5jbHVzdGVyLmxv\nY2FsMA0GCSqGSIb3DQEBCwUAA4IBAQAcYVaDmacCL4CQEsQd1PHfWJK/1B+idTHo\nQzyMHpSS+PteiVGZsr2VZJuUZuRKn0DP4z8dxOov7Z/fGrwF32CL+PMW4vqPVuQ8\ny5XmnjMAShNKBJVPKygMiRgsIzSIx1kmduV7KMtis7189mrim9FNcc9S17cel8ci\njab1ejElVK4rLaZPpM6HaMnoQqaAmQIL5myUf+bbvtCj/061vwy+OKA1+xNunsm6\nir/tPSZcxwnS9wVR+Waf9zwI/iiu/AQj0sx+GzYKTD97cs5AaMt91XuaWem7+VVR\nxIYGj8phHH/5wcuoGh0GUa5YcC8hTQ6KTKpKnhpLxkDFdsQVy5ra\n-----END CERTIFICATE-----","private_key":"-----BEGIN RSA PRIVATE KEY-----\nMIIEogIBAAKCAQEAyd2phZkIIoQDa7ZtxFQk4iJcosNZchIdjOeIBroiVdvExwDk\nsH7FW9LWMOdJYyvrybwsIeZvg4QxdsgCHWBl43+iUefAH5Ja6EsDaU04uoD6EXWP\nqH+jNcmiNPN/qYQDCg7AOujkNoxnc+Tcb4XExcX0bGkF4Tv9h9/rkfRwLOBA/kPg\n452Gr5M5ZRh2v/83pHfm5vZSPXVUoA7s4vuyhsZHfdQU9m9VpogMtcG4OGkfgXJ1\nQerG9i71eP09nGgtMDFAWld8tQRGgyWPUXoNuZVVoaf3RDyUh+YTeKrZjrveetaX\n5YiuGqnMa7/YiBr1QEKYxzhyBX19RVxgbVM2KQIDAQABAoIBAD7Qa9S3ltFutMXK\noYNrD4MSYDMBiI63VlynGyvEtbRzy1qFS6Qj/nOhOqdDARIL87X1iOIPm3mYI/Ar\nMoVDntDYwYCtFZp9Zy5LUUduEQ3v3mCabVZoSTgOgxvo/TuZaXyytFxgZcsXi4WD\nnJhTTrSf8Xvefkbk7PJf2iSzpEhB/lsijs4tSs3qQPsKlHGfFu+KDnk99erTjm5d\nuwCRiqiOzz3+i8ua/Y9LyZTmomeXSYTc1On/DO+SLF7Ja09zbLeMPkGGK6bFUCK2\npa9vtvvPAUznPS57lf8HOfYPFbWSmhzxhBxf551J4Ax4AePjObAG6QAMNQey/ihz\nIjHbhPUCgYEA5fV0LyOV9+DOJoVbQ3kf9kOyqLAgFtLRLxvr2oJidio1xFrdIXe6\nuCvDqorJyohJ6gjkZybfWJpym3aliUtDaG58C6+oizN/fVr8lXgneplLmkeAiaUr\nHY0VEM8EN5/vsmZCpcf3f4aIHuO6adAev931fu5oCcqDGeq0ujn0WIcCgYEA4LnK\nCJW2BjMlPv7GwoU0iSMyTmEPj6btyy7ytjUBsG2rNzdt4k66uf9DXKX2mA8UQtAv\nblEGP1ac1Lfqo8xlQL8I0258HN2pGo1kj8WyWfBsHTGmdEppWDdlYNjDUd86PmOL\nAdIyXeb6NLnx8fpD6yC9fZVppQb+lSw3ahU4l88CgYAZ841dFIMEKlaZektGXhEB\nVbp/1wCIEtqQmnIPgs9hznmq4yY5dK2ZwzadtHP5a1AMHVzJV1W1RhjQ+p7L07aT\nvoQ5PWWj7/ffSblflOO/rjUeABu9bOpkt1s9Pl+Xd3ExjODQnLSNq70I32JWNqqB\ntKbT4EvVbwlEj3w91/R/WQKBgHe8plgypLzi7XqGN5MXdGmJdllqv+bTk6oKBsps\nrcy6clrGTucg+b72soaf6ycUCcCbuln2E/UVihSRNhU2Z9C6uNIm8TxUIrECG027\nkY74WjKn7L/TkhOt2Hdkp5Vs8lShp0Q+IhYEZtZHKRG8Pgn+9NgADz0d3/HNkG0W\nh4PjAoGAQ5RL7WCc1by9jQEqHb/xHfKDfOrHrG/DaOcRNuu/EDnuZLV2OwnKYYKT\nUwHznCg4kfM11wcEXgVS328cTkRdNqZdnZhhqWZYb4qNaY1qEu5KQa3+jBS3v6pG\nB3PaiAn5qmL/w9ZnRR6NNN3a2iIZRgFbdbK4DV9PkLK2cEyWgX8=\n-----END RSA PRIVATE KEY-----","private_key_type":"rsa","serial_number":"0f:99:88:fa:17:c3:14:10:9f:46:be:7e:52:54:df:b0:06:4d:ff:b1"},"wrap_info":null,"warnings":null,"auth":null}

