#ifndef TEXT_LIB_H_INCLUDED
#define TEXT_LIB_H_INCLUDED

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

struct Text
{
    FILE* file_ptr;
    size_t buf_size;
    char* buffer;
};

void OpenFile(Text* const text, const char* const filename);
void ReadBuffer(Text* const text);
void WriteInNewFile(Text* const text, const char* const filename);

#endif // TEXT_LIB_H_INCLUDED
