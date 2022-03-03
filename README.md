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

Give execute permissions:

```shell
chmod +x make-stickers.sh
```

Run:

```shell
./make-stickers.sh FOLDER
```

A new `Stickers/` folder will be created under the current working directory, containing all stickers converted from `FOLDER`. The `FOLDER` will be untouched.

## Change sticker size

See the `DIMENSION` variable in `make-stickers.sh`.

## Requirements

[ImageMagick](https://imagemagick.org/), [FFmpeg](https://ffmpeg.org/)
