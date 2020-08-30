#!/bin/bash

set -e

function generate_secret() {
    local project=$1;
    oc project $project
    oc delete sealedsecret/sc-routes --ignore-not-found=true
    oc delete secret/sc-routes --ignore-not-found=true

    cat <<EOF | oc apply -f -
apiVersion: "v1"
kind: "Secret"
metadata:
  name: "sc-routes"
data:
  DEVID: "$(echo -n ${DEVID} | base64)"
  APIKEY: "$(echo -n ${APIKEY} | base64)"
  INFINISPAN_REALM: "$(echo -n default | base64)"
  INFINISPAN_USER: "$(echo -n developer | base64)"
  INFINISPAN_PASSWORD: "$(echo -n $(oc exec infinispan-0 -- cat ./server/conf/users.properties | grep developer | awk -F'[=&]' '{print $2}') | base64)"
EOF

    oc get secret sc-routes -o yaml > sc-routes-secret-$project.yaml
    kubeseal < sc-routes-secret-$project.yaml > sc-routes-secret-$project-sealedsecret.yaml
    oc delete secret/sc-routes
    rm -f sc-routes-secret-$project.yaml
}

function generate_argocd() {

    oc project labs-ci-cd
    oc delete sealedsecret/argocd-env --ignore-not-found=true
    oc delete secret/argocd-env --ignore-not-found=true
    
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: argocd-env
data:
  ARGOCD_TOKEN: "$(echo -n ${ARGOCD_TOKEN} | base64 -w0)"
EOF

    oc get secret/argocd-env -o yaml > argocd-env-secret.yaml
    kubeseal < argocd-env-secret.yaml > argocd-env-secret-sealedsecret.yaml
    oc delete secret/argocd-env
    rm -f argocd-env-secret.yaml
}

[ -z "$DEVID" ] && printf "\n\033[1;35m Please export DEVID Bye...\033[m\n\n" >&2 && exit -1
[ -z "$APIKEY" ] && printf "\n\033[1;35m Please export APIKEY Bye...\033[m\n\n" >&2 && exit -1
[ -z "$ARGOCD_TOKEN" ] && printf "\n\033[1;35m Please export ARGOCD_TOKEN Bye...\033[m\n\n" >&2 && exit -1

for project in labs-ci-cd labs-dev labs-test; do
    generate_secret $project
done

generate_argocd
