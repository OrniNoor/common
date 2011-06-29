#include <mex.h>
#include <math.h>
#include <stdio.h>

// Compilation: mex -I. maxCurvatureBezier.cpp

#include "rpoly_ak1.cpp" // http://www.akiti.ca/rpoly_ak1_Intro.html

double curvature(double t, double *a, double *b);
double curvature(double t, double *a, double *b, double *c);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    // Check number of input arguments
    if (nrhs != 1 && nrhs != 3) {
        mexErrMsgTxt("1 or 3 input arguments required.");
    }
    
    // Check number of output arguments
    if (nlhs > 2) {
        mexErrMsgTxt("Too many output arguments.");
    }
    
    // Check the dimension of the control points
    const mwSize *inputSize = mxGetDimensions(prhs[0]);
    int nCP = inputSize[0]; // Number of control points
    int controlPointsDimension = inputSize[1];
    
    if (controlPointsDimension != 3 || nCP < 2 || nCP > 4) {
        mexErrMsgTxt("Only 2,3 or 4 3D control points supported!");
    }
    
    // Variables
    double *cP; // Control points
    double *curvatureMax; // Maximal curvature of the Bezier curve
    double *tCurvMax; // Corresponding curve parameter to the maximal curvature
    double t0, t1; // Parametrization interval
    
    // Associate inputs
    cP = mxGetPr(prhs[0]);
    
    if (nrhs == 3) {
        t0 = *mxGetPr(prhs[1]);
        t1 = *mxGetPr(prhs[2]);
    } else {
        t0 = 0.0;
        t1 = 1.0;
    }
    
    // Associate outputs
    plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
    curvatureMax = mxGetPr(plhs[0]);
    
    plhs[1] = mxCreateDoubleMatrix(1, 1, mxREAL);
    tCurvMax = mxGetPr(plhs[1]);
    
    // =====================
    // Linear Bezier curve
    // =====================
    if (nCP == 2) {
        // Set the output values
        *tCurvMax = t0; // The curvature is 0 for all points!
        *curvatureMax = 0;
    }
    
    // =====================
    // Quadratic Bezier curve
    // =====================
    else if (nCP == 3) {
        // B[t_] = (1-t)^2*P0 + 2*(1-t)*t*P1 + t^2*P2;
        // B[t_] = a*t^2 + b*t + c;
        double a[3], b[3], c[3];
        double a2[3], b2[3];
        
        for (int i=0;i<3;i++) {
            // a = P0-2P1+P2
            a[i] = cP[i*nCP+0]-2*cP[i*nCP+1]+cP[i*nCP+2];
            // b = -2P0+2P1
            b[i] = -2*cP[i*nCP+0]+2*cP[i*nCP+1];
            // c = P0
            c[i] = cP[i*nCP+0];
            
            // ^2
            a2[i] = pow(a[i], 2);
            b2[i] = pow(b[i], 2);
        }
        
        // Check if denominator is zero
        double t;
        if ((a2[0]+a2[1]+a2[2])>0) {
            t = (-a[0]*b[0]-a[1]*b[1]-a[2]*b[2])/(2*(a2[0]+a2[1]+a2[2]));
        } else {
            t = t0;
        }
        
        double curvature_t = curvature(t, a, b);
        
        // Evaluate the Bezier curvature at the beginning
        double curvature_t0 = curvature(t0, a, b);
        
        // Evaluate the Bezier curvature at the end
        double curvature_t1 = curvature(t1, a, b);
        
        // Determine the highest curvature
        if ( curvature_t0 < curvature_t1 ) {
            *curvatureMax = curvature_t1;
            *tCurvMax = t1;
        } else {
            *curvatureMax = curvature_t0;
            *tCurvMax = t0;
        }
        
        // Check if the point with the highest curvature is on the curve
        if (t > t0 && t < t1) {
            // Determine the highest curvature
            if ( *curvatureMax < curvature_t ) {
                *curvatureMax = curvature_t;
                *tCurvMax = t;
            }
        }
        
        // Set the output value
        *curvatureMax = sqrt(*curvatureMax);
    }
    
    // =====================
    // Cubic Bezier curve
    // =====================
    else if (nCP == 4) {
        // B[t_] = (1-t)^3*P0 + 3*(1-t)^2*t*P1 + 3*(1-t)*t^2*P2 + t^3*P3
        // B[t_] = a*t^3 + b*t^2 + c*t + d;
        double a[3], b[3], c[3], d[3];
        double a2[3], b2[3], c2[3];
        double a3[3], b3[3], c3[3];
        double a4[3], b4[3], c4[3];
        
        for (int i=0;i<3;i++) {
            // a = -P0 + 3P1 - 3P2 + P3
            a[i] = -cP[i*nCP+0]+3*cP[i*nCP+1]-3*cP[i*nCP+2]+cP[i*nCP+3];
            // b = 3P0 - 6P1 + 3P2
            b[i] = 3*cP[i*nCP+0]-6*cP[i*nCP+1]+3*cP[i*nCP+2];
            // c = -3P0 + 3P1
            c[i] = -3*cP[i*nCP+0]+3*cP[i*nCP+1];
            // d = P0
            d[i] = cP[i*nCP+0];
            
            // ^2
            a2[i] = pow(a[i], 2);
            b2[i] = pow(b[i], 2);
            c2[i] = pow(c[i], 2);
            
            // ^3
            a3[i] = pow(a[i], 3);
            b3[i] = pow(b[i], 3);
            c3[i] = pow(c[i], 3);
            
            // ^4
            a4[i] = pow(a2[i], 2);
            b4[i] = pow(b2[i], 2);
            c4[i] = pow(c2[i], 2);
        }

        // Evaluate the Bezier curvature at the beginning
        double curvature_t0 = curvature(t0, a, b, c);
        
        // Evaluate the Bezier curvature at the end
        double curvature_t1 = curvature(t1, a, b, c);
        
        // Determine the highest curvature
        if ( curvature_t0 < curvature_t1 ) {
            *curvatureMax = curvature_t1;
            *tCurvMax = t1;
        } else {
            *curvatureMax = curvature_t0;
            *tCurvMax = t0;
        }
                       
        // Group together the terms with the same degree (Some terms could be precomputed to increase performance)
        double polyCoeff[8];

        polyCoeff[7] = 24*(-2*b[0]*b2[1]*c3[0]-2*b[0]*b2[2]*c3[0]+a[1]*b[1]*c4[0]+a[2]*b[2]*c4[0]+
                4*b2[0]*b[1]*c2[0]*c[1]-2*b3[1]*c2[0]*c[1]-2*b[1]*b2[2]*c2[0]*c[1]-
                a[1]*b[0]*c3[0]*c[1]-a[0]*b[1]*c3[0]*c[1]-2*b3[0]*c[0]*c2[1]+
                4*b[0]*b2[1]*c[0]*c2[1]-2*b[0]*b2[2]*c[0]*c2[1]+a[0]*b[0]*c2[0]*c2[1]+
                a[1]*b[1]*c2[0]*c2[1]+2*a[2]*b[2]*c2[0]*c2[1]-2*b2[0]*b[1]*c3[1]-
                2*b[1]*b2[2]*c3[1]-a[1]*b[0]*c[0]*c3[1]-a[0]*b[1]*c[0]*c3[1]+a[0]*b[0]*c4[1]+
                a[2]*b[2]*c4[1]+4*b2[0]*b[2]*c2[0]*c[2]-2*b2[1]*b[2]*c2[0]*c[2]-
                2*b3[2]*c2[0]*c[2]-a[2]*b[0]*c3[0]*c[2]-a[0]*b[2]*c3[0]*c[2]+
                12*b[0]*b[1]*b[2]*c[0]*c[1]*c[2]-a[2]*b[1]*c2[0]*c[1]*c[2]-a[1]*b[2]*c2[0]*c[1]*c[2]-
                2*b2[0]*b[2]*c2[1]*c[2]+4*b2[1]*b[2]*c2[1]*c[2]-2*b3[2]*c2[1]*c[2]-
                a[2]*b[0]*c[0]*c2[1]*c[2]-a[0]*b[2]*c[0]*c2[1]*c[2]-a[2]*b[1]*c3[1]*c[2]-
                a[1]*b[2]*c3[1]*c[2]-2*b3[0]*c[0]*c2[2]-2*b[0]*b2[1]*c[0]*c2[2]+
                4*b[0]*b2[2]*c[0]*c2[2]+a[0]*b[0]*c2[0]*c2[2]+2*a[1]*b[1]*c2[0]*c2[2]+
                a[2]*b[2]*c2[0]*c2[2]-2*b2[0]*b[1]*c[1]*c2[2]-2*b3[1]*c[1]*c2[2]+
                4*b[1]*b2[2]*c[1]*c2[2]-a[1]*b[0]*c[0]*c[1]*c2[2]-a[0]*b[1]*c[0]*c[1]*c2[2]+
                2*a[0]*b[0]*c2[1]*c2[2]+a[1]*b[1]*c2[1]*c2[2]+a[2]*b[2]*c2[1]*c2[2]-
                2*b2[0]*b[2]*c3[2]-2*b2[1]*b[2]*c3[2]-a[2]*b[0]*c[0]*c3[2]-a[0]*b[2]*c[0]*c3[2]-
                a[2]*b[1]*c[1]*c3[2]-a[1]*b[2]*c[1]*c3[2]+a[0]*b[0]*c4[2]+a[1]*b[1]*c4[2]);
        
        polyCoeff[6] = 24*(-4*b2[0]*b2[1]*c2[0]-4*b4[1]*c2[0]-4*b2[0]*b2[2]*c2[0]-
                8*b2[1]*b2[2]*c2[0]-4*b4[2]*c2[0]-6*a[1]*b[0]*b[1]*c3[0]-
                8*a[0]*b2[1]*c3[0]-6*a[2]*b[0]*b[2]*c3[0]-8*a[0]*b2[2]*c3[0]+3*a2[1]*c4[0]+
                3*a2[2]*c4[0]+8*b3[0]*b[1]*c[0]*c[1]+8*b[0]*b3[1]*c[0]*c[1]+
                8*b[0]*b[1]*b2[2]*c[0]*c[1]+6*a[1]*b2[0]*c2[0]*c[1]+22*a[0]*b[0]*b[1]*c2[0]*c[1]-
                14*a[1]*b2[1]*c2[0]*c[1]-6*a[2]*b[1]*b[2]*c2[0]*c[1]-8*a[1]*b2[2]*c2[0]*c[1]-
                6*a[0]*a[1]*c3[0]*c[1]-4*b4[0]*c2[1]-4*b2[0]*b2[1]*c2[1]-
                8*b2[0]*b2[2]*c2[1]-4*b2[1]*b2[2]*c2[1]-4*b4[2]*c2[1]-
                14*a[0]*b2[0]*c[0]*c2[1]+22*a[1]*b[0]*b[1]*c[0]*c2[1]+6*a[0]*b2[1]*c[0]*c2[1]-
                6*a[2]*b[0]*b[2]*c[0]*c2[1]-8*a[0]*b2[2]*c[0]*c2[1]+3*a2[0]*c2[0]*c2[1]+
                3*a2[1]*c2[0]*c2[1]+6*a2[2]*c2[0]*c2[1]-8*a[1]*b2[0]*c3[1]-
                6*a[0]*b[0]*b[1]*c3[1]-6*a[2]*b[1]*b[2]*c3[1]-8*a[1]*b2[2]*c3[1]-
                6*a[0]*a[1]*c[0]*c3[1]+3*a2[0]*c4[1]+3*a2[2]*c4[1]+8*b3[0]*b[2]*c[0]*c[2]+
                8*b[0]*b2[1]*b[2]*c[0]*c[2]+8*b[0]*b3[2]*c[0]*c[2]+6*a[2]*b2[0]*c2[0]*c[2]-
                8*a[2]*b2[1]*c2[0]*c[2]+22*a[0]*b[0]*b[2]*c2[0]*c[2]-6*a[1]*b[1]*b[2]*c2[0]*c[2]-
                14*a[2]*b2[2]*c2[0]*c[2]-6*a[0]*a[2]*c3[0]*c[2]+8*b2[0]*b[1]*b[2]*c[1]*c[2]+
                8*b3[1]*b[2]*c[1]*c[2]+8*b[1]*b3[2]*c[1]*c[2]+28*a[2]*b[0]*b[1]*c[0]*c[1]*c[2]+
                28*a[1]*b[0]*b[2]*c[0]*c[1]*c[2]+28*a[0]*b[1]*b[2]*c[0]*c[1]*c[2]-
                6*a[1]*a[2]*c2[0]*c[1]*c[2]-8*a[2]*b2[0]*c2[1]*c[2]+6*a[2]*b2[1]*c2[1]*c[2]-
                6*a[0]*b[0]*b[2]*c2[1]*c[2]+22*a[1]*b[1]*b[2]*c2[1]*c[2]-14*a[2]*b2[2]*c2[1]*c[2]-
                6*a[0]*a[2]*c[0]*c2[1]*c[2]-6*a[1]*a[2]*c3[1]*c[2]-4*b4[0]*c2[2]-
                8*b2[0]*b2[1]*c2[2]-4*b4[1]*c2[2]-4*b2[0]*b2[2]*c2[2]-
                4*b2[1]*b2[2]*c2[2]-14*a[0]*b2[0]*c[0]*c2[2]-6*a[1]*b[0]*b[1]*c[0]*c2[2]-
                8*a[0]*b2[1]*c[0]*c2[2]+22*a[2]*b[0]*b[2]*c[0]*c2[2]+6*a[0]*b2[2]*c[0]*c2[2]+
                3*a2[0]*c2[0]*c2[2]+6*a2[1]*c2[0]*c2[2]+3*a2[2]*c2[0]*c2[2]-
                8*a[1]*b2[0]*c[1]*c2[2]-6*a[0]*b[0]*b[1]*c[1]*c2[2]-14*a[1]*b2[1]*c[1]*c2[2]+
                22*a[2]*b[1]*b[2]*c[1]*c2[2]+6*a[1]*b2[2]*c[1]*c2[2]-6*a[0]*a[1]*c[0]*c[1]*c2[2]+
                6*a2[0]*c2[1]*c2[2]+3*a2[1]*c2[1]*c2[2]+3*a2[2]*c2[1]*c2[2]-
                8*a[2]*b2[0]*c3[2]-8*a[2]*b2[1]*c3[2]-6*a[0]*b[0]*b[2]*c3[2]-
                6*a[1]*b[1]*b[2]*c3[2]-6*a[0]*a[2]*c[0]*c3[2]-6*a[1]*a[2]*c[1]*c3[2]+
                3*a2[0]*c4[2]+3*a2[1]*c4[2]);
        
        polyCoeff[5] = 24*(-24*a[1]*b2[0]*b[1]*c2[0]-14*a[0]*b[0]*b2[1]*c2[0]-38*a[1]*b3[1]*c2[0]-
                24*a[2]*b2[0]*b[2]*c2[0]-38*a[2]*b2[1]*b[2]*c2[0]-14*a[0]*b[0]*b2[2]*c2[0]-
                38*a[1]*b[1]*b2[2]*c2[0]-38*a[2]*b3[2]*c2[0]+3*a2[1]*b[0]*c3[0]+
                3*a2[2]*b[0]*c3[0]-39*a[0]*a[1]*b[1]*c3[0]-39*a[0]*a[2]*b[2]*c3[0]+
                24*a[1]*b3[0]*c[0]*c[1]+52*a[0]*b2[0]*b[1]*c[0]*c[1]+52*a[1]*b[0]*b2[1]*c[0]*c[1]+
                24*a[0]*b3[1]*c[0]*c[1]+28*a[2]*b[0]*b[1]*b[2]*c[0]*c[1]+24*a[1]*b[0]*b2[2]*c[0]*c[1]+
                24*a[0]*b[1]*b2[2]*c[0]*c[1]+33*a[0]*a[1]*b[0]*c2[0]*c[1]+39*a2[0]*b[1]*c2[0]*c[1]-
                36*a2[1]*b[1]*c2[0]*c[1]+3*a2[2]*b[1]*c2[0]*c[1]-39*a[1]*a[2]*b[2]*c2[0]*c[1]-
                38*a[0]*b3[0]*c2[1]-14*a[1]*b2[0]*b[1]*c2[1]-24*a[0]*b[0]*b2[1]*c2[1]-
                38*a[2]*b2[0]*b[2]*c2[1]-24*a[2]*b2[1]*b[2]*c2[1]-38*a[0]*b[0]*b2[2]*c2[1]-
                14*a[1]*b[1]*b2[2]*c2[1]-38*a[2]*b3[2]*c2[1]-36*a2[0]*b[0]*c[0]*c2[1]+
                39*a2[1]*b[0]*c[0]*c2[1]+3*a2[2]*b[0]*c[0]*c2[1]+33*a[0]*a[1]*b[1]*c[0]*c2[1]-
                39*a[0]*a[2]*b[2]*c[0]*c2[1]-39*a[0]*a[1]*b[0]*c3[1]+3*a2[0]*b[1]*c3[1]+
                3*a2[2]*b[1]*c3[1]-39*a[1]*a[2]*b[2]*c3[1]+24*a[2]*b3[0]*c[0]*c[2]+
                24*a[2]*b[0]*b2[1]*c[0]*c[2]+52*a[0]*b2[0]*b[2]*c[0]*c[2]+
                28*a[1]*b[0]*b[1]*b[2]*c[0]*c[2]+24*a[0]*b2[1]*b[2]*c[0]*c[2]+
                52*a[2]*b[0]*b2[2]*c[0]*c[2]+24*a[0]*b3[2]*c[0]*c[2]+33*a[0]*a[2]*b[0]*c2[0]*c[2]-
                39*a[1]*a[2]*b[1]*c2[0]*c[2]+39*a2[0]*b[2]*c2[0]*c[2]+3*a2[1]*b[2]*c2[0]*c[2]-
                36*a2[2]*b[2]*c2[0]*c[2]+24*a[2]*b2[0]*b[1]*c[1]*c[2]+24*a[2]*b3[1]*c[1]*c[2]+
                24*a[1]*b2[0]*b[2]*c[1]*c[2]+28*a[0]*b[0]*b[1]*b[2]*c[1]*c[2]+
                52*a[1]*b2[1]*b[2]*c[1]*c[2]+52*a[2]*b[1]*b2[2]*c[1]*c[2]+24*a[1]*b3[2]*c[1]*c[2]+
                72*a[1]*a[2]*b[0]*c[0]*c[1]*c[2]+72*a[0]*a[2]*b[1]*c[0]*c[1]*c[2]+
                72*a[0]*a[1]*b[2]*c[0]*c[1]*c[2]-39*a[0]*a[2]*b[0]*c2[1]*c[2]+
                33*a[1]*a[2]*b[1]*c2[1]*c[2]+3*a2[0]*b[2]*c2[1]*c[2]+39*a2[1]*b[2]*c2[1]*c[2]-
                36*a2[2]*b[2]*c2[1]*c[2]-38*a[0]*b3[0]*c2[2]-38*a[1]*b2[0]*b[1]*c2[2]-
                38*a[0]*b[0]*b2[1]*c2[2]-38*a[1]*b3[1]*c2[2]-14*a[2]*b2[0]*b[2]*c2[2]-
                14*a[2]*b2[1]*b[2]*c2[2]-24*a[0]*b[0]*b2[2]*c2[2]-24*a[1]*b[1]*b2[2]*c2[2]-
                36*a2[0]*b[0]*c[0]*c2[2]+3*a2[1]*b[0]*c[0]*c2[2]+39*a2[2]*b[0]*c[0]*c2[2]-
                39*a[0]*a[1]*b[1]*c[0]*c2[2]+33*a[0]*a[2]*b[2]*c[0]*c2[2]-39*a[0]*a[1]*b[0]*c[1]*c2[2]+
                3*a2[0]*b[1]*c[1]*c2[2]-36*a2[1]*b[1]*c[1]*c2[2]+39*a2[2]*b[1]*c[1]*c2[2]+
                33*a[1]*a[2]*b[2]*c[1]*c2[2]-39*a[0]*a[2]*b[0]*c3[2]-39*a[1]*a[2]*b[1]*c3[2]+
                3*a2[0]*b[2]*c3[2]+3*a2[1]*b[2]*c3[2]);
        
        polyCoeff[4] = 24*(-16*a[1]*b3[0]*b[1]*c[0]+16*a[0]*b2[0]*b2[1]*c[0]-16*a[1]*b[0]*b3[1]*c[0]+
                16*a[0]*b4[1]*c[0]-16*a[2]*b3[0]*b[2]*c[0]-16*a[2]*b[0]*b2[1]*b[2]*c[0]+
                16*a[0]*b2[0]*b2[2]*c[0]-16*a[1]*b[0]*b[1]*b2[2]*c[0]+32*a[0]*b2[1]*b2[2]*c[0]-
                16*a[2]*b[0]*b3[2]*c[0]+16*a[0]*b4[2]*c[0]-18*a2[1]*b2[0]*c2[0]-
                18*a2[2]*b2[0]*c2[0]-132*a[0]*a[1]*b[0]*b[1]*c2[0]+12*a2[0]*b2[1]*c2[0]-
                138*a2[1]*b2[1]*c2[0]-36*a2[2]*b2[1]*c2[0]-132*a[0]*a[2]*b[0]*b[2]*c2[0]-
                204*a[1]*a[2]*b[1]*b[2]*c2[0]+12*a2[0]*b2[2]*c2[0]-36*a2[1]*b2[2]*c2[0]-
                138*a2[2]*b2[2]*c2[0]-36*a[0]*a2[1]*c3[0]-36*a[0]*a2[2]*c3[0]+
                16*a[1]*b4[0]*c[1]-16*a[0]*b3[0]*b[1]*c[1]+16*a[1]*b2[0]*b2[1]*c[1]-
                16*a[0]*b[0]*b3[1]*c[1]-16*a[2]*b2[0]*b[1]*b[2]*c[1]-16*a[2]*b3[1]*b[2]*c[1]+
                32*a[1]*b2[0]*b2[2]*c[1]-16*a[0]*b[0]*b[1]*b2[2]*c[1]+16*a[1]*b2[1]*b2[2]*c[1]-
                16*a[2]*b[1]*b3[2]*c[1]+16*a[1]*b4[2]*c[1]+168*a[0]*a[1]*b2[0]*c[0]*c[1]+
                108*a2[0]*b[0]*b[1]*c[0]*c[1]+108*a2[1]*b[0]*b[1]*c[0]*c[1]+
                36*a2[2]*b[0]*b[1]*c[0]*c[1]+168*a[0]*a[1]*b2[1]*c[0]*c[1]+
                72*a[1]*a[2]*b[0]*b[2]*c[0]*c[1]+72*a[0]*a[2]*b[1]*b[2]*c[0]*c[1]+
                96*a[0]*a[1]*b2[2]*c[0]*c[1]+72*a2[0]*a[1]*c2[0]*c[1]-36*a3[1]*c2[0]*c[1]-
                36*a[1]*a2[2]*c2[0]*c[1]-138*a2[0]*b2[0]*c2[1]+12*a2[1]*b2[0]*c2[1]-
                36*a2[2]*b2[0]*c2[1]-132*a[0]*a[1]*b[0]*b[1]*c2[1]-18*a2[0]*b2[1]*c2[1]-
                18*a2[2]*b2[1]*c2[1]-204*a[0]*a[2]*b[0]*b[2]*c2[1]-132*a[1]*a[2]*b[1]*b[2]*c2[1]-
                36*a2[0]*b2[2]*c2[1]+12*a2[1]*b2[2]*c2[1]-138*a2[2]*b2[2]*c2[1]-
                36*a3[0]*c[0]*c2[1]+72*a[0]*a2[1]*c[0]*c2[1]-36*a[0]*a2[2]*c[0]*c2[1]-
                36*a2[0]*a[1]*c3[1]-36*a[1]*a2[2]*c3[1]+16*a[2]*b4[0]*c[2]+
                32*a[2]*b2[0]*b2[1]*c[2]+16*a[2]*b4[1]*c[2]-16*a[0]*b3[0]*b[2]*c[2]-
                16*a[1]*b2[0]*b[1]*b[2]*c[2]-16*a[0]*b[0]*b2[1]*b[2]*c[2]-16*a[1]*b3[1]*b[2]*c[2]+
                16*a[2]*b2[0]*b2[2]*c[2]+16*a[2]*b2[1]*b2[2]*c[2]-16*a[0]*b[0]*b3[2]*c[2]-
                16*a[1]*b[1]*b3[2]*c[2]+168*a[0]*a[2]*b2[0]*c[0]*c[2]+72*a[1]*a[2]*b[0]*b[1]*c[0]*c[2]+
                96*a[0]*a[2]*b2[1]*c[0]*c[2]+108*a2[0]*b[0]*b[2]*c[0]*c[2]+
                36*a2[1]*b[0]*b[2]*c[0]*c[2]+108*a2[2]*b[0]*b[2]*c[0]*c[2]+
                72*a[0]*a[1]*b[1]*b[2]*c[0]*c[2]+168*a[0]*a[2]*b2[2]*c[0]*c[2]+
                72*a2[0]*a[2]*c2[0]*c[2]-36*a2[1]*a[2]*c2[0]*c[2]-36*a3[2]*c2[0]*c[2]+
                96*a[1]*a[2]*b2[0]*c[1]*c[2]+72*a[0]*a[2]*b[0]*b[1]*c[1]*c[2]+
                168*a[1]*a[2]*b2[1]*c[1]*c[2]+72*a[0]*a[1]*b[0]*b[2]*c[1]*c[2]+
                36*a2[0]*b[1]*b[2]*c[1]*c[2]+108*a2[1]*b[1]*b[2]*c[1]*c[2]+
                108*a2[2]*b[1]*b[2]*c[1]*c[2]+168*a[1]*a[2]*b2[2]*c[1]*c[2]+
                216*a[0]*a[1]*a[2]*c[0]*c[1]*c[2]-36*a2[0]*a[2]*c2[1]*c[2]+72*a2[1]*a[2]*c2[1]*c[2]-
                36*a3[2]*c2[1]*c[2]-138*a2[0]*b2[0]*c2[2]-36*a2[1]*b2[0]*c2[2]+
                12*a2[2]*b2[0]*c2[2]-204*a[0]*a[1]*b[0]*b[1]*c2[2]-36*a2[0]*b2[1]*c2[2]-
                138*a2[1]*b2[1]*c2[2]+12*a2[2]*b2[1]*c2[2]-132*a[0]*a[2]*b[0]*b[2]*c2[2]-
                132*a[1]*a[2]*b[1]*b[2]*c2[2]-18*a2[0]*b2[2]*c2[2]-18*a2[1]*b2[2]*c2[2]-
                36*a3[0]*c[0]*c2[2]-36*a[0]*a2[1]*c[0]*c2[2]+72*a[0]*a2[2]*c[0]*c2[2]-
                36*a2[0]*a[1]*c[1]*c2[2]-36*a3[1]*c[1]*c2[2]+72*a[1]*a2[2]*c[1]*c2[2]-
                36*a2[0]*a[2]*c3[2]-36*a2[1]*a[2]*c3[2]);
        
        polyCoeff[3] = 24*(-30*a2[1]*b3[0]*c[0]-30*a2[2]*b3[0]*c[0]-60*a[0]*a[1]*b2[0]*b[1]*c[0]+
                90*a2[0]*b[0]*b2[1]*c[0]-120*a2[1]*b[0]*b2[1]*c[0]-30*a2[2]*b[0]*b2[1]*c[0]+
                120*a[0]*a[1]*b3[1]*c[0]-60*a[0]*a[2]*b2[0]*b[2]*c[0]-180*a[1]*a[2]*b[0]*b[1]*b[2]*c[0]+
                120*a[0]*a[2]*b2[1]*b[2]*c[0]+90*a2[0]*b[0]*b2[2]*c[0]-30*a2[1]*b[0]*b2[2]*c[0]-
                120*a2[2]*b[0]*b2[2]*c[0]+120*a[0]*a[1]*b[1]*b2[2]*c[0]+120*a[0]*a[2]*b3[2]*c[0]-
                180*a[0]*a2[1]*b[0]*c2[0]-180*a[0]*a2[2]*b[0]*c2[0]-45*a2[0]*a[1]*b[1]*c2[0]-
                225*a3[1]*b[1]*c2[0]-225*a[1]*a2[2]*b[1]*c2[0]-45*a2[0]*a[2]*b[2]*c2[0]-
                225*a2[1]*a[2]*b[2]*c2[0]-225*a3[2]*b[2]*c2[0]+120*a[0]*a[1]*b3[0]*c[1]-
                120*a2[0]*b2[0]*b[1]*c[1]+90*a2[1]*b2[0]*b[1]*c[1]-30*a2[2]*b2[0]*b[1]*c[1]-
                60*a[0]*a[1]*b[0]*b2[1]*c[1]-30*a2[0]*b3[1]*c[1]-30*a2[2]*b3[1]*c[1]+
                120*a[1]*a[2]*b2[0]*b[2]*c[1]-180*a[0]*a[2]*b[0]*b[1]*b[2]*c[1]-
                60*a[1]*a[2]*b2[1]*b[2]*c[1]+120*a[0]*a[1]*b[0]*b2[2]*c[1]-30*a2[0]*b[1]*b2[2]*c[1]+
                90*a2[1]*b[1]*b2[2]*c[1]-120*a2[2]*b[1]*b2[2]*c[1]+120*a[1]*a[2]*b3[2]*c[1]+
                405*a2[0]*a[1]*b[0]*c[0]*c[1]+45*a3[1]*b[0]*c[0]*c[1]+45*a[1]*a2[2]*b[0]*c[0]*c[1]+
                45*a3[0]*b[1]*c[0]*c[1]+405*a[0]*a2[1]*b[1]*c[0]*c[1]+45*a[0]*a2[2]*b[1]*c[0]*c[1]+
                360*a[0]*a[1]*a[2]*b[2]*c[0]*c[1]-225*a3[0]*b[0]*c2[1]-45*a[0]*a2[1]*b[0]*c2[1]-
                225*a[0]*a2[2]*b[0]*c2[1]-180*a2[0]*a[1]*b[1]*c2[1]-180*a[1]*a2[2]*b[1]*c2[1]-
                225*a2[0]*a[2]*b[2]*c2[1]-45*a2[1]*a[2]*b[2]*c2[1]-225*a3[2]*b[2]*c2[1]+
                120*a[0]*a[2]*b3[0]*c[2]+120*a[1]*a[2]*b2[0]*b[1]*c[2]+120*a[0]*a[2]*b[0]*b2[1]*c[2]+
                120*a[1]*a[2]*b3[1]*c[2]-120*a2[0]*b2[0]*b[2]*c[2]-30*a2[1]*b2[0]*b[2]*c[2]+
                90*a2[2]*b2[0]*b[2]*c[2]-180*a[0]*a[1]*b[0]*b[1]*b[2]*c[2]-30*a2[0]*b2[1]*b[2]*c[2]-
                120*a2[1]*b2[1]*b[2]*c[2]+90*a2[2]*b2[1]*b[2]*c[2]-60*a[0]*a[2]*b[0]*b2[2]*c[2]-
                60*a[1]*a[2]*b[1]*b2[2]*c[2]-30*a2[0]*b3[2]*c[2]-30*a2[1]*b3[2]*c[2]+
                405*a2[0]*a[2]*b[0]*c[0]*c[2]+45*a2[1]*a[2]*b[0]*c[0]*c[2]+45*a3[2]*b[0]*c[0]*c[2]+
                360*a[0]*a[1]*a[2]*b[1]*c[0]*c[2]+45*a3[0]*b[2]*c[0]*c[2]+45*a[0]*a2[1]*b[2]*c[0]*c[2]+
                405*a[0]*a2[2]*b[2]*c[0]*c[2]+360*a[0]*a[1]*a[2]*b[0]*c[1]*c[2]+
                45*a2[0]*a[2]*b[1]*c[1]*c[2]+405*a2[1]*a[2]*b[1]*c[1]*c[2]+45*a3[2]*b[1]*c[1]*c[2]+
                45*a2[0]*a[1]*b[2]*c[1]*c[2]+45*a3[1]*b[2]*c[1]*c[2]+405*a[1]*a2[2]*b[2]*c[1]*c[2]-
                225*a3[0]*b[0]*c2[2]-225*a[0]*a2[1]*b[0]*c2[2]-45*a[0]*a2[2]*b[0]*c2[2]-
                225*a2[0]*a[1]*b[1]*c2[2]-225*a3[1]*b[1]*c2[2]-45*a[1]*a2[2]*b[1]*c2[2]-
                180*a2[0]*a[2]*b[2]*c2[2]-180*a2[1]*a[2]*b[2]*c2[2]);
        
        polyCoeff[2] = 24*(-12*a2[1]*b4[0]-12*a2[2]*b4[0]+24*a[0]*a[1]*b3[0]*b[1]-
                12*a2[0]*b2[0]*b2[1]-12*a2[1]*b2[0]*b2[1]-24*a2[2]*b2[0]*b2[1]+
                24*a[0]*a[1]*b[0]*b3[1]-12*a2[0]*b4[1]-12*a2[2]*b4[1]+
                24*a[0]*a[2]*b3[0]*b[2]+24*a[1]*a[2]*b2[0]*b[1]*b[2]+24*a[0]*a[2]*b[0]*b2[1]*b[2]+
                24*a[1]*a[2]*b3[1]*b[2]-12*a2[0]*b2[0]*b2[2]-24*a2[1]*b2[0]*b2[2]-
                12*a2[2]*b2[0]*b2[2]+24*a[0]*a[1]*b[0]*b[1]*b2[2]-24*a2[0]*b2[1]*b2[2]-
                12*a2[1]*b2[1]*b2[2]-12*a2[2]*b2[1]*b2[2]+24*a[0]*a[2]*b[0]*b3[2]+
                24*a[1]*a[2]*b[1]*b3[2]-12*a2[0]*b4[2]-12*a2[1]*b4[2]-
                234*a[0]*a2[1]*b2[0]*c[0]-234*a[0]*a2[2]*b2[0]*c[0]+
                162*a2[0]*a[1]*b[0]*b[1]*c[0]-306*a3[1]*b[0]*b[1]*c[0]-306*a[1]*a2[2]*b[0]*b[1]*c[0]+
                72*a3[0]*b2[1]*c[0]+306*a[0]*a2[1]*b2[1]*c[0]+72*a[0]*a2[2]*b2[1]*c[0]+
                162*a2[0]*a[2]*b[0]*b[2]*c[0]-306*a2[1]*a[2]*b[0]*b[2]*c[0]-306*a3[2]*b[0]*b[2]*c[0]+
                468*a[0]*a[1]*a[2]*b[1]*b[2]*c[0]+72*a3[0]*b2[2]*c[0]+72*a[0]*a2[1]*b2[2]*c[0]+
                306*a[0]*a2[2]*b2[2]*c[0]-135*a2[0]*a2[1]*c2[0]-135*a4[1]*c2[0]-
                135*a2[0]*a2[2]*c2[0]-270*a2[1]*a2[2]*c2[0]-135*a4[2]*c2[0]+
                306*a2[0]*a[1]*b2[0]*c[1]+72*a3[1]*b2[0]*c[1]+72*a[1]*a2[2]*b2[0]*c[1]-
                306*a3[0]*b[0]*b[1]*c[1]+162*a[0]*a2[1]*b[0]*b[1]*c[1]-306*a[0]*a2[2]*b[0]*b[1]*c[1]-
                234*a2[0]*a[1]*b2[1]*c[1]-234*a[1]*a2[2]*b2[1]*c[1]+
                468*a[0]*a[1]*a[2]*b[0]*b[2]*c[1]-306*a2[0]*a[2]*b[1]*b[2]*c[1]+
                162*a2[1]*a[2]*b[1]*b[2]*c[1]-306*a3[2]*b[1]*b[2]*c[1]+72*a2[0]*a[1]*b2[2]*c[1]+
                72*a3[1]*b2[2]*c[1]+306*a[1]*a2[2]*b2[2]*c[1]+270*a3[0]*a[1]*c[0]*c[1]+
                270*a[0]*a3[1]*c[0]*c[1]+270*a[0]*a[1]*a2[2]*c[0]*c[1]-135*a4[0]*c2[1]-
                135*a2[0]*a2[1]*c2[1]-270*a2[0]*a2[2]*c2[1]-135*a2[1]*a2[2]*c2[1]-
                135*a4[2]*c2[1]+306*a2[0]*a[2]*b2[0]*c[2]+72*a2[1]*a[2]*b2[0]*c[2]+
                72*a3[2]*b2[0]*c[2]+468*a[0]*a[1]*a[2]*b[0]*b[1]*c[2]+72*a2[0]*a[2]*b2[1]*c[2]+
                306*a2[1]*a[2]*b2[1]*c[2]+72*a3[2]*b2[1]*c[2]-306*a3[0]*b[0]*b[2]*c[2]-
                306*a[0]*a2[1]*b[0]*b[2]*c[2]+162*a[0]*a2[2]*b[0]*b[2]*c[2]-
                306*a2[0]*a[1]*b[1]*b[2]*c[2]-306*a3[1]*b[1]*b[2]*c[2]+162*a[1]*a2[2]*b[1]*b[2]*c[2]-
                234*a2[0]*a[2]*b2[2]*c[2]-234*a2[1]*a[2]*b2[2]*c[2]+270*a3[0]*a[2]*c[0]*c[2]+
                270*a[0]*a2[1]*a[2]*c[0]*c[2]+270*a[0]*a3[2]*c[0]*c[2]+270*a2[0]*a[1]*a[2]*c[1]*c[2]+
                270*a3[1]*a[2]*c[1]*c[2]+270*a[1]*a3[2]*c[1]*c[2]-135*a4[0]*c2[2]-
                270*a2[0]*a2[1]*c2[2]-135*a4[1]*c2[2]-135*a2[0]*a2[2]*c2[2]-
                135*a2[1]*a2[2]*c2[2]);
        
        polyCoeff[1] = 24*(-90*a[0]*a2[1]*b3[0]-90*a[0]*a2[2]*b3[0]+180*a2[0]*a[1]*b2[0]*b[1]-
                90*a3[1]*b2[0]*b[1]-90*a[1]*a2[2]*b2[0]*b[1]-90*a3[0]*b[0]*b2[1]+
                180*a[0]*a2[1]*b[0]*b2[1]-90*a[0]*a2[2]*b[0]*b2[1]-90*a2[0]*a[1]*b3[1]-
                90*a[1]*a2[2]*b3[1]+180*a2[0]*a[2]*b2[0]*b[2]-90*a2[1]*a[2]*b2[0]*b[2]-
                90*a3[2]*b2[0]*b[2]+540*a[0]*a[1]*a[2]*b[0]*b[1]*b[2]-90*a2[0]*a[2]*b2[1]*b[2]+
                180*a2[1]*a[2]*b2[1]*b[2]-90*a3[2]*b2[1]*b[2]-90*a3[0]*b[0]*b2[2]-
                90*a[0]*a2[1]*b[0]*b2[2]+180*a[0]*a2[2]*b[0]*b2[2]-90*a2[0]*a[1]*b[1]*b2[2]-
                90*a3[1]*b[1]*b2[2]+180*a[1]*a2[2]*b[1]*b2[2]-90*a2[0]*a[2]*b3[2]-
                90*a2[1]*a[2]*b3[2]-243*a2[0]*a2[1]*b[0]*c[0]-243*a4[1]*b[0]*c[0]-
                243*a2[0]*a2[2]*b[0]*c[0]-486*a2[1]*a2[2]*b[0]*c[0]-243*a4[2]*b[0]*c[0]+
                243*a3[0]*a[1]*b[1]*c[0]+243*a[0]*a3[1]*b[1]*c[0]+243*a[0]*a[1]*a2[2]*b[1]*c[0]+
                243*a3[0]*a[2]*b[2]*c[0]+243*a[0]*a2[1]*a[2]*b[2]*c[0]+243*a[0]*a3[2]*b[2]*c[0]+
                243*a3[0]*a[1]*b[0]*c[1]+243*a[0]*a3[1]*b[0]*c[1]+243*a[0]*a[1]*a2[2]*b[0]*c[1]-
                243*a4[0]*b[1]*c[1]-243*a2[0]*a2[1]*b[1]*c[1]-486*a2[0]*a2[2]*b[1]*c[1]-
                243*a2[1]*a2[2]*b[1]*c[1]-243*a4[2]*b[1]*c[1]+243*a2[0]*a[1]*a[2]*b[2]*c[1]+
                243*a3[1]*a[2]*b[2]*c[1]+243*a[1]*a3[2]*b[2]*c[1]+243*a3[0]*a[2]*b[0]*c[2]+
                243*a[0]*a2[1]*a[2]*b[0]*c[2]+243*a[0]*a3[2]*b[0]*c[2]+243*a2[0]*a[1]*a[2]*b[1]*c[2]+
                243*a3[1]*a[2]*b[1]*c[2]+243*a[1]*a3[2]*b[1]*c[2]-243*a4[0]*b[2]*c[2]-
                486*a2[0]*a2[1]*b[2]*c[2]-243*a4[1]*b[2]*c[2]-243*a2[0]*a2[2]*b[2]*c[2]-
                243*a2[1]*a2[2]*b[2]*c[2]);
        
        polyCoeff[0] = 24*(-108*a2[0]*a2[1]*b2[0]-108*a4[1]*b2[0]-108*a2[0]*a2[2]*b2[0]-
                216*a2[1]*a2[2]*b2[0]-108*a4[2]*b2[0]+216*a3[0]*a[1]*b[0]*b[1]+
                216*a[0]*a3[1]*b[0]*b[1]+216*a[0]*a[1]*a2[2]*b[0]*b[1]-108*a4[0]*b2[1]-
                108*a2[0]*a2[1]*b2[1]-216*a2[0]*a2[2]*b2[1]-108*a2[1]*a2[2]*b2[1]-
                108*a4[2]*b2[1]+216*a3[0]*a[2]*b[0]*b[2]+216*a[0]*a2[1]*a[2]*b[0]*b[2]+
                216*a[0]*a3[2]*b[0]*b[2]+216*a2[0]*a[1]*a[2]*b[1]*b[2]+216*a3[1]*a[2]*b[1]*b[2]+
                216*a[1]*a3[2]*b[1]*b[2]-108*a4[0]*b2[2]-216*a2[0]*a2[1]*b2[2]-
                108*a4[1]*b2[2]-108*a2[0]*a2[2]*b2[2]-108*a2[1]*a2[2]*b2[2]);
        
        // Polynomial root solver
        int degree = 7;
        double outZeroReal[7];
        double outZeroImag[7];
        int info[7];
        rpoly_ak1(polyCoeff, &degree, outZeroReal, outZeroImag);
                
        for (int i=0;i<degree;i++) {
            if (outZeroReal[i] > t0 && outZeroReal[i] < t1 && outZeroImag[i] == 0) {
                double t = outZeroReal[i];
                
                double curvature_t = curvature(t, a, b, c);
                
                if ( *curvatureMax < curvature_t ) {
                    *curvatureMax = curvature_t;
                    *tCurvMax = t;
                }
            }
        }

        // Set the output value
        *curvatureMax = sqrt(*curvatureMax);
    }
}

// Evaluate the curvature at a given position (quadratic Bezier curve)
double curvature(double t, double *a, double *b) {
    return (pow(2*a[1]*(b[0]+2*a[0])-2*a[0]*(b[1]+2*a[1]*t), 2)
    +pow(-2*a[2]*(b[0]+2*a[0]*t)+2*a[0]*(b[2]+2*a[2]*t), 2)
    +pow(2*a[2]*(b[1]+2*a[1]*t)-2*a[1]*(b[2]+2*a[2]*t), 2))
    /pow(pow(b[0]+2*a[0]*t, 2)+pow(b[1]+2*a[1]*t, 2)+pow(b[2]+2*a[2]*t, 2), 3);
}

// Evaluate the curvature at a given position (cubic Bezier curve)
double curvature(double t, double *a, double *b, double *c) {
    return (pow((2*b[1]+6*a[1]*t)*(c[0]+2*b[0]*t+3*a[0]*pow(t, 2))-(2*b[0]+6*a[0]*t)*(c[1]+2*b[1]*t+3*a[1]*pow(t, 2)), 2)
    +pow(-(2*b[2]+6*a[2]*t)*(c[0]+2*b[0]*t+3*a[0]*pow(t, 2))+(2*b[0]+6*a[0]*t)
    *(c[2]+2*b[2]*t+3*a[2]*pow(t, 2)), 2)
    +pow((2*b[2]+6*a[2]*t)*(c[1]+2*b[1]*t+3*a[1]*pow(t, 2))-(2*b[1]+6*a[1]*t)
    *(c[2]+2*b[2]*t+3*a[2]*pow(t, 2)), 2))
    /pow(pow(c[0]+2*b[0]*t+3*a[0]*pow(t, 2), 2)
    +pow(c[1]+2*b[1]*t+3*a[1]*pow(t, 2), 2)+pow(c[2]+2*b[2]*t+3*a[2]*pow(t, 2), 2), 3);
}


