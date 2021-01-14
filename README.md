# Procedure to annotate genomes with PROKKA with the CARD database


## Install prokka in a new environment via conda

    conda create -n prokka install -c bioconda prokka=1.14.6


## Activate the prokka environment

    conda activate prokka


Once the installation is completed, you can check the programm version and the several options available:

    prokka blabla


## Get the CARD database and more specifically the protein_fasta_protein_homolog_model.fasta file

    wget https://card.mcmaster.ca/download/0/broadstreet-v3.1.0.tar.bz2

    tar -xvpf broadstreet-v3.1.0.tar.bz2


## Annotate you assemblies files with PROKKA using the --proteins option

    prokka 







