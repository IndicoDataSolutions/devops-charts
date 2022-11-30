#!/bin/bash

set -e

num_charts=0
num_pushed=0
skipped_charts=()
pushed_charts=()
validate_versions=()
devel=''

# our chart repository
# harbordevops https://harbor.devops.indico.io/chartrepo/indico-devops

for fullpath in $(find . -name Chart.yaml | sort)
do
  dir=$(dirname $fullpath)
  name=$(helm show chart $dir | yq '.name')
  version=$(helm show chart $dir | yq '.version')
  devel=''
  echo "Processing chart ${name}"
  for dep in $(helm dependency list $dir | grep 'file://' | awk '{print $1}')
  do
    echo "  ${name}: helm dependency build $dep"
    helm dependency build $dep > /dev/null
  done
  
  # not building on main
  if [ ! -z "$1" ]; then
    branch=${1//\//\-} # replace slashes with -
    branch=${branch//_/\-} # replace underscores with -
   
    if [ ! -z "$DRONE_TAG" ]; then
      version=$version-${DRONE_TAG}
    else
      version=$version-$branch
    fi
    devel='--devel'
  else
  # on main, respect the tag if it exists
    if [ ! -z "$DRONE_TAG" ]; then
      version=$version-${DRONE_TAG}
    fi
  fi
 
  num_charts=$((num_charts+1))

  echo "Working on Chart $name, Version: $version"
 
  if [ -d "$dir/tests" ]
  then
    for testfile in $(find $dir/tests -name '*.yaml')
    do
      testname=$(basename "$testfile")
      echo "Running test with $testfile"
    
      echo helm template ./$dir --dependency-update --name-template $testname --namespace default --kube-version 1.20 --values $testfile --include-crds --debug
      helm template ./$dir --dependency-update --name-template $testname --namespace default --kube-version 1.20 --values $testfile --include-crds --debug
      
      echo "Linting chart"
      helm lint ./$dir --values $testfile

      echo "Images referenced"
      helm template ./$dir --dependency-update --name-template $testname --namespace default --kube-version 1.20 --values $testfile --include-crds | yq '..|.image? | select(.)' | sort -u
    done
  fi

  prod_chart=$(helm search repo ${devel} --regexp "harbordevops/$name"'[^-]' --version $version -o json | jq '.[0].name')

  needs_update="true"

  if [ "${prod_chart}" == "null" ]; then
    if [ "${needs_update}" == "true" ]; then
      helm dependency build ./$dir > /dev/null
      helm package ./$dir -d ./$dir --version $version
      needs_update="false"
    fi
    num_pushed=$((num_pushed+1))
    cv="harbordevops/${name}:--version:${version}"
   
    validate_versions+=(${cv})

    helm cm-push ./$dir --version $version harbordevops
    helm repo update harbordevops > /dev/null
 
    pushed_charts+=("\t--> harbordevops/${name}:${version}\n")
  else
    skipped_charts+=("\t--- harbordevops/${name}:${version}\n")
  fi

done

echo "Validating Chart Pushes with ${validate_versions}"
helm repo update harbordevops
for cv in ${validate_versions[*]}
do
  chart_name=${cv//:/ }
  echo "Validating ${cv} as ${chart_name}"
  echo "  helm search repo ${devel} ${chart_name}  -o json | jq '.[0].name'"
  uploaded_chart=$(helm search repo ${devel} ${chart_name} -o json | jq '.[0].name')
  if [ "${uploaded_chart}" == "null" ]; then
      helm repo update harbordevops
      uploaded_chart=$(helm search repo ${devel} ${chart_name} -o json | jq '.[0].name')
      if [ "${uploaded_chart}" == "null" ]; then
        echo "Error Uploading Chart: ${chart_name}"
        exit 1
      fi
  else
      echo "Successfully uploaded ${chart_name}"
  fi
done

echo -e "\nPushed Charts:"
echo -e "${pushed_charts[*]}"
echo -e "\nSkipped Charts:"
echo -e "${skipped_charts[*]}"
echo -e "Total charts processed: ${num_charts}, total pushed ${num_pushed}"
