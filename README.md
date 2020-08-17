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

Deploy tripvibe Tekton resources
```bash
cd ../
kustomize build | oc apply -f-
```

Start a pipeline build
```bash
oc process build-image-tv-data-lake | oc create -f-
```

## Tekton design rationale

- Do not use PipelineResources due to the unclear nature of their future (deprecated).
- Instead, uses tasks, workspaces, results and persistent volume claims
- For each component, there is a separate PVC to allow parallel component builds without two pipeline runs stepping on each others toes. In the future (post Tekton-v0.11), the PVCs can be created on the fly instead of having to be static.
- The git clone tasks clone their repositories into a subdirectory of this PVC, so both the dev and ops repos reside on the same PVC.
- The build-and-test pipeline is designed to be generic in nature and to be used on all components.
