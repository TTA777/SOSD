#! /usr/bin/env bash
DATASETS=$(cat scripts/datasets_under_test.txt)
INDEXES="ALEX BTree ART PGM"

echo "Executing benchmark and saving results..."
num_iterations=1
while getopts n:c arg; do
  case $arg in
  c) do_csv=true ;;
  n) num_iterations=${OPTARG} ;;
  esac
done

echo $DATASETS

BENCHMARK=build/benchmark
if [ ! -f $BENCHMARK ]; then
  echo "benchmark binary does not exist"
  exit
fi

function do_benchmark() {

  RESULTS=./results/$1_results.txt
  if [ -f $RESULTS ]; then
    echo "Already have results for $1"
  else
    echo "Executing workload $1 for index $3"
    vtune -collect uarch-exploration -start-paused $BENCHMARK -r $2 ./data/$1 ./data/$1_equality_lookups_10M --only=$3 | tee ./results/$1_results_$3.txt
  fi
}

function do_benchmark_csv() {

  RESULTS=./results/$1_results_table.csv
  if [ -f $RESULTS ]; then
    # Previously existing file could be from incomplete run
    echo "Removing results CSV for $1"
    rm $RESULTS
  fi
  echo "Executing workload $1 for index $3 and printing to CSV"
  vtune -collect uarch-exploration -start-paused $BENCHMARK -r $2 ./data/$1 ./data/$1_equality_lookups_10M  --csv --only=$3
}

mkdir -p ./results

for dataset in $DATASETS; do
  for index in $INDEXES; do
    if [ "$do_csv" = true ]; then
      do_benchmark_csv "$dataset" $num_iterations $index
    else
      do_benchmark "$dataset" $num_iterations $index
    fi
  done
done

./result_parser.sh > results.csv