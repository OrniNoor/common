/* [prmVect prmStd covarianceMatrix residuals Jacobian] = fitAnisoGaussian2D(prmVect, initValues, mode);
 *
 * (c) Sylvain Berlemont, 2011 (last modified Jan 22, 2011)
 *
 * Compile with: mex -I/usr/local/include -lgsl -lgslcblas fitAnisoGaussian2D.c
 */

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <ctype.h> // tolower()

#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>
#include <gsl/gsl_vector.h>
#include <gsl/gsl_blas.h>
#include <gsl/gsl_multifit_nlin.h>

#include "mex.h"
#include "matrix.h"

#define NPARAMS		7
// r = sigmax
// s = sigmay
#define REFMODE		"xyarstc"

typedef struct argStruct
{
  double xi, yi;
  double A;
  double g;
  double ct, st;
  double c2t, s2t;
  double sx2, sy2;
  double sx3, sy3;
  double a, b, c;
} argStruct_t;

typedef int(*pfunc_t)(gsl_matrix*, int, int, argStruct_t*);

typedef struct dataStruct
{
  int nx, np;
  double *pixels;
  int *estIdx;
  int *idx;
  int nValid; // number of non-NaN pixels
  double *x_init;
  double prmVect[NPARAMS];
  pfunc_t *dfunc;
  gsl_vector *residuals;
  gsl_matrix *J;
} dataStruct_t;

// -2 A gg (aa x + bb y)
static int df_dx(gsl_matrix *J, int i, int k, argStruct_t *argStruct)
{
  double xi = argStruct->xi;
  double yi = argStruct->yi;
  double A = argStruct->A;
  double g = argStruct->g;
  double a = argStruct->a;
  double b = argStruct->b;
  
  gsl_matrix_set(J, i, k, -2 * A * g * (a * xi + b * yi));
	
  return 0;
}

// -2 A g (bb xi + cc yi)
static int df_dy(gsl_matrix *J, int i, int k, argStruct_t *argStruct)
{
  double xi = argStruct->xi;
  double yi = argStruct->yi;
  double A = argStruct->A;
  double g = argStruct->g;
  double b = argStruct->b;
  double c = argStruct->c;
	
  gsl_matrix_set(J, i, k, -2 * A * g * (b * xi + c * yi));
	
  return 0;
}

// g
static int df_dA(gsl_matrix *J, int i, int k, argStruct_t *argStruct)
{
  gsl_matrix_set(J, i, k, argStruct->g);
  return 0;
}

// (A g (xi ct - yi st)^2)/sx^3
static int df_dsx(gsl_matrix *J, int i, int k, argStruct_t *argStruct)
{
  double xi = argStruct->xi;
  double yi = argStruct->yi;
  double A = argStruct->A;
  double g = argStruct->g;
  double ct = argStruct->ct;
  double st = argStruct->st;
  double sx3 = argStruct->sx3;
	
  double r = xi * ct - yi * st;
	
  gsl_matrix_set(J, i, k, A * g * r * r / sx3);
	
  return 0;
}

// (A g (yi ct + xi st)^2)/sy^3
static int df_dsy(gsl_matrix *J, int i, int k, argStruct_t *argStruct)
{
  double xi = argStruct->xi;
  double yi = argStruct->yi;
  double A = argStruct->A;
  double g = argStruct->g;
  double ct = argStruct->ct;
  double st = argStruct->st;
  double sy3 = argStruct->sy3;
	
  double r = yi * ct + xi * st;
	
  gsl_matrix_set(J, i, k, A * g * r * r / sy3);
	
  return 0;
}

// -((A g (sx^2 - sy^2) (xi yi c2t + (xi^2 - yi^2) ct st))/(sx^2 sy^2))
static int df_dt(gsl_matrix *J, int i, int k, argStruct_t *argStruct)
{
  double xi = argStruct->xi;
  double yi = argStruct->yi;
  double A = argStruct->A;
  double g = argStruct->g;
  double ct = argStruct->ct;
  double st = argStruct->st;
  double c2t = argStruct->c2t;
  double sx2 = argStruct->sx2;
  double sy2 = argStruct->sy2;
	
  gsl_matrix_set(J, i, k, -((A * g * (sx2 - sy2) * (xi * yi * c2t + (xi * xi - yi - yi) * ct * st)) / (sx2 * sy2)));
	
  return 0;
}

// 1
static int df_dC(gsl_matrix *J, int i, int k, argStruct_t *argStruct)
{
  gsl_matrix_set(J, i, k, 1);
  return 0;
}

static int gaussian_f(const gsl_vector *x, void *params, gsl_vector *f)
{    
  dataStruct_t *dataStruct = (dataStruct_t *)params;
  int nx = dataStruct->nx;
  int nx_div2 = nx >> 1;
    
  double *pixels = dataStruct->pixels;
    
  // update prmVect with new estimates
  for (int i=0; i<dataStruct->np; ++i) {
    dataStruct->prmVect[dataStruct->estIdx[i]] = gsl_vector_get(x, i);
  }

  double xp = dataStruct->prmVect[0];
  double yp = dataStruct->prmVect[1];
  double A = dataStruct->prmVect[2];
  double sx = dataStruct->prmVect[3];
  double sy = dataStruct->prmVect[4];
  double t = dataStruct->prmVect[5];
  double C = dataStruct->prmVect[6];

  double ct = cos(t);
  double st = sin(t);
  double s2t = sin(2 * t);
  double sx2 = sx * sx;
  double sy2 = sy * sy;
	
  double xi, yi;
  double a = ct * ct / (2 * sx2) + st * st / (2 * sy2);
  double b = -s2t / (4 * sx2) + s2t / (4 * sy2);
  double c = st * st / (2 * sx2) + ct * ct / (2 * sy2);
    
  div_t divRes;
  int idx;
	
  for (int i=0; i < dataStruct->nValid; ++i)
    {
      idx = dataStruct->idx[i];
      divRes = div(idx, nx);
	  
      xi = divRes.quot-nx_div2-xp;
      yi = divRes.rem-nx_div2-yp;
	  
      gsl_vector_set(f, i, A * exp(-a * xi * xi - yi * (2 * b * xi + c * yi)) + C - pixels[idx]);
    }   
	
  return GSL_SUCCESS;
}

static int gaussian_df(const gsl_vector *x, void *params, gsl_matrix *J)
{    
  dataStruct_t *dataStruct = (dataStruct_t *)params;
  int nx = dataStruct->nx;
  int nx_div2 = nx >> 1;
    
  // update prmVect with new estimates
  for (int i=0; i<dataStruct->np; ++i) {
    dataStruct->prmVect[dataStruct->estIdx[i]] = gsl_vector_get(x, i);
  }
    
  double xp = dataStruct->prmVect[0];
  double yp = dataStruct->prmVect[1];
  double A = dataStruct->prmVect[2];
  double sx = dataStruct->prmVect[3];
  double sy = dataStruct->prmVect[4];
  double t = dataStruct->prmVect[5];
	
  double xi, yi;
  double ct = cos(t);
  double st = sin(t);
  double c2t = cos(2 * t);
  double s2t = sin(2 * t);
  double sx2 = sx * sx;
  double sy2 = sy * sy;
  double a = ct * ct / (2 * sx2) + st * st / (2 * sy2);
  double b = -s2t / (4 * sx2) + s2t / (4 * sy2);
  double c = st * st / (2 * sx2) + ct * ct / (2 * sy2);

  argStruct_t argStruct;
  argStruct.A = A;
  argStruct.ct = ct;
  argStruct.st = st;
  argStruct.c2t = c2t;
  argStruct.s2t = s2t;
  argStruct.sx2 = sx2;
  argStruct.sy2 = sy2;
  argStruct.sx3 = sx2 * sx;
  argStruct.sy3 = sy2 * sy;
  argStruct.a = a;
  argStruct.b = b;
  argStruct.c = c;
    
  div_t divRes;
  int idx;
  for (int i=0; i<dataStruct->nValid; ++i)
    {
      idx = dataStruct->idx[i];
      divRes = div(idx, nx);
		
      xi = divRes.quot-nx_div2-xp;
      yi = divRes.rem-nx_div2-yp;
		
      argStruct.xi = xi;
      argStruct.yi = yi;
      argStruct.g = exp(-a * xi * xi - yi * (2 * b * xi + c * yi));
		
      for (int k=0; k<dataStruct->np; ++k)
	dataStruct->dfunc[k](J, i, k, &argStruct);
    }
  return GSL_SUCCESS;
}

static int gaussian_fdf(const gsl_vector *x, void *params, gsl_vector *f, gsl_matrix *J)
{
  dataStruct_t *dataStruct = (dataStruct_t *)params;
  int nx = dataStruct->nx;
  int nx_div2 = nx >> 1;
    
  double *pixels = dataStruct->pixels;
    
  // update prmVect with new estimates
  for (int i=0; i<dataStruct->np; ++i) {
    dataStruct->prmVect[dataStruct->estIdx[i]] = gsl_vector_get(x, i);
  }
    
  double xp = dataStruct->prmVect[0];
  double yp = dataStruct->prmVect[1];
  double A = dataStruct->prmVect[2];
  double sx = dataStruct->prmVect[3];
  double sy = dataStruct->prmVect[4];
  double t = dataStruct->prmVect[5];
  double C = dataStruct->prmVect[6];
	
  double xi, yi;
  double ct = cos(t);
  double st = sin(t);
  double c2t = cos(2 * t);
  double s2t = sin(2 * t);
  double sx2 = sx * sx;
  double sy2 = sy * sy;
  double a = ct * ct / (2 * sx2) + st * st / (2 * sy2);
  double b = -s2t / (4 * sx2) + s2t / (4 * sy2);
  double c = st * st / (2 * sx2) + ct * ct / (2 * sy2);
	
  argStruct_t argStruct;
  argStruct.A = A;
  argStruct.ct = ct;
  argStruct.st = st;
  argStruct.c2t = c2t;
  argStruct.s2t = s2t;
  argStruct.sx2 = sx2;
  argStruct.sy2 = sy2;
  argStruct.sx3 = sx2 * sx;
  argStruct.sy3 = sy2 * sy;
  argStruct.a = a;
  argStruct.b = b;
  argStruct.c = c;
    
  div_t divRes;
  int idx;
  for (int i=0; i<dataStruct->nValid; ++i)
    {
      idx = dataStruct->idx[i];
      divRes = div(idx, nx);
		
      xi = divRes.quot-nx_div2-xp;
      yi = divRes.rem-nx_div2-yp;
		
      argStruct.xi = xi;
      argStruct.yi = yi;
      argStruct.g = exp(-a * xi * xi - yi * (2 * b * xi + c * yi));

      gsl_vector_set(f, i, A*argStruct.g + C - pixels[idx]);
        
      for (int k=0; k<dataStruct->np; ++k)
	dataStruct->dfunc[k](J, i, k, &argStruct);
    }
  return GSL_SUCCESS;
}

static int MLalgo(struct dataStruct *data)
{
  // declare solvers
  const gsl_multifit_fdfsolver_type *T;
  gsl_multifit_fdfsolver *s;
    
  // number of parameters to optimize
  const size_t p = data->np;
    
  gsl_vector_view x = gsl_vector_view_array(data->x_init, p);
    
  const gsl_rng_type *type;
    
  gsl_rng_env_setup();
    
  type = gsl_rng_default;
    
  gsl_multifit_function_fdf f;
  f.f = &gaussian_f;
  f.df = &gaussian_df;
  f.fdf = &gaussian_fdf;
  size_t n = data->nx;
  n *= n;
  f.n = n;
  f.p = p;
  f.params = data;
    
  T = gsl_multifit_fdfsolver_lmsder;
  s = gsl_multifit_fdfsolver_alloc(T, n, p);
  gsl_multifit_fdfsolver_set(s, &f, &x.vector);
    
  int status;
  int iter = 0;
  do {
    iter++;
    status = gsl_multifit_fdfsolver_iterate(s);
    if (status)
      break;
        
    status = gsl_multifit_test_delta(s->dx, s->x, 1e-8, 1e-8);
  }
  while (status == GSL_CONTINUE && iter < 500);
    
  for (int i=0; i<data->np; ++i)
    data->prmVect[data->estIdx[i]] = gsl_vector_get(s->x, i);
    
  // copy model
  data->residuals = gsl_vector_alloc(n);
  gsl_vector_memcpy(data->residuals, s->f);
    
  // copy Jacobian
  data->J = gsl_matrix_alloc(n, data->np);
  gsl_matrix_memcpy(data->J, s->J);
    
  gsl_multifit_fdfsolver_free(s);
	
  return 0;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{       
  /* inputs:
   * image array
   * prmVect
   * mode
   *
   */
		
  // check inputs
  if (nrhs < 3) mexErrMsgTxt("Inputs should be: data, prmVect, mode.");
  if (!mxIsDouble(prhs[0])) mexErrMsgTxt("Data input must be double array.");
  if (mxGetNumberOfElements(prhs[1])!=NPARAMS || !mxIsDouble(prhs[1])) mexErrMsgTxt("Incorrect parameter vector format.");
  if (!mxIsChar(prhs[2])) mexErrMsgTxt("Mode needs to be a string.");

  size_t nx = mxGetN(prhs[0]);
  int nx2 = nx*nx;

  // read mode input
  int np = mxGetNumberOfElements(prhs[2]);
  char *mode;
  mode = (char*)malloc(sizeof(char)*(np+1));
  mxGetString(prhs[2], mode, np+1);

  for (int i = 0; i < strlen(mode); ++i)
    mode[i] = tolower(mode[i]);

  np = 0; // number of parameters to fit
  for (int i = 0; i < NPARAMS; ++i)
    if (strchr(mode, REFMODE[i])!=NULL) { np++; }

  // allocate
  dataStruct_t data;
  data.nx = nx;
  data.np = np;
  data.pixels = mxGetPr(prhs[0]);
  data.estIdx = (int*)malloc(sizeof(int)*np);
  memcpy(data.prmVect, mxGetPr(prhs[1]), NPARAMS*sizeof(double));    
  data.dfunc = (pfunc_t*) malloc(sizeof(pfunc_t) * np);

  // read mask/pixels
  data.nValid = nx2;
  for (int i=0; i<nx2; ++i)
    data.nValid -= (int)mxIsNaN(data.pixels[i]);

  data.idx = (int*)malloc(sizeof(int)*data.nValid);
  int k = 0;
  for (int i=0; i<nx2; ++i)
    if (!mxIsNaN(data.pixels[i]))
      data.idx[k++] = i;
    
  np = 0;
  if (strchr(mode, 'x')!=NULL) {data.estIdx[np] = 0; data.dfunc[np++] = df_dx;}
  if (strchr(mode, 'y')!=NULL) {data.estIdx[np] = 1; data.dfunc[np++] = df_dy;}
  if (strchr(mode, 'a')!=NULL) {data.estIdx[np] = 2; data.dfunc[np++] = df_dA;}
  if (strchr(mode, 'r')!=NULL) {data.estIdx[np] = 3; data.dfunc[np++] = df_dsx;}
  if (strchr(mode, 's')!=NULL) {data.estIdx[np] = 4; data.dfunc[np++] = df_dsy;}
  if (strchr(mode, 't')!=NULL) {data.estIdx[np] = 5; data.dfunc[np++] = df_dt;}
  if (strchr(mode, 'c')!=NULL) {data.estIdx[np] = 6; data.dfunc[np++] = df_dC;}
    
  data.x_init = (double*)malloc(sizeof(double)*np);
  for (int i=0; i<np; ++i)
    data.x_init[i] = data.prmVect[data.estIdx[i]];
    
  MLalgo(&data);
    
  // parameters
  if (nlhs > 0)
    {
      // Make sure the angle parameter lies in -pi/2...pi/2
      //float x = data.prmVect[5];
      //x = x - fmodl(x + M_PI_2,M_PI)*M_PI - M_PI_2;
      //data.prmVect[5] = x;

      plhs[0] = mxCreateDoubleMatrix(1, NPARAMS, mxREAL);
      memcpy(mxGetPr(plhs[0]), data.prmVect, NPARAMS * sizeof(double));
    }
    
  // standard dev. of parameters & covariance matrix
  if (nlhs > 1)
    {
      gsl_matrix *covar = gsl_matrix_alloc(np, np);
      gsl_multifit_covar(data.J, 0.0, covar);
      double sigma_e = 0.0, e;
      for (int i=0; i<data.nValid; ++i)
	{
	  e = data.residuals->data[data.idx[i]];
	  sigma_e += e*e;
	}
      sigma_e /= data.nValid - data.np - 1;
      plhs[1] = mxCreateDoubleMatrix(1, data.np, mxREAL);
      double *prmStd = mxGetPr(plhs[1]);
      for (int i=0; i<data.np; ++i)
	prmStd[i] = sqrt(sigma_e*gsl_matrix_get(covar, i, i));
      if (nlhs > 2)
	{
	  plhs[2] = mxCreateDoubleMatrix(np, np, mxREAL);
	  // cov. matrix is symmetric, no need to transpose
	  memcpy(mxGetPr(plhs[2]), covar->data, np*np*sizeof(double));
	}
      free(covar);
    }
    
  // residuals
  if (nlhs > 3)
    {
      plhs[3] = mxCreateDoubleMatrix(nx, nx, mxREAL);
      memcpy(mxGetPr(plhs[3]), data.residuals->data, nx2*sizeof(double));
    }
    
  // Jacobian
  if (nlhs > 4)
    {
      // convert row-major double* data.J->data to column-major double*
      plhs[4] = mxCreateDoubleMatrix(nx2, np, mxREAL);
      double *J = mxGetPr(plhs[4]);
        
      for (int p=0; p<np; ++p)
	for (int i=0; i<nx2; ++i)
	  J[i+p*nx2] = (data.J)->data[p + i*np];
    }
    
  free(mode);
  free(data.estIdx);
  free(data.dfunc);
  free(data.idx);
  free(data.x_init);
  gsl_vector_free(data.residuals);
  gsl_matrix_free(data.J);
}

// Compile line:
// export DYLD_LIBRARY_PATH=/Applications/MATLAB_R2010b.app/bin/maci64 && gcc -std=c99 -Wall -g -DARRAY_ACCESS_INLINING -I. -I/Applications/MATLAB_R2010b.app/extern/include -L/Applications/MATLAB_R2010b.app/bin/maci64 -lmx -lmex -lgsl -lgslcblas -lmat fitAnisoGaussian2D.c

int main(void) {
    
  int nx = 15;
  int nx2 = nx*nx;
  double* px;
  px = (double*)malloc(sizeof(double)*nx2);
    
  // fill with noise
  for (int i=0; i<nx2; ++i)
    px[i] = rand();
    
  dataStruct_t data;
  data.nx = nx;
  data.np = NPARAMS;
  data.pixels = px;
	
  data.estIdx = (int*)malloc(sizeof(int) * NPARAMS);
  data.dfunc = (pfunc_t*) malloc(sizeof(pfunc_t) * NPARAMS);
	
  // read mask/pixels
  data.nValid = nx2;
  data.idx = (int*)malloc(sizeof(int)*data.nValid);
  int k = 0;
  for (int i=0; i<nx2; ++i)
    if (!mxIsNaN(data.pixels[i]))
      data.idx[k++] = i;
    
  data.prmVect[0] = 0;
  data.prmVect[1] = 0;
  data.prmVect[2] = 5;
  data.prmVect[3] = 1;
  data.prmVect[4] = 1;
  data.prmVect[5] = 0;
  data.prmVect[6] = 0;
	
  data.estIdx[0] = 0; data.dfunc[0] = df_dx;
  data.estIdx[1] = 1; data.dfunc[1] = df_dy;
  data.estIdx[2] = 2; data.dfunc[2] = df_dA;
  data.estIdx[3] = 3; data.dfunc[3] = df_dsx;
  data.estIdx[4] = 4; data.dfunc[4] = df_dsy;
  data.estIdx[5] = 5; data.dfunc[5] = df_dt;
  data.estIdx[6] = 6; data.dfunc[6] = df_dC;
    
  data.x_init = (double*)malloc(sizeof(double)*NPARAMS);
  for (int i=0; i<NPARAMS; ++i)
    data.x_init[i] = data.prmVect[data.estIdx[i]];
    
  MLalgo(&data);
    
  free(px);
  free(data.estIdx);
  free(data.dfunc);
  free(data.idx);
  free(data.x_init);
  gsl_vector_free(data.residuals);
  gsl_matrix_free(data.J);
    
  return 0;
}

