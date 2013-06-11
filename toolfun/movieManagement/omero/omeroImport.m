function movie = omeroImport(session,imageID,varargin)
% OMEROIMPORT imports images from an OMERO server into MovieData objects
%
% movie = omeroImport(session)
%
% Load proprietary files using the Bioformats library. Read the metadata
% that is associated with the movie and the channels and set them into the
% created movie objects. Optionally images can be extracted and saved as
% individual TIFF files.
%
% Input:
% 
%   session - an omero session
%
%   imageID - The ID of the image to be associated with the movie Data.
%
%   importMetadata - A flag specifying whether the movie metadata read by
%   Bio-Formats should be copied into the MovieData. Default: true.
%
%   Optional Parameters :
%       ('FieldName' -> possible values)
%
%       outputDirectory - A string giving the directory where to save the
%       created MovieData as well as the analysis output. In the case of
%       multi-series images, this string gives the basename of the output
%       folder and will be exanded as basename_sxxx for each movie
%
% Output:
%
%   movie - A MovieData object

% Sebastien Besson, Dec 2011 (last modified May 2013)

% Input check
ip=inputParser;
ip.addRequired('session', @MovieObject.isOmeroSession);
ip.addRequired('imageID', @isscalar);
ip.addOptional('importMetadata', true, @islogical);
ip.addParamValue('outputDirectory', '', @ischar);
ip.parse(session, imageID, varargin{:});

% Retrieve image and pixels
image = getImages(session, imageID);
assert(~isempty(image), 'No image of id %g found', imageID);
pixels = image.getPrimaryPixels();

% Create metadata service
metadataService = session.getMetadataService();

% Read Image metadata
if ip.Results.importMetadata
    movieArgs = getMovieMetadata(metadataService, image);
else
    movieArgs = {};
end
    
% Set output directory (based on image extraction flag)
if isempty(ip.Results.outputDirectory)
    [movieFileName, outputDir] = uiputfile('*.mat',...
        'Find a place to save your analysis', 'movieData.mat');
    if isequal(outputDir,0), return; end
else
    outputDir = ip.Results.outputDirectory;
    if ~isdir(outputDir), mkdir(outputDir); end
    movieFileName = 'movie.mat';
end

% Create movie channels
nChan =  pixels.getSizeC().getValue();
movieChannels(1,nChan) = Channel();

% Read OMERO channels
pixels = session.getPixelsService().retrievePixDescription(pixels.getId.getValue);
omeroChannels = toMatlabList(pixels.copyChannels);

for i=1:nChan
    if ip.Results.importMetadata
        channelArgs = getChannelMetadata(omeroChannels(i));
    else
        channelArgs = {};
    end

    % Read channel xame
    chanName = omeroChannels(i).getLogicalChannel().getName.getValue;
    if isempty(chanName), chanName = ['Channel_' num2str(i)]; end
    
    movieChannels(i)=Channel('',channelArgs{:});
end

% Create movie object
movie=MovieData(movieChannels,outputDir,movieArgs{:});
movie.setPath(outputDir);
movie.setFilename(movieFileName);
movie.setOmeroId(imageID);
movie.setOmeroSession(session);
movie.setOmeroSave(true);

movie.sanityCheck;

function movieArgs = getMovieMetadata(metadataService, image)

movieArgs={}; 
pixels = image.getPrimaryPixels();

% Read pixel size
pixelSize = pixels.getPhysicalSizeX();
if ~isempty(pixelSize)
    assert(isequal(pixelSize, pixels.getPhysicalSizeY),...
        'Pixel size different in x and y');
    movieArgs = horzcat(movieArgs, 'pixelSize_', pixelSize.getValue * 1e3);
end

% Read camera bit depth
camBitdepth = pixels.getPixelsType.getBitSize.getValue/2;
if ~isempty(camBitdepth)
    movieArgs=horzcat(movieArgs,'camBitdepth_',camBitdepth);
end

% Read time interval
timeInterval = pixels.getTimeIncrement();
if ~isempty(timeInterval)
    movieArgs=horzcat(movieArgs,'timeInterval_', timeInterval.getValue());
end

% Read the lens numerical aperture
instrument = image.getInstrument();
if ~isempty(instrument)
    instrument = metadataService.loadInstrument(instrument.getId.getValue);
    objectives = toMatlabList(instrument.copyObjective());
    if ~isempty(objectives)
        lensNA = objectives(1).getLensNA().getValue();
        movieArgs=horzcat(movieArgs,'numAperture_',double(lensNA));
    end
end

function channelArgs = getChannelMetadata(omeroChannel)

channelArgs = {};

% Read excitation wavelength
exwlgth = omeroChannel.getLogicalChannel().getExcitationWave();
if ~isempty(exwlgth) && exwlgth.getValue() ~= -1
    channelArgs=horzcat(channelArgs,...
        'excitationWavelength_', exwlgth.getValue());
end

% Read emission wavelength
emwlgth=omeroChannel.getLogicalChannel().getEmissionWave();
if ~isempty(emwlgth) && emwlgth.getValue() ~= -1 % Bug
    channelArgs=horzcat(channelArgs,...
        'emissionWavelength_', emwlgth.getValue());
end
