#!/bin/bash
# with the new method we know that all dependent charts are already built
set -euxo pipefail
dir=$1

if [ -d "$dir/charts" ]; then
  rm -rf $dir/charts
  mkdir $dir/charts
else 
  mkdir $dir/charts
fi

for local_chart in $(helm dependency list $dir | grep "file://" | awk '{print $2}' | sed -n -e 's/^.*file:\/\/..\///p' )
do
  local_chart_tgz=$(ls .built_local_charts | grep "^$local_chart-v*[0-9]*\.[0-9]*\.[0-9]*\.tgz")
  cp ./.built_local_charts/$local_chart_tgz $dir/charts
done

IFS=$'\n' # make newlines the only separator
for external_chart in $(helm dependency list $dir | grep -E 'https://|oci://' )
do
  chart=$(echo $external_chart | awk '{print $1}')
  version=$(echo $external_chart | awk '{print $2}')
  source_registry=$(echo $external_chart | awk '{print $3}')

  if [[ $source_registry == oci://* ]]; then
    helm pull $source_registry/$chart --version $version --destination $dir/charts
  else
    registry_name=$(cat .helm_repo_map | grep "$source_registry" | uniq | awk '{print $1}')

    helm pull $registry_name/$chart --version $version --destination $dir/charts
  fi
done
unset IFS

helm package $dir --destination ./.built_local_charts

mkdir -p .built_oci_charts

branch=${BRANCH_NAME//\//\-} # replace slashes with -
branch=${branch//_/\-} # replace underscores with -

chart_version=$(helm show chart $dir | grep '^version:' | awk '{print $2}')

if [ ! -z "$DRONE_TAG" ]; then
  version=$chart_version-${DRONE_TAG}
else
  version=$chart_version-$branch
fi

helm package $dir --version "$version" --destination ./.built_oci_charts
