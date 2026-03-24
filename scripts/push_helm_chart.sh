#!/bin/bash

set -e
fullpath=${1#"./"}
BRANCH_NAME=$2  # e.g: "main-xxxxxx"

dir=$(dirname $fullpath)
name=$(helm show chart $dir | yq '.name')
version=$(helm show chart $dir | yq '.version')
chart_version=$version

echo " "
echo "-------------------------------------------------------------------------------------------"

branch=${BRANCH_NAME//\//\-} # replace slashes with -
branch=${branch//_/\-} # replace underscores with -

if [ ! -z "$DRONE_TAG" ]; then
  version=$version-${DRONE_TAG}
else
  version=$version-$branch
fi

num_charts=$((num_charts+1))

echo "Working on Chart $name, Version: $version"

if [ -d "$dir/tests" ]
then
  for testfile in $(find $dir/tests -name '*.yaml')
  do
    testname=$(basename "$testfile")
    echo "Running test with $testfile"
  
    echo helm template ./$dir --dependency-update --name-template $testname --namespace default --kube-version 1.27 --values $testfile --include-crds --debug > /dev/null
    helm template ./$dir --dependency-update --name-template $testname --namespace default --kube-version 1.27 --values $testfile --include-crds --debug > /dev/null
      

    echo "Linting chart"
    helm lint ./$dir --values $testfile

    echo "Images referenced"
    helm template ./$dir --dependency-update --name-template $testname --namespace default --kube-version 1.27 --values $testfile --include-crds | yq '..|.image? | select(.)' | sort -u
  done
fi

#Push chart, check if it succeeded, if not, retry.
oci_chart_tgz=$(ls .built_oci_charts | grep "^$dir-v*[0-9]*\.[0-9]*\.[0-9]*-.*.tgz")
pushed="false"
retry_attempts=10
until [ $pushed == "true" ] || [ $retry_attempts -le 0 ]
do
  if [ $retry_attempts -ne 10 ]; then
    echo "Retry push ${dir} [$retry_attempts]"
    sleep 10
  fi

  set +e
  echo "helm push .built_oci_charts/$oci_chart_tgz oci://harbor.devops.indico.io/indico-charts [$retry_attempts]"
  if helm push .built_oci_charts/$oci_chart_tgz oci://harbor.devops.indico.io/indico-charts; then
    echo "\t--> oci://harbor.devops.indico.io/indico-charts/${name}:${version}\n" >> .pushed
    pushed="true"
  else
    pushed="false"
  fi
  set -e
  ((retry_attempts--))
done

echo "done"
set -e
# double-check that the chart was pushed.
if [ $retry_attempts -le 0 ]; then
  echo "Error: Unable to push oci://harbor.devops.indico.io/indico-charts/${name}:${version}"
  exit 1
fi







