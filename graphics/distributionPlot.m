function handles = distributionPlot(varargin)
%DISTRIBUTIONPLOT plots distributions similar to boxplot
%
% SYNOPSIS: handles = distributionPlot(data,distWidth,showMM,xNames)
%           handles = distributionPlot(ah,...)
%
% INPUT data : cell array of length nData or m-by-nData array of values
%       distWidth : (opt) width of distributions. 1 means that the maxima 
%           of  two adjacent distributions will touch bar. Negative numbers
%           indicate that the distributions should have constant width, i.e
%           the density is only expressed through greylevels. Default: 0.9
%       showMM : (opt) if 1, mean and median are shown as red circles and
%                green squares, respectively. Default: 1
%       xNames : (opt) cell array of length nData containing x-tick names
%               (instead of the default '1,2,3')
%       ah (opt) axes handle to plot the distribution. Default: gca
%
% OUTPUT handles : 1-by-2 cell array with patch-handles for the
%                  distributions, and plot handles for mean/median
%
% REMARKS
%
% created with MATLAB ver.: 7.6.0.324 (R2008a) on Windows_NT
%
% created by: Jonas Dorn
% DATE: 08-Jul-2008
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%====================================
%% TEST INPUT
%====================================

% set defaults
def_xNames = [];
def_showMM = 1;
def_distWidth = 0.9;

if nargin == 0 
    error('not enough input arguments')
end

% check for axes handle
if ~iscell(varargin{1}) && ishandle(varargin{1}) && strcmp(get(varargin{1},'Type'),'axes')
    ah = varargin{1};
    data = varargin{2};
    varargin(1:2) = [];
else
    ah = gca;
    data = varargin{1};
    varargin(1) = []; 
end

% check data. If not cell, convert
if ~iscell(data)
    [nPoints,nData] = size(data);
    data = mat2cell(data,nPoints,ones(nData,1));
else
    % get nData
    data = data(:);
    nData = length(data);
end

% check for names, defaults
if ~isempty(varargin) && ~isempty(varargin{1})
    distWidth = varargin{1};
    if distWidth == 0
        error('distWidth==0 will not plot anything')
    end
else
    distWidth = def_distWidth;
end
if length(varargin) > 1 && ~isempty(varargin{2})
    showMM = varargin{2};
else
    showMM = def_showMM;
end
if length(varargin) > 2 && ~isempty(varargin{3})
    xNames = varargin{3};
else
    xNames = def_xNames;
end


% set hold on
holdState = get(ah,'NextPlot');
set(ah,'NextPlot','add');

%===================================



%===================================
%% PLOT DISTRIBUTIONS
%===================================

% assign output
hh = cell(nData,1);
[m,md] = deal(zeros(nData,1));

% get base x-array
xBase = abs(distWidth) .* [-0.5;0.5;0.5;-0.5];

% loop through data. Prepare patch input, then draw patch into gca
for iData = 1:nData
    currentData = data{iData};
    
    % make histogram (use ksdensity for now)
    % x,y are switched relative to normal histogram
    [xHist,yHist] = ksdensity(currentData,'kernel','epanechnikov');
    
    % find y-step
    dy = min(diff(yHist));

    % create x,y arrays
    nPoints = length(xHist);
    xArray = repmat(xBase,1,nPoints);
    yArray = repmat([-0.5;-0.5;0.5;0.5],1,nPoints);
    
    % x is iData +/- almost 0.5, multiplied with the height of the
    % histogram
    if distWidth > 0
        xArray = xArray.*repmat(xHist,4,1)./max(xHist) + iData;
    else
        xArray = xArray + iData;
    end
    
    % yData is simply the bin locations
    yArray = repmat(yHist,4,1) + dy*yArray;
    
    % add patch
    axes(ah);
    hh{iData} = patch(xArray,yArray,repmat(1-xHist/max(xHist),[4,1,3]));
    set(hh{iData},'EdgeColor','none')
    
    m(iData) = mean(currentData);
    md(iData) = median(currentData);
end % loop

if showMM
% plot mean, median. Mean is filled red circle, median is green square
mh = plot(1:nData,m,'or','MarkerFaceColor','r');
mdh = plot(1:nData,md,'sg');
end

% if ~empty, use xNames 
set(ah,'XTick',1:nData);
if ~isempty(xNames)
    set(ah,'XTickLabel',xNames)
end
% have plot start/end properly
xlim([0,nData+1])

%==========================


%==========================
%% CLEANUP & ASSIGN OUTPUT
%==========================

if nargout > 0
    handles{1} = hh;
    if showMM
    handles{2} = [mh;mdh];
    end
end

set(ah,'NextPlot',holdState);