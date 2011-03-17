function [M maxCost] = maxWeightMatching(D, eps, nonLinkMarker)
% this function resolve the maximum weight matching problem for a given
% undirected graph G = (V, E), where each edge in E has a weight d >= 0. A
% matching M of G is a set of edges no two of which share an endpoint. In
% other words, every vertex of the input graph is at most linked with
% another vertex.
%
% D is a squared matrix that represents the undirected graph G = (V,E)
% where V is the set of vertices 1...size(D,1) and E is the set of edges
% defined by any D(i,j) non equal to nonLinkMarker. If D is sparse, there
% is no need to specify nonLinkMarker. Keep in mind that if D is sparse, it
% prevents to have weights strictly equal to 0. One way to address this is
% to assign a very small value eps to null weights. Except for that small
% value which is most likely a double value (1e-12 for instance), EVERY
% WEIGHT MUST BE INTEGER.
%
% G is an undirected graph which means D(i,j) == D(j,i). Only the lower
% triangular part of the matrix is taken into account, i.e. if there
% is an edge between vertex i and j, D(i,j), i > j must be defined.
%
% For each defined edge (i,j), D(i,j) >= 0
%
% This function uses 'blossom5' library located in the 'extern' project.
%
% References:
%
% (1) L. Lovasz an M. Plummer. Matching Theory. Springer Edition. 1986
%
% (2) V. Kolmogorov. Blossom V: A new implementation of a minimum cost
% perfect matching algorithm. In Mathematical Programming Computation
% (MPC), 1(1):43-67. July 2009.
%
% (3) G. Shafer. Weight Matchings in General Graphs. Diplomarbeit. May
% 2000.
%
% Sylvain Berlemont, Dec 2010

[n m] = size(D);

if n ~= m
  error('Input matrix must be squared.');
end

if any(D < 0)
  error('Weights must be >= 0');
end

if issparse(D)
    if nargin < 2 || isempty(eps)
        error('eps value required when cost function is sparse.');
    end
    
    [u, v, w] = find(tril(D));
    
    % replace every element w == eps by 0.
    w(w == eps) = 0;
else
    if nargin < 3 || isempty(nonLinkMarker)
        error('nonLinkMarker value required when cost function is not sparse.');
    end
    
    x = meshgrid(1:n);
    ind = find(x < x' & D ~= nonLinkMarker);
    [u, v] = ind2sub([n n], ind);
    w = D(ind);  
end

% Assert every weight is an integer value
assert(all(w == round(w)));

% Number of edges in the graph
nE = numel(w);

% expand the graph to G to G' (see section 1.5.1 in (3))

% lower left corner
[x y] = meshgrid(n+1:2*n, 1:n);

uEx = vertcat(u, u + n, x(:));
vEx = vertcat(v, v + n, y(:));
wEx = vertcat(w, w, zeros(n^2,1));

% Solve minimum perfect matching problem
M = perfectMatchingMEX(2 * n, [uEx vEx], -wExRescaled);
M = logical(M);

% Compute the maximum cost of the matching
maxCost = sum(wEx(M(1:nE)));

% Retain only edges that are in the perfect matching (M == 1) and where
% both endpoints are in G (i.e. <= nE).
M = [uEx(M(1:nE)), vEx(M(1:nE))];