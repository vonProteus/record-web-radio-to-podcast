#!/bin/bash -xe

TMP_DIR="$(mktemp -d)"
DATE=$(date +"%Y-%m-%d")


RECORDING="$TMP_DIR/$DATE-out.mp3"

ffmpeg -i "$WRURL" \
   -t "$RECORD_TIME_IN_SECONDS" \
   $FFMPEGOPTIONS \
   -c copy \
   "$RECORDING" ||
   FFMPEG_EXIT_CODE=$?

ffprobe -show_format -show_streams "$RECORDING" -v quiet -of json > "$RECORDING.json"
jq . "$RECORDING.json"

TITLE=$(jq -r ".format.tags.\"icy-description\"" "$RECORDING.json")
UPLOADER=$(jq -r ".format.tags.\"icy-name\"" "$RECORDING.json")
SIZE=$(echo "scale=2; $(jq -r ".format.size" "$RECORDING.json") / 1024.0 / 1024.0" | bc | sed 's/^\./0./')
DURATION=$(jq -r ".streams[]|select(.codec_name == \"mp3\").duration" "$RECORDING.json")
BITRATE=$(($(jq -r ".streams[]|select(.codec_name == \"mp3\").bit_rate" "$RECORDING.json") / 1024))
FREQUENCY=$(jq -r ".streams[]|select(.codec_name == \"mp3\").sample_rate" "$RECORDING.json")

NEWFILENAME="$DATE-$TITLE"
cp "$RECORDING" "$NEWFILENAME.mp3"

cp /scripts/template.xml "${NEWFILENAME}.xml"
xmlstarlet ed -L -u "/PodcastGenerator/episode/titlePG" --value "#CDATASTART#${TITLE}#CDATAEND#" "${NEWFILENAME}.xml"
xmlstarlet ed -L -u "/PodcastGenerator/episode/shortdescPG" --value "#CDATASTART#${SHORT}#CDATAEND#" "${NEWFILENAME}.xml"
xmlstarlet ed -L -u "/PodcastGenerator/episode/longdescPG" --value "#CDATASTART#${FULL}#CDATAEND#" "${NEWFILENAME}.xml"
xmlstarlet ed -L -u "/PodcastGenerator/episode/imgPG" --value "$IMGPGURL" "${NEWFILENAME}.xml"
xmlstarlet ed -L -u "/PodcastGenerator/episode/categoriesPG/category1PG" --value "uncategorized" "${NEWFILENAME}.xml"
xmlstarlet ed -L -u "/PodcastGenerator/episode/categoriesPG/category2PG" --value "" "${NEWFILENAME}.xml"
xmlstarlet ed -L -u "/PodcastGenerator/episode/categoriesPG/category3PG" --value "" "${NEWFILENAME}.xml"
xmlstarlet ed -L -u "/PodcastGenerator/episode/keywordsPG" --value "#CDATASTART##CDATAEND#" "${NEWFILENAME}.xml"
xmlstarlet ed -L -u "/PodcastGenerator/episode/explicitPG" --value "no" "${NEWFILENAME}.xml"
xmlstarlet ed -L -u "/PodcastGenerator/episode/authorPG/namePG" --value "${UPLOADER}" "${NEWFILENAME}.xml"
xmlstarlet ed -L -u "/PodcastGenerator/episode/authorPG/emailPG" --value "" "${NEWFILENAME}.xml"
xmlstarlet ed -L -u "/PodcastGenerator/episode/fileInfoPG/size" --value "$SIZE" "${NEWFILENAME}.xml"
xmlstarlet ed -L -u "/PodcastGenerator/episode/fileInfoPG/duration" --value "$DURATION" "${NEWFILENAME}.xml"
xmlstarlet ed -L -u "/PodcastGenerator/episode/fileInfoPG/bitrate" --value "$BITRATE" "${NEWFILENAME}.xml"
xmlstarlet ed -L -u "/PodcastGenerator/episode/fileInfoPG/frequency" --value "$FREQUENCY" "${NEWFILENAME}.xml"



mkdir -p "${PGAPPDATA}/media" "${PGAPPDATA}/images"
cp -p "$NEWFILENAME.mp3" "${PGAPPDATA}/media"
cp -p "$NEWFILENAME.xml" "${PGAPPDATA}/media"

curl -s -I -L "$PGREGENERATERSSURL" || echo "notifying PodcastGenerator failed…"

exit ${FFMPEG_EXIT_CODE:=0}
