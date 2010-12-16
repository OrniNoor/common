classdef ImageCorrectionProcess < ImageProcessingProcess
    
    %A class for performing corrections on images using other "correction"
    %images.
    %
    %Hunter Elliott, 5/2010
    %
    
    properties (SetAccess = private, GetAccess = public)
        
        %Paths for the images used in calculating/performing the correction.
        correctionImagePaths_ = {};
        
    end
    
    methods (Access = public)
        
        function obj = ImageCorrectionProcess(owner,name,funName,funParams,...                                              
                                              inImagePaths,outImagePaths,...
                                              correctionImagePaths)
            
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
            
            if nargin > 6
                obj.correctionImagePaths_ = correctionImagePaths;
            end
            
        end                 
        
        function setCorrectionImagePath(obj,iChan,imagePaths)           
            if ~obj.checkChanNum(iChan);
                error('lccb:set:fatal','Invalid image channel number for correction image path!\n\n'); 
            end
            nChan = length(iChan);
            if ~iscell(imagePaths)
                imagePaths = {imagePaths};
            end
            if numel(imagePaths) ~= nChan
                error('lccb:set:fatal','You must specify one image path for each correction image channel!\n\n'); 
            end
            for j = 1:nChan
                if exist(imagePaths{j},'dir') && numel(imDir(imagePaths{j})) > 0
                    obj.correctionImagePaths_{iChan(j)} = imagePaths{j};
                else
                   error(['The correction image path specified for channel ' num2str(iChan(j)) ' was not a valid image-containing directory!']) 
                end
            end
        end
        
        function fileNames = getCorrectionImageFileNames(obj,iChan)
            if obj.checkChanNum(iChan)
                fileNames = cellfun(@(x)(imDir(x)),obj.correctionImagePaths_(iChan),'UniformOutput',false);
                fileNames = cellfun(@(x)(arrayfun(@(x)(x.name),x,'UniformOutput',false)),fileNames,'UniformOutput',false);
                nIm = cellfun(@(x)(length(x)),fileNames);
                if any(nIm == 0)
                    error('No images in one or more correction channels!')
                end                
            else
                error('lccb:set:fatal','Invalid channel numbers! Must be positive integers less than the number of image channels!')
            end    
            
            
        end
        function h = resultDisplay(obj)
           %Overrides default display so averaged correction images can be displayed

           %First, just show the corrected images with the viewer
           h = movieDataVisualizationGUI(obj.owner_,obj);

           %Load and display the averaged correction images
           corrImNames = dir([obj.funParams_.OutputDirectory filesep '*correction_image*.mat']);
           if ~isempty(corrImNames)

               for j = 1:numel(corrImNames)
                   figure
                   tmp = load([obj.funParams_.OutputDirectory filesep corrImNames(j).name]);
                   tmpF = fieldnames(tmp);
                   imagesc(tmp.(tmpF{1}));
                   colorbar,axis image,axis off,colormap(jet(2^16)) %Use hi-res colormap to avoid apparent stratification
                   title(['Processed ' obj.name_ ' Image, Channel ' corrImNames(j).name(end-4) ]);
               end

           end

        end
    end
end