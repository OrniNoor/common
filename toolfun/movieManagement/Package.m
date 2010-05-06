classdef Package < handle 
% Defines the abstract class Package from which every user-defined packages 
% will inherit. This class cannot be instantiated.
    properties (SetAccess = private, GetAccess = public)
    % SetAccess = private - cannot change the values of variables outside object
    % GetAccess = public - can get the values of variables outside object without
    % defining accessor functions
    %
    % Objects of sub-class of Package cannot change variable values since 
    % 'SetAccess' attribute is set to private
        name_  % the name of instantiated package
        createTime_ % The time when object is created. Same output as 
                    % function 'clock' 
    end
    properties(SetAccess = protected, GetAccess = public)
        owner_ % The MovieData object this package belongs to
        % Cell array containing all processes who will be used in this package
        processes_ 
        processClassNames_ % Must have accurate process class name
                           % List of processes required by the package, 
                           % Cell array - same order and number of elements
                           % as processes in dependency matrix
        depMatrix_ % Processes' dependency matrix
        notes_ % The notes users put down
    end
    
    methods (Access = protected)
        function obj = Package(owner, name, depMatrix, processClassNames)
            % Constructor of class Package
            
            if nargin > 0
                obj.name_ = name;
                obj.owner_ = owner; 
                obj.depMatrix_ = depMatrix;
                obj.processClassNames_ = processClassNames;
                
                obj.processes_ = cell(1,length(processClassNames));
                obj.createTime_ = clock;
            end
        end
        function processExceptions = checkProcesses(obj, full, procID) 
            % checkProcesses is called by package's sanitycheck. It returns
            % a cell array of exceptions. Keep in mind, make sure all process 
            % objects of processes checked in the GUI exist before running
            % package sanitycheck. Otherwise, it will cause a runtime error
            % which is not caused by algorithm itself.
            %
            % The following steps will be checked in this function
            %   1. The process itself has a problem
            %   2. The parameters in the process setting panel have changed
            %   3. The process that current process depends on has a
            %      problem
            %
            % OUTPUT:
            %   processExceptions - a cell array with same length of
            % processClassNames_. It collects all the exceptions found in
            % sanity check. Exceptions of i th process will be saved in
            % processExceptions{i}
            %
            % INPUT:
            %   obj - package object
            %   full - ture   check 1,2,3 steps 
            %          false  check 2,3 steps
            %   procID - A. Numeric array: id of processes for sanitycheck
            %            B. String 'all': all processes will do 
            %                                      sanity check 
            %

            nProcesses = length(obj.processClassNames_);
            processExceptions = cell(1,nProcesses);
            processVisited = false(1,nProcesses);
            
            if nargin < 2
                full = true;
                procID = 1:nProcesses;
            end
            if nargin < 3
               procID = 1:nProcesses ;
            end
            if strcmp(procID,'all')
                procID = 1:nProcesses;
            end
            if any(procID > nProcesses)
                error('User-defined: process id exceeds number of processes');
            end
            
        if full
            % 1 Step. Check if the process itself has a problem
            for i = procID
                if isempty(obj.processes_{i})
                    continue;
                else
                    try
                        obj.processes_{i}.sanityCheck;
                    catch ME
                        % Add process exception to the ith process
                        processExceptions{i} = horzcat(processExceptions{i}, ME);
                    end
                end
            end
        end
            % 2 Step. 
            % Determine the pamameters are changed if satisfying the 
            % following two conditions:
            % A. Process has been successfully run (obj.success_ = ture)
            % B. Pamameters are changed (reported by uicontrols in setting
            % panel, and obj.procChanged_ field is 'true')
            for i = procID
                if isempty(obj.processes_{i})
                    continue;
                else            
                    if obj.processes_{i}.success_ && ...
                            obj.processes_{i}.procChanged_

                        ME = MException('lccb:paraChanged:warn',...
                            ['Parameters of process ', ...
                            obj.processes_{i}.name_,' have been',...
                            ' changed since previous run']);
                        % Add para exception to the ith process
                        processExceptions{i} = horzcat(processExceptions{i}, ME);                           
                    end
                end 
            end
            % 3 Step. Check if the processes that current process depends on
            %    have problems   
            for i = procID
                if isempty(obj.processes_{i})
                    continue;
                elseif ~processVisited(i)
                   [processExceptions, processVisited]= ...
                            obj.dfs_(i, processExceptions, processVisited);
                end
            end
        end
    end
    methods (Access = private)
        function [processExceptions, processVisited] = dfs_(obj, ...
                i,processExceptions,processVisited)
            processVisited(i) = true;
            parentIndex = find(obj.depMatrix_(i,:));
            if isempty(parentIndex)
                return;
            else
                for j = parentIndex
                    if ~isempty(obj.processes_{j}) && ~processVisited(j)
                         [processExceptions, processVisited] = ...
                        obj.dfs_(j, processExceptions,processVisited);
                    end
                    % If j th process has an exception, add an exception to
                    % the exception list of i th process. Since i th
                    % process depends on the j th process
                    % Exception is created when satisty:
                    % 1. Process is successfully run in the last time
                    % 2. Parent process has error OR parent process does
                    %    not exist
                    if obj.processes_{i}.success_ && ...
          ( ~isempty(processExceptions{j}) || isempty(obj.processes_{j}) )
      
                        ME = MException('lccb:depe:warn', ...
   ['The current step is outdated since upriver steps have changed '...
    'Please run again to keep the the result of this step up to date.']);
                        % Add dependency exception to the ith process
                        processExceptions{i} = ...
                                horzcat(processExceptions{i}, ME); 
                    end
                end
            end
        end
    end
    methods (Access = public)
        function setProcess (obj, i, newProcess)
            % set the i th process of obj.processes_ to newprocess
            assert(i<=length(obj.processClassNames_),'UserDefined Error: i exceeds obj.processes length');
            assert(isa(newProcess, 'Process'), ...
                'UserDefined Error: input is not ''Process'' object.');
            obj.processes_{i} = newProcess;
        end
        function setNotes (obj, text)
            obj.notes_ = text;
        end
    end
    
    methods (Abstract)
        sanityCheck(obj)

        % More abstract methods go here
    end
end