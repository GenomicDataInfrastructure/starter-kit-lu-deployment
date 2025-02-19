# Number of case (1 to 6)
CASENO=1

# Type of case (index, mother, father)
CASETYPE=index

# Shorthand (IC, M, F) - to match the one above - index=IC, mother=M, father=F
CASESHORT=IC

DATASET=synthetic-data

for CHROM in {1..2} X Y MT
do
	# Generate the path automatically
	FILEPATH="${CASENO}${CASESHORT}${CHROM}"
	echo "Using $FILEPATH"

	# Upload and encrypt
	./scripts/sda-admin --sda-config s3cmd.conf --sda-key c4gh.pub.pem upload /mnt/gdi-synth-data-nfs/b1mg-rd-synthetic-data/vcf_symlinks/$FILEPATH
done

for CHROM in {1..2} X Y MT
do
	# Ingest first file from the top (assumes successful resolution of the previous command)
	# ./scripts/sda-admin ingest $(./scripts/sda-admin ingest | head -n1)

	# Ingest the file
	FILEPATH="${CASENO}${CASESHORT}${CHROM}"
	FILECRYPTED="${FILEPATH}.c4gh"
	echo "Ingesting $FILECRYPTED"
	./scripts/sda-admin ingest $FILECRYPTED

	# Set accession
	ACCESSIONID="${CASENO}${CASESHORT}${CHROM}"
	echo "Accession ID: $ACCESSIONID"
	./scripts/sda-admin accession $ACCESSIONID $FILECRYPTED
	
	echo "Loading $ACCESSIONID in dataset $DATASET"
	./scripts/sda-admin dataset "${DATASET}" $FILECRYPTED
done
