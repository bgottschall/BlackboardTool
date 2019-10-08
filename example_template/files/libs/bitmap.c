#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "bitmap.h"


#define BMP_HEADER_SIZE 54

void freeBmpData(bmpImage *image) {
	if (image->data != NULL) {
		free(image->data);
		image->data = NULL;
	}
	if (image->rawdata != NULL) {
		free(image->rawdata);
		image->rawdata = NULL;
	}
}


void freeBmpImage(bmpImage *image) {
	freeBmpData(image);
	if (image) {
		free(image);
	}
}

int reallocateBmpBuffer(bmpImage *image, unsigned int const width, unsigned int const height) {
	freeBmpData(image);
	if (height * width > 0) {
		image->rawdata = calloc(image->height * image->width, sizeof(pixel));
		if (image->rawdata == NULL) {
			return 1;
		}
		image->data = malloc(image->height * sizeof(pixel *));
		if (image->data == NULL) {
			freeBmpData(image);
			return 1;
		}
		for (unsigned int i = 0; i < height; i++) {
			image->data[i] = &(image->rawdata[i * width]);
		}
	}
	return 0;
}


bmpImage * newBmpImage(unsigned int const width, unsigned int const height) {
	bmpImage *new = malloc(sizeof(bmpImage));
	if (new == NULL)
		return NULL;
	new->width = width;
	new->height = height;
	new->data = NULL;
	new->rawdata = NULL;
	reallocateBmpBuffer(new, width, height);
	return new;
}

void freeBmpChannelData(bmpImageChannel *image) {
	if (image->data != NULL) {
		free(image->data);
		image->data = NULL;
	}
	if (image->rawdata != NULL) {
		free(image->rawdata);
		image->rawdata = NULL;
	}
}

void freeBmpImageChannel(bmpImageChannel *image) {
	freeBmpChannelData(image);
	if (image) {
		free(image);
	}
}

int reallocateBmpChannelBuffer(bmpImageChannel *image, unsigned int const width, unsigned int const height) {
	freeBmpChannelData(image);
	if (height * width > 0) {
		image->rawdata = calloc(image->height * image->width, sizeof(unsigned char));
		if (image->rawdata == NULL) {
			return 1;
		}
		image->data = malloc(image->height * sizeof(unsigned char *));
		if (image->data == NULL) {
			freeBmpChannelData(image);
			return 1;
		}
		for (unsigned int i = 0; i < height; i++) {
			image->data[i] = &(image->rawdata[i * width]);
		}
	}
	return 0;
}

bmpImageChannel * newBmpImageChannel(unsigned int const width, unsigned int const height) {
	bmpImageChannel *new = malloc(sizeof(bmpImageChannel));
	if (new == NULL)
		return NULL;
	new->width = width;
	new->height = height;
	new->data = NULL;
	new->rawdata = NULL;
	reallocateBmpChannelBuffer(new, width, height);
	return new;
}



int loadBmpImage(bmpImage *image, char const *filename) {
	int ret = 1;
	FILE* fImage = fopen(filename, "rb");   //read the file
	if (!fImage) {
		goto failed_file;
	}

	unsigned char header[BMP_HEADER_SIZE];
	if (fread(header, sizeof(unsigned char), BMP_HEADER_SIZE, fImage) < BMP_HEADER_SIZE) {
		goto failed_read;
	}
	image->width = *(int *) &header[18];
	image->height = *(int *) &header[22];

	reallocateBmpBuffer(image, image->width, image->height);
	if (image->rawdata == NULL) {
		goto failed_read;
	}

	int padding=0;
	while ((image->width * 3 + padding) % 4 != 0)
		padding++;

	size_t lineSize = (image->width * 3);
	size_t paddedLineSize = lineSize + padding;
	unsigned char* data = malloc(paddedLineSize * sizeof(unsigned char));

	for (unsigned int y=0; y < image->height; y++ ) {
		if (fread( data, sizeof(unsigned char), paddedLineSize, fImage) < paddedLineSize) {
			goto failed_read;
		}
		memcpy(image->data[y], data, lineSize);
	}
	ret = 0;
failed_read:
	fclose(fImage); //close the file
failed_file:
	return ret;
}

int saveBmpImage(bmpImage *image, char const *filename) {
	int ret = 0;
	FILE *fImage=fopen(filename,"wb");
	if(!fImage) {
		return 1;
	}

	char padBuffer[4] = {};
	const size_t dataSize = image->width * image->height * sizeof(pixel);
	size_t lineWidth = image->width * sizeof(pixel);
	size_t padding = 0;
	if (lineWidth % 4 != 0) {
		padding = 4 - (lineWidth % 4);
	}

	const size_t size= dataSize + BMP_HEADER_SIZE;

	unsigned char header[BMP_HEADER_SIZE]= {
		'B', 'M', size & 255, (size >> 8) & 255, (size >> 16) & 255, size >> 24, 0,
		0, 0, 0, 54, 0, 0, 0, 40, 0, 0, 0, image->width & 255, image->width >> 8, 0,
		0, image->height & 255, image->height >> 8, 0, 0, 1, 0, 24, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	};

	if (fwrite(header, sizeof(unsigned char), BMP_HEADER_SIZE,fImage) < BMP_HEADER_SIZE) {
		ret = 1;
	} else {
		for (unsigned int i = 0; i < image->height; i++) {
			if (fwrite(image->data[i], sizeof(pixel), image->width ,fImage) < image->width)  {
				ret = 1;
				break;
			}
			if (padding > 0) {
				if (fwrite(padBuffer, sizeof(char), padding ,fImage) < padding)  {
					ret = 1;
					break;
				}
			}
		}
	}
	fclose(fImage);
	return ret;
}

int extractImageChannel(bmpImageChannel *to, bmpImage *from, unsigned char extractMethod(pixel from)) {
	if (from->width > to->width || from->height > to->height)
		return 1;
	for (unsigned int y = 0; y < from->height; y++) {
		for (unsigned int x = 0; x < from->width; x++) {
			to->data[y][x] = extractMethod(from->data[y][x]);
		}
	}
	return 0;
}
int mapImageChannel(bmpImage *to, bmpImageChannel *from, pixel extractMethod(unsigned char from)) {
	if (from->width > to->width || from->height > to->height)
		return 1;
	for (unsigned int y = 0; y < from->height; y++) {
		for (unsigned int x = 0; x < from->width; x++) {
			to->data[y][x] = extractMethod(from->data[y][x]);
		}
	}
	return 0;
}

pixel mapRed(unsigned char from) {
	pixel res = {};
	res.r = from;
	return res;
}
pixel mapGreen(unsigned char from) {
	pixel res = {};
	res.g = from;
	return res;
}
pixel mapBlue(unsigned char from) {
	pixel res = {};
	res.b = from;
	return res;
}

unsigned char extractRed(pixel from) {
	return from.r;
}
unsigned char extractGreen(pixel from) {
	return from.g;
}
unsigned char extractBlue(pixel from) {
	return from.b;
}

unsigned char extractAverage(pixel from) {
	return ((from.r + from.g + from.b) / 3);
}

pixel mapEqual(unsigned char from) {
	pixel res = {from, from, from};
	return res;
}
