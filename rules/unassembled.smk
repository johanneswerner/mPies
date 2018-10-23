SAMPLES = ["OSD14"]
READS = ["R1", "R2"]

# rule create_train_dir:
#     input:
#         "/data/miniconda3/envs/mpies/bin/train/"
#     output:
#         "checkpoints/train_dir.done"
#     shell:
#         "ln -s {input} . && touch ${output}"

rule fastq2fasta:
    input:
        "{sample}/reads/{sample}_R1.fastq.gz",
        "{sample}/reads/{sample}_R2.fastq.gz",
    output:
        "{sample}/reads_fasta/{sample}_R1.fasta",
        "{sample}/reads_fasta/{sample}_R2.fasta"
    shell:
        """
        zcat {input[0]} | sed -n '1~4s/^@/>/p;2~4p' | sed 's/ /_/g' > {output[0]}
        zcat {input[1]} | sed -n '1~4s/^@/>/p;2~4p' | sed 's/ /_/g' > {output[1]}
        """

rule run_fraggenescan:
    input:
        "{sample}/reads_fasta/{sample}_R1.fasta",
        "{sample}/reads_fasta/{sample}_R2.fasta"
    output:
        "{sample}/reads_fasta/{sample}_R1_fgs.faa",
        "{sample}/reads_fasta/{sample}_R2_fgs.faa"
    threads:
        28
    shell:
        """
        run_FragGeneScan.pl -genome={input[0]} -out={wildcards.sample}/reads_fasta/fgs_{wildcards.sample}_R1 -complete=0 -train=illumina_1 -thread={threads}
        run_FragGeneScan.pl -genome={input[1]} -out={wildcards.sample}/reads_fasta/fgs_{wildcards.sample}_R2 -complete=0 -train=illumina_1 -thread={threads}
        mv {wildcards.sample}/reads_fasta/fgs_{wildcards.sample}_R1.faa {output[0]}
        mv {wildcards.sample}/reads_fasta/fgs_{wildcards.sample}_R2.faa {output[1]}
        # rm {wildcards.sample}/reads_fasta/fgs_{wildcards.sample}_R[12].ffn
        # rm {wildcards.sample}/reads_fasta/fgs_{wildcards.sample}_R[12].out
        # rm {wildcards.sample}/reads_fasta/fgs_{wildcards.sample}_R[12].gbk
        """

rule combine_results:
    input:
        expand("{sample}/reads_fasta/{sample}_{read}_fgs.faa", read=READS, sample=SAMPLES)
    output:
        expand("{sample}/proteome/{sample}_unassembled.faa", sample=SAMPLES)
    shell:
        "cat {input} > {output}"

rule get_unassembled_proteome_done:
    input:
        expand("{sample}/proteome/{sample}_unassembled.faa", sample=SAMPLES)
    output:
        touch("checkpoints/unassembled_proteome.done")
