#include "interface.h"

void ShowFunnyInterface()
{
    txCreateWindow(800, 500);

    HDC picture = txLoadImage(PICTURE_NAME, 800, 500);

    if (picture == NULL)
        printf("Cannot open file with picture...\n");

    txBitBlt (txDC(), 0, 0, 800, 500, picture, 0, 0); 

    txPlaySound("music\\mingoster.wav");  

    txDeleteDC(picture);

    return;
}