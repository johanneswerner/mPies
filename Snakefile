rule all:
    output:
        "newfile"
    shell:
        "touch {output}"