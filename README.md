# stickr-makr

A script that converts images/gifs into stickers (downscaled images/gifs).

## Example

Say you have a gif that you intend to use as a reaction gif (sticker) in online group chats:

![original](https://i.imgur.com/zcwHNQC.gif)

However, it is 600*337px with a size of 1.4M, which kind of wastes your bandwidth every time you post it.

So, you can put it inside a folder `reactions/`, execute the script with `reactions/` as an argument, then it will be downscaled to 266*149px with a reasonable size (273KB) while still being visible:

![downscaled](https://i.imgur.com/n1Q4hXG.gif)

Images can also be downscaled in the same fashion to reduce size.

## Usage

```
NAME
	stickr-makr - generate stickers from images/gifs

SYNOPSIS
	make-stickers.sh [OPTIONS] FOLDER

DESCRIPTION
	This script will generate stickers (downscaled
	images and gifs) from files in the FOLDER. Stickers
	will be put under a new folder ./Stickers; Original
	images/gifs will be untouched.

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
		The default value is 200.
```

## Requirements

[ImageMagick](https://imagemagick.org/), [FFmpeg](https://ffmpeg.org/)
