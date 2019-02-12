#!/bin/bash
#Config file containing paths to tools
config=$1
#Ini file for this specific filtering run
ini=$2

#echo $config
#echo $ini


#Load parameters
source $config
source $ini

##########################Check parameters in config##################################


if [ ! -d "$SNVFI_ROOT" ]; then
    printf "Installation directory '$SNVFI_ROOT' specified as SNVFI_ROOT in $config not found!\n"
    exit 1
fi
if [ ! -d "$BIOVCF_PREFIX" ]; then
    printf "biovcf directory '$BIOVCF_PREFIX' specified as BIOVCF_PREFIX in $config not found or empty!\n"
    exit 1
fi
if [ ! -d "$TABIX_PREFIX" ]; then
    printf "tabix directory '$TABIX_PREFIX' specified as TABIX_PREFIX in $config not found or empty!\n"
    exit 1
fi
if [ ! -d "$VCFTOOLS_PREFIX" ]; then
    printf "vcftools directory '$VCFTOOLS_PREFIX' specified as VCFTOOLS_PREFIX in $config not found or empty!\n"
    exit 1
fi
if [ ! -d "$R_PREFIX" ]; then
    printf "R directory '$R_PREFIX' specified as R_PREFIX in $config not found or empty!\n"
    exit 1
fi
if [ ! -f "$RSCRIPT" ]; then
    printf "Filtering rscript '$RSCRIPT' specified as RSCRIPT in $config not found or empty!\n"
    exit 1
fi
if [ ! "$MAX_THREADS" ]; then
    printf "Maximum threads specified as MAX_THREADS in $config not found or empty!\n"
fi
if [ ! "$SGE" ]; then
    printf "Please specify whether you want to use the Sun Grid Engine or not. Use SGE=<YES|NO>\n"
fi


###########################Check parameters in ini###################################
if [ ! -f $SNV ]; then
    printf "VCF file '$SNV' specified as SNV in $ini not found or empty!\n"
    exit 1
fi
if [ ! $CON ]; then
    printf "No CON column specified in $ini!\n"
    exit 1
fi
if [ ! $SUB ]; then
    printf "No SUB column specified in $ini!\n"
    exit 1
fi
if [ ! -d "$OUT_DIR" ]; then
    mkdir -p "$OUT_DIR"
#    printf "Output directory '$OUT_DIR' specified as OUT_DIR in $ini not found or empty!\n"
#    exit 1
fi

if [ ! "$BLACKLIST" ]; then

    printf "No blacklist vcf's found. Specified as BLACKLIST array in $ini!\n"
    exit 1
else
    for vcf in "${BLACKLIST[@]}";
    do
	if [ ! -f $vcf ]; then
	    printf "Blacklist vcf $vcf doesn't exist!\n"
	fi
    done
fi


if [ ! $QUAL ]; then
    printf "Minimum Quality score specified as QUAL in $ini not found!\n"
    exit 1
fi
if [ ! $SUB_GQ ]; then
    printf "Minimum Genotype Quality Score in subject specified as SUB_GQ in $ini not found! If you don't want to use Subject GQ filtering set the value of SUB_GQ to 0\n"
    exit 1
fi
if [ ! $CON_GQ ]; then
    printf "Minimum Genotype Quality Score in control specified as CON_GQ in $ini not found! If you don't want to use Control GQ filtering set the value of CON_GQ to 0\n"
    exit 1
fi
if [ ! $MQ ]; then
    printf "Minimum mapping quality in $ini not found! If you don't want to use mapping quality filtering set the value of MQ to 0\n"
    exit 1
fi


if [ ! $COV ]; then
    printf "Minimum Quality score specified as COV in $ini not found!\n"
    exit 1
fi
if [ ! $VAF ]; then
    printf "VAF specified as VAF in $ini not found!\n"
    exit 1
fi

if [ ! $FILTER ]; then
    printf "No value for FILTER found in $ini!\n"
    exit 1
fi

if [ ! ${CHR+x} ]; then
    printf "No CHR (autosomal or X chromosome) specification found in $ini!\n"
    exit 1
fi

if [ ! $CHR_NAM ]; then
    printf "No CHR name specification found in $ini!\n"
    exit 1
fi

if [ ! $SNV_only ]; then
    printf "Specify whether you want only SNVs specify as SNV_only='YES' or SNV_only='no' in $ini!\n"
    exit 1
fi

if [ ! $max_alleles ]; then
    printf "Specify the maximum number of desired alleles per site. Specify as max_alleles=x in $ini!\n"
    exit 1
fi

if [ ! $MAIL ] && [ $SGE == "YES" ]; then
    printf "Mail adress specified as MAIL in $ini not found!\n"
    exit 1
fi

if [ ! $CLEANUP ]; then
    printf "Please specify if you want to clean up in-between files. Specify as CLEANUP=YES|NO in $ini!\n"
    exit
fi



printf "Running filtering with the following settings:\n"
printf "\tBIOVCF : $BIOVCF_PREFIX\n"
printf "\tTABIX : $TABIX_PREFIX\n"
printf "\tVCFTOOLS : $VCFTOOLS_PREFIX\n"
printf "\tR VERSION : $R_PREFIX\n"
printf "\tRSCRIPT : $RSCRIPT\n"
printf "\tMAX_THREADS : $MAX_THREADS\n"
printf "\tSGE : $SGE\n"

printf "\tSNV : $SNV\n"
printf "\tCON : $CON\n"
printf "\tSUB : $SUB\n"
printf "\tOUT_DIR : $OUT_DIR\n"
printf "\tBLACKLIST :\n"

printf "\tCHR : $CHR\n"


for vcf in "${BLACKLIST[@]}";
do
    printf "\t\t$vcf\n"
done


printf "\tQUAL : $QUAL\n"
printf "\tMQ : $MQ\n"
printf "\tCON_GQ : $CON_GQ\n"
printf "\tSUB_GQ : $SUB_GQ\n"
printf "\tCOV : $COV\n"
printf "\tVAF : $VAF\n"
printf "\tFILTER : $FILTER\n"
printf "\tMAIL : $MAIL\n"
printf "\tCLEANUP : $CLEANUP\n"

#Create job script

JOB_ID=SNVFI_Filtering_`date | md5sum | cut -d' ' -f1`
JOB_LOG=$OUT_DIR/$JOB_ID.log
JOB_ERR=$OUT_DIR/$JOB_ID.err
JOB_SCRIPT=$OUT_DIR/$JOB_ID.sh

echo "$SNVFI_ROOT/SNVFI_filtering_v1.2.sh $config $ini" >> $JOB_SCRIPT

if [ "$SGE" = "YES" ]; then
    qsub -q all.q -P pmc_vanboxtel -pe threaded $MAX_THREADS -l h_rt=2:0:0 -l h_vmem=10G -N $JOB_ID -e $JOB_ERR -o $JOB_LOG -m a -M $MAIL $JOB_SCRIPT
else
    sh $JOB_SCRIPT 1>> $JOB_LOG 2>> $JOB_ERR
fi
