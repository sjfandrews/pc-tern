# MERGING CODE

OUTDIR=/sc/arion/projects/rg_choj07/sloofl01/covid19/MASTER/files/shea_PCA/051721/
imputed=/sc/arion/projects/rg_choj07/sloofl01/covid19/MERGED/results/downloaded_from_topmed/imputation_results_031521/*.dose.vcf.gz
logs=/sc/arion/projects/rg_choj07/sloofl01/covid19/MASTER/scratch/logs/shea_pca/051721/
mkdir -p $logs
mkdir -p $OUTDIR
cd $logs

cut -f1 /sc/arion/projects/rg_choj07/sloofl01/covid19/MASTER/files/ganna_pca/hg38/hgdp_tgp_pca_covid19hgi_snps_loadings.GRCh38.plink.afreq > $OUTDIR/ganna_snps.txt # Nadia – snps are in the list I sent you before, you might have to re-run this cut command

# NOTE TO NADIA: I forgot keep-allele-order the first time, so I went in and added it here. I copied all of my notes into this email in order, and re-added the flag for you so you shouldn’t hit the same issue.

for vcf in $imputed
do
chr=$(basename $vcf .dose.vcf.gz)
outfile=$OUTDIR/covid.${chr}.purcell.hg38.vcf.gz # Nadia: ignore the Purcell suffix, I meant to delete this but it won’t impact anything.
~/scripts/mybsub.sh 1kg_${bname} 5000 100:00 private 1 "bcftools view --include ID==@/sc/arion/projects/rg_choj07/sloofl01/covid19/MASTER/files/shea_PCA/051721/ganna_snps.txt $vcf | bgzip -f > $outfile && tabix -f $outfile ; plink --vcf $outfile --double-id --keep-allele-order --make-bed --allow-no-sex --out $OUTDIR/covid.${chr}.purcell.hg38"
done

# Get corresponding 1000G SNPs (Went back on June 11)
#-r, --regions chr|chr:pos|chr:beg-end|chr:beg-[,…]
# ROUGHLY subset 1000G data - A1 and A2 might not match, will fix after
cut -f1,2  $OUTDIR/ganna_snps.txt -d":"  > $OUTDIR/rough_1kg_filter.txt
sed 's/chr//g'  $OUTDIR/rough_1kg_filter.txt | grep -v ^# | tr ":" "\t" >  $OUTDIR/rough_1kg_filter_nochr.txt

oneKG=/sc/arion/projects/data-ark/1000G/phase3/supporting/GRCh38_positions/*chr*gz
regions_file=$OUTDIR/rough_1kg_filter_nochr.txt

for vcf in $oneKG
do
chr=$(basename $vcf | cut -f2 -d"." )
outfile=$OUTDIR/oneKG.${chr}.ganna.hg38.vcf.gz
~/scripts/mybsub.sh 1kg_${chr} 7000 100:00 private 1 "bcftools view -R $regions_file $vcf | bgzip -f > $outfile && tabix -f $outfile ; plink --vcf $outfile --double-id --make-bed --allow-no-sex --out $OUTDIR/1kg.${chr}.purcell.hg38"
done

# Merge oneKG all together. NOTE TO NADIA: WATCH THE TAIL PART. I didn’t have sex chromosomes in this analysis. So I merged all autosomes with respect to the first file.
OUTDIR=/sc/arion/projects/rg_choj07/sloofl01/covid19/MASTER/files/shea_PCA/051721/
ls $OUTDIR/1kg*bim | sed 's/.bim$//g' | awk '{print $1 ".bed\t" $1 ".bim\t" $1 ".fam"}' | tail -n 21 > $OUTDIR/merge_list_1kg_vcfs # Manually checked 21

first_file=$(ls $OUTDIR/1kg*bim | sed 's/.bim$//g' | head -n1 )
plink --bfile $first_file --merge-list $OUTDIR/merge_list_1kg_vcfs --allow-no-sex --out $OUTDIR/merged.1kg.gannasnps

# Get oneKG into namespace of imputed data (chr:pos:ref:alt)
awk '{print $2 "\t" "chr" $1 ":" $4 ":" $6 ":" $5 }' $OUTDIR/merged.1kg.gannasnps.bim > $OUTDIR/change_1kg_names.list

plink --bfile $OUTDIR/merged.1kg.gannasnps --update-name $OUTDIR/change_1kg_names.list --make-bed -allow-no-sex --out $OUTDIR/merged.1kg.gannasnps.chr.pos.ref.alt

cd $OUTDIR
cat merged.purcell.bim merged.1kg.gannasnps.chr.pos.ref.alt.bim | cut -f2 | sort | uniq -c | awk '$1==2 {print $2}' > ganna.overlap.snps.txt

# Nadia: I copied this so you can run
cat *cov*kept*bim | awk '{print $2}' > reconfirm_ganna_list.txt # You can use the original list or look below to see how this is made.

plink --bfile $OUTDIR/merged.1kg.gannasnps.chr.pos.ref.alt --make-bed --extract reconfirm_ganna_list.txt --allow-no-sex --out final.oneKG.covid

# Rename oneKG (key attached)
fnames=/sc/arion/projects/buxbaj01a/pc-tern/data/rename_superpop.famstyle # in case you need to update IDs to have oneKG supergroup in the first identifier
plink --bfile  $OUTDIR/final.oneKG.covid --update-ids $fnames --allow-no-sex --make-bed --out $OUTDIR/final.oneKG.covid.superpop




# Nadia: You shouldn’t need these but adding for posterity/just in case
# NOTE: I just realized I didn't run --keep-allele-order when plink was converting between vcf and plink for either imputed data or for current data. Redoing, might be sloppy
vcfs=/sc/arion/projects/rg_choj07/sloofl01/covid19/MASTER/files/shea_PCA/051721/*chr*vcf.gz
for vcf in $vcfs
do
bname=$(basename $vcf .vcf.gz)
~/scripts/mybsub.sh redo_allele_order_${bname} 5000 100:00 private 1 "plink --vcf $vcf --double-id --make-bed --allow-no-sex --keep-allele-order --out $OUTDIR/${bname}_kept_allele_order"
done

# Check to see SNPs that made it
cat *kept_allele_order.bim | cut -f1,4- | sort | uniq -c | awk '$1==2 {print $0}' | wc -l
# 117220 - there are a few extra in oneKG - that will get filtered out

# Make new named list
cat one*kept*bim | awk '{print $2 "\t" "chr" $1 ":" $4 ":" $6 ":" $5 }' > change_1kg_names.keptalleles.list

# change the names! and subset to SNPs
for plinkfile in $(ls oneKG*kept*bim)
do
pfile=$(echo $plinkfile | sed 's/.bim//g')
bname=$(basename $pfile)
plink --bfile $pfile --update-name $OUTDIR/change_1kg_names.keptalleles.list --make-bed -allow-no-sex --out $OUTDIR/${bname}.chr.pos.ref.alt
done

files=$(ls oneKG.chr*.ganna.hg38_kept_allele_order.chr.pos.ref.alt.chr.pos.ref.alt.bim covid.chr*.purcell.hg38_kept_allele_order.bim)

# Merge files and restrict to ganna SNPs
ls $files | sed 's/.bim$//g' | awk '{print $1 ".bed\t" $1 ".bim\t" $1 ".fam"}' | tail -n 43 > $OUTDIR/merge_list_1kg_vcfs_kept # Manually checked 43

first_file=$(ls $files | sed 's/.bim$//g' | head -n1 )
plink --bfile $first_file --merge-list $OUTDIR/merge_list_1kg_vcfs_kept --allow-no-sex --out $OUTDIR/merged.1kg.keptalleleorder.gannasnps

# Remove stragglers
cat *cov*kept*bim | awk '{print $2}' > reconfirm_ganna_list.txt
plink --bfile merged.1kg.keptalleleorder.gannasnps --make-bed --extract reconfirm_ganna_list.txt --allow-no-sex --out final.oneKG.covid

# Rename oneKG
fnames=/sc/arion/projects/buxbaj01a/pc-tern/data/rename_superpop.famstyle
plink --bfile  $OUTDIR/final.oneKG.covid --update-ids $fnames --allow-no-sex --make-bed --out $OUTDIR/final.oneKG.covid.superpop
