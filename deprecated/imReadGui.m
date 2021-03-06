function img = imReadGui(type,title,filter)
%IMREADGUI reads an image with a GUI / interface to imread()
%
% SYNOPSIS img = imReadGui(type,title,filter)
%
% INPUT type: (optional) 'double' or 'uint8'; default -> 'double'
%             if set to 'struct' image becomes a structure with
%             *.data image matrix (double)
%             *.perm = 'M' permutation status set to MATLAB
%       title (optional) Title for the file dialogue. 
%              Default: 'imReadGui ...' 
%       filter (optional) filterspec (as in uigetfile to suggest certain
%              image formats. Default {'*.tif','Tiff-files';'*.*,'All files'}
%
% OUTPUT img : image matrix

fprintf(2,['Warning: ''' mfilename ''' is deprecated and should no longer be used.\n']);

if(nargin<1) || isempty(type)
   type = 'double';
end;
if nargin < 2 || isempty(title)
    title = 'imReadGui ...';
end
if nargin < 3 || isempty(filter)
    filter = {'*.tif;*.tiff','Tiff-files';'*.*','All files'};
end
    

[fName,dirName] = uigetfile(filter,title);

if( isa(fName,'char') & isa(dirName,'char'))
   aux = imread([dirName,fName]);
else
   img = [];
   return;
end;

if(~strcmp(type,'uint8'))
   aux = double(aux)/255;
else
   img = aux;
   return;
end;

if(strcmp(type,'struct'))
   img.data = aux;
   img.perm = 'M';
else
   img = aux;
end;
