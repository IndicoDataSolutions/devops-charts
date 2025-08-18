#!/bin/bash

set -e

# Requirements:
# 1. harbor.devops.indico.io is already added as a helm repo (named harbor)
# 2. cm-push is already installed as a helm plugin
# 3. yq has been added to the container
find . -name 'Chart.lock' -type f -delete
find . -name '*.tgs' -type f -delete
find . -name 'requirements.lock' -type f -delete

# Connect to all dependency helm repos
repo_index=0

rm -f .helm_repo_map

for url in $( cat required_helm_repos.txt )
do
  repo_index=$((repo_index+1))
  reponame=$(basename "$url")
  #echo "Adding helm repo $url"
  helm repo add $reponame-$repo_index $url > /dev/null
  echo "$reponame-$repo_index $url" >> .helm_repo_map
done

echo "harborprod https://harbor.devops.indico.io/chartrepo/indico-charts" >> .helm_repo_map
helm registry login --username $USERNAME --password $PASSWORD  https://harbor.devops.indico.io/indico-charts

if [ -d ".built_local_charts" ]; then
  rm -rf .built_local_charts 
  mkdir .built_local_charts
else 
  mkdir .built_local_charts
fi

export BRANCH_NAME=$1

# Build and package all helm charts
sh scripts/dependency_map_and_build.sh


# Push the packaged helm charts
if [ -f ".indico-charts" ]; then
  rm .indico-charts
fi

# only push charts that have the marker indico.chart and a Chart.yaml file in it.
for fullpath in $(find . -name indico.chart | sort)
do
  dirname=$(dirname $fullpath)
  if [ -f "$dirname/Chart.yaml" ]; then
    echo "$dirname/Chart.yaml" >> .indico-charts
  fi
done

if [ -f ".pushed" ]; then
  rm .pushed
else 
  touch .pushed
fi

jobs_parallel_pushed=1
echo "Pushing Charts $jobs_parallel_pushed way"
cat .indico-charts | parallel --halt-on-error 1 -k --joblog .push-results -j $jobs_parallel_pushed ./scripts/push_helm_chart.sh {} "$1"
echo "Finished Chart Uploads"
cat .push-results

cat .pushed
