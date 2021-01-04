

## Install prokka in a new environment via conda

    conda create -n prokka install -c bioconda prokka=1.14.6


## Activate the prokka environment

    conda activate prokka



## List of prokka commands

Once the installation is completed, you can check the programm version and the several options available:

    prokka


## Get scripts to lauch many prokka commands in parallel, PLASMID core database, and more by cloning this gitlab project:

    git clone https://gccode.ssc-spc.gc.ca/ac_/dpl/genome_annotation/prokka_annotation_with_arg_labelling.git



## Add some folders to match the folder organization used in this notebook:

    mkdir data metadata doc
    mkdir -p analysis/prokka
    mkdir -p data/mob_suite

The analysis/prokka folder will hold the input and output of the prokka analysis
The data/mob_suite will hold the output of a mob_suite analysis

**Typically, MOB-suite assemblies files are the input of the prokka analysis**


## Copy the modified prokka exectubable at the right location in the conda prokka env

**Note: the original prokka will be overwritten by this action.**


To know where your original prokka executable is located use the UNIX command which:

    which prokka

Copy the file at the right location

    cp ./scripts/edited_executable/prokka  /home/brouardjs/miniconda3/envs/prokka/bin

## Note à Mario à propos des modifications de l'exécutable prokka

*Auparavant, j'utilisais l'option --protein pour l'annotation des gènes d'antibiorésistance avec CARD. Je n'ai pas eu le temps de formater les informations du fichier protein_fasta_protein_homolog_model.fasta pour en faire un fichier fasta spécial utilisable par prokka, mais je vais le faire rapidement à mon retour. Le but est de remplacer la NCBI Bacterial Antimicrobial Resistance Reference Gene Database par une base de données similaire (core database) avec les données de CARD. Comme nous en avions discuté, la meilleure option serait de préparer une base de données de résistance aux métaux de la même manière que j'ai préparé la db PLASMIDS et dont l'ajout est décrit ici.*

## Information about the modification #1 of the prokka executable (No action required!)

The first line has been changed to allow the use of Perl installed in the conda environment (with BioPerl):

```perl
#!/usr/bin/env perl
```

Otherwise, you could get errors like : 'Can't locate Bio/SeqIO.pm in @INC (you may need to install the Bio::SeqIO module'.


## Information about the modification #2 of the prokka executable (No action required!)

As documented [here](https://github.com/tseemann/prokka#installation), the three core databases used by prokka, applied in order, are:
 * ISfinder
 * a NCBI Bacterial Antimicrobial Resistance Reference Gene Database
 * UniProtKB (SwissProt).

Here, by adding the second block of code, we modify the prokka executable to allow the query of an additionnal BLAST+ core database (PLASMIDS) as a primary source of annotation. PLASMID is a custom database of curated sequences found in some enterobacteriaceae plasmids.


```perl
# https://www.ncbi.nlm.nih.gov/bioproject/PRJNA313047
# if there is an AMR (antimicrobial resitance) database we use that early on
my $AMR_db = "$dbdir/kingdom/$kingdom/AMR";
if (-r $AMR_db) {
  push @database, {
    DB  => $AMR_db,
    SRC => 'similar to AA sequence:BARRGD:',
    FMT => 'blast',
    CMD => $BLASTPCMD,
    MINCOV => 90,
    #EVALUE => 1E-300,   # need to exact alleles (~ MIN_DBL, 0.0 not accepted
    EVALUE => 1E-9,   # JSB no hits with 1E-300
  };
}


# added by JSB | custom db to annotate our plasmids GT lab 211
my $PLASMIDS_db = "$dbdir/kingdom/$kingdom/PLASMIDS";
if (-r $PLASMIDS_db) {
  push @database, {
    DB  => $PLASMIDS_db,
    SRC => 'similar to AA sequence:PLASMIDS:',
    FMT => 'blast',
    CMD => $BLASTPCMD,
    MINCOV => 90,
    EVALUE => 1E-9,
  };
}
```

## Information about the Modification #3 of the fasta executbable (No action required!)

The third modification is to add the name of the new core database in an array. Note that this function is not used by the main prokka executable but rather by a companion script (setupdb.pl) used to prepare NCBI BLAST+ database.


```perl
sub setup_db {

  add_bundle_to_path();

  clean_db(0);  # don't quit, come back here

  check_tool('makeblastdb');

  for my $db (qw/sprot IS AMR PLASMIDS/) {               # <---- JSB edited line
    for my $fasta (<$dbdir/kingdom/*/$db>) {
      next unless -r $fasta;
      msg("Making kingdom BLASTP database: $fasta");
      runcmd("makeblastdb -hash_index -dbtype prot -in \Q$fasta\E -logfile /dev/null");
    }
  }
  for my $genus (<$dbdir/genus/*>) {
    msg("Making genus BLASTP database: $genus");
    runcmd("makeblastdb -hash_index -dbtype prot -in \Q$genus\E -logfile /dev/null");
  }

  check_tool('hmmpress');
  for my $hmm (<$dbdir/hmm/*.hmm>) {
    msg("Pressing HMM database: $hmm");
    runcmd("hmmpress \Q$hmm\E");
  }

  check_tool('cmpress');
  for my $cm (<$dbdir/cm/{Viruses,Bacteria,Archaea}>) {
    msg("Pressing CM database: $cm");    
    runcmd("cmpress \Q$cm\E");
  }
  
  list_db();
}
```


## Copy the special fasta file containing the sequences of the new PLASMID core database at the right place.

By default, prokka use the Bacteria kingdom.

    cp ./db/core_database/PLASMIDS /home/brouardjs/miniconda3/envs/prokka/db/kingdom/Bacteria


## Information about the special fasta file containing the sequences of the new Core database
The format of prokka special fasta file is described [here](https://github.com/tseemann/prokka#installation). Briefly, crucial informations in the header (the seq ID, the gene name and the gene product) are separated by ~~~ . The prokka program then used these fields to produce better annotations by adding the gene name and the gene product to the annotated features. Here are some lines of the PLASMID prokka special fasta file :


```shell
>BAB91567.1 ~~~repY~~~regulator of repZ expression
MKPYQRFNPVQCINTRHNRSAISDSLWQV
>BAB91569.1 ~~~arsR1~~~DNA-binding transcriptional repressor ArsR
MLQLTPLQLFKNLSDETRLGIVLLLREMGELCVCDLCMALDQSQPKISRHLAMLRESGIL
LDRKQGKWVHYRLSPHIPSWAAQIIEQAWLSQQDDVQVIARKLASVNCSGSSKAVCI
>BAB91570.1 ~~~arsD1~~~arsenic metallochaperone
MKTLMVFDPAMCCSTGVCGTDVDQALVDFSADVQWLKQCGVQIERFNLAQQPMSFVQNEK
VKAFIEASGAEGLPLLLLDGETVMAGRYPKRAELARWFGIPLDKVGLAPSGCCGGNTSCC
>BAB91571.1 ~~~tnpA~~~transposase_7
MPRRVTLTDRQKDALLRLPTSQTDLLKHYTLSDEDLGHIRLRRRAHNRFGFALQLCVLRY
PGRVLAPGELIPAEVIEFIGAQLGLGADDLVDYAAREETRHEHLAELRGLYGFRTFSGRG
ASELKEWLFREAEMAVSNEDIARRFVAECRRTRTVLPATSTIERLCAAALVDAERRIETR
IASRLPMSIREQLLALLEETADDRVTRFVWLRQFEPGSNSSSANRLLDRLEYLQRIDLPE
DLLAGVPAHRVTRLRRQGERYYADGMRDLPEDRRLAILAVCVSEWQAMLADAVVETHDRI
VGRLYRASERICHAKVADEAGVVRDTLKSFAEIGGALVDAQDDGQPLGDVIASGSGWDGL
KTLVAMATRLTATMADDPLNHVLDGYHRFRRYAPRMLRLLDLRAAPVALPLLEAVTALRT
GLNDAAMTSFLRPSSKWHRHLRAQRAGDARLWEIAVLFHLRDAFRSGDVWLTRSRRYGDL
KHALVPAQSIAEGGRLAVPLRPEEWLADRQARLDMRLRELGRAARAGTIPGGSIENGVLH
IEKLEAAAPTGAEDLVLDLYKQIPPTRITDLLLEVDAATGFTEAFTHLRTGAPCADRIGL
MNVILAEGINLGLRKMADATNTHTFWELIRIGRWHVEGEAYDRALAMVVEAQAALPMARF
WGMGTSASSDGQFFVATEQGEAMNLVNAKYGNTPGLKAYSHVSDQYAPFATQVIPATASE
APYILDGLLMNDAGRHIREQFTDTGGFTDHVFAACAILGYRFAPRIRDLPSKRLYAFNPS
AAPAHLRALIGGKVNQAMIERNWPDILRIAATIAAGTVAPSQILRKLASYPRQNELATAL
REVGRVERTLFMIDWILDAELQRRAQIGLNKGEAHHALKRAISFHRRGEIRDRSAEGQHY
RIAGMNLLAAIIIFWNTMKLGEVVANQKRDGKLLSPDLLAHVSPLGWEHINLTGEYRWPK
P
>BAB91572.1 ~~~yahA~~~transposase_8
MSLKHSDEFKRDAVRIALTSGLTRRQVASDLSIGLSTLGKWIASISDETKIPTQDTDLLR
ENERLRKENRILREEREILKKAAIFFAVQKL
>BAB91573.1 ~~~tnpR~~~transposase_11
MCELDILHDSLYQFCPELHLKRLNSLTLACHALLDCKTLTLTELGRNLPTKARTKHNIKR
IDRLLGNRHLHKERLAVYRWHASFICSGNTMPIVLVDWSDIREQKRLMVLRASVALHGRS
VTLYEKAFPLSEQCSKKAHDQFLADLASILPSNTTPLIVSDAGFKVPWYKSVEKLGWYWL
SRVRGKVQYADLGAENWKPISNLHDMSSSHSKTLGYKRLTKSNPISCQILLYKSRSKGRK
NQRSTRTHCHHPSPKIYSASAKEPWVLATNLPVEIRTPKQLVNIYSKRMQIEETFRDLKS
PAYGLGLRHSRTSSSERFDIMLLIALMLQLTCWLAGVHAQKQGWDKHFQANTVRNRNVLS
TVRLGMEVLRHSGYTITREDLLVAATLLAQNLFTHGYALGKL
>BAB91574.1 ~~~tetD~~~transcriptional regulator of tet operon
MYIEQHSRYQNKANNIQLRYDDKQFHTTVIKDVLLWIEHNLDQSLLLDDVANKAGYTKWY
FQRLFKKVTGVTLASYIRARRLTKAAVELRLTKKTILEIALKYQFDSQQSFTRRFKYIFK
VTPSYYRRNKLWELEAMH
```


## Run a prokka script to prepare all the core databases:


    prokka --setupdb

You can check that the new core database has been detected properly with:
    
    prokka --listdb



## Running the lauch_prokka on MOB-suite output assemblies files

Now that everything is set up correctly, you can run prokka on a batch of assemblies files

Navigate to the scripts/ folder and use the new lauch_prokka.py script. (Le script fonctionne n'est pas terminé, mais il fonctionne!)







## Note a propos de l'ajout des métadonnées

Auparavant, l'ajout des métadonnées se faisait avec l'aide d'un fichier texte SPECIES_INFOS qui devait contenir les noms des souches de l'analyses et les informations correspondantes à propos des genres et des espèces de ces souches. Clairement, le script lauch_prokka pourra utilisé comme input la (future) db sqlite pour aller chercher ces informations.


## Note à moi-même du 2 janvier

Avec les noms de protéines de type accession number on peut trouver le protein_product avec le fichier aro_catergories_index.csv de CARR.


## Note à moi-même du 3 janvier

Il y a qqch à corriger dans le script fastaReHeader.pl pour qu'il gère correctement les nouveaux plasmids_novel avec des caractères alphanumériques.

