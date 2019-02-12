## SNVFI
Single Nucleotide Variant Filtering

##New features present in this fork
* Filter on MQ
* Select chromosomes you want to analyze
* Possibility to remove indels
* Filter on maximum number of alleles per site


## Download
Individual releases can be downloaded from:
```bash
    https://github.com/ToolsVanBox/SNVFI
```
Alternatively use git clone:
```bash
    git@github.com:ToolsVanBox/SNVFI
```

## Usage
SNVFI is configured using a config file, and an ini file for each filtering
run. In most scenarios you'll create the config file once and create an ini
file per filtering run.

### Edit SVNFI_default.config
```bash
    SNVFI_ROOT=<path to SNFVI install directory>
    BIOVCF_PREFIX=<path to bio-vcf executable>
    TABIX_PREFIX=<path to tabix executable>
    VCFTOOLS_PREFIX=<path to vcftools executable>
    R_PREFIX=<path to R executable>
    RSCRIPT=<path to SNVFI_filtering_R.R R-script>
    MAX_THREADS=<maximum number of threads used by SNFVI>
    SGE=<YES|NO> #Use Sun Grid Engine yes or no

```

### Edit SNVFI_dummy.ini
```bash
    SNV=<Path to input vcf>
    SUB=<Subject column in vcf>
    CON=<Control column in vcf>
    OUT_DIR=<Output directory>

    BLACKLIST=(
    '<blacklist1.vcf>'
    '<blacklist2.vcf>'
    );

    SUB_GQ=<Minimum Genotype Quality in subject sample>
    CON_GQ=<Minimum Genotype Quality in control sample>
    QUAL=<Minimum quality threshold>
    COV=<Minimum coverage threshold>
    FILTER=<Select either ALL variants or only PASS>
    VAF=<Variant Allele Frequency threshold>
    MQ=<Minimum MQ quality>
    CHR="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X" 		#Specifiy chromosomes with spaces
    CHR_NAM=<Name for the chosen selection of chromosomes. For example 'autosomal'>
    SNV_only=<YES | NO>
    max_alleles=<Maximum number of alleles that can be present at a given site>

    MAIL=<Mail address for qsub>

    CLEANUP=<YES|NO>
```

### Run SNVFI
```bash
    sh SNVFI_run.sh <config> <ini>
```
The full path needs to be given for both the config and ini file.

## Dependencies

### OS
    - GNU/Linux (tested on CentOS Linux release 7.6.1810)

### Grid Engine
    - (optional) Sun Grid Engine (tested on SGE 8.1.9)

### Standalone tools
    - R 3.5.0 (https://www.r-project.org)
    - bio-vcf 0.9.2 (https://rubygems.org/gems/bio-vcf/versions/0.9.2)
    - htslib 1.8 (http://www.htslib.org)
    - vcftools 0.1.15 (https://vcftools.github.io)
    - zgrep, grep 3.1

### R libraries
    - VariantAnnotation 1.26.1
    - ggplot2 3.0.0
    - reshape2 1.4.3
