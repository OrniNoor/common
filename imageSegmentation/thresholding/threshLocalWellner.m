function [ imThresh, varargout ] = threshLocalWellner( im, windowRadius, thresh_fraction, varargin )
% A fast ND implementation of wellner's locally adaptive thresholding 
% algorithm where in the threshold for a pixel (i,j) is calculated as 
% follows:
% 
%           T(i,j) = thresh_fraction * mean(i,j) 
% 
% where mean is computed in a small window around the pixel.
% 
% Usage:
% 
%   Inputs: 
%     
%     im: 
%         
%       Input grayscale image (of any dimension >= 2) that needs to 
%       be thresholded
% 
%     windowRadius: 
%     
%       It must be a scalar or a 1D array of d positive integers where 
%       d is the dimension of the input image.        
%       
%       Determines the size of the local window for computing the threshold. 
%       Note that this parameter specifies the radius of the local window
%       in each dimension. The actual window size = 2 * windowRadius + 1.
%             
%     thresh_fraction:
%     
%       determines what fraction of the local window should be used as a 
%       threshold.
% 
%       Typical value of thresh_fraction is 0.85 for document images.
% 
%     padMethod (optional):
%     
%       Can be one of the following strings:       
%         { 'none', 'symmetric', 'replicate', 'circular' }
%       
%       Determines how the threshold is determined for the pixels on the 
%       boundary of the image. There are two ways to handle this:
%       
%       (1) crop the local window to lie entirely inside the image
%       (2) pad the image by windowRadius using the matlab function padarray 
%           In this case no cropping is needed. The values of the extra 
%           padded pixels can be determined in one of the three ways as 
%           described in the matlab function padarray.
%           
%     allowedThresholdRange (optional but recommended):    
%     
%       must be an array of two elements - [minLocalThreshold, maxLocalThreshold]
%       If the local window threshold for a pixel falls outside this range 
%       it is adjusted to the nearest value in the specified range as 
%       shown below:
%       
%       if local_threshold < minLocalThreshold
%           
%           local_threshold = minLocalThreshold          
%           
%       elseif local_threshold > maxLocalThreshold
%           
%           local_threshold = maxLocalThreshold
%           
%       else
%           
%           local_threshold = local_threshold
%           
%       end      
%       
%       A typical way to specify this range is to compute a threshold using 
%       a global thresholding algorithm first and then set the range as:
%       
%       allowedThresholdRange = [ 0.75 * global_threshold, 1.5 * global_threshold ]
%       
%       This helps resolve the problem of local thresholding algorithms where 
%       the intensities in the local window are more or less homogenous.
%       
%   Output:
%     
%     imThresh -- binary mask of the thresholded image
% 
%     imThreshValues -- values of the actual thresholds used for each pixel
% 
% This implementation uses integral images to speed up the computation as 
% described in the following paper: 
% 
% Tapia, E. (2011). "A note on the computation of high-dimensional integral images." 
% Pattern Recognition Letters 32(2): 197-201
% 
% A big plus of this approach is that the computational time is the same 
% for any windowsize.
%
% Below are the typical computation times on a computer equipped with an 
% Intel-i7 2.93 GHz (Quadcore) processor and 12 GB of RAM:
%
% (1) 2D image of size 512 x 512 - 0.1 sec
% (2) 3D volume of size 512 x 512 x 15 - 2 sec
% (3) you could potentially run it on higher dimensional datasets
%     and see similar speeds provided you have enough RAM.
%
% Much more speedup can be achieved if someone can implement it in C/C++
% and also the code has blocks of computation which could be parallelized 
% 
% References:
% 
% 1) Sezgin, M. and B. Sankur (2004). "Survey over image thresholding
%    techniques and quantitative performance evaluation." 
%    Journal of Electronic Imaging 13(1): 146-168.
%
% 2) Tapia, E. (2011). "A note on the computation of high-dimensional
%    integral images." Pattern Recognition Letters 32(2): 197-201.
%
% Author: Deepak Roy Chittajallu
% 
% 
    p = inputParser;
    p.addRequired( 'im', @(x) (isnumeric(x) && ndims(x) >= 2) );
    p.addRequired( 'windowRadius', @(x) (isnumeric(x) && ~(any( x <= 0 ) || any( abs( x - round( x ) ) > 0 ))) );
    p.addRequired( 'thresh_fraction',  @(x) (isnumeric(x) && isscalar(x)) )
    p.addParamValue( 'padMethod', 'none', @(x) (ischar(x) && ismember( lower( x ), { 'none', 'symmetric', 'replicate', 'circular' } )) );
    p.addParamValue( 'allowedThresholdRange', [0,1], @(x) (isnumeric(x) && numel(x) == 2 && x(1) <= x(2)) );    
    p.parse( im, windowRadius, thresh_fraction, varargin{:} );    
    
    padMethod = lower( p.Results.padMethod );
    allowedThresholdRange = p.Results.allowedThresholdRange;
    
    if isscalar( windowRadius )
        windowRadius = zeros(1,ndims(im)) + windowRadius;
    end

    ImageIntensityRange = [min(im(:)), max(im(:))];
    
    % scale down the intensity range of the image to avoid possible overflow 
    % while computing the integral image for high dynamic range images of 
    % large dimension. 
    im = mat2gray( im );
    
    % readjust the allowedThresholdRange parameter to the [0,1] range if it
    % was specified by the user    
    if ~ismember( 'allowedThresholdRange', p.UsingDefaults )
        allowedThresholdRange = mat2gray( allowedThresholdRange, ImageIntensityRange );
    end
    
    if  strcmpi( padMethod, 'none' )
        
        imsize = size(im);

        % compute integral image of im and im.^2
        imIntegral = ComputeIntegralImage(im);

        % perform locally adaptive wellners thresholding
        pixsubind = cell(1,ndims(im));
        [pixsubind{:}] = ind2sub( imsize, (1:numel(im))' );            
        pixsubind = cell2mat( pixsubind );

        boxOrigin = pixsubind - repmat( windowRadius, numel(im), 1 );           
        boxOrigin(boxOrigin < 1) = 1; % boundary window size correction

        boxEnd = pixsubind + repmat( windowRadius, numel(im), 1 );
        clear pixsubind;            
        for i = 1:ndims(im)
            boxEnd( boxEnd(:,i) > imsize(i), i ) = imsize(i); % boundary window size correction
        end

        boxSize = boxEnd - boxOrigin;
        clear boxEnd;

        boxsum = 0;
        for i = 0:2^(ndims(im))-1
            b = dec2binarray(i,ndims(imIntegral));       
            cornerPixSubind = cell(1,ndims(im));
            for j = 1:ndims(im)
                if b(j)
                    cornerPixSubind{j} = boxOrigin(:,j) + boxSize(:,j);
                else
                    cornerPixSubind{j} = boxOrigin(:,j);
                end              
            end
            cornerPixInd = sub2ind( imsize, cornerPixSubind{:} );
            boxsum = boxsum + (-1)^(ndims(im)-sum(b)) * imIntegral( cornerPixInd );              
        end            

        boxSize( boxSize == 0 ) = 1;
        boxSize = prod( boxSize, 2 );            
        clear boxEnd boxOrigin;

        meanBoxIntensity = boxsum ./ boxSize;
        clear boxsum boxSize;

    else
        
        % pad the input image with windowRadius 
        imPadded = padarray( im, windowRadius, padMethod ); 
        imPaddedMask = padarray( ones(size(im)), windowRadius, 0 ); 

        % compute integral image of im and im.^2
        imIntegral = ComputeIntegralImage(imPadded);

        % perform locally adaptive wellners thresholding
        impaddedsize = size( imPadded );

        pixsubind = cell(1,ndims(im));
        padimind = find( imPaddedMask > 0 );
        [pixsubind{:}] = ind2sub( impaddedsize, padimind );            
        pixsubind = cell2mat( pixsubind );

        boxOrigin = pixsubind - repmat( windowRadius, numel(im), 1 );           
        boxSize = 2 * windowRadius + 1;
        clear pixsubind;

        boxsum = 0;
        for i = 0:2^(ndims(im))-1
            b = dec2binarray(i,ndims(imIntegral));       
            cornerPixSubind = cell(1,ndims(im));
            for j = 1:ndims(im)
                if b(j)
                    cornerPixSubind{j} = boxOrigin(:,j) + boxSize(j) - 1;
                else
                    cornerPixSubind{j} = boxOrigin(:,j);
                end              
            end
            cornerPixInd = sub2ind( impaddedsize, cornerPixSubind{:} );
            boxsum = boxsum + (-1)^(ndims(im)-sum(b)) * imIntegral( cornerPixInd );              
        end            

        boxSize = prod( boxSize );            
        clear boxOrigin;

        meanBoxIntensity = boxsum ./ boxSize;
        clear boxsum boxSize;

    end        
    
    % adjust threshold values to the allowed threshold range
    thresh_vals = thresh_fraction * meanBoxIntensity;
    clear meanBoxIntensity;
    thresh_vals( thresh_vals < allowedThresholdRange(1) ) = allowedThresholdRange(1);
    thresh_vals( thresh_vals > allowedThresholdRange(2) ) = allowedThresholdRange(2);

    % apply threshold
    imThresh = zeros( size(im) );
    imThresh(:) = double( im(:) > thresh_vals );    
    
    % return actual threshold values if requested
    if nargout > 1 
       imThreshValues = zeros( size(im) );
       imThreshValues(:) = thresh_vals;
       imThreshValues = ImageIntensityRange(1) + range(ImageIntensityRange) * imThreshValues;
       varargout(1) = imThreshValues;
    end
    
end
