#!/bin/bash

# version du 17sept pour 'ecrire' les commandes dans des fichiers afin d'utiliser GNU parallel
# ajustee pour CARD DB 3.03 le 17 sept 2019
# en preparation de l'article, je souhaite 'normaliser les choses le plus possible!


# usage lauchProkka.sh full_path_MOB_suite_folder full_path_PROKKA_folder SPECIES_INFOS

# example ./lauchProkka.sh /data/ext4/dataDP/data_WGS/analysis/MOBsuite /data/ext4/dataDP/data_WGS/analysis/PROKKA_310119 MINI_SPECIES

# si on veut fournir une db prioritaire , il faut que le fichier soit présent dans le dossier courant, avec un lien symbolique
# ça ne fonctionne pas

# un autre exemple avec hybrid assemblies data
# ./lauchProkka.sh /data/ext4/dataDP/MOB_suite_hybrid_assemblies /home/brouardjs/data/ext4/dataDP/PROKKA_hybrid_assemblies MINI_SPECIES 


# make a ***tab-delimited*** file to put genus and species infos

# SPECIES INFOS
# 3G3	Escherichia coli
# 3G4	Escherichia coli


sourceDir=$(pwd)

rm -r -f $2/input_files
rm -r -f $2/output

mkdir -p $2/input_files

printf "\n"


# Creation and filling of arrays
declare -a dna_ids
declare -a genus_array
declare -a species_array
IFS=$'\n'       # make newlines the only separator
j=0
for i in $(cat $3); do
dna_ids[j]=$(echo $i | cut -f 1 | tr -d '\n')
genus_array[j]=$(echo  $i | cut -f 2 | tr -d '\n')
species_array[j]=$(echo $i | cut -f 3 | tr -d '\n')
((j++))
done

# Reinitialisation de IFS
IFS=$' \t\n'



dna_id_count=0
# for all sub folders (DNA_ID)
for i in "${dna_ids[@]}"; do

	echo $i

	# make folders to place fasta 'edited' input files
	mkdir -p $2/input_files/$i

	cd $1/$i
	echo "### processing $i $dna_id_count ${genus_array[dna_id_count]} ${species_array[dna_id_count]} ###" 2>&1 | tee -a $2/log.txt
	
	# a - list all plamid sequences
	for plasmid in `ls -1 *plasmid_*fasta | cut -f 1 -d '.'`; do
		
		# this custom script will change the fasta header of the files produced by MOBsuite
		$sourceDir/fastaReHeader.pl $plasmid.fasta $i $2/input_files/$i
		
		# here the full PROKKA command
		echo "prokka --prefix $i"_"$plasmid " | tr -d '\n' >> $sourceDir/prokka_plasmid_commands.txt
		echo "--force --addgenes --outdir $2/output/$i/$plasmid " | tr -d '\n' >> $sourceDir/prokka_plasmid_commands.txt
		echo "--genus ${genus_array[dna_id_count]} --species ${species_array[dna_id_count]} --strain $i " | tr -d '\n' >> $sourceDir/prokka_plasmid_commands.txt
		echo "--proteins /data/ext4/dataDP/db/CARD_DB/protein_fasta_protein_homolog_model.fasta --evalue 1e-09 $2/input_files/$i/$plasmid.fasta" >> $sourceDir/prokka_plasmid_commands.txt


	done

	# j'ai enelve --usegenus \ pour plasmides, car cela n'est pas pertinent dans le cas de plasmides

	# b - list all chromosomal sequences
	for chromosome in `ls -1 chromosome.fasta | cut -f 1 -d '.'`; do

		# this custom script will change the fasta header of the files produced by MOBsuite
		$sourceDir/fastaReHeader.pl $chromosome.fasta $i $2/input_files/$i
		
		# here the full PROKKA command
		echo "prokka --prefix $i"_"$chromosome " | tr -d '\n' >> $sourceDir/prokka_chr_commands.txt
		echo "--force --addgenes --outdir $2/output/$i/$chromosome " | tr -d '\n' >> $sourceDir/prokka_chr_commands.txt
		echo "--genus ${genus_array[dna_id_count]} --species ${species_array[dna_id_count]} --strain $i " | tr -d '\n' >> $sourceDir/prokka_chr_commands.txt
		echo "--proteins /data/ext4/dataDP/db/CARD_DB/protein_fasta_protein_homolog_model.fasta --usegenus --evalue 1e-09 $2/input_files/$i/$chromosome.fasta" >> $sourceDir/prokka_chr_commands.txt

	done


	cd $1

	printf "### End of process for $i ###\n\n"
	((dna_id_count++))

done
