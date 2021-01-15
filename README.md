# Procedure to annotate antibiotic resistance genes (ARGs) referenced by the CARD database using PROKKA

## Before starting

As documented [here](https://github.com/tseemann/prokka#installation), the three core databases used by PROKKA, applied in order, are:

  * ISfinder
  * a NCBI Bacterial Antimicrobial Resistance Reference Gene Database
  * UniProtKB (SwissProt).

However, with the --proteins option, PROKKA can annotate, **as the first priority**, genes included in a Protein fasta file.

The procedure described here lead to the production of regular genbank files where genes were detected because of their homology with ARGs present in CARD. The resulting annotations are therefore slightly different. Rather than having references to the NCBI Bacterial Antimicrobial Resistance Reference Gene Database, ARGs have a specific label in their \inference field: *similar to AA sequence:protein_fasta_protein_homolog_model.fasta*:

```shell

    gene            complement(81189..82004)
                     /locus_tag="EHEC_00095"
     CDS             complement(81189..82004)
                     /locus_tag="EHEC_00095"
                     /inference="ab initio prediction:Prodigal:002006"
                     /inference="similar to AA
                     sequence:protein_fasta_protein_homolog_model.fasta:gb|AAL5
                     9753.1|ARO:3000412|sul2"
                     /codon_start=1
                     /transl_table=11
                     /product="[Vibrio cholerae]"
                     /translation="MNKSLIIFGIVNITSDSFSDGGRYLAPDAAIAQARKLMAEGADV
                     IDLGPASSNPDAAPVSSDTEIARIAPVLDALKADGIPVSLDSYQPATQAYALSRGVAY
                     LNDIRGFPDAAFYPQLAKSSAKLVVMHSVQDGQADRREAPAGDIMDHIAAFFDARIAA
                     LTGAGIKRNRLVLDPGMGFFLGAAPETSLSVLARFDELRLRFDLPVLLSVSRKSFLRA
                     LTGRGPGDVGAATLAAELAAAAGGADFIRTHEPRPLRDGLAVLAALKETARIR"
     gene            82334..82510
                     /locus_tag="EHEC_00096"
     CDS             82334..82510
                     /locus_tag="EHEC_00096"
                     /inference="ab initio prediction:Prodigal:002006"
                     /codon_start=1
                     /transl_table=11
                     /product="hypothetical protein"
                     /translation="MLTDTKLRNLKPRDKLYKVNDREGLYVGVASENGIYGHSRFCNT
                     DFDDKLACLNLSGV"
     gene            complement(82692..83381)
                     /locus_tag="EHEC_00097"
     CDS             complement(82692..83381)
                     /locus_tag="EHEC_00097"
                     /inference="ab initio prediction:Prodigal:002006"
                     /inference="similar to AA sequence:ISfinder:IS5075"
                     /codon_start=1
                     /transl_table=11
                     /product="IS110 family transposase IS5075"
                     /translation="MRFVQPRTESQQAMRALHRVRESLVQDKVKTTNQMHAFLLEFGI
                     SVPRGAAVISRLSTLLEDSSLPLYLSQLLLKLQQHYHYLVEQIKDLESQLKRKLDEDE
                     VGQRLLSIPCVGTLTASTISTEIGDGKQYASSRDFAAATGLVPRQYSTGGRTTLLGIS
                     KRGNKKIRTLLVQCARVFIQKLEHQSGKLADWVRELLCRKSNFVVTCALANKLARIAW
                     ALTARQQTYEA"
```

This specfic label is searched by [GENcontext](URL) to targer ARGs.

Note that PROKKA also annotate IS elements by adding a reference to the ISfinder database, which is one of the three core databases included in PROKKA.

 
## Installation

Install prokka in a new environment via conda

```shell
conda create -n prokka install -c bioconda prokka=1.14.6
```

Activate the prokka environment

```shell
conda activate prokka
```

Once the installation is completed, you can check the programm version and the several options available:

```shell
prokka
```

## Get the CARD database

```shell
    wget https://card.mcmaster.ca/download/0/broadstreet-v3.1.0.tar.bz2
    tar -xvpf broadstreet-v3.1.0.tar.bz2
```

More specifically, get the protein_fasta_protein_homolog_model.fasta file. The key point is to annotate you assemblies files with PROKKA using the --proteins option.



## Run PROKKA with fasta files from [MOBsuite](https://github.com/phac-nml/mob-suite) output as input files.

This could be useful when you have sequencing data from many strains.

assemblies -> MOB-suite -> PROKKA (with CARD labelling) --> GENcontext

This strategy was used in Poulin-Laprade et al. 2021 to unreveal the genetic context around some ARGs.

I you plan to use [GENcontext](https://github.com/soda460/GENcontext) in a similar scenario, you should organize your genbank files in subfolders to benefit from good metadata labeling in output files.

At first level, create folders with strain_names and at second level, create folders with molecule names in which your genbank files will be located.

```shell
tree ./annotation folder/ -P *.gbk


├── strain1
│   └── a_molecule
│       └── your_genbank_file_here.gbk
├── strain2
│   └── a molecule
│       └── another_genbank_file.gbk
├── PC29
│   └── plasmid_476
│       └── PC-29-I_plasmid_476.gbk
├── Res13-Lact-PER04-34
│   ├── chromosome
│   │   └── Res13-Lact-PER04-34_chromosome.gbk
│   ├── plasmid_1009
│   │   └── Res13-Lact-PER04-34_plasmid_1009.gbk
│   ├── plasmid_1068
│   │   └── Res13-Lact-PER04-34_plasmid_1068.gbk
etc
```

### Example commands

```shell
prokka --force \
       --outdir prokka_output/R13-AF11-pFin-05 \
       --proteins protein_fasta_protein_homolog_model.fasta \
       --evalue 1e-9 \
       --addgenes \
       mob_suite_output/R13-AF11-pFin-05/plasmid_476.fasta


prokka --force \
       --outdir prokka_output/Res13-Sevr-PER06-05-b-A \
       --proteins protein_fasta_protein_homolog_model.fasta \
       --evalue 1e-9 \
       --addgenes \
       prokka_input/mob_suite_output/Res13-Sevr-PER06-05-b-A/plasmid_476.fasta
Res13-Sevr-PER06-05-b-A


```

## Run PROKKA with fasta file obtainded from Genbank

```shell
prokka --force \
       --outdir prokka_output/MK070495.1 \
       --proteins protein_fasta_protein_homolog_model.fasta \
       --evalue 1e-9 \
       --addgenes \
       prokka_input/genbank_files/MK070495.1

```


## Corresponding GENcontext commands with these gbk files


```shell
./expl_gen_context.py -t 'sul3' -c 'card' -p /home/brouardjs/data/local_gccode_projects/dpl/genome_annotation/prokka_annotation_with_arg_labelling/prokka_output/MK070495.1 -n 5

/expl_gen_context.py -t 'CTX-M-1' -c 'card' -p /home/brouardjs/data/local_gccode_projects/dpl/genome_annotation/prokka_annotation_with_arg_labelling/prokka_output/Res13-Lact-PEA12-26 -n 6

./expl_gen_context.py -t 'sul3' -c 'card' -p ../../genome_annotation/prokka_annotation_with_arg_labelling/prokka_output/MK070495.1 -n 6
```


## Note about FASTA headers and PROKKA

Prokka sometimes complain when fasta header are too long.

You could use the --compliant option or, even better, rename the fasta header before lauching PROKKA.


## Contributors

  * Jean-Simon Brouard, Ph.D.  
Biologist in bioinformatics, Science and Technology Branch  
Agriculture and Agri-Food Canada / Government of Canada  
jean-simon.brouard@canada.ca