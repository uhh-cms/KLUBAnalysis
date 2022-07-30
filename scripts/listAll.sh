#!/usr/bin/env bash

initialdir="$PWD"

rm -f "remove_commands.txt"
rm -f "resubmission_commands.txt"

for dir in ./*/; do
    cd $dir
    pwd
    anybad=false
    if [ ! -f goodfiles.txt ]; then # safe if already run on part of dataset
        touch goodfiles.txt
        touch badfiles.txt
        for logfile in output_*.log; do
            tmp=${logfile#*_}
            idx=${tmp%.*}

            # check errors
            isbad=false
            if grep -q "R__unzip: error" "$logfile"; then
                echo "job num $idx: file corrupted"
                isbad=true
            elif ! grep -q "... SKIM finished, exiting." "$logfile"; then
                echo "job num $idx: not correctly finished"
                isbad=true
            fi

            # add to good and bad files, but also build a list with remove and resub commands
            if ! $isbad; then
                # remember in goodfiles
                echo $PWD/output_$idx.root >> goodfiles.txt
            else
                anybad=true
                # remember in badfiles
                echo $PWD/output_$idx.root >> badfiles.txt
                # add to files to delete
                echo "rm $PWD/output_$idx.root" >> "$initialdir/remove_commands.txt"
                echo "rm $PWD/output_$idx.log" >> "$initialdir/remove_commands.txt"
                # build resubmission command
                filelist="$( cat output_${idx}.log | grep -Po "^\*\*\s+INFO\:\s+inputFile\s+:\s+\K/.*" )"
                if [ -f "$filelist" ]; then
                    subdir="$( dirname "$filelist" )"
                    echo "( cd "${subdir}" && condor_submit condorLauncher_${idx}.sh )" >> "$initialdir/resubmission_commands.txt"
                else
                    echo "job num $idx: cannot build resubmission command!"
                fi
            fi
        done
    fi
    $anybad && echo
    cd "$initialdir"
done
