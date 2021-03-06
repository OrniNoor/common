function header=readr3dheader(fname)
% READR3DHEADER read SOFTWORX r3d file header
% 
%
% SYNOPSIS header=read3rdheader(fname)
%
% INPUT fname : string
%
% OUTPUT header : struct containing the header information

% c: 4/3/03	dT

%define constant
DV_MAGIC = -16224;
HEADER_SIZE = 1024;

% add filenameextension if neccessary
if nargin < 1 || isempty(fname)
    [filename, pathname, filterindex] = uigetfile( ...
       {'*.r3d;*.dv', 'DeltaVision File';
        '*.mrc',  'Sedat scope file'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Pick a file to read movieHeader from');
    if isequal(filename,0)
        error('no movie selected')
    else
        fname = [pathname,filesep,filename];
    end
% add filenameextension if neccessary
elseif isempty(findstr(fname,'.'))
	fname=[fname,'.r3d'];
end;

[fid, message] = fopen(fname,'r','b');
if fid == -1
    error(['file ',fname,' not found.']);
end

% read in a number which identifies the correct byte ordering
fseek(fid,96,-1);
nDVID = fread(fid,1,'short');
if (nDVID~=DV_MAGIC)
    %try little endian
    fclose(fid);
    [fid, message] = fopen(fname,'r','l');
    fseek(fid,96,-1);
    nDVID = fread(fid,1,'short');
    %if still not good ->  corrupt file
    if (nDVID~=DV_MAGIC)
        error('file is corrupt..')
    end;
end;

% rewind
fseek(fid,0,-1);


% read header
block = fread(fid,10,'int32');
%extract interesting information
numCols = block(1);
numRows = block(2);
numImages = block(3);
header.pixelX = fread(fid,1,'float');
header.pixelY = fread(fid,1,'float');
header.pixelZ = fread(fid,1,'float');

fseek(fid,0,-1);
block = fread(fid,24,'int32');
header.firstImageAddress = block(24); % important info for reading images


%offset
fseek(fid,128,-1);
nint=fread(fid,1,'short');
nreal=fread(fid,1,'short');

insectionOffset=nint*4;  %size of int=4
sectionOffset=insectionOffset+4*nreal; %size of real=4

%skip values to lensID
fseek(fid,162,-1);
header.lensID=fread(fid,1,'short'); 


%skip values to number of time points
fseek(fid,180,-1);
numTimepoints=fread(fid,1,'short');
imagesequence=fread(fid,1,'short');


%skip values to number of wavelengths
fseek(fid,196,-1);
numWvs=fread(fid,1,'short');
header.numCols = numCols;
header.numRows = numRows;
header.numZSlices=numImages/(numTimepoints*numWvs);
header.numTimepoints=numTimepoints;
header.numWvs=numWvs;

% make header.zwtOrder understandable
strs = {'ztw';'wzt';'zwt'};
header.zwtOrder = strs{imagesequence+1};


% read wavelengths
for i=1:header.numWvs
    header.wvl(i)=fread(fid,1,'short')/1000;
end;

% preassign header.Time, header.timestamp
header.Time = zeros(numTimepoints*numWvs*header.numZSlices,1);
[header.timestamp,expTime,ndFilter,header.lampIntensity,header.minInt,header.maxInt] = deal(zeros(header.numZSlices,numTimepoints,numWvs));


%read extended header information
for t=0:numTimepoints-1
    for w=0:numWvs-1
        for z=0:header.numZSlices-1
            switch header.zwtOrder
                case 'ztw'
                    theSection=z+t*header.numZSlices+(w*header.numZSlices*numTimepoints);
                case 'wzt'
                    theSection=w+z*numWvs+(t*numWvs*header.numZSlices);
                case 'zwt'
                    theSection=z+w*header.numZSlices+(t*header.numZSlices*numWvs);
            end;
            fseek(fid,1024+theSection*sectionOffset+insectionOffset,-1);
            % this block contains
            % Lamp Intensity
            % Time
            % stage X
            % stage Y
            % stage Z
            % minInt
            % maxInt
            % meanInt
            % xpTime
            % ndFilter (0=100%)
            % exWave
            % emWave
            % ???
            
            block = fread(fid,13,'float');
            % timestamp, expTime and ndFilter should be stored for zwt.
            % There is no function that actually reads exposure time or
            % ndFilter for calculations. However, header.Time is used a few
            % times. Thus, I add a new field, timestamp, that will
            % basically carry the same information as Time, only that the
            % info will be useful.
            header.Time(theSection+1)=block(2);
            header.timestamp(z+1,t+1,w+1) = block(2);
            expTime(z+1,t+1,w+1)=block(9); % before: expTime(theSection+1)
            ndFilter(z+1,t+1,w+1)=block(10);
            header.lampIntensity(z+1,t+1,w+1) = block(1);
            header.minInt(z+1,t+1,w+1) = block(6);
            header.maxInt(z+1,t+1,w+1) = block(7);
            header.meanInt(z+1,t+1,w+1) = block(8);
            
            % store stagePosition of the first slice (once)
            if z==0 && t==0 && w==0
                header.stagePosition = block(3:5);
            end
        end;
    end;
end;

% properly assign expTime, ndFilter. Assume it doesn't change for a single
% channel
header.expTime = reshape(expTime(1,1,:),1,numWvs);
header.ndFilter = reshape(ndFilter(1,1,:),1,numWvs);

% if all(expTime(1)==expTime)
%     header.expTime=expTime(1);
% else
%     % only warn if there is only one color
%     if numWvs == 1
%     warning('R3DREADHEADER:exposureTimeChanged',...
%         'exposure time changed during acquisition');
%     end
%     header.expTime=expTime;
% end;
% if all(ndFilter(1)==ndFilter)
%     header.ndFilter=ndFilter(1);
% else
%     if numWvs == 1
%     warning('R3DREADHEADER:ndFilterChanged',...
%         'ndFilter changed during acquisition');
%     end
%     header.ndFilter=ndFilter;
% end;

fclose(fid);

%-------------------------------
% correct pixelsize if necessary
%-------------------------------
d = dir(fname);
date = datenum(d.date);
firstDate = datenum('01-Mar-2002');
lastDate  = datenum('01-May-2004');

% make sure we get the right thing
isLaterThanFirst = date > firstDate;
isBeforeLast     = date < lastDate;
isSmallPix       = abs(1-header.pixelX/0.0515) < 0.001;
isLargePix       = abs(1-header.pixelX/0.0720) < 0.001;
isRightLens      = header.lensID == 12003;

% correct if necessary
if isRightLens & (isSmallPix | isLargePix)
    if isLaterThanFirst
        if isBeforeLast
            % using so many digits after the decimal is kind of nonsense,
            % but API wants at least six, so we give them eight
            header.pixelX = 0.04803126;
            header.pixelY = 0.04803126;
        end
    else
        warning('Very old movie - pixelsize might be slightly off!')
    end
end

 % correct a small mistake of Eugenio - the software said that
 % the lens was 10x
 if header.lensID == 10105 && header.pixelX > 0.6
     header.pixelX = header.pixelX/10;
     header.pixelY = header.pixelY/10;
 end

%-------------------------------

% header structure:

%struct dv_head {
% BLOCK1
%	long   numCol,numRow,numImages;			   /* nsec +AD0- nz-nw+ACo-nt */
%	long   mode;
%	long   nxst, nyst, nzst;
%	long   mx, my, mz;
%	float xlen, ylen, zlen;
%	float alpha, beta, gamma;
%	long   mapc, mapr, maps;
%	float min1, max1, amean;
%	long   ispg, next;
% END BLOCK1                   offset 96
%	short nDVID,nblank;			 /* nblank preserves byte boundary */
%	char  ibyte[28];
% BLOCK2
%	short nint,nreal;
%	short nres,nzfact;
% END BLOCK2
% BLOCK3
%	float min2,max2,min3,max3,min4,max4;
% END BLOCK3
% BLOCK4
%	short filetype, lens, n1, n2, v1, v2;
% END BLOCK4
% BLOCK5
%	float min5,max5;
% END BLOCK5
% BLOCK6                      offset 180
%	short numtimes;
%	short imagesequence;
% END BLOCK6
% BLOCK7
%	float tiltx, tilty, tiltz;
% END BLOCK7
% BLOCK8                      offset 196
%	short NumWaves, iwav1, iwav2, iwav3, iwav4, iwav5;
% END BLOCK8
% BLOCK9
%	float zorig, xorig, yorig;
% END BLOCK9
%	long   nlab;
%	char  label[800];
%};


