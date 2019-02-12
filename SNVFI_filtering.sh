#!/bin/bash
# @Date: 02-02-2016

# @Author(s): Francis Blokzijl, Sander Boymans, Roel Janssen
# @Title: SNVFI

# @Description: Pipeline for filtering somatic SNVs for clonal (organoid) cultures
# @Args: (1) Path to .cfg file containing paths to tools. (2) Path to .ini file containing
# job specific settings

#MODIFICATION by Freek Manders
# @Date: 27-11-2018
# @Description: Free combinations of chromosomes can now be chosen. Also added filtering on MQ

# MODIFICATION by Rurika Oka
# @Date: 09-04-2018
# @Description: Added option to select autosomal or chrX for the filtering

# -----------------------------------------------------------------------------
# Define helper functions
# -----------------------------------------------------------------------------
function join { local IFS="$1"; shift; echo "$*"; }
function techo { echo `date +"%Y-%m-%d_%H:%M:%S"`": "$*; }


# Read default configuration file
config=$1
ini=$2

source $config
source $ini

# -----------------------------------------------------------------------------
# Define absolute paths to external programs
# -----------------------------------------------------------------------------


run_RSCRIPT="$R_PREFIX"Rscript
run_VCFTOOLS="$VCFTOOLS_PREFIX"vcftools
run_BGZIP="$TABIX_PREFIX"bgzip
run_TABIX="$TABIX_PREFIX"tabix
run_BIOVCF="$BIOVCF_PREFIX"bio-vcf
run_GREP="$GREP_PREFIX"grep
run_ZGREP="$ZGREP_PREFIX"zgrep

# create tmp dir and log-files
TMP_DIR=$OUT_DIR/tmp

if [ ! -d $TMP_DIR ]; then
    mkdir $TMP_DIR
fi

#Create chromosome filter for bio-vcf
CHROMS_LIST=$(echo $CHR | sed 's/ /$|^/g')
CHR_OPT="r.chrom =~ /^$CHROMS_LIST$/"


# get sample names
SAMPLES=($($run_GREP -P "^#CHROM" < $SNV))

CON_NAME=${SAMPLES[ $(( $CON+8 )) ]}
SUB_NAME=${SAMPLES[ $(( $SUB+8 )) ]}

LOG=$OUT_DIR/$SUB_NAME"_"$CON_NAME"_filter-log.txt"
ERR=$OUT_DIR/$SUB_NAME"_"$CON_NAME"_filter-err.txt"
COUNTS=$OUT_DIR/$SUB_NAME"_"$CON_NAME"_filter-count.txt"

#get version
INSTALL_DIR=$( cd $( dirname '${BASH_SOURCE[0]}' ) && pwd )
SCRIPT_NAME=`basename "$0"`
VERSION=$INSTALL_DIR/$SCRIPT_NAME

# -----------------------------------------------------------------------------
# Print control and subject sample names, as feedback for user
# -----------------------------------------------------------------------------
techo $SUB_NAME" is used as the subject sample" >> $LOG
techo $CON_NAME" is used as the control sample" >> $LOG




# make output file names
s="_Q"$QUAL"_CGQ"$CON_GQ"_SGQ"$SUB_GQ"_"$FILTER"_"$COV"X_"$CHR_NAM
vcf_filtered=$OUT_DIR$SUB_NAME"_"$CON_NAME$s".vcf"
vcf_filtered_zip=$OUT_DIR$SUB_NAME"_"$CON_NAME$s".vcf.gz"
vcf_no_blacklist=$OUT_DIR$SUB_NAME"_"$CON_NAME$s"_nonBlacklist.vcf.gz"
vcf_no_evidence_and_called=$OUT_DIR$SUB_NAME"_"$CON_NAME$s"_nonBlacklist_noEvidenceCon.vcf"

s="_Q"$QUAL"_CGQ"$CON_GQ"_SGQ"$SUB_GQ"_"$FILTER"_"$COV"X_VAF"$VAF"_"$CHR_NAM"_nonBlacklist_final.vcf"
vcf_final="$OUT_DIR$SUB_NAME"_"$CON_NAME$s"

s="_VAF.pdf"
VAF_plot_file="$OUT_DIR$SUB_NAME"_"$CON_NAME$s"

techo "(1) Filtering SNV file with bio_vcf STARTED" >> $LOG
# bio vcf is zero based: subtract one from CON and sub index
export TMPDIR=$TMP_DIR
if [ $FILTER = "PASS" ]; then
  cat $SNV | $run_BIOVCF -i --num-threads $MAX_THREADS --thread-lines 50_000 --filter "r.qual>=$QUAL and r.filter=='PASS' and $CHR_OPT" \
  --sfilter-samples $(($CON-1)),$(($SUB-1)) --sfilter "!s.empty? and s.dp>=$COV" 1>$vcf_filtered"tmp1" 2>>$ERR
  cat $vcf_filtered"tmp1" | $run_BIOVCF -i --num-threads $MAX_THREADS --thread-lines 50_000 --sfilter-samples $(($CON-1)) --sfilter "s.gq>=$CON_GQ" 1>$vcf_filtered"tmp2" 2>>$ERR
  cat $vcf_filtered"tmp2" | $run_BIOVCF -i --num-threads $MAX_THREADS --thread-lines 50_000 --sfilter-samples $(($SUB-1)) --sfilter "s.gq>=$SUB_GQ" 1>$vcf_filtered 2>>$ERR

elif [ $FILTER = "ALL" ]; then
  cat $SNV | $run_BIOVCF -i --num-threads $MAX_THREADS --thread-lines 50_000 --filter "r.qual>=$QUAL and $CHR_OPT" \
  --sfilter-samples $(($CON-1)),$(($SUB-1)) --sfilter "!s.empty? and s.dp>=$COV"  1>$vcf_filtered"tmp1" 2>>$ERR
  cat $vcf_filtered"tmp1" | $run_BIOVCF -i --num-threads $MAX_THREADS --thread-lines 50_000 --sfilter-samples $(($CON-1)) --sfilter "s.gq>=$CON_GQ" 1>$vcf_filtered"tmp2" 2>>$ERR
  cat $vcf_filtered"tmp2" | $run_BIOVCF -i --num-threads $MAX_THREADS --thread-lines 50_000 --sfilter-samples $(($SUB-1)) --sfilter "s.gq>=$SUB_GQ" 1>$vcf_filtered 2>>$ERR

else
  printf "$FILTER is not a valid value for FILTER (PASS | ALL)\n"
  exit 1
fi

$run_BGZIP -c $vcf_filtered 1> $vcf_filtered_zip 2>> $ERR
$run_TABIX -p vcf $vcf_filtered_zip 2>> $ERR

techo "(1) Filtering SNV file with bio_vcf DONE" >> $LOG

echo "Input file:" > $COUNTS
$run_GREP -Pvc "^#" $SNV >> $COUNTS

echo "Q"$QUAL" CGQ"$CON_GQ" SGQ"$SUB_GQ $FILTER $COV"X "$CHR_NAM":" >> $COUNTS
$run_GREP -Pvc "^#" $vcf_filtered >> $COUNTS

techo "(2) Removing blacklisted SNPs from SNV file STARTED" >> $LOG
COUNT=1
vcf_tmp=$vcf_filtered_zip
for vcf in "${BLACKLIST[@]}";
do
    OUT=$TMP_DIR/$SUB_NAME"_"$CON_NAME"_Q"$QUAL"_CGQ"$CON_GQ"_SGQ"$SUB_GQ"_"$FILTER"_"$COV"X_"$CHR_NAM"_nonBlacklist_"$COUNT

    $run_VCFTOOLS --gzvcf $vcf_tmp --exclude-positions $vcf --recode --recode-INFO-all --out $OUT 2>>$ERR
    $run_BGZIP -c $OUT.recode.vcf > $OUT.recode.vcf.gz 2>>$ERR
    $run_TABIX $OUT.recode.vcf.gz 2>>$ERR

    echo "Not in blacklist $vcf: " >> $COUNTS
    $run_ZGREP -Pvc "^#" $OUT.recode.vcf.gz >> $COUNTS

    vcf_tmp=$OUT.recode.vcf.gz
    ((COUNT++))
done

mv $vcf_tmp $vcf_no_blacklist
mv $vcf_tmp.tbi $vcf_no_blacklist.tbi

techo "(2) Removing blacklisted SNPs from SNV file DONE" >> $LOG

#Removing sites with to many alleles and optionally remove indels
if [ $SNV_only = "YES" ]; then
    techo "(3) Removing indels and sites with many alleles from file STARTED" >> $LOG
    OUT=$TMP_DIR/$SUB_NAME"_"$CON_NAME"_Q"$QUAL"_CGQ"$CON_GQ"_SGQ"$SUB_GQ"_"$FILTER"_"$COV"X_"$CHR_NAM"_nonBlacklist"$COUNT"_snv_clear"
    $run_VCFTOOLS --gzvcf $vcf_no_blacklist --remove-indels --max-alleles $max_alleles --recode --recode-INFO-all --out $OUT 2>>$ERR
    echo "Only SNVs with no more than $max_alleles alleles" >> $COUNTS
    $run_GREP -Pvc "^#" $OUT.recode.vcf.gz >> $COUNTS
else
    techo "(3) Removing sites with many alleles from file STARTED" >> $LOG
    OUT=$TMP_DIR/$SUB_NAME"_"$CON_NAME"_Q"$QUAL"_CGQ"$CON_GQ"_SGQ"$SUB_GQ"_"$FILTER"_"$COV"X_"$CHR_NAM"_nonBlacklist"$COUNT"_clear"
    $run_VCFTOOLS --gzvcf $vcf_no_blacklist --max-alleles $max_alleles --recode --recode-INFO-all --out $OUT 2>>$ERR
    echo "Only sites with no more than $max_alleles alleles" >> $COUNTS
    $run_GREP -Pvc "^#" $OUT.recode.vcf >> $COUNTS
fi
$run_BGZIP -c $OUT.recode.vcf > $OUT.recode.vcf.gz 2>>$ERR
$run_TABIX $OUT.recode.vcf.gz 2>>$ERR
vcf_clear=$OUT".recode.vcf.gz"
techo "(3) Removing (indels and) sites with many alleles from file DONE" >> $LOG



#Load appropriate R version
techo "(4) Filtering SNV file with R STARTED" >> $LOG
$run_RSCRIPT $RSCRIPT $vcf_clear $CON $SUB $VAF $vcf_no_evidence_and_called $vcf_final $VAF_plot_file $MQ 2>>$ERR
techo "(4) Filtering SNV file with R DONE" >> $LOG




#add filter steps to header
vcf_final_tmp=$vcf_final"_tmp"

TIME=`date +"%Y-%m-%d_%H:%M:%S"`
#FINAL_HEADER=`grep -P "^#" $vcf_final`
HEADER_ADD="##SNVFI_filtering=<Version=$VERSION, Date=$TIME, Tools='bio-vcf=$run_BIOVCF tabix=$run_TABIX vcftools=$run_VCFTOOLS rscript=$run_RSCRIPT', SNV=$SNV, SUB=$SUB, CON=$CON, OUT_DIR=$OUT_DIR, QUAL=$QUAL, SUB_GQ=$SUB_GQ, CON_GQ=$CON_GQ,COV=$COV, VAF=$VAF, CHR=$CHR_NAM, BLACKLIST=["
HEADER_ADD+=`join , ${BLACKLIST[@]}`
HEADER_ADD+="]>"

$run_GREP -P "^##" $vcf_final > $vcf_final_tmp
echo $HEADER_ADD >> $vcf_final_tmp
$run_GREP -P "^#CHROM" $vcf_final >> $vcf_final_tmp
$run_GREP -Pv "^#" $vcf_final >> $vcf_final_tmp
mv $vcf_final_tmp $vcf_final

techo "(5) Writing info on mutation numbers to log file STARTED" >> $LOG

# Write info on mutations numbers to log file
echo "No evidence control and called:" >> $COUNTS
$run_GREP -Pvc "^#" $vcf_no_evidence_and_called >> $COUNTS

echo "Called and VAF > $VAF in subject:" >> $COUNTS
$run_GREP -Pvc "^#" $vcf_final >> $COUNTS

techo "(5) Writing info on mutation numbers to log file DONE" >> $LOG
techo "(6) Removing files that are not needed STARTED" >> $LOG

# remove files that are not needed
if [ $CLEANUP == "YES" ]; then
    rm -r $TMP_DIR
    rm $OUT_DIR/*$CHR_NAM.vcf
    rm $OUT_DIR/*$CHR_NAM.vcf.gz
    rm $OUT_DIR/*$CHR_NAM.vcf.gz.tbi
    rm $OUT_DIR/*nonBlacklist.vcf.gz
    rm $OUT_DIR/*nonBlacklist.vcf.gz.tbi
    rm $vcf_filtered"tmp1"
    rm $vcf_filtered"tmp2"
fi

techo "(6) Removing files that are not needed DONE" >> $LOG
