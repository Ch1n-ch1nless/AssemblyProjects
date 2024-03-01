#include "text_lib.h"

void OpenFile(Text* const text, const char* const filename)
{
    assert((text     != nullptr) && "Pointer to \"text\"     is NULL!!!\n");
    assert((filename != nullptr) && "Pointer to \"filename\" is NULL!!!\n");

    struct stat st = {};

    text->file_ptr = fopen(filename, "rb");
    assert((text->file_ptr != nullptr) && "Program can not read the file!");

    stat(filename, &st);
    text->buf_size = st.st_size + 1;

    return;
}

void ReadBuffer(Text* const text)
{
    assert((text != nullptr) && "Pointer to \"text\" is NULL!!!\n");

    text->buffer = (char*) calloc(text->buf_size, sizeof(char));
    assert((text->buffer != nullptr) && "Program can not allocate memory!\n");

    const size_t symbol_number = fread(text->buffer, sizeof(char), text->buf_size, text->file_ptr);
    if (symbol_number != text->buf_size) {
        #if 0
        if (feof(text->file_ptr)) {
            printf("Error reading %s: unexpected end of file\n", "<STRING>");
        } else if (ferror(text->file_ptr)) {
            printf("Error reading %s", "<STRING>");
        }
        #endif
        if (symbol_number > text->buf_size) {
            printf("ERROR! Symbols in file are more then buf_size!");
            assert(0);
        }
    }

    fclose(text->file_ptr);
    text->file_ptr = nullptr;

    return;
}

void WriteInNewFile(Text* const text, const char* const filename)
{
    assert((text     != nullptr) && "Pointer to \"text\"     is NULL!!!\n");
    assert((filename != nullptr) && "Pointer to \"filename\" is NULL!!!\n");

    FILE* file_ptr = fopen(filename, "wb");
    assert((file_ptr != nullptr) && "Program can not open the file!");

    fwrite(text->buffer, sizeof(char), text->buf_size, file_ptr);

    fclose(file_ptr);

    return;
}
