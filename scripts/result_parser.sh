#! /usr/bin/env bash
# Script assumes SOSD is only run for a single data structure at a time, and for a single repetition
RESULT_NAME=results/$1
QUERY_COUNT=10000000 #TODO replace with other count if workload is changed from 10M
function formatTmamMetric() {
  UNFORMATED=$1
  echo -n $UNFORMATED | sed 's/ *:.*//'
  echo -ne '\t'
  echo $UNFORMATED | sed 's/ *%.*//' | sed 's/.*://'
}

function getOverallMetrics() {
  FILE=$1
  SOSDRESULT=$(cat $FILE | grep RESULT| sed 's/,/ /g' )
  echo -ne 'Index\t'
  echo $SOSDRESULT | awk '{print $2}'
  echo -ne 'Dataset \t'
  echo $FILE | sed 's/_results.txt//' | sed 's/results\///'
  echo -ne 'Memory (Bytes)\t'
  echo $SOSDRESULT | awk '{print $5}'
  echo -ne 'Build_time(ms?|ns?)\t'
  echo $SOSDRESULT | awk '{print $6}'
  echo -ne 'Average_lookup_time(ns?)\t'
  echo $SOSDRESULT | awk '{print $4}'
  formatTmamMetric "$(cat $FILE | grep 'Elapsed Time')"
  formatTmamMetric "$(cat $FILE | grep 'Clockticks:')"
  formatTmamMetric "$(cat $FILE | grep 'Instructions Retired:')"
  formatTmamMetric "$(cat $FILE | grep 'CPI Rate:')"
  Retired=$(formatTmamMetric "$(cat $FILE | grep 'Instructions Retired:' )" | awk '{print $3}' | sed 's/,//g')
  Clockticks=$(formatTmamMetric "$(cat $FILE | grep 'Clockticks:' )" | awk '{print $2}'| sed 's/,//g')
  echo -ne "Instructions retired per request\t"
  awk -v var1=$Retired -v var2=$QUERY_COUNT 'BEGIN { print  ( var1 / var2 ) }'
}

function printColumnHeaders() {
  echo -ne "Index \t"
  echo -ne "Dataset \t"
  echo -ne "Memory (Bytes) \t"
  echo -ne "Build_time(ms?|ns?) \t"
  echo -ne "Average_lookup_time(ns?) \t"
  echo -ne "Elapsed Time\t"
  echo -ne "Clockticks\t"
  echo -ne "Instructions Retired\t"
  echo -ne "CPI Rate\t"
  echo -ne "Instructions retired per request\t"
  echo -ne "Retiring\t"
  echo -ne "Front-End Bound\t"
  echo -ne "Bad Speculation\t"
  echo -ne "Back-End Bound\t"
  echo -ne "Memory Bound\t"
  echo -ne "L1 Bound\t"
  echo -ne "L2 Bound\t"
  echo -ne "L3  Bound\t"
  echo -ne "DRAM Bound\t"
  echo -ne "Store Bound\t"
  echo -e "Core Bound\t"
}

for file in $(ls results | grep .txt); do
  echo $file #TODO delete me
  printColumnHeaders
  getOverallMetrics "results/"$file
  # TMAM metrics
  while read -r line; do
    if [[ $line =~ "Bad" || $line =~ "Bound:" || $line =~ "Retiring" ]]; then
      formatTmamMetric "$line"
    fi
  done <"results/$file"
  echo
done
