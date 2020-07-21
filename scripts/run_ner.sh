#!/usr/bin/env bash

declare -a langs=("bn" "gu" "kn" "ml" "mr" "or" "pa" "ta" "te" "hi" "as") 

for lang in "${langs[@]}"
do
	echo "Processing $lang"
	export DATA_DIR="data/wikiann-ner"
	export LANG=$lang
	export MAX_LENGTH=128
	export TASK=ner
	# export BERT_MODEL=bert-base-multilingual-cased
	export BERT_MODEL="models/albert-large-orig-full-final"
        export CONFIG=models/albert-large-orig-full-final/config.json
        export TOKENIZER=models/albert-large-orig-full-final/spiece.model
	export BATCH_SIZE=32
	export NUM_EPOCHS=3
	export SEED=1
	export OUTPUT_DIR_NAME=$LANG-malbert-large
	export CURRENT_DIR=${PWD}
	export OUTPUT_DIR=${CURRENT_DIR}/outputs/$TASK/${OUTPUT_DIR_NAME}

	cat "$DATA_DIR/$LANG/$LANG-train.txt" | awk -F" " '{if($NF>0) {print $1, $(NF)} else {print $0;}}' > "$DATA_DIR/$LANG/train.txt.tmp"
	cat "$DATA_DIR/$LANG/$LANG-valid.txt" | awk -F" " '{if($NF>0) {print $1, $(NF)} else {print $0;}}' > "$DATA_DIR/$LANG/valid.txt.tmp"
	cat "$DATA_DIR/$LANG/$LANG-test.txt" | awk -F" " '{if($NF>0) {print $1, $(NF)} else {print $0;}}' > "$DATA_DIR/$LANG/test.txt.tmp"

	# wget "https://raw.githubusercontent.com/stefan-it/fine-tuned-berts-seq/master/scripts/preprocess.py"

	python3 scripts/preprocess.py "$DATA_DIR/$LANG/train.txt.tmp" $BERT_MODEL $MAX_LENGTH > "$DATA_DIR/$LANG/train.txt"
	python3 scripts/preprocess.py "$DATA_DIR/$LANG/valid.txt.tmp" $BERT_MODEL $MAX_LENGTH > "$DATA_DIR/$LANG/valid.txt"
	python3 scripts/preprocess.py "$DATA_DIR/$LANG/test.txt.tmp" $BERT_MODEL $MAX_LENGTH > "$DATA_DIR/$LANG/test.txt"

	cat "$DATA_DIR/$LANG/train.txt" "$DATA_DIR/$LANG/valid.txt" "$DATA_DIR/$LANG/test.txt" | cut -d " " -f 2 | grep -v "^$"| sort | uniq > "$DATA_DIR/$LANG/labels.txt"

	mkdir -p $OUTPUT_DIR

	# Add parent directory to python path to access lightning_base.py
	# export PYTHONPATH="../":"${PYTHONPATH}"

	python3 -m tasks.token-classification.run_model \
	--data_dir $DATA_DIR \
	--lang $LANG \
	--labels "$DATA_DIR/$LANG/labels.txt" \
	--model_name_or_path $BERT_MODEL \
        --config_name $CONFIG \
        --tokenizer_name $TOKENIZER \
	--output_dir $OUTPUT_DIR \
	--max_seq_length  $MAX_LENGTH \
	--num_train_epochs $NUM_EPOCHS \
	--train_batch_size $BATCH_SIZE \
	--seed $SEED \
	--n_tpu_cores 8 \
	--do_train \
	--do_predict

done