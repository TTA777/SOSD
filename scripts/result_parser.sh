#! /usr/bin/env bash
# Script assumes SOSD is only run for a single data structure at a time, and for a single repetition
RESULT_NAME=results/$1
QUERY_COUNT=10000000 #TODO replace with other count if workload is changed from 10M
function formatTmamMetric() {
  UNFORMATED=$1
  echo -n $UNFORMATED| sed 's/ *%.*//' | sed 's/.*://'
  echo -ne "\t"
}

function getOverallMetrics() {
  FILE=$1
  SOSDRESULT=$(cat $FILE | grep RESULT| sed 's/,/ /g' )
  echo $SOSDRESULT'\t' | awk '{printf $2 "\t"}' #Index name
  echo -ne $FILE'\t' | sed 's/_results.*.txt//' | sed 's/results\///' #Dataset name
  echo $SOSDRESULT | awk '{printf $5 "\t"}' # Memory(bytes)
  echo $SOSDRESULT | awk '{printf $6 "\t"}' # Build_time(ns)
  echo $SOSDRESULT | awk '{printf $8 "\t"}' # Total_Query_time(ns)
  echo $SOSDRESULT | awk '{printf $9 "\t"}' # Lookup count
  echo $SOSDRESULT | awk '{printf $4 "\t"}' #  Average_lookup_time(ns)\
  formatTmamMetric "$(cat $FILE | grep 'Clockticks:'| sed 's/,//g')"
  formatTmamMetric "$(cat $FILE | grep 'Instructions Retired:'| sed 's/,//g')"
  formatTmamMetric "$(cat $FILE | grep 'CPI Rate:')"
  Retired=$(formatTmamMetric "$(cat $FILE | grep 'Instructions Retired:' )"  | sed 's/,//g')
  Clockticks=$(formatTmamMetric "$(cat $FILE | grep 'Clockticks:' )" | sed 's/,//g')
  awk -v var1="$Retired" -v var2="$QUERY_COUNT" 'BEGIN { printf  ( var1 / var2 ) "\t" }' # Instructions retired per request
  }

function printColumnHeaders() {
  echo -ne "Index \t"
  echo -ne "Dataset \t"
  echo -ne "Memory (Bytes) \t"
  echo -ne "Build_time(ns) \t"
  echo -ne "Total_Query_time(ns) \t"
  echo -ne "Average_lookup_time(ns) \t"
  echo -ne "Lookup count\t"
  echo -ne "Clockticks\t"
  echo -ne "Instructions Retired\t"
  echo -ne "CPI Rate\t"
  echo -ne "Instructions retired per request\t"
  echo -ne "Retiring(Normalized)\t"
  echo -ne "Front-End Bound(Normalized)\t"
  echo -ne "Bad Speculation(Normalized)\t"
  echo -ne "Back-End Bound(Normalized)\t"
  echo -ne "Memory Bound(Normalized)\t"
  echo -ne "L1 Bound(Normalized)\t"
  echo -ne "L2 Bound(Normalized)\t"
  echo -ne "L3  Bound(Normalized)\t"
  echo -ne "DRAM Bound(Normalized)\t"
  echo -ne "Store Bound(Normalized)\t"
  echo -e "Core Bound(Normalized)\t"
}

printColumnHeaders
for file in $(ls results | grep .txt); do
  getOverallMetrics "results/"$file
  # TMAM metrics
  while read -r line; do
    if [[ $line =~ "Bad" || $line =~ "Bound:" || $line =~ "Retiring" ]]; then
      formatTmamMetric "$line"
    fi
  done <"results/$file"
  echo
done
