function varargout = msgboxGUI(varargin)
% MSGBOXGUI M-file for msgboxGUI.fig
%      MSGBOXGUI, by itself, creates a new MSGBOXGUI or raises the existing
%      singleton*.
%
%      H = MSGBOXGUI returns the handle to a new MSGBOXGUI or the handle to
%      the existing singleton*.
%
%      MSGBOXGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MSGBOXGUI.M with the given input arguments.
%
%      MSGBOXGUI('Property','Value',...) creates a new MSGBOXGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before msgboxGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to msgboxGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help msgboxGUI

% Last Modified by GUIDE v2.5 07-Sep-2011 08:37:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @msgboxGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @msgboxGUI_OutputFcn, ...
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


% --- Executes just before msgboxGUI is made visible.
function msgboxGUI_OpeningFcn(hObject, eventdata, handles, varargin)
%
% fhandle = msgboxGUI
%
% fhandle = msgboxGUI(paramName, 'paramValue', ... )
%
% Help dialog GUI
% 
% Parameter Field Names:
%       'text' -> Help text
%       'title' -> Title of text box
%       'name'-> Name of dialog box
%

% Choose default command line output for msgboxGUI
handles.output = hObject;

% Parse input
ip = inputParser;
ip.CaseSensitive=false;
ip.addRequired('hObject',@ishandle);
ip.addRequired('eventdata',@(x) isstruct(x) || isempty(x));
ip.addRequired('handles',@isstruct);
ip.addParamValue('text','',@ischar);
ip.addParamValue('name','',@ischar);
ip.addParamValue('title','',@ischar);
ip.parse(hObject,eventdata,handles,varargin{:});

% Apply input
set(hObject, 'Name',ip.Results.name)
set(handles.edit_text, 'String',ip.Results.text)
set(handles.text_title, 'string',ip.Results.title)

% Update handles structure
uicontrol(handles.pushbutton_done)
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = msgboxGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)
delete(handles.figure1)


% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 'return'), delete(hObject); end
