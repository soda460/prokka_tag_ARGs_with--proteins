

## Install prokka in a separate environment via conda

    conda create -n prokka install -c bioconda prokka=1.14.6


## Activate the prokka environment

    conda activate prokka



## List of prokka commands

once the installation is completed, you can check the programm version and the several options available.

    prokka

## Suggested folder organization

    mkdir db  mob_suite metadata scripts prokka doc


## Get this gitlab project

    git clone https://gccode.ssc-spc.gc.ca/ac_/dpl/genome_annotation/prokka_annotation_with_arg_labelling.git 


## Copy the modified prokka exectubable at the right place in conda prokka env (overwrite)

To know where your original prokka exectuble is located use which

    which prokka

   cp fbla/fasta  /home/brouardjs/miniconda3/envs/prokka/bin/prokka


## Information about the first modification of the fasta executbable relative to the original file (lines 929-971)

The second block of code was added. It allows prokka to use as a primary source
of annotation a custom database of curated sequences found in enterobacteriaceae strains.
As documented here (link), the three core databases, applied in order, are (i) ISfinder, (ii) a NCBI Bacterial Antimicrobial Resistance Reference Gene Database and (iii) UniProtKB (SwissProt).
Here prokka will simply use another core database. 

#### Note à Mario

*Auparavant, j'utilisais l'option --protein pour l'annotation des gènes d'antibiorésistance avec CARD. Mais je vais préparer bientôt un fichier d'input pour que prokka puisse utiliser card comme une core database. On pourra aussi préparer une base de données de résistance aux métaux de la même manière.*


```perl
#...
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
#...
```

## Modification 2 of the fasta executbable relative to the original file (lines 1659-1692)

**The second modification is to add the name of the new core database in an array. Note that this function is note used by the main prokka executable but rather by a companion script (setupdb.pl).**


```perl
#...
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
#...
```



## Copy the sepcial fasta file containing the sequences of the new Core database at the right place.

    cp edited_executable/prokka /home/brouardjs/miniconda3/envs/prokka/db/kingdom/Bacteria


## Information about the sepcial fasta file containing the sequences of the new Core database
The special fasta file is described here (put link here). Briefly it can holds a couple of informations in the header (ID, gene name, gene product) and help prokka to produce better annotations. Here an example of some lines of the PLASMID fasta file :


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





## Running the lauch_prokka on MOB-suite output assemblies files


input : a mob_suite folder containing subfolders like this :


mob_suite


franchement, ça serait cool de faire une queries sur la db sqlite3
pour aller fetcher le nom d'espèce


ça marche avec des PATH absolus poche


si :Can't locate Bio/SeqIO.pm in @INC (you may need to install the Bio::SeqIO module)

changer le header du fichier prokkka



./lauch_prokka_gnu_parallel.sh /home/brouardjs/data/local_gccode_projects/dpl/genome_annotation/prokka_annotation_with_arg_labelling/mob_suite/wgs_assemblies /home/brouardjs/data/local_gccode_projects/dpl/genome_annotation/prokka_annotation_with_arg_labelling/prokka /home/brouardjs/data/local_gccode_projects/dpl/genome_annotation/prokka_annotation_with_arg_labelling/metadata/SPECIES_INFOS_2


## 2 janvier

avec les noms de protéines AAL58 on peut trouver le produit avec le ficheir aro_catergories_index.csv



