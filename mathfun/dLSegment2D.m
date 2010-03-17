function F = dLSegment2D(xRange, yRange, xC, yC, A, sigmaPSF, l, theta)
% 2D Diffraction-limited Segment Model
% F = dLSegment2D(xRange, yRange, xC, xC, A, sigmaPSF, l, theta)
%
% parameters:
% (xRange, yRange)   2 vectors representing the 2-dimensional domain (e.g.
%                    xRange = -10:.1:10, yRange = -5:.1:5
%
% (xC,yC)            center of the segment
%
% A                  amplitude of the segment
%
% sigmaPSF           half width of the gaussian PSF model.
%
% l                  length of the segment
%
% theta              orientation of the segment
%
% output:
% F is a NxM matrix where N = numel(X) and M = numel(Y).
%
% Sylvain Berlemont, 2009

ct = cos(theta);
st = sin(theta);

l = l / 2;

c0 = sqrt(2) * sigmaPSF;
c = A / (2 * erf(l / c0));

[X Y] = meshgrid(xRange, yRange);

X = X - xC;
Y = Y - yC;

F = c * exp(-((st * X - ct * Y) / c0).^2) .* ...
    (erf((l - ct * X - st * Y) / c0) + ...
    erf((l + ct * X + st * Y) / c0));
