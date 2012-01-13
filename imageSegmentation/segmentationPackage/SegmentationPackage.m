classdef SegmentationPackage < Package
    % A concrete process for Segmentation Package
    
    methods (Access = public)
        function obj = SegmentationPackage (owner,varargin)
            % Construntor of class MaskProcess
            if nargin == 0
                super_args = {};
            else
                % Check input
                ip =inputParser;
                ip.addRequired('owner',@(x) isa(x,'MovieObject'));
                ip.addOptional('outputDir',owner.outputDirectory_,@(x) isa(x,'MovieObject'));
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                
                super_args{1} = owner;               
                super_args{2} = [outputDir filesep 'SegmentationPackage'];
            end
            % Call the superclass constructor
            obj = obj@Package(super_args{:});
        end
        
        function [status processExceptions] = sanityCheck(obj,varargin)
            
            % Check that the channels have a psf function
            nProc = length(obj.getProcessClassNames);
            ip = inputParser;
            ip.CaseSensitive = false;
            ip.addRequired('obj');
            ip.addOptional('full',true, @(x) islogical(x));
            ip.addOptional('procID',1:nProc,@(x) all(ismember(x,1:nProc)) || strcmp(x,'all'));
            ip.parse(obj,varargin{:});
            full = ip.Results.full;
            procID = ip.Results.procID;
            if strcmp(procID,'all'), procID = 1:nProc;end
            
            if full
                validProc = procID(~cellfun(@isempty,obj.processes_(procID)));
                if all(ismember([1 2],validProc))
                    % Find the segmentation process index and set it in the
                    % mask refinement process
                    funParams.SegProcessIndex = find(cellfun(@(x) isequal(x,obj.processes_{1}),...
                        obj.owner_.processes_));
                    parseProcessParams(obj.processes_{2},funParams);
                end
            end
            [status processExceptions] = sanityCheck@Package(obj,varargin{:});
        end
        
    end
    methods (Static)
        
        function name = getName()
            name = 'Segmentation';
        end
        
        function m = getDependencyMatrix(i,j)
            m = [0 0; % SegmentationProcess
                1 0]; % MaskRefinementProcess
            if nargin<2, j=1:size(m,2); end
            if nargin<1, i=1:size(m,1); end
            m=m(i,j);
        end
        
        
        function varargout = GUI(varargin)
            % Start the package GUI
            varargout{1} = segmentationPackageGUI(varargin{:});
        end
        
        function procConstr = getDefaultProcessConstructors(index)
            segProcConstr = {
                @ThresholdProcess,...
                @MaskRefinementProcess};
            
            if nargin==0, index=1:numel(segProcConstr); end
            procConstr=segProcConstr(index);
        end
        function classes = getProcessClassNames(index)
            segClasses = {
                'SegmentationProcess',...
                'MaskRefinementProcess'};
            if nargin==0, index=1:numel(segClasses); end
            classes=segClasses(index);
        end
    end
end

