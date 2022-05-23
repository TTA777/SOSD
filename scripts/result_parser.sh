#! /usr/bin/env bash
# Script assumes SOSD is only run for a single data structure at a time, and for a single repetition
INDEXES="ALEX BTree ART PGM"
RESULT_FOLDER=$1
QUERY_COUNT=100000000
function formatTmamMetric() {
  UNFORMATED=$1
  echo -n $UNFORMATED | sed 's/ *%.*//' | sed 's/.*://'
  echo -ne "\t"
}

function getOverallMetrics() {
  FILE=$1
  SOSDRESULT=$(cat $FILE | grep RESULT | sed 's/,/ /g')
  echo -ne $FILE'\t' | sed "s,$RESULT_FOLDER,,"  | sed 's/_results.*.txt//'                             #Full dataset name
  echo -ne $FILE'\t' | sed "s,$RESULT_FOLDER,," | perl -pe 's/_[0-9].+?M//' | sed 's/results\///' | sed 's/_results.*.txt//' #Dataset name
  echo $SOSDRESULT'\t' | awk '{printf $2 "\t"}'                                                   #Index name
  echo -ne $FILE'\t' | sed "s,$RESULT_FOLDER,," | sed 's/M_.*//' | grep -o '[0-9:]*' | tr -d '\n'
  echo -ne '\t'                                                 #NUmber of entries in dataset (Millions)
  echo $SOSDRESULT | awk '{printf $5 "\t"}'                     # Memory(bytes)
  echo $SOSDRESULT | awk '{printf $6 "\t"}'                     # Build_time(ns)
  Total_Query_time=$(echo $SOSDRESULT | awk '{printf $8 "\t"}') # Total_Query_time(ns)
  echo -ne $Total_Query_time'\t'
  LookupCount=$(echo $SOSDRESULT | awk '{printf $9 "\t"}')
  awk -v var1="$LookupCount" -v var2="$Total_Query_time" 'BEGIN { printf  ( var1 / (var2 / 1000000000) ) "\t" }' # Throughput (Lookups/s)
  echo $SOSDRESULT | awk '{printf $4 "\t"}'
  formatTmamMetric "$(cat $FILE | grep 'Clockticks:' | sed 's/,//g')" #  Average_lookup_time(ns)"
  formatTmamMetric "$(cat $FILE | grep 'Instructions Retired:' | sed 's/,//g')"
  formatTmamMetric "$(cat $FILE | grep 'CPI Rate:')"
  Retired=$(formatTmamMetric "$(cat $FILE | grep 'Instructions Retired:')" | sed 's/,//g')
  Clockticks=$(formatTmamMetric "$(cat $FILE | grep 'Clockticks:')" | sed 's/,//g')
  awk -v var1="$Retired" -v var2="$QUERY_COUNT" 'BEGIN { printf  ( var1 / var2 ) "\t" }' # Instructions retired per request
}

function printColumnHeaders() {
  echo -ne "Full dataset name\t"
  echo -ne "Dataset \t"
  echo -ne "Index \t"
  echo -ne "Entries (Millions) \t"
  echo -ne "Memory (Bytes) \t"
  echo -ne "Build_time(ns) \t"
  echo -ne "Total_Query_time(ns) \t"
  echo -ne "Throughput (Lookups/s)\t"
  echo -ne "Average_lookup_time(ns) \t"
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
for dataset in $(cat ./scripts/datasets_under_test.txt); do
  for index in $INDEXES; do
    file=$dataset'_results_'$index'.txt'
    if [ -f "$RESULT_FOLDER$file" ]; then
      getOverallMetrics "$RESULT_FOLDER"$file
      # TMAM metrics
      while read -r line; do
        if [[ $line =~ "Bad" || $line =~ "Bound:" || $line =~ "Retiring" ]]; then
          formatTmamMetric "$line"
        fi
      done <"$RESULT_FOLDER$file"
      echo
    fi
  done
  echo
done
