%% Create a MovieData object

%% Data setup
% Creating a fake file in a temporary directory for testing purposes

% Create temporary directory
java_tmpdir = char(java.lang.System.getProperty('java.io.tmpdir'));
uuid = char(java.util.UUID.randomUUID().toString());
tmpdir = fullfile(java_tmpdir, uuid);
mkdir(tmpdir);

% Create .fake file readable by Bio-Formats
filePath = fullfile(tmpdir, 'test&sizeC=3&sizeZ=4&sizeT=10.fake');
fid = fopen(filePath, 'w+');
fclose(fid);

%% MovieData initialization

% Using this constructor, filePath refers the full path to any file
% readable by Bio-Formas
% See http://www.openmicroscopy.org/site/support/bio-formats5/supported-formats.html
MD = MovieData(filePath);
fprintf(1, 'Object saved under: %s\n', MD.getFullPath());
fprintf(1, 'Output directory for analysis: %s\n', MD.outputDirectory_);

%% MovieData metadata

% Path location
disp('Raw data location');
fprintf(1, 'Channels path: %s\n', MD.getChannel(1).channelPath_);

% Retrieve movie dimensions
disp('Dimensions');
fprintf(1, '  Image size: %gX%g\n', MD.imSize_);
fprintf(1, '  Number of channels: %g\n', numel(MD.channels_));
fprintf(1, '  Number of timepoints: %g\n', MD.nFrames_);
fprintf(1, '  Number of z-slices: %g\n', MD.zSize_);

% Retrieve raw metadata
disp('Metadata');
fprintf(1, '  Pixel size: %g nm\n', MD.pixelSize_);
fprintf(1, '  Numerical aperture: %g nm\n', MD.numAperture_);
for i = 1 : numel(MD.channels_),
    fprintf(1, '  Channel %g\n', i);
    fprintf(1, '    Emission wavelength: %g nm\n',...
        MD.getChannel(i).emissionWavelength_);
    fprintf(1, '    Excitation wavelength: %g nm\n',...
        MD.getChannel(i).excitationWavelength_);
    fprintf(1, '    Psf sigma: %g\n',...
        MD.getChannel(i).psfSigma_);
end

% Retrieve the raw data
disp('Planes');
for c = 1 : numel(MD.channels_)
    for t = 1 : MD.nFrames_
        for z = 1 : MD.zSize_
            I = MD.getChannel(c).loadImage(t, z);
            fprintf(1, '  Channel %g Timepoint %g Z-slice %g\n',...
                c, t, z);
        end
    end
end

disp('Stacks');
for c = 1 : numel(MD.channels_)
    for t = 1 : MD.nFrames_
        fprintf(1, '  Channel %g Timepoint %g\n',...
            c, t);
        I = MD.getChannel(c).loadStack(t);
    end
end

%% MovieData metadata

% Check
disp('Write Metadata');
fprintf(1, '  Initial time interval: %g s\n', MD.timeInterval_);

% Set time interval
MD.timeInterval_ = 1;
fprintf(1, '  Initial time interval: %g s\n', MD.timeInterval_);

% Reset same time interval
MD.timeInterval_ = 1;

% Setting different metadata fails
try
    MD.timeInterval_ = 2;
catch ME
    disp(ME.message)
end

% Setting invalid metadata fails
try
    MD.getChannel(1).exposureTime_ = - 2;
catch ME
    disp(ME.message)
end

%% Graphical User interface
% Launch the movie creation GUI
movieDataGUI();

% Launch the movie viewing GUI
movieViewer(MD);
