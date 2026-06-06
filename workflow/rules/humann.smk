ruleorder: renorm_humann_table > regroup_table

rule humann:
    input:
        rules.kneaddata_pe.output.r1_out,
        rules.kneaddata_pe.output.r2_out,
        rules.metaphlan.output.profile,
    output:
        directory("02.profiles/humann/{sample,[^/]+}/"),
        temp_fq = temp("02.profiles/humann/{sample}/{sample}.fastq"),
        genefamilies = "02.profiles/humann/{sample}/{sample}_genefamilies.tsv",
        pathabundance = "02.profiles/humann/{sample}/{sample}_pathabundance.tsv",
        pathcoverage = "02.profiles/humann/{sample}/{sample}_pathcoverage.tsv"
    params:
        nucl_db = config["humann"]["nucleotide_db"],
        prot_db = config["humann"]["protein_db"],
    log:
        "logs/humann/humann_{sample}.log"
    threads: config["humann"]["threads"]
    resources:
        runtime="36h", mem="60GB"
    shell:
        "cat {input[0]} {input[1]} > {output.temp_fq}\n"
        "humann"
        " --input {output.temp_fq}"
        " --output {output[0]}"
        " --threads {threads}"
        " --taxonomic-profile {input[2]}"
        " --input-format fastq"
        " --nucleotide-database {params.nucl_db}"
        " --protein-database {params.prot_db}"
        " --remove-temp-output"
        " --output-basename {wildcards.sample}"
        " --o-log {log}"


rule compress_fastq:
    input:
        rules.kneaddata_pe.output.r1_out,
        rules.kneaddata_pe.output.r2_out,
        rules.humann.output.genefamilies,
        rules.humann.output.pathabundance,
        rules.humann.output.pathcoverage,
    output:
        "01.QC/{sample}/{sample}_paired_1.fastq.gz",
        "01.QC/{sample}/{sample}_paired_2.fastq.gz",
    threads: 10
    resources:
        runtime="3h", mem_mb=400
    priority: 20
    shell:
        "pigz --processes {threads} {input[0]} {input[1]}"


rule renorm_humann_table:
    input:
        rules.humann.output.genefamilies,
        rules.humann.output.pathabundance,
    output:
        "02.profiles/humann/{sample}/{sample}_genefamilies_cpm.tsv",
        "02.profiles/humann/{sample}/{sample}_pathabundance_cpm.tsv",
    params:
        units = "cpm",
    resources:
        runtime="2h", mem_mb=2000
    shell:
        "humann_renorm_table"
        " --input {input[0]}"
        " --output {output[0]}"
        " --units {params.units} --update-snames\n"
        "humann_renorm_table"
        " --input {input[1]}"
        " --output {output[1]}"
        " --units {params.units} --update-snames"


rule regroup_table:
    input:
        rules.renorm_humann_table.output[0]
    output:
        "02.profiles/humann/{sample}/{sample}_{map_type,[a-z4]+}_cpm.tsv",
    params:
        map_db = get_map_file,
    threads: 2
    resources:
        runtime="3h", mem_mb=4000
    shell:
        "humann_regroup_table"
        " --input {input}"
        " --custom {params.map_db}"
        " --output {output}"


rule merge_table:
    input:
        "02.profiles/humann",
        expand("02.profiles/humann/{sample}/{sample}_genefamilies_cpm.tsv",
               sample=SAMPLES),
        expand("02.profiles/humann/{sample}/{sample}_pathabundance_cpm.tsv",
               sample=SAMPLES),
    output:
        "02.profiles/humann_genefamilies_cpm.txt",
        "02.profiles/humann_metacyc_cpm.name.txt",
    params:
        genefam_name = "genefamilies_cpm",
        pathabu_name = "pathabundance_cpm"
    benchmark:
        "benchmarks/humann_merge_table.benchmark.txt"
    #localrule: True
    threads: 30
    resources:
        runtime="3h", mem="60GB"
    shell:
        "humann_join_tables"
        " --input {input[0]}"
        " --file_name {params.genefam_name}"
        " --search-subdirectories"
        " --output {output[0]}\n"
        "humann_join_tables"
        " --input {input[0]}"
        " --file_name {params.pathabu_name}"
        " --search-subdirectories"
        " --output {output[1]}"


rule merge_other_table:
    input:
        "02.profiles/humann",
        expand("02.profiles/humann/{sample}/{sample}_{{map_type}}_cpm.tsv",
               sample=SAMPLES)
    output:
        "02.profiles/humann_{map_type,[^_]+}_cpm.txt",
    params:
        func=lambda wildcards: wildcards.map_type,
    resources:
        runtime="3h", mem_mb=3000
    shell:
        "humann_join_tables"
        " --input {input[0]}"
        " --file_name {params.func}_cpm"
        " --search-subdirectories"
        " --output {output}"


rule rename_genefam_table:
    input:
        "02.profiles/humann_genefamilies_cpm.txt",
    output:
        "02.profiles/humann_genefamilies_cpm.name.txt",
    params:
        name_db = os.path.join(config["humann"]["map_db"],
                               "map_uniref90_name.txt")
    threads: 60/2
    resources:
        runtime="3h", mem="60GB"
    shell:
        "humann_rename_table"
        " --input {input}"
        " --custom {params.name_db}"
        " --output {output}"


rule rename_other_table:
    input:
        "02.profiles/humann_{map_type}_cpm.txt",
    output:
        "02.profiles/humann_{map_type}_cpm.name.txt",
    params:
        name_db = get_name_file
    benchmark:
        "benchmarks/rename_other_table.{map_type}.benchmark.txt"
    #localrule: True
    threads: 60/2
    resources:
        runtime="3h", mem="60GB"
    shell:
        "humann_rename_table"
        " --input {input}"
        " --custom {params.name_db}"
        " --output {output}"
