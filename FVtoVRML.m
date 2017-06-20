function out = FVtoVRML(fv,filename,col,trans,diffuse)

% out = FVtoVRML(fv,filename,col,trans,diffuse) exports the 3D volume
% represented by the MATLAB faces and vertices structure fv into the string
% out in VRML97 (VRML 2.0) format. fv may be a structure array, in which
% case the VRML will contain one object for each element.
%
% If optional variable filename is provided, the VRML will be output to a
% file. Object colours may optionally be specified by col, an n-by-3 array,
% where n is the number of elements of fv, and each row is the RGB triplet
% for the corresponding object's colour on the scale [0,1]. Transparency
% may optionally be specified by trans, a vector of length n, on the scale
% [0,1] where 0 is opaque and 1 is transparent. A diffuse color model is
% used by default, but this may be overriden by speciying optional variable
% diffuse, a logical vector of length n, with false indicating an emissive
% color model and true representing a diffuse color model.
%
% Daniel Warren - August 2015

if ~exist('col','var')
    col = ones(numel(fv),3);
end
if ~exist('trans','var')
    trans = zeros(numel(fv),1);
end
if ~exist('diffuse','var')
    diffuse = ones(numel(fv),1);
end

newline = sprintf('\n');

header = ['#VRML V2.0 utf8' newline];

data = ['Transform { rotation ' num2str([1 0 0 3*pi/2]) newline 'children [' ...
        'Background { skyColor [1 1 1]} NavigationInfo { headlight FALSE }' newline];

for i = 1:numel(fv)
    data = [data 'Shape { ' newline 'geometry IndexedFaceSet { ' newline ...
            'coord Coordinate {point [' sprintf('%.4g %.4g %.4g,  ',fv(i).vertices')];
    data = [data ']}' newline];
    data = [data 'coordIndex [' sprintf('%d, %d, %d, -1  ',fv(i).faces'-1)];
    data = [data ']' newline];
    data = [data '}' newline];
    if diffuse(i)
        data = [data 'appearance Appearance {material Material {diffuseColor ' sprintf('%.4g, ',col(i,:)) ' transparency ' sprintf('%6.4g',trans(i)) '}}' newline];
    else
        data = [data 'appearance Appearance {material Material {shininess 0 ambientIntensity 0 emissiveColor ' sprintf('%.4g, ',col(i,:)) ' transparency ' sprintf('%6.4g',trans(i)) '}}' newline];
    end
    data = [data '}' newline];
end

data = [data ']}'];

out = [header data];

if exist('filename','var')
    fid = fopen(filename,'w');
    fprintf(fid,[header data]);
    fclose(fid);
end

end