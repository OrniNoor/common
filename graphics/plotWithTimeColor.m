function plotWithTimeColor(trackedFeatureInfo,timeRange)
%PLOTWITHTIMECOLOR plots a group of tracks with time color-coding
%
%SYNOPSIS plotWithTimeColor(trackedFeatureInfo)
%
%INPUT  trackedFeatureInfo: Matrix indicating the positions and amplitudes 
%                           of the tracked features to be plotted. Number 
%                           of rows = number of tracks, while number of 
%                           columns = 6*number of time points. Each row 
%                           consists of 
%                           [x1 y1 a1 dx1 dy1 da1 x2 y2 a2 dx2 dy2 da2 ...]
%                           in image coordinate system (coordinates in
%                           pixels). NaN is used to indicate time points 
%                           where the track does not exist.
%       timeRange         : Time range to plot. Optional. Default: whole
%                           movie.
%
%OUTPUT no output variables, just the plot
%
%Khuloud Jaqaman, March 2006

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%check whether correct number of input arguments was used
if nargin < 1
    disp('--plotWithTimeColor: Incorrect number of input arguments!');
    return
end

%get number of tracks and number of time points
[numTracks,numTimePoints] = size(trackedFeatureInfo);
numTimePoints = numTimePoints/6;

errFlag = 0;

%check whether a time range for plotting was input
if nargin < 2 || isempty(timeRange)
    timeRange = [1 numTimePoints];
else
    if timeRange(1) < 1 || timeRange(2) > numTimePoints
        disp('--plotWithTimeColor: Wrong time range for plotting!');
        errFlag = 1;
    end
end

if errFlag
    disp('--plotWithTimeColor: Please fix input data!');
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Plotting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%calculate the number of time points to be plotted
numTimePlot = timeRange(2) - timeRange(1) + 1;

%get the fraction of each color in each time interval to be plotted
numTimePlotOver2 = ceil((numTimePlot-1)/2); %needed to change blue color over time
redVariation = [0:numTimePlot-2]'/(numTimePlot-2);
greenVariation = [numTimePlot-2:-1:0]'/(numTimePlot-2);
blueVariation = [[0:numTimePlotOver2-1]'/(numTimePlotOver2-1);...
    [numTimePlot-numTimePlotOver2-2:-1:0]'/(numTimePlot-numTimePlotOver2-1)];

%get the overall color per time interval
colorOverTime = [redVariation greenVariation blueVariation];

%get the x,y-coordinates of features in all tracks
tracksX = trackedFeatureInfo(:,1:6:end)';
tracksY = trackedFeatureInfo(:,2:6:end)';

%find the beginning and end of each track
startEndPos = zeros(2,2,numTracks);
for i=1:numTracks
    timePoint = find(~isnan(tracksX(:,i)));
    startInfo(i,:) = [tracksX(timePoint(1),i) ...
        tracksY(timePoint(1),i) timePoint(1)];
    endInfo(i,:) = [tracksX(timePoint(end),i) ...
        tracksY(timePoint(end),i) timePoint(end)];
end

%extract the portion of tracksX and tracksY that is of interest
tracksXP = tracksX(timeRange(1):timeRange(2),:);
tracksYP = tracksY(timeRange(1):timeRange(2),:);

%open figure and hold on
figure1 = figure;
hold on

%plot tracks ignoring missing points
for i=1:numTracks
    obsAvail = find(~isnan(tracksXP(:,i)));
    plot(tracksXP(obsAvail,i),tracksYP(obsAvail,i),'k:')
end

%place circles at track starts and squares at track ends if they happen to
%be in the plotting region of interest
indx = find(startInfo(:,3)>=timeRange(1) & startInfo(:,3)<=timeRange(2));
plot(startInfo(indx,1),startInfo(indx,2),'k.','marker','o');
indx = find(endInfo(:,3)>=timeRange(1) & endInfo(:,3)<=timeRange(2));
plot(endInfo(indx,1),endInfo(indx,2),'k.','marker','square');

%overlay tracks with color coding wherever a feature has been detected
for i=1:numTimePlot-1
    plot(tracksXP(i:i+1,:),tracksYP(i:i+1,:),'color',colorOverTime(i,:));
end

%ask the user whether she wants to click on figure and get frame
%information
userEntry = input('select points in figure? y/n ','s');

while strcmp(userEntry,'y')

    %let the user choose the points of interest
    [x,y] = getpts;

    %find the time points of the indicated points
    for i=1:length(x)
        distTrack2Point = (tracksXP-x(i)).^2+(tracksYP-y(i)).^2;
        [frameChosen,trackChosen] = find(distTrack2Point==min(distTrack2Point(:)));
        disp(['Coordinates: ' num2str(tracksX(frameChosen,trackChosen)) ' ' ...
            num2str(tracksY(frameChosen,trackChosen)) '   Frame: ' ...
            num2str(frameChosen+timeRange(1)-1)]);
    end

    %ask the user again whether she wants to click on figure and get frame
    %information
    userEntry = input('select points again? y/n ','s');

end

%hold off figure
hold off

%%%%% ~~ the end ~~ %%%%%

