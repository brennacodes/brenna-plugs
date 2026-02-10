# sips Reference

macOS built-in image processing tool (Scriptable Image Processing System). No installation required.

## Resize

```bash
# Aspect-preserving resize to max dimension
sips -Z 1280 image.png --out image.png

# Exact resize (NOTE: height before width)
sips -z 600 800 image.png --out image.png

# Resize width only (preserves aspect ratio)
sips --resampleWidth 1024 image.png --out image.png

# Resize height only (preserves aspect ratio)
sips --resampleHeight 768 image.png --out image.png
```

## Crop

```bash
# Center crop (NOTE: height before width)
sips -c 600 800 image.png --out image.png
```

Cropping centers the crop region on the image. If the image is smaller than the crop dimensions, it pads with white.

## Format Conversion

```bash
# Convert format
sips -s format jpeg image.png --out image.jpg
sips -s format heic image.png --out image.heic
```

Supported formats: `jpeg`, `png`, `tiff`, `gif`, `heic`, `pdf`, `bmp`

## Query Properties

```bash
# Get pixel dimensions
sips -g pixelWidth image.png
sips -g pixelHeight image.png

# Get multiple properties
sips -g pixelWidth -g pixelHeight -g format image.png

# Get all properties
sips -g all image.png
```

## Key Notes

- **Argument order matters**: `-z height width` and `-c height width` — height comes first
- **In-place editing**: Use `--out` pointing to the same file for in-place modification
- **Retina awareness**: sips works with actual pixel dimensions, not point dimensions. A retina screenshot will report 2x the display resolution.
- **No quality setting for resize**: sips uses system defaults for resampling quality
