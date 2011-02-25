function [xRange,yRange,nzIdx] = anisoGaussian2DSupport(x0,y0,sigmaX,sigmaY,theta,kSigma)
% [xRange,yRange,nzIdx] = anisoGaussian2DSupport(x0,y0,sigmaX,sigmaY,theta,kSigma)
%
% Compute the finite support of an anisotropic Gaussian 2D model given
% its parameters.
%
% parameters:
% (x0,y0)            center of the model (in the image domain)
%
% sigmaX             dispersion along the main axis
%
% sigmaY             dispersion aside the main axis
%
% theta              orientation of the model 
%
% kSigma             cutoff in number of standard deviations
%
% output:
% (xRange, yRange)   2 vectors representing the 2-dimensional support of
%                    the model in the image domain 1:size(imSize,1) x
%                    1:size(imSize,2).
%
% nzIdx              linear indices where pixel value is not zero. These
%                    indices are local.
%
% Sylvain Berlemont, 2011

% half length along the main axis
l2 = kSigma * sigmaX;

% Hypothenuse length, corresponding to the half-length diagonal of a
% 2*(l2+d) long by 2d wide rectangle surrounding the segment.
d = kSigma * sigmaY;
lh = sqrt(d.^2 + (l2 + d).^2);

% Angle between a rectangle border and a diagonal of the rectangle
at = atan(d ./ (l2 + d));

s1 = [1 1 -1 -1];
s2 = [1 -1 1 -1];

% xy-coordinates of the 4 rectangle's corners.
x = x0 + s1 .* cos(theta + s2 * at) * lh;
y = y0 + s1 .* sin(theta + s2 * at) * lh;

% truncate numbers towards zero with 10 decimals.
x = fix(x * 1e10) * 1e-10;
y = fix(y * 1e10) * 1e-10;

xMin = min(floor(x));
xMax = max(ceil(x));
yMin = min(floor(y));
yMax = max(ceil(y));

xRange = xMin:xMax;
yRange = yMin:yMax;

% find pixel indices of the model support
[X,Y] = meshgrid(xRange,yRange);
ct = cos(theta);
st = sin(theta);
D1 = abs((Y - y0) * ct + (-X + x0) * st);
D2 = abs((X - x0) * ct + (Y - y0) * st);
% truncate numbers towards zeros with 10 decimals to avoid numerical errors
D1 = fix(D1 * 1e10) * 1e-10;
D2 = fix(D2 * 1e10) * 1e-10;
nzIdx = find(D1 <= d & D2 <= l2 + d);