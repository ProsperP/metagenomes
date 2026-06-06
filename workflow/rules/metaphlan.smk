rule metaphlan:
    input:
        rules.kneaddata_pe.output.r1_out,
        rules.kneaddata_pe.output.r2_out,
    output:
        bowtie_out = "02.profiles/metaphlan/{sample}/{sample}_metaphlan_bowtie2.txt",
        profile = "02.profiles/metaphlan/{sample}/{sample}_profile.txt",
    params:
        db = config["metaphlan"]["db"],
        index = config["metaphlan"]["index"],
    log:
        stdout = "logs/metaphlan/metaphlan_{sample}.log",
        stderr = "logs/metaphlan/metaphlan_{sample}.err",
    threads: config["metaphlan"]["threads"]
    resources:
        runtime="6h", mem="50GB"
    shell:
        "metaphlan {input[0]},{input[1]}"
        " --bowtie2db {params.db}"
        " --index {params.index}"
        " -t rel_ab_w_read_stats"
        " --sample_id_key {wildcards.sample}"
        " --input_type fastq"
        " --offline"
        " --bowtie2out {output.bowtie_out}"
        " --output_file {output.profile}"
        " --nproc {threads}"
        " > {log.stdout} 2> {log.stderr}"


rule merge_metaphlan:
    input:
        expand("02.profiles/metaphlan/{sample}/{sample}_profile.txt", sample=SAMPLES)
    output:
        "02.profiles/metaphlan_merged_relative.txt",
        "02.profiles/metaphlan_merged_count.txt",
    resources:
        runtime="3h", mem_mb=2000
    shell:
        "python {wf_basedir}/scripts/merge_metaphlan_tables.py {input} > {output[0]}\n"
        "python {wf_basedir}/scripts/merge_metaphlan_tables.py"
        " -c estimated_number_of_reads_from_the_clade"
        " {input} > {output[1]}"


rule split_taxnomic_level:
    input:
        "02.profiles/metaphlan_merged_{pr_type}.txt",
    output:
        "02.profiles/metaphlan_{lv}_{pr_type}.txt",
    params:
        lv = lambda wildcards: wildcards.lv,
        pr_type = lambda wildcards: wildcards.pr_type,
    resources:
        runtime="1h", mem_mb=2000
    shell:
        "sh {wf_basedir}/scripts/get_specific_level.sh"
        " {input} {params.lv} {output}"
