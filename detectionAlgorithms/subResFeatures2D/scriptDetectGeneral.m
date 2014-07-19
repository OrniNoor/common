
%% movie information
movieParam.imageDir = '/project/biophysics/jaqaman_lab/vegf_tsp1/touretLab/140522_coloc/Actin-CD36-Fyn/NoTSP/imagesCD36/'; %directory where images are
movieParam.filenameBase = 'NoTSP_new_'; %image file name base
movieParam.firstImageNum = 1; %number of first image in movie
movieParam.lastImageNum = 10; %number of last image in movie
movieParam.digits4Enum = 4; %number of digits used for frame enumeration (1-4).

%% detection parameters
detectionParam.psfSigma = 1.2; %point spread function sigma (in pixels)
detectionParam.testAlpha = struct('alphaR',0.05,'alphaA',0.2,'alphaD',0.2,'alphaF',0); %alpha-values for detection statistical tests
detectionParam.visual = 1; %1 to see image with detected features, 0 otherwise
detectionParam.doMMF = 1; %1 if mixture-model fitting, 0 otherwise
detectionParam.bitDepth = 16; %Camera bit depth
detectionParam.alphaLocMax = 0.15; %alpha-value for initial detection of local maxima
detectionParam.numSigmaIter = 0; %maximum number of iterations for PSF sigma estimation
detectionParam.integWindow = 0; %number of frames before and after a frame for time integration

detectionParam.calcMethod = 'g';

% %absolute background info and parameters...
% background.imageDir = 'C:\kjData\Galbraiths\data\alphaVY773AandCellEdge\140109_Cs1C4_Y773A\bgAlphaVY773A\';
% background.filenameBase = 'crop_140109_Cs1C4_mEos2AvBeta3Y773A_';
% background.alphaLocMaxAbs = 0.01;
% detectionParam.background = background;

% detectionParam.maskLoc = 'C:\kjData\Javitch\140115_data\40ms1-5mWPd80G500\maskTest.tif';

%% additional input

%saveResults
saveResults.dir = '/project/biophysics/jaqaman_lab/vegf_tsp1/touretLab/140522_coloc/Actin-CD36-Fyn/NoTSP/analysis/'; %directory where to save input and output
saveResults.filename = 'detectionCD36Test5.mat'; %name of file where input and output are saved
% saveResults = 0;

%verbose state
verbose = 1;

%% run the detection function
[movieInfo,exceptions,localMaxima,background,psfSigma] = ...
    detectSubResFeatures2D_StandAlone(movieParam,detectionParam,saveResults,verbose);
