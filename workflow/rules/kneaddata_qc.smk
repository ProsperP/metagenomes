rule kneaddata_pe:
    input:
        get_input_fastqs,
    output:
        directory("01.QC/{sample}/fastqc/"),
        r1_out = "01.QC/{sample}/{sample}_paired_1.fastq",
        r2_out = "01.QC/{sample}/{sample}_paired_2.fastq",
        r1_unpaired = "01.QC/{sample}/{sample}_unmatched_1.fastq.gz",
        r2_unpaired = "01.QC/{sample}/{sample}_unmatched_2.fastq.gz",
        r1_unpaired_contam = temp("01.QC/{sample}/{sample}_hg_39_bowtie2_unmatched_1_contam.fastq.gz"),
        r2_unpaired_contam = temp("01.QC/{sample}/{sample}_hg_39_bowtie2_unmatched_2_contam.fastq.gz"),
    params:
        idx = config["kneaddata"]["bowtie2_db"],
        f_qual = config["kneaddata"]["lead_qual"],
        t_qual = config["kneaddata"]["trail_qual"],
        trim_mem = "6g",
        adapter = config["kneaddata"]["adapter"],
        crop = config["kneaddata"]["head_crop"],
        min_len = config["kneaddata"]["min_len"],
        size = config["kneaddata"]["window_size"],
        quality = config["kneaddata"]["avg_quality"],
    log:
        stdlog = "01.QC/{sample}/{sample}_kneaddata.log",
        stderr = "logs/kneaddata/{sample}_kneaddata.log",
    shell:
        'export _JAVA_OPTIONS="-Xmx{params.trim_mem}"\n'
        "kneaddata --input1 {input[0]} --input2 {input[1]}"
        " --reference-db {params.idx}"
        " --output 01.QC/{wildcards.sample}"
        " --output-prefix {wildcards.sample}"
        " --max-memory {params.trim_mem}"
        ' --trimmomatic-options "ILLUMINACLIP:{params.adapter}:2:30:10 LEADING:{params.f_qual} TRAILING:{params.t_qual} SLIDINGWINDOW:{params.size}:{params.quality} HEADCROP:{params.crop} MINLEN:{params.min_len}"'
        " --remove-intermediate-output"
        " --run-fastqc-start"
        " --run-fastqc-end"
        " --threads {threads}"
        " --log {log.stdlog}"
        " 2> {log.stderr}"
        " && gzip 01.QC/{wildcards.sample}/*_unmatched_?.fastq 01.QC/{wildcards.sample}/*_contam*fastq"
        #" --trimmomatic {config[databases][kneaddata][trimmomatic]}"
        #" --sequencer-source {params.adapter}"
