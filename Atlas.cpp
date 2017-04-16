#include "Atlas.h"

float atlas_tx1[eLAST] = {0};
float atlas_tx2[eLAST] = {0};
float atlas_ty1[eLAST] = {0};
float atlas_ty2[eLAST] = {0};

void InitAtlasCoord() {
    const int x[eLAST] = { 
        160, 128, 96, 64, 32, 0,    //eWheel
        0, 16, 0,  //eHole, eNotHole, eCracking
        0, 0, 0, 0, 320 // eCockpit, eEgines...
    };
    const int y[eLAST] = { 
        0, 0, 0, 0, 0, 0,    //eWheel
        64, 64, 128,
        160, 384, 576, 768, 0
    };
    const int w[eLAST]  = {
        24, 24, 24, 24, 24, 24,
        12, 12, 238,
        320, 320, 320 ,320, 320
    };
    const int h[eLAST] = {
        56, 56, 56, 56, 56, 56,
        8, 8, 8,
        200, 200, 200 ,200, 200
    };

    for (int i=0; i<eLAST; i++) {
        atlas_tx1[i] = (float)x[i] / 1024.0f;
        atlas_tx2[i] = (float)(x[i]+w[i]) / 1024.0f;
        #ifdef linux
        atlas_ty1[i] = 1.0f-(float)y[i] / 1024.0f;
        atlas_ty2[i] = 1.0f-(float)(y[i]+h[i]) / 1024.0f;
        #else
        atlas_ty1[i] = (float)y[i] / 1024.0f;
        atlas_ty2[i] = (float)(y[i]+h[i]) / 1024.0f;
        #endif
    }

}