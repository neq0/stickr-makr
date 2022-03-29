#!/bin/bash

# stickr-makr (C) 2022 ElectroQt

# A square image will be downscaled to DIMENSION*DIMENSION (max).
# Non-square images will be downscaled to the area of DIMENSION*DIMENSION.
IMG_DIMENSION=400
GIF_DIMENSION=200

SHORT=h,o,i:,g:
LONG=help,only-images,image-dimension:,gif-dimension:
USAGE="\
NAME
	stickr-makr - generate stickers from images/gifs

SYNOPSIS
	make-stickers.sh [OPTIONS] FOLDER

OPTIONS
	-h, --help
		Print this help text and exit

	-o, --only-images
		Skip gifs when converting; as a result,
		FFmpeg is not a requirement

	-i DIM, --image-dimension DIM
		Set image sticker dimension.
		The side length of a square sticker
		would be DIM. If the sticker is
		non-square, its area would be the same
		as that of a square sticker with side
		length of DIM. The default value
		is 400, which means every converted
		sticker would be 160000 pixels large.

	-g DIM, --gif-dimension DIM
		Set gif sticker dimension.
		The default value is 200."

PARSED=$(getopt --options $SHORT --longoptions $LONG \
	--name "stickr-makr" -- "$@")
# The parameters are malformed
if [[ $? -ne 0 ]]; then exit 1; fi

eval set -- "$PARSED"

ONLY_IMAGES=0

while [[ $# -gt 0 ]]; do
	case "$1" in
		-h|--help)
			echo "$USAGE"
			exit 0
			;;
		-o|--only-images)
			ONLY_IMAGES=1
			shift
			;;
		-i|--image-dimension)
			IMG_DIMENSION="$2"
			if [[ ! ( 20 -le $IMG_DIMENSION && $IMG_DIMENSION -le 2000 ) ]]; then
				>&2 echo "Image dimension invalid."
				exit 1
			fi
			shift
			shift
			;;
		-g|--gif-dimension)
			GIF_DIMENSION="$2"
			if [[ ! ( 20 -le $GIF_DIMENSION && $GIF_DIMENSION -le 2000 ) ]]; then
				>&2 echo "Gif dimension invalid."
				exit 1
			fi
			shift
			shift
			;;
		--)
			# End of options
			shift
			break
			;;
		*)
			>&2 echo "Unrecogized option: $1"
			exit 1
			;;
	esac
done

if [[ $# -eq 0 ]]; then
	>&2 echo "No folder given."
	exit 1
fi

IMG_DIR="$1"
if [ ! -d "$IMG_DIR" ]; then
	echo "$IMG_DIR is not a directory."
	echo "Exit."
	exit 1
fi

# Store the script location to correctly locate bin/pngquant
SCRIPT_DIR=$(dirname "$0")

# ImageMagick is required
command -v magick >/dev/null
if [ $? -ne 0 ]; then
	echo "ImageMagick not detected."
	echo "Exit."
	exit 1
fi

# If ONLY_IMAGES flag not set, FFmpeg is required
command -v ffmpeg >/dev/null
if [[ $ONLY_IMAGES -eq 1 && $? -ne 0 ]]; then
	echo "FFmpeg not detected."
	echo "Exiting..."
	exit 1
fi

# Confirmation of overwriting Stickers/
if [[ -d Stickers/ && -n $(ls -A Stickers/) ]]; then
	echo "The directory Stickers/ exists and is non-empty."
	read 2>&1 -p "Its contents will be wiped out. Proceed? (Y/N) "
	if [[ "$REPLY" != Y && "$REPLY" != y ]]; then
		echo "Abort."
		exit 0
	fi
fi

img_area=$(echo $IMG_DIMENSION | awk '{ print $1 * $1 }')
gif_area=$(echo $GIF_DIMENSION | awk '{ print $1 * $1 }')

# Wipe out Stickers/
rm -rf Stickers/ 
mkdir -p Stickers/

# Temporary directory for storing gif frames
# Ideally, use a directory that mktemp assigns.
# However, in the case that mktemp fails - perhaps when the user lacks access to /tmp/
# or something - make a temporary directory under ./ as a backup plan
tmp_dir=$(mktemp -d) || tmp_dir="./.temp/"
mkdir -p $tmp_dir

scale_down_jpg() {
	# Purge tmp_dir
	rm -rf $tmp_dir/*

	# Doc on resizing images: https://legacy.imagemagick.org/Usage/resize/#resize
	err_msg=$(convert "$input" -quality 85% \
		-resize "$img_area@>" "$tmp_dir/simple.jpg" 2>&1 >/dev/null) || return 1
	# Jpeg compression technique copied from https://stackoverflow.com/a/7262050/10435897
	err_msg=$(convert "$input" -interlace Plane -gaussian-blur 0.05 -quality 85% \
		-resize "$img_area@>" "$tmp_dir/optimized.jpg" 2>&1 >/dev/null) || return 1

	if [[ $(stat --printf %s "$tmp_dir/simple.jpg") -le $(stat --printf %s "$tmp_dir/optimized.jpg") ]]
	then cp "$tmp_dir/simple.jpg" "$output"
	else cp "$tmp_dir/optimized.jpg" "$output"
	fi
}

scale_down_png() {
	err_msg=$(convert "$input" -resize "$img_area@>" "$output" 2>&1 >/dev/null) || return 1
	# Use pngquant to compress png. Overwrite original
	err_msg=$("$SCRIPT_DIR/bin/pngquant" --skip-if-larger --force --ext ".png" "$output") || return 1
}

scale_down_gif() {
	# Purge tmp_dir
	rm -rf $tmp_dir/*

	# Generate palette from source gif for better gif quality
	# Copied from https://superuser.com/a/1049820/1344967
	err_msg=$(ffmpeg -y -i "$input" -vf palettegen $tmp_dir/palette.png 2>&1 >/dev/null) || return 1

	# Find fps of source gif.
	# Copied from https://askubuntu.com/a/110269/1420906
	fps=$(ffmpeg -i "$input" 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p")

	mkdir $tmp_dir/frames
	# Split source gif into frames 0001.png, 0002.png, etc
	err_msg=$(ffmpeg -i "$input" $tmp_dir/frames/%04d.png 2>&1 >/dev/null) || return 1

	# Downscale each frame
	for frame in $tmp_dir/frames/*; do
		frame_name=$(basename $frame)
		frame_output="$tmp_dir/frames/final_$frame_name"
		# Doc on resizing images: https://legacy.imagemagick.org/Usage/resize/#resize
		err_msg=$(convert "$frame" -resize "$gif_area@>" "$frame_output" 2>&1 >/dev/null) || return 1
	done

	# Reassemble frames into gif, set framerate, use pallete
	# Copied from https://superuser.com/a/1049820/1344967
	err_msg=$(ffmpeg -y -r $fps -i $tmp_dir/frames/final_%04d.png \
		-i $tmp_dir/palette.png -filter_complex paletteuse "$output" 2>&1 >/dev/null) || return 1
}

echo "Converting..."
# Find all files; -printf formats filenames to be relative to starting-point instead of working directory
files=$(find "$IMG_DIR" -mindepth 1 -type f -printf "%P\n")
old_IFS="$IFS"
IFS=$'\n'
for file in $files; do
	# Match JPEGs
	input="$IMG_DIR/$file"
	directory=$(dirname "$file")
	mkdir -p "./Stickers/$directory"
	if [[ "$file" =~ .+\.(jpe?g|jf?if)$ ]]; then
		# Change extension to .jpg
		output="./Stickers/${file%\.*}.jpg"
		scale_down_jpg "$input" "$output"	
	# Match PNGs
	elif [[ "$file" =~ .+\.png$ ]]; then
		output="./Stickers/$file"
		scale_down_png "$input" "$output"	
	# Match gifs
	elif [[ "$file" =~ .+\.gif$ ]]; then
		if [ $ONLY_IMAGES -eq 1 ]; then
			continue
		fi
		output="./Stickers/$file"
		scale_down_gif "$input" "$output"
	else
		continue
	fi

	# Error handling
	if [ $? -eq 0 ]; then
		echo "Created: $output"
	else
		input_path=$(realpath "$input")
		>&2 echo -e "Failed to convert $input_path. Error message:\n$err_msg"
	fi
done
IFS="$old_IFS"

echo "Conversion completed"
rm -rf $tmp_dir
