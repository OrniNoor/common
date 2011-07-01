classdef DoubleProcessingProcess < ImageProcessingProcess
    %A class definition for a generic image processing process whose
    %resulting images are stored as a double-precision floating point
    %values, rather than integers. That is, this process takes in either 
    %raw images or double-precision images and and produces
    %double-precision images of the same dimension and number as output.
    %These images may or may not overwrite the original input images.
    %
    %
    % Hunter Elliott, 6/2010
    %
    
    methods (Access = public)
        
        function obj = DoubleProcessingProcess(owner,name,funName,funParams,...
                                                inImagePaths,outImagePaths)
                                          
           if nargin == 0
                super_args = {};
            else
                                
                super_args{1} = owner;
                super_args{2} = name;
                if nargin > 2
                    super_args{3} = funName;                
                end
                if nargin > 3                    
                    super_args{4} = funParams;                                    
                end                                
                
                if nargin > 4
                    super_args{5} = inImagePaths;
                end
                if nargin > 5
                    super_args{6} = outImagePaths;
                end
                                
            end
            
            obj = obj@ImageProcessingProcess(super_args{:});                        
            
        end
        
        function setInImagePath(obj,chanNum,imagePath)
            
            if ~obj.checkChanNum(chanNum)
                error('lccb:set:fatal','Invalid image channel number for image path!\n\n'); 
            end
            
            if ~iscell(imagePath)
                imagePath = {imagePath};
            end
            nChan = length(chanNum);
            if nChan ~= length(imagePath)
                error('lccb:set:fatal','You must specify a path for every channel!')
            end
            
            for j = 1:nChan
               if ~exist(imagePath{j},'dir')
                   error('lccb:set:fatal',...
                       ['The directory specified for channel ' ...
                       num2str(chanNum(j)) ' is invalid!']) 
               
               else
                   if isempty(imDir(imagePath{j})) && ...
                           isempty(dir([imagePath{j} filesep '*.mat']))
                       error('lccb:set:fatal',...
                       ['The directory specified for channel ' ...
                       num2str(chanNum(j)) ' does not contain any images!!']) 
                   else                       
                       obj.inFilePaths_{1,chanNum(j)} = imagePath{j};                
                   end
               end
            end                        
        end
        
        function fileNames = getOutImageFileNames(obj,iChan)
            if obj.checkChannelOutput(iChan)
                fileNames = cellfun(@(x)(dir([x filesep '*.mat'])),obj.outFilePaths_(1,iChan),'UniformOutput',false);                
                fileNames = cellfun(@(x)(arrayfun(@(x)(x.name),x,'UniformOutput',false)),fileNames,'UniformOutput',false);
                nChan = numel(iChan);
                for j = 1:nChan
                    %Sort the files by the trailing numbers
                    fNums = cellfun(@(x)(str2double(...
                            x(max(regexp(x(1:end-4),'\D'))+1:end-4))),fileNames{j});
                    [~,iX] = sort(fNums);
                    fileNames{j} = fileNames{j}(iX);                    
                end
                nIm = cellfun(@(x)(length(x)),fileNames);
                if ~all(nIm == obj.owner_.nFrames_)                    
                    error('Incorrect number of images found in one or more channels!')
                end                
            else
                error('Invalid channel numbers! Must be positive integers less than the number of image channels!')
            end    
            
            
        end
        function fileNames = getInImageFileNames(obj,iChan)
            if obj.checkChanNum(iChan)
                
                nChan = numel(iChan);
                fileNames = cell(1,nChan);
                for j = 1:nChan
                    %First check for regular image inputs
                    fileNames{j} = imDir(obj.inFilePaths_{1,iChan(j)});                   
                    if isempty(fileNames{j})
                        %If none found, check for .mat image inputs
                        fileNames{j} = dir([obj.inFilePaths_{1,inFilePaths_iChan(j)} filesep '*.mat']);                                                                        
                    end
                    fileNames{j} = arrayfun(@(x)(x.name),fileNames{j},'UniformOutput',false);                                    
                    nIm = length(fileNames{j});
                    if nIm ~= obj.owner_.nFrames_                    
                        error(['Incorrect number of images found in channel ' num2str(iChan(j)) ' !'])
                    end                
                end
            else
                error('Invalid channel numbers! Must be positive integers less than the number of image channels!')
            end    
            
            
        end
        
        function OK = checkChannelOutput(obj,iChan)
            
           %Checks if the selected channels have valid output images          
           nChanTot = numel(obj.owner_.channels_);
           if nargin < 2 || isempty(iChan)
               iChan = 1:nChanTot;
           end
           
           OK =  arrayfun(@(x)(x <= nChanTot && ...
                             x > 0 && isequal(round(x),x) && ...
                             (length(dir([obj.outFilePaths_{1,x} filesep '*.mat']))...
                             == obj.owner_.nFrames_)),iChan);
        end   
        function outIm = loadOutImage(obj,iChan,iFrame)
            
            if nargin < 3 || isempty(iChan) || isempty(iFrame)
                error('You must specify a frame and channel number!')
            end            
            
            if length(iChan) > 1 || length(iFrame) > 1
                error('You can only specify 1 image to load!')
            end
            
            if ~obj.checkFrameNum(iFrame)
                error('Invalid frame number!')
            end
            
            %get the image names
            imNames = getOutImageFileNames(obj,iChan);
            
            outIm = load([obj.outFilePaths_{1,iChan} ...
                filesep imNames{1}{iFrame}]);
            fNames = fieldnames(outIm);
            if numel(fNames) > 1 || isempty(fNames)
                error(['The file for image ' num2str(iFrame) ' in channel ' num2str(iChan) ' is invalid! Check images...'])
            end
            outIm = outIm.(fNames{1});
            
        end

        function outIm = loadChannelOutput(obj,iChan,iFrame,varargin)
            
            ip =inputParser;
            ip.addRequired('obj',@(x) isa(x,'ImageProcessingProcess'));
            ip.addRequired('iChan',@(x) ismember(x,1:numel(obj.owner_.channels_)));
            ip.addRequired('iFrame',@(x) ismember(x,1:obj.owner_.nFrames_));
            ip.addOptional('output',[],@ischar);            
            ip.parse(obj,iChan,iFrame,varargin{:})
            
            %get the image names
            imNames = getOutImageFileNames(obj,iChan);
            outIm = load([obj.outFilePaths_{1,iChan} ...
                filesep imNames{1}{iFrame}]);
            fNames = fieldnames(outIm);
            if numel(fNames) > 1 || isempty(fNames)
                error(['The file for image ' num2str(iFrame) ' in channel ' num2str(iChan) ' is invalid! Check images...'])
            end
            outIm = outIm.(fNames{1});
            
        end


    end
    
end