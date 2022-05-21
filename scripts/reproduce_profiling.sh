#! /usr/bin/env bash
num_iterations=3

for iteration in $(seq 1 $num_iterations); do
  # Read and write only workloads
  for write_protion in 0 100; do
    echo "Submitting job qsub -d . -l nodes=1:gold6128:ppn=2 ./scripts/execute_profiling.sh -w $write_protion -i $iteration"
    qsub -d . -l nodes=1:gold6128:ppn=2 ./scripts/execute_profiling.sh -F "-w $write_protion -i $iteration" -l walltime=24:00:00
    done
  # Mixed workloads
  for write_protion in 25 50 75; do
    echo "Submitting job qsub -d . -l nodes=1:gold6128:ppn=2 ./scripts/execute_profiling.sh -F -w $write_protion -i $iteration -d scripts/datasets_under_test_write.txt"
    qsub -d . -l nodes=1:gold6128:ppn=2 ./scripts/execute_profiling.sh -F "-w $write_protion -i $iteration -d scripts/datasets_under_test_write.txt" -l walltime=24:00:00
    done
done
