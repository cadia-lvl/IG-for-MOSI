#!/bin/bash
# Place this bash script adjacent to the audio folder
# run:
# bash make_index_csv.sh



SYNTH='_gen'

TALROMUR_DATA_PATH="/data/tts/talromur"

for file in audio/*/*; do
	filename="$(basename "$file")"
	NAME_OF_RECORDING=${file:6}
	echo $filename
	if [[ "$filename" == *"$SYNTH"* ]]; then
		SYNTH_OR_RECORDING="S"
		filename="$(sed s/_gen././ <<< $filename)"
		IS_GROUND_TRUTH="0"
	else
		SYNTH_OR_RECORDING="R"
		IS_GROUND_TRUTH="1"
	fi
	
	#Token_text
	for info in ${TALROMUR_DATA_PATH}2/raw/*/info.json ${TALROMUR_DATA_PATH}/published/??*/index.tsv; do

		if [[ $(echo ${info} | tail -c 5) = "json" ]]; then
			TOKEN_TEXT="$(cat $info | jq -r '.[] | select(.recording_info.recording_fname=='\"$filename\"') | .text_info.text')"
			[[ ! -z "$TOKEN_TEXT" ]] && \
				VOICE_ID="$(cat $info | jq -r '.[] | select(.recording_info.recording_fname=='\"$filename\"') | .collection_info.user_id')" && \
				UTTERANCE_ID="$(cat $info | jq -r '.[] | select(.recording_info.recording_fname=='\"$filename\"') | .text_info.id')" && \
				break
		else
			TOKEN_TEXT="$(grep "${filename::-4}" ${info} | awk 'BEGIN { FS="\t" } { print $2 }')"
			[[ ! -z "$TOKEN_TEXT" ]] && \
				VOICE_ID="$(echo $info | awk 'BEGIN {FS="/"} {print $6}')" && \
				UTTERANCE_ID="${filename::-4}" && \
				break
		fi
	done
	#Model_id or gt
	MODEL_ID="$(echo $file | awk 'BEGIN { FS="/"} {print $2}')"
	echo "${NAME_OF_RECORDING};${SYNTH_OR_RECORDING};${TOKEN_TEXT};${IS_GROUND_TRUTH};${MODEL_ID};${UTTERANCE_ID};${VOICE_ID};" >> index.csv

done
