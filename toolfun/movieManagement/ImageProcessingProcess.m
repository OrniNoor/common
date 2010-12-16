classdef ImageProcessingProcess < Process
    %A class definition for a generic image processing process. That is, a
    %process which takes in images and produces images of the same
    %dimension and number as output. These images may or may not overwrite
    %the original input images.
    %
    %
    % Hunter Elliott, 5/2010
    %
    properties (SetAccess = protected, GetAccess = public)
        
        outImagePaths_ %Location of processed images for each channel.
        inImagePaths_ %Location of images which were processed. May or may not be the original, raw images.        
        
    end
    
    methods (Access = public)
        
        function obj = ImageProcessingProcess(owner,name,funName,funParams,...
                                              inImagePaths,outImagePaths)
                                          
            if nargin == 0;
                super_args = {};
            else
                super_args{1} = owner;
                super_args{2} = name;                
            end
            
            obj = obj@Process(super_args{:});
            
            if nargin > 2
                obj.funName_ = funName;                              
            end
            if nargin > 3
               obj.funParams_ = funParams;              
            end
            
            if nargin > 4
              if ~isempty(inImagePaths) && numel(inImagePaths) ...
                      ~= numel(owner.channels_) || ~iscell(inImagePaths)
                 error('lccb:set:fatal','Input image paths must be a cell-array of the same size as the number of image channels!\n\n'); 
              end
              obj.inImagePaths_ = inImagePaths;              
            else
                %Default is to use raw images as input.
                obj.inImagePaths_ = owner.getChannelPaths;               
            end                        
            if nargin > 5               
              if ~isempty(outImagePaths) && numel(outImagePaths) ...
                      ~= numel(owner.channels_) || ~iscell(outImagePaths)
                 error('lccb:set:fatal','Output image paths must be a cell-array of the same size as the number of image channels!\n\n'); 
              end
              obj.outImagePaths_ = outImagePaths;              
            else
                obj.outImagePaths_ = cell(1,numel(owner.channels_));               
            end
            
        end
        
        function setOutImagePath(obj,chanNum,imagePath)
            
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
                   obj.outImagePaths_{chanNum(j)} = imagePath{j};                
               end
            end
            
            
        end
        function clearOutImagePath(obj,chanNum)

            if ~obj.checkChanNum(chanNum)
                error('lccb:set:fatal','Invalid image channel number for image path!\n\n'); 
            end
            
            for j = 1:numel(chanNum)
                obj.outImagePaths_{chanNum(j)} = [];
            end
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
                   if isempty(imDir(imagePath{j}))
                       error('lccb:set:fatal',...
                       ['The directory specified for channel ' ...
                       num2str(chanNum(j)) ' does not contain any images!!']) 
                   else                       
                       obj.inImagePaths_{chanNum(j)} = imagePath{j};                
                   end
               end
            end                        
        end
        function fileNames = getOutImageFileNames(obj,iChan)
            if obj.checkChannelOutput(iChan)
                fileNames = cellfun(@(x)(imDir(x)),obj.outImagePaths_(iChan),'UniformOutput',false);
                fileNames = cellfun(@(x)(arrayfun(@(x)(x.name),x,'UniformOutput',false)),fileNames,'UniformOutput',false);
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
                fileNames = cellfun(@(x)(imDir(x)),obj.inImagePaths_(iChan),'UniformOutput',false);
                fileNames = cellfun(@(x)(arrayfun(@(x)(x.name),x,'UniformOutput',false)),fileNames,'UniformOutput',false);
                nIm = cellfun(@(x)(length(x)),fileNames);
                if ~all(nIm == obj.owner_.nFrames_)                    
                    error('Incorrect number of images found in one or more channels!')
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
                             ~isempty(imDir(obj.outImagePaths_{x}))),iChan);
        end
        
        
        function hfigure = resultDisplay(obj)
        % Call resultDisplayGUI to show result
        
            if isa(obj, 'Process')
                hfigure = movieDataVisualizationGUI(obj.owner_, obj);
            else
                error('User-defined: the input is not a Process object.')
            end
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
            
            outIm = imread([obj.outImagePaths_{iChan} ...
                filesep imNames{1}{iFrame}]);
            
        end
            
        function sanityCheck(obj)
            
        end
        
        
        
        
    end
    
end