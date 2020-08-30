# tv-ci-cd

Tekton, UJ for tripvibe

## Run

Bootstrap UJ argocd
```bash
cd ubiquitous-journey
helm template bootstrap --dependency-update -f bootstrap/values-bootstrap.yaml bootstrap | oc apply -f-
```

Deploy UJ apps
```bash
helm template -f ubiquitous-journey/values-tooling.yaml ubiquitous-journey/ | oc apply -n labs-ci-cd -f-
```

Prerequisite deployments as cluster admin (wip - this should become more gitops)
```bash
cd ../
# cluster operators and privileged apps
kustomize build operators | oc apply -f-
# or
oc apply -k "github.com/tripvibe/tv-ci-cd/operators?ref=master"
```

Prerequisite Secrets (wip - this should become more gitops)
```
# decrypt master for sealed secrets
ansible-vault decrypt secrets/sealed-secret-master.key --vault-password-file=~/.vault_pass.txt
# edit secret name
pod=$(oc -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key=active -o name)
sed -i -e "s|name:.*|name: ${pod##secret/}|" secrets/sealed-secret-master.key
oc replace -f secrets/sealed-secret-master.key
# restart sealedsecret controller pod
oc delete pod -n kube-system -l name=sealed-secrets-controller
# generate argocd token
oc edit cm argocd-cm

data:
  accounts.admin: apiKey

HOST=$(oc get route argocd-server --template='{{ .spec.host }}')
argocd login $HOST:443 --sso --insecure --username admin
argocd account generate-token --account admin
# regen secrets for new deployment
export DEVID=<your ptv devid>
export APIKEY=<your ptv apikey>
export ARGOCD_TOKEN=<your argocd token>
./regen-sealed-secret.sh
```

Seed CI - Deploy tripvibe Tekton resources (wip - this will move to its own seed pipeline)
```bash
cd ../ && oc project labs-ci-cd
kustomize build | oc apply -f-
# or
oc apply -k "github.com/tripvibe/tv-ci-cd/?ref=master"
```

Prerequisite for applications - run middleware pipelines manually (wip - these should become gitops)
```
# middleware
oc process s3-deploy | oc -n labs-ci-cd create -f-
oc process kafka-deploy | oc -n labs-ci-cd create -f-
```

Start an Application pipeline build manually
```bash
oc -n labs-ci-cd process sc-routes | oc -n labs-ci-cd create -f-
oc -n labs-ci-cd process tv-data-lake | oc -n labs-ci-cd create -f-
oc -n labs-ci-cd process tv-submit | oc -n labs-ci-cd create -f-
oc -n labs-ci-cd process tv-query | oc -n labs-ci-cd create -f-
oc -n labs-ci-cd process tv-streams-route-1 | oc -n labs-ci-cd create -f-
oc -n labs-ci-cd process tv-streams-route-5 | oc -n labs-ci-cd create -f-
oc -n labs-ci-cd process tv-streams-trip-1 | oc -n labs-ci-cd create -f-
oc -n labs-ci-cd process tv-streams-trip-5 | oc -n labs-ci-cd create -f-
oc -n labs-ci-cd process tripvibe | oc -n labs-ci-cd create -f-
```

Else add json webhook in github repo pointing to this route to trigger pipeline (wip - automation to create webhooks)
```bash
oc get route webhook -o custom-columns=ROUTE:.spec.host --no-headers
```

## Tekton design rationale

- Do not use PipelineResources due to the unclear nature of their future (deprecated).
- Instead, uses tasks, workspaces, results and persistent volume claims
- For each component, there is a separate PVC to allow parallel component builds without two pipeline runs stepping on each others toes. In the future (post Tekton-v0.11), the PVCs can be created on the fly instead of having to be static.
- Switched to EFS RWX for PVC's. This allows parallel builds to work as expected. No way to serialize or limit tekton pipeline runs yet. These PV'c can be made RWO if that's the only storage class you have available.
- Each source branch uses a separate output directory so we don't corrupt each other
- The git clone tasks clone their repositories into a subdirectory of this PVC, so both the dev and cicd repos reside on the same PVC.
- The maven build-and-test application pipeline is designed to be generic in nature and to be used on all components.
- Integrates with Ubiquitous Journey (ArgoCD, Helm3) app-of-apps
- Webhooks and CEL integration for application github workflow (master/trunk-based development, short lived branch builds, pull requests)
  - branches, pr's - deployed to development namespace only
  - master - deployed to development and test namespaces
  - git commit short and long ref used for images taggging and argocd sync

Directory structure:

```
├── applications                    <--->  application deployments (helm,kustomize,argocd app-or-apps pattern)
├── conditionals                    <--->  pipeline logic conditionals
├── kustomization.yaml              <--->  top level kustomize target to apply to cicd namespace
├── operators                       <--->  any middleware infra that requires privilege including operators
├── persistent-volume-claims        <--->  pipeline PVC definitions
├── pipelines                       <--->  pipeline definitions
├── rolebindings                    <--->  pipeline rbac
├── secrets                         <--->  secrets for cicd and apps
├── tasks                           <--->  pipeline tasks
├── templates                       <--->  manual templates to trigger pipelines if no webhooks deployed
├── triggers                        <--->  pipeline webhook triggers
└── ubiquitous-journey              <--->  UJ to bootstrap argocd and cicd tooling
```
