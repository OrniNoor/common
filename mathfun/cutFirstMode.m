function [cutoffIndex, cutoffValue] = cutFirstMode(varargin);
%CUTFIRSTMODE finds the end of the first mode in a histogram
%
% cutFirstMode is an implementation of the algorithm presented in "unimodal
% thresholding" by P.L. Rosin, Pattern Recognition (2001); 34:2083. It
% assumes  that the first mode in the histogram (noise/background values
% for most applications) is strongest, and places the cutoff where distance 
% between the line from the largest bin in the first mode to the first
% empty bin after the last nonempty bin and the histogram is largest.
%
% SYNOPSIS [cutoffIndex, cutoffValue] = cutFirstMode(counts, bins);
%          [cutoffIndex, cutoffValue] = cutFirstMode(data);
%
% INPUT    counts, bins : counts in and center of histogram bins (output
%               of functions such as "hist" or "histogram"
%          alternatively, you can pass the data directly, and the program
%               set up the histogram
%
% OUTPUT   cutoffIndex : Index into list of bins/data of the placement of
%               cutoff
%          cutoffValue : position of bin/data point where the histogram is
%               cut off
%
% REMARKS  If data is supplied, cutoffIndex/cutoffData will point to the
%               data point just at or above the center of the bin
%          The function works only on 1D data so far (multidimensional data
%          is handled as a vector)
%
%
% c: jonas, 8/06
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%======================
% TEST INPUT
%======================

switch nargin
    case 1 % data
        doHistogram = 1;
        data = varargin{1};
        data = data(:);
        
    case 2 % conts,bins
        doHistogram = 0;
        counts = varargin{1};
        bins = varargin{2};
        counts = counts(:);
        bins = bins(:);
        
    otherwise
        error('wrong number of input arguments')
end
    
%===========================


%==========================
% BUILD HISTOGRAM
%==========================
if doHistogram
    [counts,bins] = histogram(data);
    counts = counts(:);
    bins = bins(:);
end
%=========================


%=========================
% CUTOFF
%=========================

% for the line, we need the position of the maximum count and the position
% of the first empty bin following the last nonempty bin
[maxVal, maxIdx] = max(counts);
pointMax = [bins(maxIdx), maxVal];
pointEnd = [2*bins(end) - bins(end-1), 0];
nBins = length(bins)-maxIdx+1;

% calculate perpendicular distance to the line
vector = pointEnd-pointMax;
[dummy,vector] = normList(vector);
distanceVector = perpVector(...
    repmat(pointMax,[nBins,1]),repmat(vector,[nBins,1]),...
    [bins(maxIdx:end),counts(maxIdx:end)]);
distance = normList(distanceVector);

% find maximum
[maxDistance, maxDistanceIdx] = max(distance);

%========================


%========================
% ASSIGN OUTPUT
%========================

cutoffIndex = maxDistanceIdx + maxIdx - 1;
cutoffValue = bins(cutoffIndex);

if doHistogram
    % we have to transform these values to match data point. Take the one
    % that is just above the cutoffValue
    delta = data-cutoffValue;
    positiveDeltaIdx = find(delta >= 0);
    [minPositiveDelta, minPositiveDeltaIdx] = min(delta(positiveDeltaIdx));
    
    cutoffValue = data(positiveDeltaIdx(minPositiveDeltaIdx));
    cutoffIndex = positiveDeltaIdx(minPositiveDeltaIdx);

end