## SNVFI 
Single Nucleotide Variant Filtering

## Download
Individual releases can be downloaded from:
```bash
    https://github.com/CuppenResearch/SNVFI/releases
```
Alternatively use git clone:
```bash
    git@github.com:CuppenResearch/SNVFI.git
```

## Usage
SNVFI is configured using a config file, and an ini file for each filtering run. In most scenarios you'll create the config file once and create an ini file per filtering run.

### Edit SVNFI_default.config
```bash
    SNVGI_ROOT=<path to SNFVI install directory>
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

    QUAL=<Minimum quality threshold>
    COV=<Minimum coverage threshold>
    VAF=<Variant Allele Frequency threshold>

    MAIL=<Mail address for qsub>

    CLEANUP=<YES|NO>
```

### Run SNVFI
```bash
    sh SNVFI_run.sh <config> <ini>
```

## Dependencies

### OS
    - CentOS Linux release 7.2.1511 (should work on any Linux system)

### Grid Engine
    - Sun Grid Engine (tested on SGE 8.1.8)
    
### Standalone tools
    - R 3.2.2
    - bio-vcf 0.9.2 (https://github.com/pjotrp/bioruby-vcf)
    - tabix-0.2.6
    - vcftools-0.1.14
    - zgrep, grep

### R libraries
    - VariantAnnotation
    - ggplot2
    - reshape2
