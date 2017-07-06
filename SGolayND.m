function [CC DC] = SGolayND(p,w)

% Calculate Savitzky-Golay convolution coefficients in N dimensions for
% evenly-spaced data
%
% Inputs:
%   p is the order of the smoothing polynomial (max derivative order will
%        be p-1)
%   w is the smoothing window size (vector of N dimensions; dimensions
%        with value 1 will not be smoothed)
%
% In this implementation, the smoothing polynomial has the same order
% in all directions. The order of cross terms is considered to be the sum
% of orders over all directions, so eg. for N=2 p=3 the highest order cross
% terms will be x*(y^2) and (x^2)*y, not (x^3)*(y^3).
%
% Outputs CC and DC are convolution coefficients for smoothing and
% derivatives:
%   CC is the matrix of smoothing coefficients
%   DC is a cell structure containing matrices of coefficients for the
%         differential of the smoothed function. DC{m,n} is differential of
%         order (m-1) in dimension 1 and (n-1) in dimension 2.
%
% Daniel Warren
% July 2017

% Skip dimensions with smoothing window size 1
w_init = w;
skipdims = w==1;
w(skipdims) = [];

d = numel(w); % number of dimensions to smooth

% if nothing to do, return identity
if d == 0
    CC = 1;
    DC = {1};
    return;
end

if any(w < p+1)
    error('All elements of w must be either 1, or greater than p');
end

% make q, matrix of all valid combinations of polynomial exponents (size n-by-d)
q = repmat({0:p},[1 d]);
[q{:}] = ndgrid(q{:});
q = cellfun(@(x)x(:),q,'UniformOutput',false);
q = cat(2,q{:});
q(sum(q,2) > p,:) = []; % exclude combos where combined order is greater than p

% make array of data subscripts (size {d}(w^d)) and linear indices (size w^d)
subs = arrayfun(@(x)1:x,w,'UniformOutput',false);
[subs{:}] = ndgrid(subs{:});
inds = sub2ind(size(subs{1}),subs{:});
subs = cellfun(@(x,w)x-((w+1)/2),subs,num2cell(w),'UniformOutput',false); % Place zero in center

% Form Jacobian:
% rows are data points; columns are polynomial functions of position
J = zeros(numel(inds),size(q,1));
for i = 1:numel(inds)
    J(i,:) = prod(cellfun(@(x)x(inds(i)),subs).^q,2);
end

% Solve for convolution coefficients:
C = (J'*J)\(J');

% First row of C is smoothing; subsequent rows are numerical derivatives.
% Create cell DC with convolution coefficients for all orders of derivatives
DC = cell(repmat(1+p,[1 d]));
DCsubs = num2cell(1+q,1);
DCind = sub2ind(size(DC),DCsubs{:});
for i = 1:size(C,1)
    DC{DCind(i)} = C(i,:);
    if numel(w_init) > 1
        DC{DCind(i)} = reshape(DC{DCind(i)},w_init);
    end
end
CC = DC{1}; % output smoothing coefficients separately