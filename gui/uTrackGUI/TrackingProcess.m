classdef TrackingProcess < DataProcessingProcess
    % A class definition for a generic tracking process.
    %
    % Chuangang Ren, 11/2010
    % Modified by Sebastien Besson 03/2011
    
    properties(SetAccess = protected, GetAccess = public)
        
        
        channelIndex_ % The index of channel to process
        filename_ % file name of result data
        overwrite_ = 0; % If overwrite the original result MAT file
        
    end
    
    methods(Access = public)
        
        function obj = TrackingProcess(owner, outputDir, channelIndex, funParams )
            
            if nargin == 0
                super_args = {};
            else
                super_args{1} = owner;
                super_args{2} = TrackingProcess.getName;
            end
            obj = obj@DataProcessingProcess(super_args{:});
            
            if nargin < 2 || isempty(outputDir)
                outputDir = owner.outputDirectory_ ;
            end
            
            if nargin < 3 || isempty(channelIndex) % Default channel Index
                channelIndex = 1:length(owner.channels_);
            end
            
            if nargin < 4 || isempty(funParams)
                funParams = TrackingProcess.getDefaultParams(owner,outputDir);
            end
            
            obj.funParams_ = funParams;
            
            obj.channelIndex_ = channelIndex;
            obj.filename_ = 'tracking_result.mat';
            
            obj.funName_ = @trackCloseGapsKalmanSparse;
            
            % ---------------- Visualization Parameters --------------------
            
            % Tool 1: plotTracks2D
            
            obj.visualParams_.pt2D.timeRange = [1 owner.nFrames_];
            obj.visualParams_.pt2D.colorTime = '3';
            obj.visualParams_.pt2D.markerType = 'none';
            obj.visualParams_.pt2D.indicateSE = 0;
            obj.visualParams_.pt2D.newFigure = 1;
            obj.visualParams_.pt2D.image = [];
            obj.visualParams_.pt2D.imageDir = []; % Not in original function
            obj.visualParams_.pt2D.flipXY = 0;
            obj.visualParams_.pt2D.ask4sel = 0;
            obj.visualParams_.pt2D.offset = [0 0];
            obj.visualParams_.pt2D.minLength = 1;
            
            % Tool 2: plotCompTrack
            
            obj.visualParams_.pct.trackid = 1; % Not in original function
            obj.visualParams_.pct.plotX = 1;
            obj.visualParams_.pct.plotY = 1;
            obj.visualParams_.pct.plotA = 1;
            obj.visualParams_.pct.inOneFigure = 1;
            obj.visualParams_.pct.plotAggregState = 1;
            
            % Tool 3: overlayTracksMovieNew
            
            obj.visualParams_.otmn.startend = [1 owner.nFrames_];
            obj.visualParams_.otmn.dragtailLength = 5;
            obj.visualParams_.otmn.saveMovie = 1;
            obj.visualParams_.otmn.movieName = [];
            obj.visualParams_.otmn.dir2saveMovie = funParams.saveResults.dir;
            obj.visualParams_.otmn.filterSigma = 0;
            obj.visualParams_.otmn.classifyGaps = 0;
            obj.visualParams_.otmn.highlightES = 0;
            obj.visualParams_.otmn.showRaw = 1;
            obj.visualParams_.otmn.imageRange = []; % TO DO in GUI
            obj.visualParams_.otmn.onlyTracks = 0;
            obj.visualParams_.otmn.classifyLft = 0;
            obj.visualParams_.otmn.diffAnalysisRes = [];
            obj.visualParams_.otmn.intensityScale = 1;
            obj.visualParams_.otmn.colorTracks = 1;
            obj.visualParams_.otmn.minLength = 1;
            file = owner.getImageFileNames(1);
            obj.visualParams_.otmn.firstImageFile = [owner.channels_(1).channelPath_ filesep file{1}{1}];
            
        end
        
        
        function setChannelIndex(obj, index)
            % Set channel index
            if any(index > length(obj.owner_.channels_))
                error ('User-defined: channel index is larger than the number of channels.')
            end
            if ~isequal(obj.channelIndex_,index)
                obj.channelIndex_ = index;
                obj.procChanged_=true;
            end
        end
        
        % Set result file name
        function setFileName(obj, name)
            obj.filename_ = name;
        end
        
        % Set overwrite
        function setOverwrite (obj, i)
            obj.overwrite_ = i;
        end
        
        function run(obj)
            % Run the process!
            
            iDetection = obj.owner_.getProcessIndex('DetectionProcess',1,0);
            obj.owner_.processes_{iDetection}.checkChannelOutput(obj.channelIndex_);
            obj.setInFilePaths(obj.owner_.processes_{iDetection}.outFilePaths_);
            obj.success_=false;
            for i = obj.channelIndex_
                
                load(obj.inFilePaths_{i},'movieInfo');
                obj.funParams_.saveResults.filename = ['Channel_' num2str(i) '_' obj.filename_];
                
                %Check/create directory
                if ~exist(obj.funParams_.saveResults.dir,'dir')
                    mkdir(obj.funParams_.saveResults.dir)
                end
                
                if ~obj.overwrite_
                    % file name enumeration
                    obj.funParams_.saveResults.filename = enumFileName(obj.funParams_.saveResults.dir, obj.funParams_.saveResults.filename);
                end
                
                % Call function - return tracksFinal for reuse in the export
                % feature
                tracksFinal = obj.funName_(movieInfo, obj.funParams_.costMatrices, obj.funParams_.gapCloseParam,...
                    obj.funParams_.kalmanFunctions, obj.funParams_.probDim, obj.funParams_.saveResults, obj.funParams_.verbose);
                
                obj.setOutFilePath(i,[obj.funParams_.saveResults.dir filesep obj.funParams_.saveResults.filename]);
                
                % Optional export
                if obj.funParams_.saveResults.export
                    if ~obj.funParams_.gapCloseParam.mergeSplit
                        [M.trackedFeatureInfo M.trackedFeatureIndx]=...
                            convStruct2MatNoMS(tracksFinal);
                    else
                        [M.trackedFeatureInfo M.trackedFeatureIndx,M.trackStartRow,M.numSegments]=...
                            convStruct2MatIgnoreMS(tracksFinal);
                    end
                    
                    matResultsSaveFile=[obj.funParams_.saveResults.dir filesep obj.funParams_.saveResults.filename(1:end-4) '_mat.mat'];
                    save(matResultsSaveFile,'-struct','M');
                    clear M;
                end
                
            end
            obj.success_=true;
            obj.procChanged_=false;
            obj.setDateTime;
            obj.owner_.save;
            
            %         [tracksFinal,kalmanInfoLink,errFlag] = trackCloseGapsKalmanSparse(movieInfo,...
            %             costMatrices,gapCloseParam,kalmanFunctions,probDim,saveResults,verbose);
            
        end
        
        function hfigure = resultDisplay(obj,fig,procID)
            % Display the output of the process
            
            % Copied and pasted from the old uTrackPackageGUI
            % but there is definitely some optimization to do
            % Check for movie output before loading the GUI
            chan = [];
            for i = 1:length(obj.owner_.channels_)
                if obj.checkChannelOutput(i)
                    chan = i;
                    break
                end
            end
            
            if isempty(chan)
                warndlg('The current step does not have any output yet.','No Output','modal');
                return
            end
            
            % Make sure detection output is valid
            load(obj.outFilePaths_{chan},'tracksFinal');
            if isempty(tracksFinal)
                warndlg('The tracking result is empty. There is nothing to visualize.','Empty Output','modal');
                return
            end
            
            if isa(obj, 'Process')
                hfigure = trackingVisualGUI('mainFig', fig, procID);
            else
                error('User-defined: the input is not a Process object.')
            end
        end
        
        
    end
    methods(Static)
        function name = getName()
            name = 'Tracking';
        end
        function h = GUI()
            h= @trackingProcessGUI;
        end

        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:})
            outputDir=ip.Results.outputDir;
            
            % Set default parameters
            % --------------- gapCloseParam ----------------
            
            funParams.gapCloseParam.timeWindow = 5; %IMPORTANT maximum allowed time gap (in frames) between a track segment end and a track segment start that allows linking them.
            funParams.gapCloseParam.mergeSplit = 0; % (SORT OF FLAG: 4 options for user) 1 if merging and splitting are to be considered, 2 if only merging is to be considered, 3 if only splitting is to be considered, 0 if no merging or splitting are to be considered.
            funParams.gapCloseParam.minTrackLen = 1; %minimum length of track segments from linking to be used in gap closing.
            funParams.gapCloseParam.diagnostics = 1; %FLAG 1 to plot a histogram of gap lengths in the end; 0 or empty otherwise.
            
            
            % --------------- kalmanFunctions ----------------
            
            funParams.kalmanFunctions.reserveMem  = func2str(@kalmanResMemLM);
            funParams.kalmanFunctions.initialize  = func2str(@kalmanInitLinearMotion);
            funParams.kalmanFunctions.calcGain    = func2str(@kalmanGainLinearMotion);
            funParams.kalmanFunctions.timeReverse = func2str(@kalmanReverseLinearMotion);
            
            
            % --------------- saveResults ----------------
            
            funParams.saveResults.dir = [outputDir  filesep 'Tracking' filesep]; %directory where to save input and output
            funParams.saveResults.filename = []; % Note: channel-specific
            funParams.saveResults.export = 0; %FLAG allow additional export of the tracking results into matrix
            
            % --------------- Others ----------------
            
            funParams.verbose = 1;
            funParams.probDim = 2;
            
            funParams.costMatrices(1) = TrackingProcess.getDefaultLinkingCostMatrices(owner, funParams.gapCloseParam.timeWindow,1);
            funParams.costMatrices(2) = TrackingProcess.getDefaultGapClosingCostMatrices(owner, funParams.gapCloseParam.timeWindow,1);
            

        end
        
        function costMatrix = getDefaultLinkingCostMatrices(owner,timeWindow,varargin)
            
            % Linear motion
            costMatrices(1).name = 'Linear motion models';
            costMatrices(1).funcName = func2str(@costMatRandomDirectedSwitchingMotionLink);
            costMatrices(1).GUI = @costMatRandomDirectedSwitchingMotionLinkGUI;
            costMatrices(1).parameters.linearMotion = 0; % use linear motion Kalman filter.
            costMatrices(1).parameters.minSearchRadius = 2; %minimum allowed search radius. The search radius is calculated on the spot in the code given a feature's motion parameters. If it happens to be smaller than this minimum, it will be increased to the minimum.
            costMatrices(1).parameters.maxSearchRadius = 5; %IMPORTANT maximum allowed search radius. Again, if a feature's calculated search radius is larger than this maximum, it will be reduced to this maximum.
            costMatrices(1).parameters.brownStdMult = 3; %multiplication factor to calculate search radius from standard deviation.
            costMatrices(1).parameters.useLocalDensity = 1; %1 if you want to expand the search radius of isolated features in the linking (initial tracking) step.
            costMatrices(1).parameters.nnWindow = timeWindow; %number of frames before the current one where you want to look to see a feature's nearest neighbor in order to decide how isolated it is (in the initial linking step).
            costMatrices(1).parameters.kalmanInitParam = []; %Kalman filter initialization parameters.
            costMatrices(1).parameters.diagnostics = [2 owner.nFrames_-1];
            
                        
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addRequired('timeWindow',@isscalar);
            ip.addOptional('index',1:length(costMatrices),@isvector);
            ip.parse(owner,timeWindow,varargin{:});
            index = ip.Results.index;
            costMatrix=costMatrices(index);          
        end
        
        function costMatrix = getDefaultGapClosingCostMatrices(owner,timeWindow,varargin)
            
            % Linear motion
            costMatrices(1).name = 'Linear motion models';
            costMatrices(1).funcName = func2str(@costMatRandomDirectedSwitchingMotionCloseGaps);
            costMatrices(1).GUI = @costMatRandomDirectedSwitchingMotionCloseGapsGUI;
            costMatrices(1).parameters.linearMotion = 0; %use linear motion Kalman filter.
            
            costMatrices(1).parameters.minSearchRadius = 2; %minimum allowed search radius.
            costMatrices(1).parameters.maxSearchRadius = 5; %maximum allowed search radius.
            costMatrices(1).parameters.brownStdMult = 3*ones(timeWindow,1); %multiplication factor to calculate Brownian search radius from standard deviation.
            
            costMatrices(1).parameters.useLocalDensity = 1; %1 if you want to expand the search radius of isolated features in the gap closing and merging/splitting step.
            costMatrices(1).parameters.nnWindow = timeWindow; %number of frames before/after the current one where you want to look for a track's nearest neighbor at its end/start (in the gap closing step).
            costMatrices(1).parameters.brownScaling = [0.5 0.01]; %power for scaling the Brownian search radius with time, before and after timeReachConfB (next parameter).
            costMatrices(1).parameters.timeReachConfB = timeWindow; %before timeReachConfB, the search radius grows with time with the power in brownScaling(1); after timeReachConfB it grows with the power in brownScaling(2).
            costMatrices(1).parameters.ampRatioLimit = [0.5 2]; % (FLAG + VALUES small-big value) for merging and splitting. Minimum and maximum ratios between the intensity of a feature after merging/before splitting and the sum of the intensities of the 2 features that merge/split.
            
            % If parameters.linearMotion = 1
            costMatrices(1).parameters.lenForClassify = 5; %minimum track segment length to classify it as linear or random.
            costMatrices(1).parameters.linStdMult = 3*ones(timeWindow,1); %multiplication factor to calculate linear search radius from standard deviation.
            costMatrices(1).parameters.linScaling = [1 0.01]; %power for scaling the linear search radius with time (similar to brownScaling).
            costMatrices(1).parameters.timeReachConfL = timeWindow; %similar to timeReachConfB, but for the linear part of the motion.
            costMatrices(1).parameters.maxAngleVV = 30; %maximum angle between the directions of motion of two tracks that allows linking them (and thus closing a gap). Think of it as the equivalent of a searchRadius but for angles.
            % ---------------------------------
            
            costMatrices(1).parameters.gapPenalty = 1.5; %penalty for increasing temporary disappearance time (disappearing for n frames gets a penalty of gapPenalty^n).
            costMatrices(1).parameters.resLimit = []; % text field resolution limit, which is generally equal to 3 * point spread function sigma.
            
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addRequired('timeWindow',@isscalar);
            ip.addOptional('index',1:length(costMatrices),@isvector);
            ip.parse(owner,timeWindow,varargin{:});
            index = ip.Results.index;
            costMatrix=costMatrices(index);      
        end    
        
    end
end