function [r,r_value, magnitude] = interpft_roots(x,dim,sorted,TOL,dofft)
% interpft_roots finds the roots of the function when interpolated by fourier transform
% This is the equivalent of doing sinc interpolation.
%
% INPUT
% x - regularly sampled values to be interpolated.
%     Values are considered to be sampled at (0:length(x)-1)*2*pi/length(x)
% dim - dimension along which to find maxima
% sorted - logical value about whether to sort the maxima by value
% TOL - tolerance to determine if log(abs(root)) is zero to determine if
%       the root of the derivative is real.
%       If tolerance is negative, then use 10*abs(log(abs(root))) as the
%       tolerance only if no roots are found with tolerance at -TOL.
% dofft - logical. If true, transforms dim with fft. Default: true
%
% OUTPUT
% maxima - angle between 0 and 2*pi indicating location of local maxima
% minima - angle between 0 and 2*pi indicating location of local minima
% maxima_value - value of interpolated function at maxima
% minima_value - value of interpolated function at minima
% other - angle between 0 and 2*pi where second derivative is zero
% other_value - value of interpolated function at other
%
% If no output is requested, then the maxima and minima will be plotted.
% Maxima are indicated by a red vertical line and red circle.
% Minima are indicated by a green vertical line and a green circle
%
% 1D Example
%
% r = rand(7,1);
% figure;
% plot((0:length(r)-1)/length(r)*2*pi,r,'ko');
% hold on;
% plot((0:199)/200*2*pi,interpft(r,200),'k');
% interpft_extrema(r);
% hold off;
%
% 2D Example
% r = rand(11,3);
% figure;
% plot((0:size(r,1)-1)/size(r,1)*2*pi,r,'ko');
% hold on;
% plot((0:199)/200*2*pi,interpft(r,200),'k');
% interpft_extrema(r);
% hold off;
% 
% This function works by calculating a fourier series of degree length(x)
% that fits through the input points. Then the fourier series is then considered
% as a trigonometric polynomial and the roots are solved by evaluating the eigenvalues
% of a companion matrix via the builtin function roots.
%
% See also interpft, roots
%
% Author: Mark Kittisopikul, May 2016
    
%     original_size = size(x);
    if(nargin > 1 && ~isempty(dim))
        x = shiftdim(x,dim-1);
        unshift = ndims(x) - dim + 1;
    else
        if(isrow(x))
            % If the input is a row vector, transpose it without conjugation
            dim = 2;
            unshift = 1;
            x = x.';
        else
            dim = 1;
            unshift = 0;
        end
    end
    
    if(nargin < 3 || isempty(sorted))
        sorted = false;
    end
    if(nargin < 4 || isempty(TOL))
    	% Tolerance for log(abs(root)) to be near zero, in which case the root is real
        % Set negative so that tolerance adapts if no roots are found
        TOL = -eps(class(x))*1e3;
    end
    if(nargin < 5 || isempty(dofft))
        dofft = true;
    end



    output_size = size(x);
    output_size(1) = output_size(1) - 1;
    

    s = size(x);
    scale_factor = s(1);
    
    if(s(1) == 1)
        r = shiftdim(zeros(s),unshift);
        r_v = shiftdim(s,unshift);
%         maxima = shiftdim(zeros(s),unshift);
%         minima = maxima;
%         other = maxima;
%         maxima_value = shiftdim(x,unshift);
%         minima_value = maxima_value;
%         other_value = maxima_value;
        return;
    end

    % Calculate fft and nyquist frequency
    if(dofft)
        x_h = fft(x);
    else
        x_h = x;
    end
    nyquist = ceil((s(1)+1)/2);

    % If there is an even number of fourier coefficients, split the nyquist frequency
    if(~rem(s(1),2))
        % even number of coefficients
        % split nyquist frequency
        x_h(nyquist,:) = x_h(nyquist,:)/2;
        x_h = x_h([1:nyquist nyquist nyquist+1:end],:);
        x_h = reshape(x_h,[s(1)+1 s(2:end)]);
        output_size(1) = output_size(1) + 1;
    end
    % Wave number, unnormalized by number of points
    freq = [0:nyquist-1 -nyquist+1:1:-1]';

    % calculate derivatives, unscaled by 2*pi since we are only concerned with the signs of the derivatives
%     dx_h = bsxfun(@times,x_h,freq * 1i);
%     dx2_h = bsxfun(@times,x_h,-freq.^2);
    
    % use companion matrix approach
    x_h = -fftshift(x_h,1);
    x_h = x_h(:,:);
%     r = zeros(output_size,'like',dx_h);
    output_size1 = output_size(1);
    nProblems = prod(output_size(2:end)); 
    batchSize = min(1024,nProblems);
    nBatches = ceil(nProblems/batchSize);
    % Only use parallel workers if a pool already exists
    nWorkers = ~isempty(gcp('nocreate'))*nBatches;
    in = ones(1,nBatches)*batchSize;
    in(end) = in(end) + nProblems - sum(in);
    x_h = mat2cell(x_h,size(x_h,1),in);
    r = cell(1,nBatches);
    parfor (i=1:nBatches, nWorkers)
        r{i} = zeros(output_size1,size(x_h{i},2),'like',x_h{i});
        for j = 1:size(x_h{i},2);
            try
                % roots outputs only column vectors which may be shorter than
                % expected
                dx_h_roots = roots(x_h{i}(:,j));
                dx_h_roots(end+1:output_size1) = 0;
                r{i}(:,j) = dx_h_roots;
            catch err
                switch(err.identifier)
                    case 'MATLAB:ROOTS:NonFiniteInput'
                        r{i}(:,j) = NaN(output_size1,1);
                end
            end
        end
    end
    r = [r{:}];
    r = reshape(r,output_size);
    % magnitude
    magnitude = abs(log(abs(r)));
    % keep only the real answers
%     real_map = (magnitude <= abs(TOL));
    % If tolerance is negative and no roots are found, then use the
    % root that is closest to being real
%     if(TOL < 0)
%         no_roots = ~any(real_map);
%         real_map(:,no_roots) = bsxfun(@le,magnitude(:,no_roots),min(magnitude(:,no_roots))*10);
%     end
%     r(imaginary_map) = NaN;
%     real_map = ~imaginary_map;
%     clear imaginary_map
    
   
    % In the call to roots the coefficients were entered in reverse order (negative to positive)
    % rather than positive to negative. Therefore, take the negative of the angle..
    % angle will return angle between -pi and pi
    
%     r = -angle(r(real_map));
    r_value = r;
    r = -angle(r);
    
    % Map angles to between 0 and 2 pi, moving negative values up
    % a period
    neg_roots = r < 0;
    r(neg_roots) = r(neg_roots) + 2*pi;
    
%     roots = r;
    
%     extrema = NaN(output_size);
%     extrema(real_map) = r;

end