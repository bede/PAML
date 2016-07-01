#! /bin/bash

usage=$(cat << EOF
   # This script runs a pipeline that takes a fasta file and BAMfiles and tests for selection:
   #

   autoPAML.sh [options]
   Options:
      -t <v> : *required* Numberof threads to use.
EOF
);

while getopts o:t: option
do
        case "${option}"
        in
		t) TC=${OPTARG};;
        esac
done

##Align

for inputaln in $(ls *fasta); do
    F=$(basename "$inputaln" .fasta)
    if [ $(ps -all | grep 'java\|codeml\|raxmlHPC' | wc -l | awk '{print $1}') -lt $TC ] ;
    then
        if [ ! -f $F.out ] ;
        then
            echo 'processing' $inputaln
            java -Xmx2000m -jar /share/bin/macse_v1.01b.jar -prog alignSequences -seq "$inputaln" -out_NT $F.aln &&
            perl /share/pal2nal.v14/pal2nal.pl $F'_macse_AA.fasta' $F.aln -output fasta -nogap -nomismatch > $F.clean || true &&
            raxmlHPC-PTHREADS -f a -m GTRGAMMA -T 1 -x 340394856 -N 100 -n $F.tree -s $F.clean -p 69283650 &&
            python autoPAML.py $F.clean RAxML_bestTree.$F.tree $F.out &&
            python autoPAMLresults.py $F.out | tee -a paml.results &
        else
            echo 'next'
        fi
    else
        until [ $(ps -all | grep 'java' | wc -l | awk '{print $1}') -lt $TC ] ;
        do
            echo 'waiting for' $inputaln
            sleep 25s;
        done
        if [ ! -f $F.out ] ;
        then
            java -Xmx2000m -jar /share/bin/macse_v1.01b.jar -prog alignSequences -seq "$inputaln" -out_NT $F.aln &&
            perl /share/pal2nal.v14/pal2nal.pl $F'_macse_AA.fasta' $F.aln -output fasta -nogap -nomismatch > $F.clean || true &&
            raxmlHPC-PTHREADS -f a -m GTRGAMMA -T 1 -x 340394856 -N 100 -n $F.tree -s $F.clean -p 69283650 &&
            python autoPAML.py $F.clean RAxML_bestTree.$F.tree $F.out &&
            python autoPAMLresults.py $F.out | tee -a paml.results &
        else
            echo 'moving on'
        fi
    fi
done
