#!/bin/bash


SNAKEFILE=metagenomes/workflow/Snakefile

# useful options
    #--delete-temp-output \
    #--unlock \
snakemake \
    --snakefile ${SNAKEFILE} \
    --rerun-trigger mtime \
    --profile metagenomes/workflow/profiles/slurm_profile.yaml \
    --workflow-profile metagenomes/workflow/profiles/default/profile.yaml \
    --jobs 50 \
    --latency-wait 120
    --slurm-jobname-prefix pregnancy

# generic clsuter submit cmd
    #--executor cluster-generic \
    #--cluster-generic-submit-cmd "sbatch -p <paritition_name> -N 1 --cpus-per-task={threads} --mem={resources.mem_mb} --job-name={rule} --output=slurm_logs/{rule}.%j.out --error=slurm_logs/{rule}.%j.err" \
    #--cluster-generic-cancel-cmd "scancel %j"

#exit
# Make a DAG pdf
snakemake \
    --snakefile ${SNAKEFILE} \
    --rulegraph | dot -Tpdf > metagenome_snakemake_dag.pdf
