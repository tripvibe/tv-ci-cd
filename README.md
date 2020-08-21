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
# cluster operators
kustomize build operators | oc apply -f-
```

Prerequisite Secrets (wip - this should become more gitops)
```
# decrypt master for sealed secrets
ansible-vault decrypt secrets/sealed-secret-master.key --vault-password-file=~/.vault_pass.txt
# edit secret name
pod=$(oc -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key=active -o name)
sed -i -e "s|name:.*|name: ${pod##secret/}|" secrets/sealed-secret-master.key
# restart sealedsecret controller pod
oc delete pod -n kube-system -l name=sealed-secrets-controller
```

Deploy tripvibe Tekton resources (wip - this will move to its own seed pipeline)
```bash
cd ../
oc project labs-ci-cd
kustomize build | oc apply -f-
```

Pre-requisites for applications run middleware pipelines manually (wip - these should become gitops)
```
# middleware
oc process s3-deploy | oc -n labs-ci-cd create -f-
oc process kafka-deploy | oc -n labs-ci-cd create -f-
```

Start an Application pipeline build manually
```bash
oc process build-image-tv-data-lake | oc create -f-
```

Else add json webhook in github repo pointing to this route to trigger pipeline (wip - automation to create webhooks)
```bash
oc get route webhook -o custom-columns=ROUTE:.spec.host --no-headers
```

## Tekton design rationale

- Do not use PipelineResources due to the unclear nature of their future (deprecated).
- Instead, uses tasks, workspaces, results and persistent volume claims
- For each component, there is a separate PVC to allow parallel component builds without two pipeline runs stepping on each others toes. In the future (post Tekton-v0.11), the PVCs can be created on the fly instead of having to be static.
- Each source branch uses a separate output directory so we dont corrupt each other
- The git clone tasks clone their repositories into a subdirectory of this PVC, so both the dev and ops repos reside on the same PVC.
- The build-and-test application pipeline is designed to be generic in nature and to be used on all components.
- Integrates with Ubiquitous Journey (ArgoCD, Helm3) app-of-apps
- Webhooks and CEL integration for application github workflow (master/trunk-based development, short lived branch builds, pull requests)
  - branches, pr's - deployed to development namespace only
  - master - deployed to development and test namespaces
  - git commit short and long ref used for images taggging and argocd sync