classdef  MovieData < handle
% This is the movie management class definition
    properties (SetAccess = protected, GetAccess = public)
    % SetAccess = private - cannot change the values of variables outside object
    % GetAccess = public - can get the values of variables outside object without
    % definging accessor functions
    
    % Software defined data
    
        nFrames_                % Number of frames
        imSize_                 % Image size 1x2 array[width height]
        createTime_             % Time movie data is created
        
    % User defined data
        
        % ---- Used params ----
        
        channels_ = [];         % Channel object array - required from GUI **       
        outputDirectory_        % Output directory **
        movieDataPath_          % The path movie data is saved **
        movieDataFileName_      % The name movie data is saved **
        notes_                  % User's notes        
        pixelSize_              % Pixel size (nm)
        timeInterval_           % Time interval (s)
        numAperature_           % Numerical Aperature
        camBitdepth_            % Camera Bit-depth
        
        % ---- Un-used params ----
        magnification_
        binning_
        
    % Progress data
    
        processes_ = {};        % Process object cell array
        packages_ = {};         % Package object cell array

    end

    methods (Access = public)
        function obj = MovieData(channels, outputDirectory, movieDataPath, movieDataFileName, ...
                        notes, pixelSize, timeInterval, numAperature, camBitdepth, magnification, binning)
            if nargin > 0
                
                if isa(channels(1), 'Channel')
                    obj.channels_ = channels;
                else
                    error ('User-defined: Input channels should be of class ''Channel''')
                end
                
                if nargin > 1
                    if isempty(outputDirectory) || ischar(outputDirectory)
                        obj.outputDirectory_ = outputDirectory;
                    else
                        error ('User-defined: Output directory should be a string')
                    end
                end
                
                if nargin > 2
                    if isempty(movieDataPath) || ischar(movieDataPath)
                        obj.movieDataPath_ = movieDataPath;
                    else
                        error('User-defined: Movie Data path should be a string')
                    end
                end
                
                if nargin > 3
                    if isempty(movieDataFileName) || ischar(movieDataFileName)
                        obj.movieDataFileName_ = movieDataFileName;
                    else
                        error('User-defined: Movie Data file name should be a string')
                    end
                end
                
                if nargin > 4
                    obj.notes_ = notes;
                end               
                
                if nargin > 5
                    
                    if isempty(pixelSize) || (isnumeric(pixelSize) && pixelSize>0)
                        obj.pixelSize_ = pixelSize;
                    elseif ~isnan(str2double(pixelSize)) && str2double(pixelSize)>0
                        obj.pixelSize_ = str2double(pixelSize);
                    else
                        error('Pixel size should be a numeric and larger than zero')
                    end
                end
                
                if nargin > 6
                    if isempty(timeInterval) || ( isnumeric(timeInterval) && timeInterval>0 )
                        obj.timeInterval_ = timeInterval;
                    elseif ~isnan(str2double(timeInterval)) && str2double(timeInterval)>0
                        obj.timeInterval_ = str2double(timeInterval);                        
                    else
                       error('Time interval should be a numeric and larger than zero') 
                    end
                end
                
                if nargin > 7
                    if isempty(numAperature) || ( isnumeric(numAperature) && numAperature>0 )
                        obj.numAperature_ = numAperature;
                    elseif ~isnan(str2double(numAperature)) && str2double(numAperature)>0
                        obj.numAperature_ = str2double(numAperature);                        
                    else
                       error('Numerical aperature should be a numeric and larger than zero') 
                    end                    
                end
                
                if nargin > 8
                    if isempty(camBitdepth) || ( isnumeric(camBitdepth) && camBitdepth>0 && ~mod(camBitdepth, 2))
                        obj.camBitdepth_ = camBitdepth;
                    elseif ~isnan(str2double(camBitdepth)) && str2double(camBitdepth)>0 && ~mod(str2double(camBitdepth),2)
                        obj.camBitdepth_ = str2double(camBitdepth);                         
                    else
                       error('Invalid value for Camera Bit-depth. Should be a numeric larger than zero and multiple of 2.') 
                    end                      
                end
                
                if nargin > 9
                    if isempty(magnification) || ( isnumeric(magnification) && magnification>0 )
                        obj.magnification_ = magnification;
                    elseif ~isnan(str2double(magnification)) && str2double(magnification)>0
                        obj.magnification_ = str2double(magnification);                        
                    else
                       error('Magnification should be a numeric and larger than zero') 
                    end
                end     
                
                if nargin > 10
                    if isempty(binning) || ( isnumeric(binning) && binning>0 )
                        obj.binning_ = binning;
                    elseif ~isnan(str2double(binning)) && str2double(binning)>0
                        obj.binning_ = str2double(binning);                        
                    else
                       error('Binning should be a numeric and larger than zero') 
                    end
                end                  
                
            else
                error('User-defined: Please provide at least channel parameters to create a MovieData object')
            end
            
            obj.createTime_ = clock;
        end

        function sanityCheck(obj, movieDataPath, movieDataFileName)
        % 1. Sanity check (user input, input channels, image files)
        % 2. Assignments to 4 properties:
        %       movieDataPath_
        %       movieDataFileName_
        %       nFrames_
        %       imSize_
           
            
            % Check if the path and filename stored in the movieData are the same
            % as the ones provided in argument. They can differ if the movieData
            % MAT file has been rename, move or copy to another location.
            if nargin > 1
                
                if  ~strcmp(obj.movieDataPath_, movieDataPath)
                    obj.movieDataPath_ = movieDataPath;
                end
            
                if  ~strcmp(obj.movieDataFileName_, movieDataFileName)
                    obj.movieDataFileName_ = movieDataFileName; 
                end
            
            end
            width = zeros(1, length(obj.channels_));
            height = zeros(1, length(obj.channels_));
            nFrames = zeros(1, length(obj.channels_));
            
            for i = 1: length(obj.channels_)
                [width(i) height(i) nFrames(i)] = obj.channels_(i).sanityCheck;
            end
            
            assert(max(nFrames) == min(nFrames), ...
                'Different number of frames are detected in different channels. Please make sure all channels have same number of frames.')
            
            assert(max(width)==min(width) && max(height)==min(height), ...
                'Image sizes are inconsistent in different channels.\n\n')

		
            % Define imSize_ and nFrames_;     
            if ~isempty(obj.nFrames_)
                assert(obj.nFrames_ == nFrames(1), 'Record shows the number of frames has changed in this movie.')
            else
                obj.nFrames_ = nFrames(1);
            end
            
            if ~isempty(obj.imSize_)
                assert(obj.imSize_(1) == width(1) && obj.imSize_(2) ==height(1), 'Record shows image size has changed in this movie.')
            else
                obj.imSize_ = [width(1) height(1)];
            end

        end
        
        % Functions to manipulate process object array
        function addProcess(obj, newprocess)
            % Add a process to the processes_ array
            obj.processes_ = horzcat(obj.processes_, {newprocess});
        end
        
        function deleteProcess(obj, process)
           % Delete and clear given process object in movie data's process array
           %
           % Input:
           %        process - Process object or index of process to be
           %                  deleted in movie data's process list

            if isa(process, 'Process')
                
                id = find(cellfun(@(x)isequal(x, process), obj.processes_));
                if isempty(id)
                    error('User-defined: The given process is not in current movie data''s process list.')

                elseif length(id) ~=1
                   error('User-defined: There should be one identical maskrefinement processes exists in movie data''s process list.') 
                end                
                
            % Make sure process is a integer index   
            elseif isnumeric(process) && process == round(process)...
                    && process>0 && process<=length(obj.processes_)
                
                id = process;
            else
                error('Please provide a Process object or a valid process index of movie data''s process list.')
            end
            
            % Delete and clear the process object
            delete(obj.processes_{id})
            obj.processes_(id) = [ ];
            
        end
            
        function iProc = getProcessIndex(obj,procName,nDesired,askUser)
            %Find the index of a process or processes with given class name
            
            if nargin < 2 || isempty(procName)
                error('You must specify a process class name!')
            end            
            if nargin < 3 || isempty(nDesired)
                nDesired = 1;
            end
            if nargin < 4 || isempty(askUser)
                askUser = true;
            end
            if isempty(obj.processes_)
                iProc = [];
                return
            end
            
            iProc = find(arrayfun(@(x)(isa(obj.processes_{x},procName)),1:numel(obj.processes_)));
            nProc = numel(iProc);
            %If there are only nDesired or less processes found, return
            %them.
            if nProc <= nDesired
                return
            elseif nProc > nDesired 
                if askUser
                    isMultiple = nDesired > 1;
                    procNames = cellfun(@(x)(x.name_),...
                        obj.processes_(iProc),'UniformOutput',false);
                    iSelected = listdlg('ListString',procNames,...
                                'SelectionMode',isMultiple,...
                                'ListSize',[400,400],...
                                'PromptString',['Select the desired ' procName ':']);
                    iProc = iProc(iSelected);
                    if isempty(iProc)
                        error('You must select a process to continue!');
                    end
                else
                    warning(['More than ' num2str(nDesired) ' ' ...
                        procName 'es were found! Returning most recent process(es)!'])
                    iProc = iProc(end:(end-nDesired+1));
                end                                
            end
            
            
        end
        % Functions to manipulate package object array
        function addPackage(obj, newpackage)
            % Add a package to the packages_ array
            obj.packages_ = horzcat(obj.packages_ , {newpackage});
        end

        function setPackage(obj, i, package)
            % Set the i th package in packages_ array
            assert( i <= length(obj.packages_), ...
                'Index of package exceeds dimension of packages_ array');
                delete(obj.packages_{i});
                obj.packages_{i} = package;
        end
        
        function setMovieDataPath(obj, path)
            obj.movieDataPath_ = path;
        end
        
        function setMovieDataFileName(obj, file)
            obj.movieDataFileName_ = file;
        end        
        
        function setNotes (obj, text)
            obj.notes_ = text;
        end
        
        function fileNames = getImageFileNames(obj,iChan)
            if nargin < 2 || isempty(iChan)
                iChan = 1:numel(obj.channels_);
            end            
            if isnumeric(iChan) && min(iChan)>0 && max(iChan) <= ...
                    numel(obj.channels_) && isequal(round(iChan),iChan)                
                fileNames = arrayfun(@(x)(imDir(obj.channels_(iChan(x)).channelPath_)),1:numel(iChan),'UniformOutput',false);
                fileNames = cellfun(@(x)(arrayfun(@(x)(x.name),x,'UniformOutput',false)),fileNames,'UniformOutput',false);
                nIm = cellfun(@(x)(length(x)),fileNames);
                if ~all(nIm == obj.nFrames_)                    
                    error('Incorrect number of images found in one or more channels!')
                end                
            else
                error('Invalid channel numbers! Must be positive integers less than the number of image channels!')
            end
            
        end
        function chanPaths = getChannelPaths(obj,iChan)
            %Returns the directories for the selected channels as a cell
            %array or character strings
            nChanTot = numel(obj.channels_);
            if nargin < 2 || isempty(iChan)                
                iChan = 1:nChanTot;
            elseif (max(iChan) > nChanTot) || min(iChan) < 1 || ~isequal(round(iChan),iChan)
                error('Invalid channel index specified! Cannot return path!');                
            end
            nChan = numel(iChan);
            chanPaths = cell(1,nChan);
            for j = 1:nChan
                %Make sure the channel is OK                
                obj.channels_(iChan(j)).sanityCheck;                    
                %Get the path
                chanPaths{j} = obj.channels_(iChan(j)).channelPath_;                
            end
            
        end
        function saveMovieData(MD)
           % Save movie data to disk. Movie data variable must be named 'MD'
           
           %First, check if there is an existing file. If so, save a
           %backup.
           if exist([MD.movieDataPath_ filesep MD.movieDataFileName_],'file');
               copyfile([MD.movieDataPath_ filesep MD.movieDataFileName_],...
                    [MD.movieDataPath_ filesep MD.movieDataFileName_(1:end-3) 'old'])
           end
           save([MD.movieDataPath_ filesep MD.movieDataFileName_],'MD')
        end
    end
    
    methods (Static)
        function text = getHelp()
           text = sprintf('Select Movie Data:\n\nYou can either create new movie data or open existing movie data (or movie data list). Multiple movie data is supported in this release. To review the details of a movie, select a movie data and click "Detail" button.\n\n\nMovie Data List:\n\nMovie data list is a list of movie data you want to specify and process together. The current movie data in the listbox can be saved as a movie data list by clicking "Save as Movie Data List" button.  The movie data list will be saved as a MAT file. To load the multiple movie data at once, just open the saved movie data list MAT file. Note that movie data list only copies the directories of movie data instead of the movie data itself.\n\n\nPackage:\n\nYou can select one of the packages to process your data. Click "Apply" to go to package control panel.'); 
        end
    end
    
end