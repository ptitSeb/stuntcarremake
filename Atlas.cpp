#include "Atlas.h"

float atlas_tx1[eLAST] = {0};
float atlas_tx2[eLAST] = {0};
float atlas_ty1[eLAST] = {0};
float atlas_ty2[eLAST] = {0};

void InitAtlasCoord() {
    const int x[eLAST] = { 
        160, 128, 96, 64, 32, 0,    //eWheel
        0, 16, 0,  //eHole, eNotHole, eCracking
        41, 0, 279, 0, // eCockpit
        42, 42, 42, 362 // eEgines...
    };
    const int y[eLAST] = { 
        0, 0, 0, 0, 0, 0,    //eWheel
        64, 64, 128,
        160, 160, 160, 313,
        507, 699, 891, 123
    };
    const int w[eLAST]  = {
        24, 24, 24, 24, 24, 24,
        12, 12, 238,
        238, 41, 41, 320,
        235, 235 ,235, 235
    };
    const int h[eLAST] = {
        56, 56, 56, 56, 56, 56,
        8, 8, 8,
        16, 153, 153, 47,
        35, 35 ,35, 35
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