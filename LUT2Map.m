function map = LUT2Map(fn,format)

% LUT2Map(fn,format)
%   Converts ImageJ LUT to MATLAB colormap.
%   - fn is the filename of the lookup table.
%   - format is an optional argument specifying the format of the lookup
%     table if known (must be 'ICOL', 'ASCII' or 'binary')
%
% Seems to work for all lookup tables in the FIJI ImageJ distribution.
%
% Daniel Warren 2017

% Read input file as 8-bit integers
fid = fopen(fn,'r');
map = fread(fid,Inf,'uint8');
fclose(fid);

% Simple heuristics to identify the LUT format, if not provided (imperfect)
if ~exist('format','var')
    if strcmp(char(map(1:4)'),'ICOL')
        format = 'ICOL';
    elseif isempty(setdiff(map,[9:13 32:126])) || mod(numel(map),3) ~= 0
        format = 'ASCII';
    else
        format = 'binary';
    end
end

switch format
    case 'ICOL'
        % ICOL seems to have a 32-byte header, content unknown, otherwise binary
        map = map(33:end); % ignore header
        map = reshape(map,[size(map,1)/3 3]);

    case 'ASCII'
        % There seem to be 2 ASCII formats, 3-column RGB and 4-column Index-RGB
        
        % Process map as character array
        map = char(map');
        
        % Identify number of columns by counting 'words' in first line
        lpos = strfind(map,sprintf('\n'));
        [~,ncol] = sscanf(map(1:lpos(1)),'%s');

        % Remove non-numeric or whitespace data
        map(~ismember(map,['0123456789 ' sprintf('\t\n')])) = [];
        map = sscanf(map,'%d');

        map = reshape(map,[ncol size(map,1)/ncol]);
        
        if ncol == 4
            % For 4-column, sort rows by index, and then retain only RGB
            [~,order] = sort(map(1,:));
            map = map(:,order);
            map(1,:) = [];
        end
        
        map = map';
        
    case 'binary'
        % Binary requires no further datatype conversion
        map = reshape(map,[size(map,1)/3 3]);
        
    otherwise
        error('Unknown format.');
end

map = double(map)/255;

end