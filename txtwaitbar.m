function h = txtwaitbar(varargin)

% txtwaitbar is a text-based progress bar, intended to fill a similar role
% to MATLAB's waitbar function, but also compatible with parfor loops
%
% Usage is:
%
%      h = txtwaitbar(imax,options{:});     %      Initialize
%      parfor i = 1:imax                    %      Could also be a for loop
%        do_stuff(i);
%        txtwaitbar(i,h);                   %      Update waitbar
%      end
%      clear h;                             %      Struct h no longer needed
%
% options{:} indicates an optional list of string-value pairs which can be
% used to override the default values. See the function source code for the
% relevant options.
%
% txtwaitbar will not work as designed if anything is printed to screen
% either after initialization or between updates. It can only be used to
% display increasing progress - it is not possible to 'rewind' the bar.
%
% Only tested in MATLAB R2013b-R2016b on Windows.
%
% Daniel R Warren
% June 2017
% http://github.com/drw25

nargin = numel(varargin);

if nargin >= 2 && isstruct(varargin{2})
    % Syntax is to update waitbar - do this, then return without parsing further arguments
    i = varargin{1};
    h = varargin{2};
    [doupdate,ind] = ismember(i,h.UpdateValues);
    if doupdate
        fprintf(['\b' h.ProgressSymbol '\n']);    % Add to progress bar
        if ismember(ind,h.RoundUpIndices)
            fprintf(['\b' h.RoundUpSymbol '\n']); % To correct rounding errors
        end
    end
    return;
end

% Parse the initialization syntaxes

if nargin == 1 || (nargin >= 2 && ischar(varargin{2}))
    if numel(varargin{1}) == 1
        % Syntax is correct
        ivals = 1:varargin{1};
    end
    optindex = 2;
else
    error('Syntax not recognised.');
end

% Set default options
options = { 'BarLength',51,        ... % Progress bar length (in characters)
            'ShowTicks',true,      ... % Display a scale bar?
            'MajorTicks',11,       ... % Number of divisions on scale bar
            'MajorTickSymbol','|', ... % Single character for scale bar
            'MinorTickSymbol','-', ... % Single character for scale bar
            'ProgressSymbol','#',  ... % Single character marking progress
            'OpenPool',true };         % Open pool before init? (necessary for sensible output with parfor/spmd)

% Override default options if custom values are specified, ignoring any
% other arguments - no validation is performed, so invalid custom options
% may cause errors later on
if nargin >= optindex
    for i = 1:2:numel(options)
        matches = strcmp(varargin(optindex:2:end),options{i});
        if any(matches(:))
            mind = 2*(find(matches,1,'first')-1);
            options{i+1} = varargin{optindex+mind+1};
        end
    end
end

h = struct(options{:});

if numel(ivals) >= h.BarLength
    % More iterations than characters in the bar. Select a subset to
    % display a progress symbol.
    h.UpdateValues = ivals(round(linspace(1,end,h.BarLength)));
    h.RoundUpSymbol = '';
    h.RoundUpIndices = [];
else
    % Fewer iterations than characters in the bar. Every iteration shows a
    % symbol. Progress symbols will be repeated, so bar is full at 100%.
    % Some iterations will need an extra 'round up' symbol.
    h.UpdateValues = ivals;
    symbolreps = floor(h.BarLength/numel(ivals));
    h.RoundUpSymbol = h.ProgressSymbol;
    h.ProgressSymbol = repmat(h.ProgressSymbol,[1 symbolreps]);
    roundups = h.BarLength-numel(ivals)*numel(h.ProgressSymbol);
    h.RoundUpIndices = 1:roundups;
end

if h.OpenPool && license('test', 'Distrib_Computing_Toolbox')
    gcp; % Open a parallel pool, if not already open
end

% Construct and display initialization string (if requested)
if h.ShowTicks
    initstring = repmat(h.MinorTickSymbol,[1 h.BarLength]);
    initstring(round(linspace(1,h.BarLength,h.MajorTicks))) = h.MajorTickSymbol;
    fprintf([initstring '\n']);
end
fprintf('\n');

end