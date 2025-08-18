rm -f .charts
rm -f .charts-tmp
rm -f .tmp

for fullpath in $(find . -name Chart.yaml | sort)
do
  echo $(dirname $fullpath) >> .charts
done

count=0

cp .charts .charts-ext

while [ -s ".charts" ]; do
cp .charts .charts-tmp
rm -f ".layer${count}"
touch ".layer${count}"
for dir in $(cat .charts)
do
  waiting=0
  # check all local dependencies, if they aren't marked completed then this chart can't be either
  for dep in $(helm dependency list $dir | grep 'file://' | awk '{print $2}' | sed -n -e 's/^.*file:\/\/..\///p')
  do
    if [ $(grep -Rx "./$dep" .charts) ]; then
      waiting=1
    fi
  done
  if [ $waiting = "0" ]; then
    echo $dir >> ".layer${count}"
    cat .charts-tmp | grep -vx $dir > .tmp 
    mv .tmp .charts-tmp
  fi
done
count=$((count + 1))
mv .charts-tmp .charts
done

echo "Done building dependency map"

for layerfile in $(ls -lart | grep .layer | awk '{print $9}' | sort)
do
  cat $layerfile | parallel --halt-on-error 1 -k --joblog .dependent-results-${i} -j 16 ./scripts/build_helm_dependencies_new.sh
  cat .dependent-results-${i}
done

      
