#include <stdio.h>

extern "C" int MyPrint(const char* format, ...);

int main()
{
    MyPrint("%s_%s_%s_%s_%s", "LOL", "KEK", "CHEBUREK", "hihi", "haha");

    const char* str = "%d %d\n";

    MyPrint(str, 123, 456);

    MyPrint("%d %s %x %d%%%c%b\n", 
             -1, "love", 3802, 100, 33, 31);

    str = "Check Java work: %s + %s = %s\n";

    MyPrint(str, "123", "456", "123456");

    str = "All %%: %b %c %d %o %x %s\n";

    MyPrint(str, 5, '5', 101, 65, 52, "The end");

    str = "A lot of %b%b%b%d%x\n";

    MyPrint(str, 5, 5, 5, 5, 5);

    MyPrint("Проверка двенадцатеричной системы!: %t %t %t\n", 1, 12, 144);

    return 0;
}
