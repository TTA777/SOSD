#! /usr/bin/env bash
DATASETS_UNDER_TEST=scripts/datasets_under_test.txt
INDEXES="ALEX BTree ART PGM"
WRITE_PORTION=0

echo "Executing benchmark and saving results..."
num_iterations=1
while getopts "n:d:w:i:c" arg; do
  case $arg in
  c) do_csv=true ;;
  n) num_iterations=$OPTARG ;;
  i) ITERATION=$OPTARG ;;
  w) WRITE_PORTION=$OPTARG ;;
  d) DATASETS_UNDER_TEST=$OPTARG ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    exit 1
    ;;
  :)
    echo "Option -$OPTARG requires an argument." >&2
    exit 1
    ;;
  esac
done

DATASETS=$(cat $DATASETS_UNDER_TEST)
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
    vtune -collect uarch-exploration -start-paused $BENCHMARK -r $2 ./data/$1 ./data/$1_equality_lookups_100M --write=$WRITE_PORTION --only=$3 | tee ./results/$WRITE_PORTION/$ITERATION/$1_results_$3.txt
  fi
}

mkdir -p ./results/$WRITE_PORTION/$ITERATION

for dataset in $DATASETS; do
  for index in $INDEXES; do
    if [ "$do_csv" = true ]; then
      do_benchmark_csv "$dataset" $num_iterations $index
    else
      do_benchmark "$dataset" $num_iterations $index
    fi
  done
done

./scripts/result_parser.sh "results/$WRITE_PORTION/$ITERATION/" > "results_w"$WRITE_PORTION"_it"$ITERATION".csv"