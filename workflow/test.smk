configfile: "config/config.yaml"
HM3 = config["HM3"]
DATAOUT = config["DATAOUT"]
SAMPLE = config["SAMPLE"]
REFNAME = config["REFNAME"]
tgped = config["tgped"]
GenoMiss = config["GenoMiss"]
kb = config["kb"]
size = config["size"]
r2 = config["r2"]
SampMiss= config["SampMiss"]
MAF = config["MAF"]
HWE = config["HWE"]
BUILD = config["BUILD"]
BPLINK = [".bed", ".bim", ".fam"]

rule all:
    input:
        expand("{dataout}/{sample}_SnpQc{ext}", ext = [".bed", ".bim", ".fam"],
        dataout = DATAOUT, sample = SAMPLE)

rule snp_qc:
    input:
        multiext("data/{sample}", ".bed", ".bim", ".fam")
    output:
        multiext("{dataout}/{sample}_SnpQc",".bed", ".bim", ".fam"),
        "{dataout}/{sample}_SnpQc.hwe",
        "{dataout}/{sample}_SnpQc.frq",
        "{dataout}/{sample}_SnpQc.frqx",
    params:
        indat = "data/{sample}",
        out = "{dataout}/{sample}_SnpQc",
        GenoMiss = GenoMiss,
        MAF = MAF,
        HWE = HWE
    conda: "envs/plink.yaml"
    shell:
        r'''
        plink --keep-allele-order --bfile {params.indat} --freq --out {params.out}
        plink --keep-allele-order --bfile {params.indat} --freqx --out {params.out}
        plink --keep-allele-order --bfile {params.indat} --geno {params.GenoMiss} \
        --maf {params.MAF} --hardy --hwe {params.HWE} --make-bed --out {params.out}
        '''

# Select reference
rule extract_reference:
    input:
        plink = multiext("{dataout}/{sample}_{refname}_merged", ".bim", ".bed", ".fam"),
        fam = rules.fix_fam.output.fixed,
        sample_fam = rules.sample_hapmap.output[2]
    output: multiext("{dataout}/{sample}_{refname}", ".bim", ".bed", ".fam")
    params:
        indat= "{dataout}/{sample}_{refname}_merged",
        out = "{dataout}/{sample}_{refname}"
    conda: "envs/plink.yaml"
    shell:
        r"""
        plink --keep-allele-order --bfile {params.indat} --fam {input.fam} \
        --remove-fam {input.sample_fam} --make-bed --out {params.out}
        """
# Select sample
rule extact_sample:
    input:
        plink = multiext("{dataout}/{sample}_{refname}_merged", ".bim", ".bed", ".fam"),
        fam = rules.fix_fam.output.fixed,
        sample_fam = rules.sample_hapmap.output[2]
    output: multiext("{dataout}/{sample}_{refname}", ".bim", ".bed", ".fam")
    params:
        indat= "{dataout}/{sample}_{refname}_merged",
        out = "{dataout}/{sample}"
    conda: "envs/plink.yaml"
    shell:
        r"""
        plink --keep-allele-order --bfile {params.indat} --fam {input.fam} \
        --keep-fam {input.sample_fam} --make-bed --out {params.out}
        """
