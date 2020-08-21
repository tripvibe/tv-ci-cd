# secrets

dumping ground for secrets. this needs solutioning e.g.

- Sealed Secrets (basic)
- Vault (as deployed in UJ)
- External Secrets - https://www.openshift.com/blog/gitops-secret-management

## Sealed Secrets

UJ also supports this deployment (wip - fixme, auth)

Backup cluster secret - Not safe for git !
```
oc get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key=active -o yaml > sealed-secret-master.key
# encrypt master
ansible-vault encrypt sealed-secret-master.key --vault-password-file=~/.vault_pass.txt
```

(new cluster) Replace new secret install with existing key
```
# decrypt master for sealed secrets
ansible-vault decrypt secrets/sealed-secret-master.key --vault-password-file=~/.vault_pass.txt
# edit secret name
pod=$(oc -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key=active -o name)
sed -i -e "s|name:.*|name: ${pod##secret/}|" secrets/sealed-secret-master.key
oc replace -f ~/secrets/sealed-secret-master.key
# restart sealedsecret controller pod
oc delete pod -n kube-system -l name=sealed-secrets-controller
```

`kubeseal` Client for generating secrets
```
release=$(curl --silent "https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
GOOS=$(go env GOOS)
GOARCH=$(go env GOARCH)
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/$release/kubeseal-$GOOS-$GOARCH
sudo install -m 755 kubeseal-$GOOS-$GOARCH /usr/local/bin/kubeseal
```

Test
```
cd ~/tv-ci-cd/secrets
kubeseal < argocd-env-secret.yaml > argocd-env-secret-sealedsecret.yaml
oc delete secret argocd-env
oc apply -f argocd-env-secret-sealedsecret.yaml
```
