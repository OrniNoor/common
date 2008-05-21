#include <stdio.h>
#include "matOps.h"

void matrixAdd(double *pMatA, int mA, int nA,
               double *pMatB, int mB, int nB,
               double *pMatC)
{
    int m, n;
    int nC = nA;
    int mC = mA;

    if (nA != nB){ printf("matrix dimension mismatch!\n");}
    if (mA != mB){ printf("matrix dimension mismatch!\n");}

    for (m = 0; m < mA; m++){
        for (n = 0; n < nA; n++){
            *(pMatC + nC*m + n) = *(pMatA + nA*m + n) + *(pMatB + nB*m + n);
        }
    }

}
