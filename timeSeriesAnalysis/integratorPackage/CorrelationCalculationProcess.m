classdef CorrelationCalculationProcess < TimeSeriesProcess
    % A concrete process for calculating correlation of sampled processes
    %
    % Sebastien Besson, Oct 2011

    methods (Access = public)
        
        function obj = CorrelationCalculationProcess(owner,varargin)
            
            if nargin == 0
                super_args = {};
            else               
                % Input check
                ip = inputParser;
                ip.addRequired('owner',@(x) isa(x,'MovieObject'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;
                
                % Define arguments for superclass constructor
                super_args{1} = owner;       
                super_args{2} = CorrelationCalculationProcess.getName;
                super_args{3} = @calculateMovieCorrelation;                
                if isempty(funParams)
                    funParams=CorrelationCalculationProcess.getDefaultParams(owner,outputDir);
                end                
                super_args{4} = funParams;                
            end
            
            obj = obj@TimeSeriesProcess(super_args{:});
        end
              
        
        function varargout = loadChannelOutput(obj,i,j,varargin)
            % Check input
            outputList={'raw','bootstrap','corrFun','bounds','lags',...
                'bootstrapSteCorrFun'};
            ip=inputParser;
            ip.addRequired('obj');
            ip.addRequired('i',@isscalar);
            ip.addRequired('j',@isscalar);
            ip.addParamValue('output',outputList{1},@(x) all(ismember(x,outputList)));
            ip.parse(obj,i,j,varargin{:});
            output=ip.Results.output;
            if ischar(output), output={output}; end
            
            if strcmp(output{:},'raw')
                s=load(obj.outFilePaths_{i,j},'corrFun','bounds','lags');
            elseif strcmp(output{:},'bootstrap')
                s=load(obj.outFilePaths_{i,j},'bootstrapCorrFun','bootstrapSteCorrFun','bounds','lags');
            else
                s=load(obj.outFilePaths_{i,j},output{:});
            end
                
            for j=1:numel(output)
                if ismember(output{j},{'raw','bootstrap'})
                    varargout{j}=s;
                else
                    varargout{j} = s.(output{j});
                end
            end
        end
        
        
        function output = getDrawableOutput(obj)
            output(1).name='Correlation function';
            output(1).var='raw';
            output(1).formatData=@formatCorrelationData;
            output(1).type='correlationGraph';
            output(1).defaultDisplayMethod = @CorrelationMeshDisplay;
            output(2).name='Bootsrapped correlation';
            output(2).var='bootstrap';
            output(2).formatData=@formatBootstrappedCorrelationData;
            output(2).type='correlationGraph';
            output(2).defaultDisplayMethod = @CorrelationGraphDisplay;
        end
    end
    
    methods (Static)
        function name =getName()
            name = 'Correlation Calculation';
        end
        function h =GUI()
            h = @correlationCalculationProcessGUI;
        end
        function procNames = getTimeSeriesProcesses()
            procNames = {'WindowSamplingProcess';
                'ProtrusionSamplingProcess'};
        end
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieObject'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:})
            outputDir=ip.Results.outputDir;
            
            % Set default parameters
            funParams.OutputDirectory = [outputDir  filesep 'correlation'];
            funParams.ProcessName=TimeSeriesProcess.getTimeSeriesProcesses;
            if isa(owner,'MovieList'), 
                funParams.MovieIndex=1:numel(owner.movies_);
                winProc =cellfun(@(x) x.processes_{x.getProcessIndex('WindowingProcess',1,false)},...
                    owner.movies_,'UniformOutput',false);
                funParams.BandMin=1;
                funParams.BandMax=min(cellfun(@(x) x.nBandMax_,winProc));
                funParams.SliceIndex=cellfun(@(x) ones(x.nSliceMax_,1),winProc,'UniformOutput',false);
            else
               winProc =owner.processes_{owner.getProcessIndex('WindowingProcess',1,false)};
               funParams.BandMin=1;
               funParams.BandMax=winProc.nBandMax_;
               funParams.SliceIndex=ones(winProc.nSliceMax_,1);
            end
        end
    end
end

function data =formatCorrelationData(data)
data.X=data.lags;
data.Z=data.corrFun;
data=rmfield(data,{'lags','corrFun'});
end

function data =formatBootstrappedCorrelationData(data)
data.lags=squeeze(nanmean(data.lags,2));
data.avgCorrFun=data.bootstrapCorrFun;
data.steCorrFun=data.bootstrapSteCorrFun;
end



