function  [workTS,newX] = gapInterpolation(TS,nPoint)
%This function interpolates NaN in a TS gap. It does not interpolate borders.
%USAGE:
%       workTS = gapInterpolation(TS,nPoint)
%
%Input:
%       TS     - Time Series (Column Vector)
%       nPoint - maximum size of the gaps to be interpolated
%
%Output:
%       workTS - Time Series with closed gaps (column vector)
%       newX   - new x-axis vector 
%
% Marco Vilela, 2012

nObs   = numel(TS);
xi     = find(isnan(TS));
workTS = TS(:);

if ~isempty(xi)
    
    nanB         = findBlock(xi,1);
    
    %If NaN blocks in the beginning or end of the TS, Delete it
    leftBorder   = find(nanB{1}(1)==1);
    rightBorder  = find(nanB{end}(end)==nObs);
    
    workTS([nanB{leftBorder*1};nanB{rightBorder*end}]) = [];
    
    numIdx       = find(~isnan(workTS));
    numB         = findBlock(numIdx,1);
    fusingB      = find(cell2mat(cellfun(@(x,y)  y(1) - x(end) <= nPoint+1,numB(1:end-1),numB(2:end),'Unif',0)));
    fusedB       = findBlock(fusingB,1);
    %Fused blocks with gaps <= nPoint
    fusedPoint   = cellfun(@(x) cat(1,numB{[x;x(end)+1]}),fusedB,'Unif',0);
    %New x-axis
    newX         = (nanB{1}(1)==1)*nanB{1}(end) + cell2mat(cellfun(@(x) x(1):x(end),fusedPoint,'Unif',0));
    interpF      = @(x,y) interp1(x,y(x),x(1):x(end));
    %Interpolated points
    interpPoint  = cellfun(@(x) interpF(x,workTS),fusedPoint,'Unif',0);
    workTS       = TS(:);
    workTS(newX) = cell2mat(interpPoint)';
end
