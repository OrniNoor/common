function [cpar,pvr,dpvr] = ClusterQuantRipley (mpm,imsizex,imsizey)
% ClusterQuantRipley calculates a quantitative clustering parameter based on
% fractal theory
%
% SYNOPSIS   [cpar,pvr,dpvr] = ClusterQuantRipley (mpm,imsizex,imsizey)
%       
% INPUT      mpm:   mpm file containing (x,y) coordinates of points in the
%                   image in succesive columns for different time points
%            imsizex:   x-size of the image (maximum possible value for x-coordinate)
%            imsizey:   y-size of the image (maximum possible value for
%                       y-coordinate)
%            NOTE: in Johan's mpm-files, the image size is 1344 x 1024
%               pixels
%
%
% OUTPUT     cpar:  for each time point, a single clustering parameter 
%                   value is extracted from the pvr function  
%            pvr:   for each plane (time point), the function calculates
%                   the function pvr=points vs radius, i.e. the number of
%                   points contained in a circle of increasing radius
%                   around an object, averaged over all objects in the
%                   image
%                   NOTE: the default size for the radius implicit in the 
%                   pvr function is [1,2,3...,minimsize] where minimsize is the
%                   smalller dimension of imsizex,imsizey
%                   This function corresponds to Ripley's K-function (/pi)
%            dpvr:  pvr difference function; this function corresponds to 
%                   the L-function (or more precisely ld-d); the x^2
%                   function corresponding to a Poisson random clustering
%                   is corrected for (corr. to zero line)
%
% DEPENDENCES   FractClusterQuant uses {pointsincircle,clusterpara}
%               FractClusterQuant is used by { }
%
% Revision History
% Name                  Date            Comment
% --------------------- --------        --------------------------------------------------------
% Dinah Loerke          Sep 04          Initial version
% Andre Kerstens        Oct 04          Fixed some typos in the comment header

%create vector containing x- and y-image size
matsiz=[imsizex imsizey];

%determine size of mpm-file
[nx,ny]=size(mpm);

%initialize results matrix pvr; x-dimension equals the employed number of
%values for the circle radius, y-dimension equals number of planes of the
%input mpm-file
pvr=zeros(min(matsiz),(ny/2));
dpvr=zeros(min(matsiz),(ny/2));
cpar=[1:(ny/2)];

%initialize temporary coordinate matrix matt, which contains the object 
%coordinates for one plane of the mpm
matt=zeros(nx,2);

%cycle over all planes of series, using two consecutive columns of mpm input
%matrix as (x,y) coordinates of all measured points
for k=1:(round(ny/2))
    
    %matt is set to two consecutive columns of input matrix m1
    matt(:,:)=mpm(:,(2*k-1):(2*k));
    
    %since the original mpm file contains a lot of zeros, these zeros are 
    %deleted in the temporary coordinate matrix to yield a matrix containing
    %only the nonzero points of matt, smatt
    smatt=[nonzeros(matt(:,1)), nonzeros(matt(:,2)) ];
    
    %uncomment the next five lines if you want to monitor progress
    [smx,smy]=size(smatt);
    tempnp=max([smx,smy]);
    disp('  plane  number of objects');
    tempi=[k, tempnp];
    disp(tempi);
    
    %now determine number of objects in circle of increasing radius,
    %averaged over all objects in smatt, and normalized with point density
    %tempnp/(msx*msy)
    [pvrt]=pointsincircle(smatt,matsiz);
    %result is anormalized with point density tempnp/(msx*msy)
    %within the function fract_np_vs_rad
    pvr(:,k)=pvrt(:);
    
    %from the current shape of pvrt, calculate a quantitative clustering
    %parameter, cpar
    [cpar(k),dpvr(:,k)]=clusterpara(pvrt);
        
end




function[cpar,dpvrt]=clusterpara(pvrt);
%clusterpara calculates a quantitative cluster parameter from the input
%function (points in circle) vs (circle radius)
% SYNOPSIS   [cpar]=clusterpara(pvrt);
%       
% INPUT      pvrt:   function containing normalized point denisty in 
%                   circle around object
%                   spacing of points implicitly assumes radii of 1,2,3...
%   
% OUTPUT     cpar:    cluster parameter
%            dpvrt:   difference function of p vs r
%
% DEPENDENCES   clusterpara uses {DiffFuncParas}
%               clusterpara is used by {FractClusterQuant}
%
% Dinah Loerke, September 13th, 2004

%calculate difference L(d)-d function, using L(d)=sqrt(K(d))
%since K(d) is already divided by pi
len=max(size(pvrt));
de=(1:1:len);
diff=sqrt(abs(pvrt))-de;
dpvrt=diff;
%extract parameters from diff
[cpar1,cpar2]=DiffFuncParas(diff);
%the following can be changed to accomodate additional parameters as 
%measure of the clustering
cpar=cpar1;
    

    
function[p1,p2]=DiffFuncParas(diff);
%DiffFuncParas calculates a number of quantitative cluster parameter 
%from the input function, the difference function
% SYNOPSIS   DiffFuncParas(diff);
%       
% INPUT      diff:  difference function as calculated in clusterpara
%                   vector with len number of points
%%   
% OUTPUT     p1,p2:  cluster parameters
%                    currently: p1=integrated positive intensity (measure
%                               of total clustering)
%                               p2=maximum of difference function (measure
%                               of mean distance between objects)
%
% DEPENDENCES   DiffFuncParas uses {}
%               DiffFuncParas is used by {clusterpara}
%
% Dinah Loerke, September 13th, 2004

len=max(size(diff));
p1=0;
p2=0;
for i=1:len
    if(diff(i)>0)
        p1=p1+diff(i);
        if(diff(i)==max(diff))
            p2=diff(i);
        end
    end
end



function[m2]=pointsincircle(m1,ms)
%pointsincircle calculates the average number of points in a circle around
%a given point as a function of the circle radius (averaged over all points
%and normalized by total point density); derived from fractal theory, this
%function is an indication of the amount of clustering in the point
%distribution
% 
% SYNOPSIS   [m2]=pointsincircle(m1,ms);
%       
% INPUT      m1:   matrix of size (n x 2) containing the (x,y)-coordinates of n
%                  points
%            ms: vector containing the parameters [imsizex imsizey] (the 
%                   x-size and y-size of the image)
%            NOTE: in Johan's mpm-files, the image size is 1344 x 1024
%               pixels
%
%
% OUTPUT     m2:    vector containing the number of points in a circle 
%                   around each point, for an increasing radius;
%                   radius default values are 1,2,3,....,min(ms)
%                   function is averaged over all objects in the
%
% DEPENDENCES   pointsincircle uses {area_snippedcircleG, distanceMatrix, threshold}
%                   (distanceMatrix, threshold added to this file)
%               pointsincircle is used by {FractClusterQuant }
%
% Dinah Loerke, September 13th, 2004


[lm,wm]=size(m1);

%for points at the edges (where the circle of increasing size is cut off by
%the edges of the image), this function corrects for the reduced size of 
%the circle
%actual circle size (area of the snipped circle) is calculated using the 
%function

%for each point, determine area of circle with function 
%[aa]=area_snippedcircle(rr,x,y,msx,msy)

msx=ms(1);
msy=ms(2);
minms=min(ms);

%create neighbour matrix m3
%matrix m3 contains the distance of all points in m1 from all points
%in itself
[mdist]=distanceMatrix(m1,m1);

%create numpoints vector (number of points in circle of corresponding radius)
%loop over all radius values between 1 and minms
%initialize m2 vector
m2=1:minms;

for r=1:minms
    %for given radius, set all values of m3 higher than the radius value to zero
    [thresh_mdist]=threshold(mdist,r);
        
    %average over all points in the image, i.e. loop over all rows 
    %(or all columns) in thresh_mdist
    %initialize npv (sum of points) parameter
    npv=0;
    for n=1:lm
        %for a given point (i.e. a given row of the mdist matrix),
        %look for the number of points with distance less than r (=npvt),
        %which is the number of non-zero points in the thresholded matrix
        temp=thresh_mdist(n,:);
        findv=find(temp);
        [o,npvt]=size(findv);
        %now determine the area of the (possibly snipped) circle of radius 
        %r around this particular point to determine a correction factor
        %using function area_snippedcircleG
        %(npvt is the number of objects found in the real image (a circle 
        %possibly cut of cut off by a rectangle, i.e. the edges of the 
        %image), whereas npvt/corrfac is the projected number of objects
        %found in unsnipped circle of radius r
        x=m1(n,1);
        y=m1(n,2);
        carea=area_snippedcircleG(r,x,y,msx,msy);
        corrfac=carea/(pi*r^2);
        if(corrfac==0)
            disp('carea=0 Check if you have msx, msy entered in the correct order!!');
        end
        %add number of points npvt weighted by the correction factor
        %corrfac to the sum of points
        npv=npv+(npvt/corrfac);
    end
    
    %to average, divide sum by number of points
    npv=(npv/lm);
    
    %in order to be able to quantitatively compare the clustering in 
    %distributions of different point densities, this npv value must now 
    %be corrected for overall point density, which is lm/msx*msy; the 
    %resulting normalized function is (if we also divide by pi to scale for
    %the circle area) more or less a simple square function;
    %it is a perfect square function for a perfectly random distribution of
    %points
    m2(r)=npv/(pi*lm/(msx*msy));
    end


  

function[m2]=distanceMatrix(c1,c2)
%this subfunction makes a neighbour-distance matrix for input matrix m1
%input: c1 (n1 x 2 points) and c2 (n2 x 2 points) matrices containing 
%the x,y coordinates of n1 or n2 points
%output: m2 (n1 x n2) matrix containing the distances of each point in c1 
%from each point in c2
[ncx1,ncy1]=size(c1);
[ncx2,ncy2]=size(c2);
m2=zeros(ncx1,ncx2);
for k=1:ncx1
    for n=1:ncx2
        d=sqrt((c1(k,1)-c2(n,1))^2+(c1(k,2)-c2(n,2))^2);
        m2(k,n)=d;
    end
end

    

function[m2]=threshold(m1,t)
%this subfunction thresholds matrix m1 to value t (sets all values 
%exceeding t to zero)
%input: m1 (n x m) matrix containing distance values
%output: m2 (n x m) matrix containing all distance values
%below threshold value t, others are set to zero

[n,m]=size(m1);
m2=m1;
for k=1:n
    for n=1:m
        if(m1(k,n)>t)
            m2(k,n)=0;
        end
    end
end


function[aa]=area_snippedcircleG(rr,x,y,msx,msy)
%function[a]=area_snippedcircle(r,x,y)
%calculates the are of a snipped circle
%i.e. circle center is placed into rectangle (of size msx,msy)
%depending on radius, area of circle is limited by rectangle
%radius of circle = r
%position of cricle center = x,y
%size of rectangle msx,msy
%GEOMETRIC SOLUTION
%DEPENDENCES   area_snippedcircleG is used by pointsincircle 

rsiz=size(rr);
aa=rr;
for ii=1:rsiz
%geometrical:
    r=rr(ii);
    %loop over four quadrants
    %for each quadrant, we consider the intersection area of: 
    %A the circle of radius r around the origin (here at x,y), and 
    %B the rectangle representing the image size in this quadrant
    %The rectangle is defined by two points: the origin at (x,y) 
    %and the corresponding corner of the field of view (0,0), (msx,0),
    %(msx,msy), and (0,msy) for the respective quadrant
    %thus, the side lenghths of the rectangle are calculated below
    avector=[1:4];
    for q=1:4
        if(q==1)
            X=x;
            Y=y;
        elseif(q==2)
            X=msx-x;
            Y=y;
        elseif(q==3)
            X=msx-x;
            Y=msy-y;
        elseif(q==4)
            X=x;
            Y=msy-y;
        end
        %if the circle is fully inside the rectangle, the area of the
        %quadrant is a simple quarter circle
        aq=(1/4)*(pi*r^2);
        %if the quadrant's corner is inside the circle, then the quadrant 
        %area is the area of the rectangle
        if(sqrt(X^2+Y^2)<=r)
            aq=X*Y;
        %else the quadrant's corner is outside the circle, but not far enough
        %for the circle to be "undamaged"; thus, the quadrant area is a 
        %quarter circle with a chunk snipped away
        %the chunk is calculated geometrically as below
        else
            if(X<r)
                xchunk=pi*r^2*( 0.25-(asin(X/r))/(2*pi) )-0.5*X*sqrt(r^2-X^2);
                aq=aq-xchunk;
            end
            if(Y<r)
                ychunk=pi*r^2*( 0.25-(asin(Y/r))/(2*pi) )-0.5*Y*sqrt(r^2-Y^2);
                aq=aq-ychunk;
            end
        end
        avector(q)=aq;            
    end
    %for each radius, the total area is the sum over the four quadrants
    aa(ii)=sum(avector);
end
    
    

        
    
    
    
    
