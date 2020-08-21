# reusable tekton pipelines

- maven-pipeline - github workflow using gitops, supports branches and pr's and creates ArgoCD applications for CD. reusable across java/mvn applications. uses a jdk, mvn, mandrel based image for quarkus curerntly for CI.

## middleware infra pipelines

WIP these will migrate to a more gitops workflow, but for now are fairly simple oc apply kustomize type flows.

They also have dependencies on the cluster operators, which needs to be dealt with.