#ifndef __ATLAS_H_
#define __ATLAS_H_

enum eAtlas {
    eWheel0 = 0,
    eWheel1,
    eWheel2,
    eWheel3,
    eWheel4,
    eWheel5,
    eHole,
    eNoHole,
    eCracking,
    eCockpitTop,
    eCockpitLeft,
    eCockpitRight,
    eCockpitBottom,
    eCockpitWL,
    eCockpitWR,
    eHole2,
    eNoHole2,
    eCracking2,
    eCockpitTop2,
    eCockpitLeft2,
    eCockpitRight2,
    eCockpitBottom2,
    eCockpitWL2,
    eCockpitWR2,
    eEngine,
    eEngineFlames0,
    eEngineFlames1,
    eEngineFlames2,
    eRoadYellowDark,
    eRoadYellowLight,
    eRoadRedDark,
    eRoadRedLight,
    eRoadBlack,
    eRoadWhite,
    eRoadYellowDark2,
    eRoadYellowLight2,
    eRoadRedDark2,
    eRoadRedLight2,
    eLAST
};

extern float atlas_tx1[eLAST], atlas_tx2[eLAST], atlas_ty1[eLAST], atlas_ty2[eLAST];

void InitAtlasCoord();

#endif //__ATLAS_H_