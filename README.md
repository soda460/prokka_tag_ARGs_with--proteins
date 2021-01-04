

## Install prokka in a new environment via conda

    conda create -n prokka install -c bioconda prokka=1.14.6


## Activate the prokka environment

    conda activate prokka



## List of prokka commands

Once the installation is completed, you can check the programm version and the several options available:

    prokka


## Get scripts to lauch many prokka commands in parallel, PLASMID core database, and more by cloning this gitlab project:

    git clone https://gccode.ssc-spc.gc.ca/ac_/dpl/genome_annotation/prokka_annotation_with_arg_labelling.git



## Add some folders to cloned folder to match the folder organization used in this notebook:

    mkdir metadata doc
    mkdir -p analysis/prokka


## Copy the modified prokka exectubable at the right location in the conda prokka env

Note The original prokka will be overwritten by this action.

To know where your original prokka executable is located use the UNIX command which:

    which prokka

Copy the file at the right location

    cp ./scripts/edited_executable/prokka  /home/brouardjs/miniconda3/envs/prokka/bin

## Note à Mario à propos des modifications de l'exécutable prokka

*Auparavant, j'utilisais l'option --protein pour l'annotation des gènes d'antibiorésistance avec CARD. Je n'ai pas eu le temps de formater les informations du fichier protein_fasta_protein_homolog_model.fasta pour en faire un fichier fasta spécial utilisable par prokka, mais je vais le faire rapidement à mon retour. Le but est de remplacer la NCBI Bacterial Antimicrobial Resistance Reference Gene Database par une base de données similaire (core database) avec les données de CARD. Comme nous en avions discuté, la meilleure option serait de préparer une base de données de résistance aux métaux de la même manière.*

## Modification #1 of the prokka executable (line 1)

Change the first line to
```perl
#!/usr/bin/env perl
```

Otherwise, you could get errors like : 'Can't locate Bio/SeqIO.pm in @INC (you may need to install the Bio::SeqIO module'
in spite that bioperl is present in the conda environment.

## Information about the modification #2 of the prokka executable (lines 929-971)

The second block of code was added. It allows prokka to use as a primary source
of annotation a custom database of curated sequences found in enterobacteriaceae strains.
As documented [here](https://github.com/tseemann/prokka#installation), the three core databases, applied in order, are (i) ISfinder, (ii) a NCBI Bacterial Antimicrobial Resistance Reference Gene Database and (iii) UniProtKB (SwissProt).
Here we modify the prokka executable to allow the program to query another core database. 


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

## Modification 3 of the fasta executbable relative to the original file (lines 1659-1692)

The third modification is to add the name of the new core database in an array. Note that this function is note used by the main prokka executable but rather by a companion script (setupdb.pl) used to prepare NCBI BLAST+ database.


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



## Copy the special fasta file containing the sequences of the new Core database at the right place.

By default, prokka use the Bacteria kingdom.

    cp edited_executable/prokka /home/brouardjs/miniconda3/envs/prokka/db/kingdom/Bacteria


## Information about the sepcial fasta file containing the sequences of the new Core database
The prokka special fasta file is described [here](https://github.com/tseemann/prokka#installation). Briefly it can holds a couple of informations in its header (ID, gene name, gene product) and help prokka to produce better annotations. Here an example of some lines of the PLASMID prokka special fasta file :


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

You can check that it has been detected properly with:
    
    prokka --listdb



## Running the lauch_prokka on MOB-suite output assemblies files

Now that everything is set up correctly, you can run prokka on a batch of assemblies files

Navigate to the scripts folder and use the new lauch_prokka python script. (Need to be adjusted for qsub...)



input : a mob_suite folder containing subfolders like this :


mob_suite







## Note a propos de l'ajout des métadonnées

Auparavant, l'ajout des métadonnées se faisait avec l'aide d'un fichier texte SPECIES_INFOS qui devait contenir les noms des souches de l'analyses et les informations correspondantes à propos des genres et des espèces de ces souches. Clairement, le script lauch_prokka pourra utilisé comme input la (future) db sqlite pour aller chercher ces informations.


## Note à moi-même du 2 janvier

Avec les noms de protéines de type accession number on peut trouver le protein_product avec le fichier aro_catergories_index.csv de CARR.



