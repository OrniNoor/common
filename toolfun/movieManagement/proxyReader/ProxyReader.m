classdef ProxyReader < Reader
    %ProxyReader Facilitates the use of a proxy design pattern to extend
    %the Reader interface
    %
    % All method calls are forwarded to another reader given in the
    % constructor
    %
    % See http://goo.gl/vuYU9H
    %
    % Mark Kittisopikul
    % mark.kittisopikul@utsouthwestern.edu
    % Lab of Khuloud Jaqaman
    % UT Southwestern
    
    properties
        reader;
        deleteBaseReader = false;
    end
   
    methods
        function obj = ProxyReader(varargin)
            if(nargin < 1)
                % no parameters, return nothing to allow for extension
                return;
            end
            % at least one parameter
            if(isa(varargin{1},'MovieData'))
                varargin{1} = obj.replace(varargin{1});
            end
            if(isa(varargin{1},'Reader'))
                obj.reader = varargin{1};
                obj.proxyProperties;
            else
                error('ProxyReader:argChk','Single parameter must be a reader');
            end
        end
        
        function obj = proxyProperties(obj)
            obj.sizeX = obj.reader.sizeX;
            obj.sizeY = obj.reader.sizeY;
            obj.sizeZ = obj.reader.sizeZ;
            obj.sizeC = obj.reader.sizeC;
            obj.sizeT = obj.reader.sizeT;
            obj.bitDepth = obj.reader.bitDepth;
        end

        function varargout = subsref(obj,S)
            if(S(1).type(1) == '.')
                % if the subref for '.' is a property or method of upstream
                % then forward it
                % do not forward the reference to reader
                if(~strcmp('reader',S(1).subs) &&  isprop(obj.reader,S(1).subs))
                    [varargout{1:nargout}] = obj.reader.(S(1).subs);
                    % if it 
                    if(isprop(obj,S(1).subs))
                        obj.(S(1).subs) = obj.reader.(S(1).subs);
                    end
                elseif(~ismethod(obj,S(1).subs) && ismethod(obj.reader,S(1).subs))
                    func = eval(['@(varargin) obj.reader.'  S(1).subs '(varargin{:})']);
                    if(length(S) < 2)
                        S(2).subs = {};
                    end
                    [varargout{1:nargout}] = func(S(2).subs{:});
                else
                    [varargout{1:nargout}] = builtin('subsref',obj,S);
                end
%            elseif(numel(obj) == 1 && ismethod(obj.reader,'subsref'))
%                [varargout{1:nargout}] = builtin('subsref',obj.reader,S);
            else
                [varargout{1:nargout}] = builtin('subsref',obj,S);
%                 [varargout{1:nargout}] = builtin('subsref',obj.reader,S);
            end
        end
        
        function proxies = findProxies(obj)
            proxies = cell(1);
            proxies{1} = obj;
            while(isa(proxies{end}.reader,'ProxyReader'))
                proxies{end+1} = proxies{end}.reader;
            end
        end
        
       
        % Proxy all the functions
        % See the Reader interface for documentation
        % NB: Does not use the cached properties
        function s = getSizeX(obj,varargin)
            s = obj.reader.getSizeX(varargin{:});
        end
        function s = getSizeY(obj,varargin)
            s = obj.reader.getSizeY(varargin{:});
        end
        function s = getSizeZ(obj,varargin)
            s = obj.reader.getSizeZ(varargin{:});
        end
        function s = getSizeC(obj,varargin)
            s = obj.reader.getSizeC(varargin{:});
        end
        function s = getSizeT(obj,varargin)
            s = obj.reader.getSizeT(varargin{:});
        end
        function s = getBitDepth(obj,varargin)
            s = obj.reader.getBitDepth(varargin{:});
        end
        function s = getImageFileNames(obj,varargin)
            s = obj.reader.getImageFileNames(varargin{:});
        end
        function s = getChannelNames(obj,varargin)
            s = obj.reader.getChannelNames(varargin{:});
        end
        
        function I = loadImage(obj,varargin)
            I = obj.reader.loadImage(varargin{:});
        end
        function I = loadStack(obj,varargin)
            I = obj.reader.loadStack(varargin{:});
        end

        % Replace the reader in movieData
        function oldReader = replace(obj,movieData)
            oldReader = movieData.getReader();
            obj.deleteBaseReader = true;
            movieData.setReader(obj);
        end

        
        % Delete parent reader if deleted
        function delete(obj)
            if(obj.deleteBaseReader && ~isempty(obj.reader))
                obj.reader.delete;
            end
        end
    end
    methods( Access = protected )
        function I = loadImage_(obj, varargin)
            I = obj.reader.loadImage_(varargin{:});
        end
        function I = loadStack_(obj, varargin)
            I = obj.reader.loadStack_(varargin{:});
        end
    end
end

