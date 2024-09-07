#!/bin/bash

SRC="/mnt/raw"
DEST="/mnt/encoded"
PRESET_FILE="/app/presets.json"
PRESET="Normal"
DEST_EXT=mp4
HANDBRAKE_CLI=HandBrakeCLI
SLACK_MENTION_USER="${SLACK_MENTION_USER:-kanata}"

gen_post_data()
{
  text=$1
  cat <<EOF
{
    "blocks": [
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "${text}"
            }
         }
    ]
}
EOF
}

start_encoding()
{
  text="エンコード開始 "$1
  curl -X POST -H 'Content-type: application/json' --data "$(gen_post_data "$text")" "${SLACK_WEBHOOK_URL}"
}

succeed_encoding()
{
  text="エンコード成功 "$1
  curl -X POST -H 'Content-type: application/json' --data "$(gen_post_data "$text")" "${SLACK_WEBHOOK_URL}"
}

fail_encoding()
{
  text="エンコード失敗 "$1" <@${SLACK_MENTION_USER}>"
  curl -X POST -H 'Content-type: application/json' --data "$(gen_post_data "$text")" "${SLACK_WEBHOOK_URL}"
}

end_encoding()
{
  text="エンコード完了 <@${SLACK_MENTION_USER}>"
  curl -X POST -H 'Content-type: application/json' --data "$(gen_post_data "$text")" "${SLACK_WEBHOOK_URL}"
}

total=$(ls -p -U1 $SRC | grep -v / | wc -l)
count=0

for FILE in "$SRC"/*
do
  count=`expr $count + 1`

  extension=${FILE##*.}
  filename=${FILE%.*}
  base_filename=$(basename "$FILE")
  base_filename_ext_removed=${base_filename%.*}

  start_encoding "$base_filename $count/$total"
  $HANDBRAKE_CLI --preset-import-file $PRESET_FILE --preset $PRESET -i "$FILE" -o $DEST/"$base_filename_ext_removed".$DEST_EXT &
  pid=$!
  wait $pid

  if [ $? != 0 ]; then
    fail_encoding "$base_filename"
  else
    succeed_encoding "$base_filename"
  fi

done

end_encoding