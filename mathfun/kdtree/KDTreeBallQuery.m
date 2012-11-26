%function [idx, dist] = KDTreeBallQuery(inPts, queryPts, radii) finds all of the points which are within the specified radius of the query points
%
% Returns the indices of the input points which are within the specified radii of
% the query points. Supports 1D, 2D or 3D point sets.
%
% Inputs:
%
%        inPts : MxK matrix specifying the M input points in K dimensions.
%
%     queryPts : NxK matrix specifying the N query points in K dimensions.
%
%        radii : Nx1 vector or a scalar specifying the distances from each
%                query point to find input points. If scalar, the same radius
%                is used for all query points.
%
% Outputs:
%
%          idx : Nx1 cell array, the n-th element of which gives the indices of
%                the input points which are within the n-th radius of the n-th
%                query point.
%
%         dist : Nx1 cell array, the n-th element of which gives the corresponding
%                distances between the input points and the n-th query point.
%
% Notes:
%
%     The KD-Tree is built each time this function is called, which is suboptimal when multiple
%     queries of the same tree are performed. To build the tree once and query it multiple times,
%     the function calls below should be used instead. Building a KD-Tree takes O(n*log(n)) time;
%     range querying an already existing tree takes on the average O(n^(1-1/K) + m) time,
%     where m = #reported points.

% Deepak Chittajallu, Francois Aguet, 11/2012

function [idx, dist] = KDTreeBallQuery(inPts, queryPts, radii)

kdtreeobj = KDTree(inPts);

numQueryPoints = size(queryPts,1);
if isscalar(radii)
    radii = radii + zeros(numQueryPoints,1);
end

idx = cell(numQueryPoints, 1);
dist = cell(numQueryPoints, 1);
for i = 1:numQueryPoints
    [idx{i}, dist{i}] = kdtreeobj.ball( queryPts(i,:), radii(i) );
end
