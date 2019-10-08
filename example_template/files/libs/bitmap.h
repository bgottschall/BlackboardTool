#ifndef BITMAP_H
#define BITMAP_H

typedef struct {
  unsigned char b;
  unsigned char g;
  unsigned char r;
} pixel;

typedef struct {
	unsigned int width;
	unsigned int height;
  pixel *rawdata;
	pixel **data;
} bmpImage;

typedef struct {
  unsigned int width;
  unsigned int height;
  unsigned char *rawdata;
  unsigned char **data;
} bmpImageChannel;

bmpImage *newBmpImage(unsigned int const width, unsigned int const height);
void freeBmpImage(bmpImage *image);
int loadBmpImage(bmpImage *image, char const *filename);
int saveBmpImage(bmpImage *image, char const *filename);

bmpImageChannel * newBmpImageChannel(unsigned int const width, unsigned int const height);
void freeBmpImageChannel(bmpImageChannel *imageChannel);
int extractImageChannel(bmpImageChannel *to, bmpImage *from, unsigned char extractMethod(pixel from));
int mapImageChannel(bmpImage *to, bmpImageChannel *from, pixel extractMethod(unsigned char from));
pixel mapRedChannel(unsigned char from);
unsigned char extractRedChannel(pixel from);

pixel mapRed(unsigned char from);
pixel mapGreen(unsigned char from);
pixel mapBlue(unsigned char from);
unsigned char extractRed(pixel from);
unsigned char extractGreen(pixel from);
unsigned char extractBlue(pixel from);
unsigned char extractAverage(pixel from);
pixel mapEqual(unsigned char from);

#endif
