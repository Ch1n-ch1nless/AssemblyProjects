#include "text_lib.h"

const char * const PROGRAM = "PASSWORD.COM";
const char * const PATCHED_PROGRAM = "PATCH.COM";

const size_t ADDRESS_OF_PATCHING_BYTE = 0xF6;

void Patching(Text* const patched_program);

int main()
{
    struct Text patched_program = {};

    OpenFile(&patched_program, PROGRAM);

    ReadBuffer(&patched_program);

    Patching(&patched_program);

    WriteInNewFile(&patched_program, PATCHED_PROGRAM);

    return 0;
}

void Patching(Text* const patched_program)
{
    assert((patched_program != nullptr) && "Pointer to \"patched_program\" is NULL!!!\n");

    patched_program->buffer[ADDRESS_OF_PATCHING_BYTE] = 0x1E;
    
    return;
}
