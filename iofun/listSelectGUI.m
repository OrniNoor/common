function varargout = listSelectGUI(varargin)
%LISTSELECTGUI launches a GUI to allow selection from a list
%
% SYNOPSIS [selection, selectionList] = listSelectGUI(inputList,moveOrCopy)
%
% INPUT    inputList   Cell, list of strings or numerical array from which
%                      the user is to select any number of items
%
%          moveOrCopy  optional argument. If 'move', entries are moved from
%                      the left to the right list, if 'copy' (default), the
%                      inputList always remains on the right
%
% OUTPUT   selection   Indices into inputList of selected items
%
%          selectionList   Cell array containing selected items


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @listSelectGUI_OpeningFcn, ...
    'gui_OutputFcn',  @listSelectGUI_OutputFcn, ...
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


% --- Executes just before listSelectGUI is made visible.
function listSelectGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to listSelectGUI (see VARARGIN)

% run opening function until we wait for figure to close.
% First, we write selectionList into the left listBox

% we allow numbers, strings and cells as input
if isempty(varargin) || isempty(varargin{1})
    % run termination routine
    handles.output = [];
    guidata(hObject,handles)
    h = errordlg('No input list for listSelectGUI')
    uiwait(h)
    close(hObject)
    return
end
inputList = varargin{1};

if iscell(inputList)
    listCell = inputList(:);
elseif ischar(inputList)
    listCell = cellstr(inputList);
elseif isnumeric(inputList)
    listCell = cellstr(num2str(inputList(:)));
else
    % run termination routine
    handles.output = [];
    guidata(hObject,handles)
    h = errordlg('Non-handled input for listSelectGUI');
    uiwait(h)
    close(hObject)
    return
end

% assign list
listLength = length(listCell);
set(handles.LSG_listboxLeft,'String',listCell,...
    'Max',listLength);
% store indexLists
handles.leftIndexList = [1:listLength]';
handles.rightIndexList = [];
% remember original list
handles.originalList = listCell;

% if second input argument: remember moveOrCopy (can be 'move' or 'copy')
if length(varargin) > 1 && ~isempty(varargin{2})
    moveOrCopy = varargin{2};
    if ~(strcmpi(moveOrCopy,'move')||strcmpi(moveOrCopy,'copy'))
        % run termination routine
        handles.output = [];
        guidata(hObject,handles)
        h = errordlg('second input argument has to be either ''move'' or '' copy''!');
        uiwait(h)
        close(hObject)
        return
    end
else
    moveOrCopy = 'copy';
end


% store moveOrCopy and update handles
handles.moveOrCopy = moveOrCopy;
guidata(hObject,handles);

% UIWAIT makes listSelectGUI wait for user response (see UIRESUME)
uiwait(handles.listSelectGUI);




% --- Outputs from this function are returned to the command line.
function varargout = listSelectGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% assign varargout if handles still exist
if isempty(handles) %if closed other than by button
    varargout{1} = [];
    varargout{2} = [];
else
    listCell = get(handles.LSG_listboxRight,'String');
    varargout{1} = handles.rightIndexList;
    varargout{2} = listCell;
    delete(handles.listSelectGUI)
end



% --- Executes on selection change in LSG_listboxLeft.
function LSG_listboxLeft_Callback(hObject, eventdata, handles)
% hObject    handle to LSG_listboxLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if we're getting here through single click: continue.
% on a double click, we'll run moveRight
if strcmp(get(handles.listSelectGUI,'SelectionType'),'normal')
    return
else
    hObject = handles.LSG_moveRight;
    LSG_moveRight_Callback(hObject,[],handles);
end


% --- Executes during object creation, after setting all properties.
function LSG_listboxLeft_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LSG_listboxLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in LSG_moveRight.
function LSG_moveRight_Callback(hObject, eventdata, handles)
% hObject    handle to LSG_moveRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% we only move right if there is something to be moved
if isempty(get(handles.LSG_listboxLeft,'String'))
    return
end

% get selection, merge with rightIndexList, and then read out from
% originalList
leftSelection = get(handles.LSG_listboxLeft,'Value');
rightIndexListNew = unique([handles.leftIndexList(leftSelection);...
    handles.rightIndexList]);
handles.rightIndexList = rightIndexListNew;
set(handles.LSG_listboxRight,'String',...
    handles.originalList(rightIndexListNew));
% set selection to first
set(handles.LSG_listboxLeft,'Value',1);

% if "move", update left list, too
if strcmpi(handles.moveOrCopy,'move')
    handles.leftIndexList(leftSelection) = [];
    if ~isempty(handles.leftIndexList)
        set(handles.LSG_listboxLeft,'String',...
            handles.originalList(handles.leftIndexList));
    else
        % assign empty to listbox for test at top
        set(handles.LSG_listboxLeft,'String','');
    end
end

guidata(hObject,handles)


% --- Executes on button press in LSG_moveLeft.
function LSG_moveLeft_Callback(hObject, eventdata, handles)
% hObject    handle to LSG_moveLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% we only move left if there is something to be moved
if isempty(get(handles.LSG_listboxRight,'String'))
    return
end

% get selection, merge with leftIndexList, and then read out from
% originalList if we're moving. Otherwise, everything is already on the
% left!
rightSelection = get(handles.LSG_listboxRight,'Value');
if strcmpi(handles.moveOrCopy,'move')
    leftIndexListNew = unique([handles.rightIndexList(rightSelection);...
        handles.leftIndexList]);
    handles.leftIndexList = leftIndexListNew;
    set(handles.LSG_listboxLeft,'String',...
        handles.originalList(leftIndexListNew));
end
% set selection to first
set(handles.LSG_listboxRight,'Value',1);

% update right list
handles.rightIndexList(rightSelection) = [];
if ~isempty(handles.rightIndexList)
    set(handles.LSG_listboxRight,'String',...
        handles.originalList(handles.rightIndexList));
else
    % assign empty to listbox for test at top
    set(handles.LSG_listboxRight,'String','');
end

guidata(hObject,handles)

% --- Executes on button press in LSG_Cancel.
function LSG_Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to LSG_Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% kill figure, which automatically uiresumes
delete(handles.listSelectGUI)

% --- Executes on button press in LSG_OK.
function LSG_OK_Callback(hObject, eventdata, handles)
% hObject    handle to LSG_OK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Everything ok -> just uiresume and go into outputFcn
uiresume(handles.listSelectGUI);




% --- Executes on button press in LSG_selAllRight.
function LSG_selAllRight_Callback(hObject, eventdata, handles)
% hObject    handle to LSG_selAllRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set selection to the whole length of the rightIndexList
entriesRight = max(length(handles.rightIndexList),1);
set(handles.LSG_listboxRight,'Value',[1:entriesRight]');


% --- Executes on button press in LSG_selInvLeft.
function LSG_selInvLeft_Callback(hObject, eventdata, handles)
% hObject    handle to LSG_selInvLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% invert selection
newSelection = [1:max(length(handles.leftIndexList),1)]';
newSelection(get(handles.LSG_listboxLeft,'Value')) = [];
if isempty(newSelection)
    newSelection = 1;
end
set(handles.LSG_listboxLeft,'Value',newSelection);


% --- Executes on button press in LSG_selAllLeft.
function LSG_selAllLeft_Callback(hObject, eventdata, handles)
% hObject    handle to LSG_selAllLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set selection to the whole length of the rightIndexList
entriesLeft = max(length(handles.leftIndexList),1);
set(handles.LSG_listboxLeft,'Value',[1:entriesLeft]');


% --- Executes on selection change in LSG_listboxRight.
function LSG_listboxRight_Callback(hObject, eventdata, handles)
% hObject    handle to LSG_listboxRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if we're getting here through single click: continue.
% on a double click, we'll run moveRight
if strcmp(get(handles.listSelectGUI,'SelectionType'),'normal')
    return
else
    hObject = handles.LSG_moveLeft;
    LSG_moveLeft_Callback(hObject,[],handles);
end


% --- Executes during object creation, after setting all properties.
function LSG_listboxRight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LSG_listboxRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in LSG_selInfRight.
function LSG_selInfRight_Callback(hObject, eventdata, handles)
% hObject    handle to LSG_selInfRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% invert selection
newSelection = [1:max(length(handles.rightIndexList),1)]';
newSelection(get(handles.LSG_listboxRight,'Value')) = [];
if isempty(newSelection)
    newSelection = 1;
end
set(handles.LSG_listboxRight,'Value',newSelection);


