function imout = localnormalizecore(im, gausssizes, medsizes)
%Localnormalizecore is the core function that applies the normalization
%procedures
% imout = localnormalizecore(im,gausssizes, medsizes)

% Defaults
if nargin < 3
    medsizes = [2, 2];
    if nargin < 2
        gausssizes = [8, 30];
    end
end

% 2D filter
im = medfilt2(im, medsizes, 'symmetric'); %looks like a bug
        
% gaussian normalize
f_prime = single(im)-single(imgaussfilt(single(im),gausssizes(1)));
imout = f_prime./(imgaussfilt(f_prime.^2,gausssizes(2)).^(1/2));
imout(isnan(imout)) = 0;

end
