function varargout = movieDataViewer(varargin)
% MOVIEDATAVIEWER MATLAB code for movieDataViewer.fig
%      MOVIEDATAVIEWER, by itself, creates a new MOVIEDATAVIEWER or raises the existing
%      singleton*.
%
%      H = MOVIEDATAVIEWER returns the handle to a new MOVIEDATAVIEWER or the handle to
%      the existing singleton*.
%
%      MOVIEDATAVIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MOVIEDATAVIEWER.M with the given input arguments.
%
%      MOVIEDATAVIEWER('Property','Value',...) creates a new MOVIEDATAVIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before movieDataViewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to movieDataViewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help movieDataViewer

% Last Modified by GUIDE v2.5 06-Jul-2011 16:08:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @movieDataViewer_OpeningFcn, ...
                   'gui_OutputFcn',  @movieDataViewer_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before movieDataViewer is made visible.
function movieDataViewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to movieDataViewer (see VARARGIN)

ip = inputParser;
ip.addRequired('hObject',@ishandle);
ip.addRequired('eventdata',@(x) isstruct(x) || isempty(x));
ip.addRequired('handles',@isstruct);
ip.addOptional('MD',[],@(x) isa(x,'MovieData'));
ip.addOptional('procId',0,@isscalar);
ip.parse(hObject,eventdata,handles,varargin{:});

userData=get(handles.figure1);
userData.MD=ip.Results.MD;
nChan=numel(userData.MD.channels_);

% Expand the window for checkboxes
set(handles.figure1,'Position',...
    get(handles.figure1,'Position')+2*(nChan-1)*[0 0 30 0])
set(handles.uipanel_image,'Position',...
    get(handles.uipanel_image,'Position')+(nChan-1)*[0 0 30 0])
set(handles.uipanel_overlay,'Position',...
    get(handles.uipanel_overlay,'Position')+(nChan-1)*[30 0 30 0])

% Classify processes
validProcId= find(cellfun(@(x) ismember('getDrawableOutput',methods(x)) &...
    x.success_,userData.MD.processes_));
validProc=userData.MD.processes_(validProcId);
isImageProc =cellfun(@(x) any(strcmp({x.getDrawableOutput.type},'image')),validProc);
imageProc=validProc(isImageProc);
imageProcId = validProcId(isImageProc);
isOverlayProc =cellfun(@(x) any(strcmp({x.getDrawableOutput.type},'overlay')),validProc);
overlayProc=validProc(isOverlayProc);
overlayProcId = validProcId(isOverlayProc);

% Create series of image processes
createProcText= @(panel,i,j,pos,name) uicontrol(panel,'Style','text',...
    'Position',[10 pos 200 20],'Tag',['text_process' num2str(i)],...
    'String',name,'HorizontalAlignment','left','FontWeight','bold');
createOutputText= @(panel,i,j,pos,text) uicontrol(panel,'Style','text',...
    'Position',[40 pos 200 20],'Tag',['text_process' num2str(i) '_output'...
    num2str(j)],'String',text,'HorizontalAlignment','left');
createChannelButton= @(panel,i,j,k,pos) uicontrol(panel,'Style','radio',...
    'Position',[200+30*k pos 20 20],'Tag',['radiobutton_process' num2str(i) '_output'...
    num2str(j) '_channel' num2str(k)]);
createChannelBox= @(panel,i,j,k,pos) uicontrol(panel,'Style','checkbox',...
    'Position',[200+30*k pos 20 20],'Tag',['checkbox_process' num2str(i) '_output'...
    num2str(j) '_channel' num2str(k)],...
    'Callback',@(h,event) checkOverlay(h,event,guidata(h)));

% Create image panel
parentPanel=handles.uipanel_image;
nProc = numel(imageProc);
hPosition1=10;
for iProc=nProc:-1:1;
    output=imageProc{iProc}.getDrawableOutput;
    validChan = imageProc{iProc}.checkChannelOutput;
    for iOutput=numel(output):-1:1
        createOutputText(parentPanel,imageProcId(iProc),iOutput,hPosition1,output(iOutput).name);
        arrayfun(@(x) createChannelButton(parentPanel,imageProcId(iProc),iOutput,x,hPosition1),...
            find(validChan));
        hPosition1=hPosition1+20;
    end
    createProcText(parentPanel,imageProcId(iProc),iOutput,hPosition1,imageProc{iProc}.getName);
    hPosition1=hPosition1+20;
end

% Create channels contorols
hPosition1=hPosition1+10;
uicontrol(parentPanel,'Style','radio','Position',[10 hPosition1 200 20],...
    'Tag','radiobutton_channels','String','Channels','Value',1,...
    'HorizontalAlignment','left','FontWeight','bold');
arrayfun(@(i) uicontrol(parentPanel,'Style','checkbox',...
    'Position',[200+30*i hPosition1 20 20],...
    'Tag',['checkbox_channel' num2str(i)],'Value',i<3,...
    'Callback',@(h,event) checkChannel(h,event,guidata(h))),...
    1:numel(userData.MD.channels_));
hPosition1=hPosition1+20;
arrayfun(@(i) uicontrol(parentPanel,'Style','text',...
    'Position',[200+30*i hPosition1 20 20],...
    'Tag',['text_channel' num2str(i)],'String',i),...
    1:numel(userData.MD.channels_));
set(parentPanel,'Position',get(parentPanel,'Position')+ [0 0 0 hPosition1],...
    'SelectionChangeFcn',@(h,event) redrawImage(h,event,guidata(h)))

% Create overlay panel
parentPanel=handles.uipanel_overlay;
hPosition2=10;
nProc = numel(overlayProc);
for iProc=nProc:-1:1;
    output=overlayProc{iProc}.getDrawableOutput;
    validChan = overlayProc{iProc}.checkChannelOutput;
    for iOutput=numel(output):-1:1
        createOutputText(parentPanel,overlayProcId(iProc),iOutput,hPosition2,output(iOutput).name);
        arrayfun(@(x) createChannelBox(parentPanel,overlayProcId(iProc),iOutput,x,hPosition2),...
            find(validChan));
        hPosition2=hPosition2+20;
    end
    createProcText(parentPanel,overlayProcId(iProc),iOutput,hPosition2,overlayProc{iProc}.getName);
    hPosition2=hPosition2+20;
end
arrayfun(@(i) uicontrol(parentPanel,'Style','text',...
    'Position',[200+30*i hPosition2 20 20],...
    'Tag',['text_channel' num2str(i)],'String',i),...
    1:numel(userData.MD.channels_));
set(parentPanel,'Position',get(parentPanel,'Position')+ [0 0 0 hPosition2])

hPos = max(hPosition1,hPosition2);
set(handles.figure1,'Position',get(handles.figure1,'Position')+...
    [0 0 0 hPos]);
components={'text_copyright','uipanel_movie'};
cellfun(@(x)set(handles.(x),'Position',get(handles.(x),'Position')+...
    [0 hPos 0 0]),components);

userData.drawFig=-1;
set(handles.edit_movie,'String',[userData.MD.movieDataPath_ filesep...
    userData.MD.movieDataFileName_]);
set(handles.edit_frame,'String',1);
set(handles.slider_frame,'Value',1,'Min',1,'Max',userData.MD.nFrames_,...
    'SliderStep',[1/double(userData.MD.nFrames_)  5/double(userData.MD.nFrames_)]);
set(handles.text_frameMax,'String',userData.MD.nFrames_);

% Auto select input process
if ismember(ip.Results.procId,validProcId)
    h=findobj(handles.figure1,'-regexp','Tag',['(\w)_process' num2str(ip.Results.procId) ...
        '_output(\d+)_channel(\d+)']);
    set(h,'Value',1);
end

copyright = userfcn_softwareConfig(handles);
set(handles.text_copyright, 'String', copyright);

% Choose default command line output for movieDataViewer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
set(handles.figure1,'UserData',userData);

% Update the image ad overlays
redrawImage(hObject, eventdata, handles);
redrawOverlays(hObject, eventdata, handles);

% UIWAIT makes movieDataViewer wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = movieDataViewer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function frameEdition(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');

% Retrieve the value of the selected image
if strcmp(get(hObject,'Tag'),'edit_frame')
    frameNumber = str2double(get(handles.edit_frame, 'String'));
else
    frameNumber = get(handles.slider_frame, 'Value');
end
frameNumber=round(frameNumber);
frameNumber = min(max(frameNumber,1),userData.MD.nFrames_);

% Set the slider and editboxes values
set(handles.edit_frame,'String',frameNumber);
set(handles.slider_frame,'Value',frameNumber);

% Update the image ad overlays
redrawImage(hObject, eventdata, handles);
redrawOverlays(hObject, eventdata, handles);


function checkChannel(hObject,event,handles)
% Callback of channels checkboxes to avoid 0 or more than 4 channels
channelBoxes = findobj(handles.figure1,'-regexp','Tag','checkbox_channel*');
chanList=find(arrayfun(@(x)get(x,'Value'),channelBoxes));
if numel(chanList)==0
    set(hObject,'Value',1);
elseif numel(chanList)>4
   set(hObject,'Value',0); 
end

redrawImage(hObject,event,handles)

function redrawImage(hObject, eventdata, handles)
userData=get(handles.figure1,'UserData');
frameNr=get(handles.slider_frame,'Value');

imageTag = get(get(handles.uipanel_image,'SelectedObject'),'Tag');

if ishandle(userData.drawFig), 
    figure(userData.drawFig); 
else 
    %Create a figure
    sz=get(0,'ScreenSize');
    ratios = [sz(3)/userData.MD.imSize_(2) sz(4)/userData.MD.imSize_(1)];
    userData.drawFig = figure('Position',[sz(3)*.2 sz(4)*.2 ...
        .6*min(ratios)*userData.MD.imSize_(2) .6*min(ratios)*userData.MD.imSize_(1)]);
    
    %Create the associate axes
    axes('Parent',userData.drawFig,'XLim',[0 userData.MD.imSize_(2)],'YLim',[0 userData.MD.imSize_(1)],...
        'Position',[0.05 0.05 .9 .9]);
end
set(handles.figure1,'UserData',userData);

channelBoxes = findobj(handles.figure1,'-regexp','Tag','checkbox_channel*');
if strcmp(imageTag,'radiobutton_channels')
    set(channelBoxes,'Enable','on');
    chanList=arrayfun(@(x)get(x,'Value'),channelBoxes);
    userData.MD.channels_(chanList).draw(frameNr);
else
    set(channelBoxes,'Enable','off');
    % Retrieve the id, process nr and channel nr of the selected imageProc
    tokens = regexp(imageTag,'radiobutton_process(\d+)_output(\d+)_channel(\d+)','tokens');
    procId=str2double(tokens{1}{1});
    outputList = userData.MD.processes_{procId}.getDrawableOutput;
    output = outputList(str2double(tokens{1}{2})).var;
    iChan = str2double(tokens{1}{3});
    userData.MD.processes_{procId}.draw(iChan,frameNr,'output',output);
end

function checkOverlay(hObject, eventdata, handles)
userData=get(handles.figure1,'UserData');
frameNr=get(handles.slider_frame,'Value');

overlayTag = get(hObject,'Tag');

if ishandle(userData.drawFig), figure(userData.drawFig); end
 % Retrieve the id, process nr and channel nr of the selected imageProc
tokens = regexp(overlayTag,'checkbox_process(\d+)_output(\d+)_channel(\d+)','tokens');
procId=str2double(tokens{1}{1});
outputList = userData.MD.processes_{procId}.getDrawableOutput;
iOutput = str2double(tokens{1}{2});
output = outputList(iOutput).var;
iChan = str2double(tokens{1}{3});
if get(hObject,'Value')
    userData.MD.processes_{procId}.draw(iChan,frameNr,'output',output);
else
    h=findobj('Tag',[userData.MD.processes_{procId}.getName '_channel'...
        num2str(iChan) '_output' num2str(iOutput)]);
    if ~isempty(h), delete(h); end
end

function redrawOverlays(hObject, eventdata, handles)
userData=get(handles.figure1,'UserData');
frameNr=get(handles.slider_frame,'Value');

figure(userData.drawFig);
overlayBoxes = findobj(handles.uipanel_overlay,'Style','checkbox');
checkedBoxes = logical(arrayfun(@(x) get(x,'Value'),overlayBoxes));
overlayTags=arrayfun(@(x) get(x,'Tag'),overlayBoxes(checkedBoxes),...
    'UniformOutput',false);
for i=1:numel(overlayTags)
    overlayTag=overlayTags{i};
    tokens = regexp(overlayTag,'checkbox_process(\d+)_output(\d+)_channel(\d+)','tokens');
    procId=str2double(tokens{1}{1});
    outputList = userData.MD.processes_{procId}.getDrawableOutput;
    output = outputList(str2double(tokens{1}{2})).var;
    iChan = str2double(tokens{1}{3});

    userData.MD.processes_{procId}.draw(iChan,frameNr,'output',output);
end


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)

userData=get(handles.figure1,'UserData');
try delete(userData.drawFig);end
