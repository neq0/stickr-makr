#!/bin/bash

# Pass in a folder as parameter, this scripts converts all images in
# said folder into stickers (downscaled images).
# The scale is controlled by DIMENSION.
# Converted stickers will be put under ./Stickers/

# A square image will be downscaled to DIMENSION*DIMENSION (max).
# Non-square images will be downscaled to the area of DIMENSION*DIMENSION.
DIMENSION=200
area=$(echo $DIMENSION | awk '{ print $1 * $1 }')

# ImageMagick is required
command -v magick > /dev/null
if [ $? -ne 0 ]; then
	echo "ImageMagick is required for the use of this script."
	echo "Exiting..."
	exit 1
fi

# Parameter must be a directory
IMG_DIR="$1"
if [ ! -d "$IMG_DIR" ]; then
	echo "$IMG_DIR is not a directory."
	echo "Exiting..."
	exit 1
fi

# Confirmation of overwriting Stickers/
if [[ -d Stickers/ && -n $(ls -A Stickers/) ]]; then
	echo "The directory Stickers/ exists and is non-empty."
	read -p "Its contents will be wiped out. Proceed? (Y/N) "
	if [[ $REPLY != Y && $REPLY != y ]]; then
		echo "Aborting..."
		exit 1
	fi
fi

# Wipe out Stickers/
rm -rf Stickers/ 
mkdir -p Stickers/

scale_down_image() {
	file="$1"
	final_extension="$2"
	directory=$(dirname "$file")
	# parent_directory="${file%/*}"
	final_file="./Stickers/${file%\.*}.$final_extension"
	mkdir -p "./Stickers/$directory"
	magick convert "$IMG_DIR/$file" -resize "$area@>" "$final_file"
}

echo "Converting..."
files=$(find "$IMG_DIR" -mindepth 1 -type f -printf "%P\n")
IFS=$'\n'
for file in $files; do
	# Match jpegs
	if [[ "$file" =~ .+\.(jpe?g|jf?if)$ ]]; then
		scale_down_image "$file" jpg
	# Match pngs
	elif [[ "$file" =~ .+\.png$ ]]; then
		scale_down_image "$file" png
	fi
done
unset IFS

echo "Conversion completed"
