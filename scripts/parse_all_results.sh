#! /usr/bin/env bash

for write_portion in 0 25 50 75 100; do
  for iteration in 1 2 3; do
    echo "Parsing results from results/$write_portion/$iteration/"
    ./scripts/result_parser.sh "results/$write_portion/$iteration/" >"results_w"$write_portion"_it"$iteration".csv"
  done
done
