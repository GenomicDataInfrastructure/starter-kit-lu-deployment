#! /bin/bash

# Where the BAM files are stored
SYMLINKS_PATH=/mnt/gdi-synth-data-nfs/b1mg-rd-synthetic-data/bam_symlinks

# Which dataset is the data loaded to
DATASET=synthetic-data

# Load each case (Case1, ..., Case6)
for CASENO in {1..6}
do
    # Load each individual (Index, Father, Mother)
    for CASESHORT in IC F M
    do
        FILENAME="Case${CASENO}_${CASESHORT}.bam"
        FILEPATH="${SYMLINKS_PATH}/${FILENAME}"
        echo "`date`: Uploading $FILENAME ($FILEPATH) to Storages and Interfaces"

        # Upload and encrypt
        ./scripts/sda-admin --sda-config s3cmd.conf --sda-key c4gh.pub.pem upload $FILEPATH
        echo "`date`: sda-admin finished running, will sleep 60 secs"

        sleep 60

        # REMOVE ONCE IT'S WORKING
        break
        # -----
    done

    # REMOVE ONCE IT'S WORKING
    break
    # ---
done

for CASENO in {1..6}
do
    for CASESHORT in IC F M
    do
        # Ingest first file from the top (assumes successful resolution of the previous command)
        # ./scripts/sda-admin ingest $(./scripts/sda-admin ingest | head -n1)

        # Ingest the file
        FILENAME="Case${CASENO}_${CASESHORT}.bam"
        FILEPATH="${SYMLINKS_PATH}/${FILENAME}"
        
        FILECRYPTED="${FILENAME}.c4gh"
        echo "`date`: Ingesting $FILECRYPTED"
        ./scripts/sda-admin ingest $FILECRYPTED
        echo "`date`: sda-admin finished running, will sleep 60 secs"

        sleep 60

        # Set accession
        ACCESSIONID="BAM_${CASENO}${CASESHORT}"
        echo "`date`: Accession ID: $ACCESSIONID"
        ./scripts/sda-admin accession $ACCESSIONID $FILECRYPTED
        echo "`date`: sda-admin finished running, will sleep 120 secs"

        sleep 120

        echo "`date`: Loading $ACCESSIONID in dataset $DATASET"
        ./scripts/sda-admin dataset "${DATASET}" $FILECRYPTED
        echo "`date`: sda-admin finished running, will sleep 300 secs"

        sleep 300
        
        # REMOVE ONCE IT'S WORKING
        break
        # -----
    done

    # REMOVE ONCE IT'S WORKING
    break
    # ---
done
