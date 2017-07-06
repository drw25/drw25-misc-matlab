function data = FVtoPOVRay(fv,filename,col,trans,colourmodel,bgcolour)

% data = FVtoPOVRay(fv,filename,col,trans,diffuse) exports the 3D volume
% represented by the MATLAB faces and vertices structure fv into the string
% out in POVRay format. fv may be a structure array, in which
% case the VRML will contain one object for each element.
%
% If optional variable filename is provided, the VRML will be output to a
% file. Object colours may optionally be specified by col, an n-by-3 array,
% where n is the number of elements of fv, and each row is the RGB triplet
% for the corresponding object's colour on the scale [0,1]. Transparency
% may optionally be specified by trans, a vector of length n, on the scale
% [0,1] where 0 is opaque and 1 is transparent - this is mapped to density
% rather than colour transparancy. A diffuse colour model is used by default,
% but this may be overriden by speciying optional variable colourmodel, a
% vector of length n, with 0 indicating a diffuse colour model, 1 indicating
% an absorption colour model and 2 indicating an emissive colour model.
%
% Background colour can be specified by the variable bgcolour, again RGB
% triplet on scale [0,1].
%
% Daniel R Warren
% August 2015
% http://github.com/drw25

if ~exist('col','var')
    col = repmat([0 1 0],[numel(fv) 1]);
end
if ~exist('trans','var')
    trans = zeros(numel(fv),1);
end
if ~exist('colourmodel','var')
    colourmodel = ones(numel(fv),1);
end
if ~exist('bgcolour','var')
    bgcolour = [1 1 1];
end

newline = sprintf('\n');

header = [''];

data = ['union{' newline];

for i = 1:numel(fv)
    %fv(i).vertices = fv(i).vertices+(-0.5+rand(size(fv(i).vertices)))*1e-2; %jitter to avoid nasty artefacts from coincidental planes
    if ~isempty(fv(i).faces)
    data = [data 'mesh { ' newline];
    for j = 1:size(fv(i).faces,1)
        data = [data 'triangle { <' sprintf('%.6g,%.6g,%.6g',fv(i).vertices(fv(i).faces(j,1),:)) '>,<' ...
                                    sprintf('%.6g,%.6g,%.6g',fv(i).vertices(fv(i).faces(j,2),:)) '>,<' ...
                                    sprintf('%.6g,%.6g,%.6g',fv(i).vertices(fv(i).faces(j,3),:)) '> } '];
    end
    data = [data '' newline];
    switch colourmodel
        case 0 % diffuse
            data = [data 'pigment { rgbt <' sprintf('%.6g,%.6g,%.6g,%.4g',[col(i,:) trans(i)]) '> } ' newline];
        case 1 % absorb
            data = [data 'pigment { rgbt <' sprintf('%.6g,%.6g,%.6g,%.4g',[col(i,:) 1]) '> } hollow interior { media { absorption <' sprintf('%.6g,%.6g,%.6g',ones(1,3)-col(i,:)) '>*' sprintf('%-6.6g',(1-trans(i))) '} } ' newline];
        case 2 % emit
            data = [data 'pigment { rgbt <' sprintf('%.6g,%.6g,%.6g,%.4g',[col(i,:) 1]) '> } finish { emission 0.9 } hollow interior { media { emission <' sprintf('%.6g,%.6g,%.6g',col(i,:)) '> density {rgb ' sprintf('%-6.6g',(1-trans(i))) '*<1,1,1>}' '}' ...
                    ' media { absorption <' sprintf('%.6g,%.6g,%.6g',ones(1,3)-col(i,:)) '> density {rgb ' sprintf('%-6.6g',(1-trans(i))) '*<1,1,1>}' '} } ' newline];
        otherwise
            error('Unknown colour model');
    end
    data = [data 'matrix <1,0,0,0,0,-1,0,1,0,0,0,0>' newline];
    data = [data '}' newline];
    end
end

pts = vertcat(fv(:).vertices);
c_approx = mean(pts,1);
xextent = max(pts(:,1))- min(pts(:,1));
yextent = max(pts(:,2))- min(pts(:,2));
zextent = max(pts(:,3))- min(pts(:,3));

data = [data 'rotate <0,360*clock,0>' newline];
data = [data '}' newline];

data = [data 'camera { location <' sprintf('%.6g',c_approx(1)) ',' ...
                                   sprintf('%.6g',c_approx(2)) ',' ...
                                   sprintf('%.6g',c_approx(3)+2*max([xextent yextent zextent])) '>' ...
                      ' look_at <' sprintf('%.6g',c_approx(1)) ',' ...
                                   sprintf('%.6g',c_approx(2)) ',' ...
                                   sprintf('%.6g',c_approx(3)) '>' ...
        ' direction <0,0,-1> sky <0,1,0> up <0,1,0> right <4/3,0,0> angle 45 }' newline];

data = [data 'light_source {0*x color rgb <1,1,1>' ...
                    ' translate <' sprintf('%.6g',c_approx(1)) ',' ...
                                   sprintf('%.6g',c_approx(2)) ',' ...
                                   sprintf('%.6g',c_approx(3)+max([xextent yextent zextent])) '> }' newline];

data = [data 'background { color rgb <' sprintf('%.6g',bgcolour(1)) ',' ...
                                        sprintf('%.6g',bgcolour(2)) ',' ...
                                        sprintf('%.6g',bgcolour(3)) '> }'];

if exist('filename','var')
    fid = fopen(filename,'w');
    fprintf(fid,[header data]);
    fclose(fid);
end

end
