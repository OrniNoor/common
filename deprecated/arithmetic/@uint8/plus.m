function c=plus(a,b)
% This functions implements the plus operator for variables of class uint8
%
% Aaron Ponti, May 7th, 2004

% Min and max values allowed
cmin=0;
cmax=255;

% Perform the summation operation
c=double(a)+double(b);

% Check for possible overflows
if any(c(:)<cmin) | any(c(:)>cmax)
    error('Result out of range.')
else
    c=uint8(c);
end