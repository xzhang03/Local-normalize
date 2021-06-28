function localnormalize_batch(varargin)
%localnormalize_batch applies segmentation from a parameter file in batch

%% Parse
if nargin < 1
    varargin = {'tifnames', {}};
end

% Debug
% varargin{2} = 'F:\2p\stephen\SZ336\SZ336\SZ336\AVG_SZ336_200303_001_pmt0_midi.tif';
% varargin{2} = 'E:\histology\stephen\SZ705\SZ705A small.tif';
% varargin = {'defaultpath', 'E:\histology\stephen\SZ725B'};


p = inputParser;

addOptional(p, 'tifnames', {}); % Give direct names, expect a cell
addOptional(p, 'tifpath', ''); % Give direct path
addOptional(p, 'parapath', ''); % Full path for parameter file
addOptional(p, 'defaultpath', '\\nasquatch\data\2p'); % Give default path for ui


% Unpack if needed
if iscell(varargin) && size(varargin,1) * size(varargin,2) == 1
    varargin = varargin{:};
end

parse(p, varargin{:});
p = p.Results;

%% IO
% Path parsing
if isempty(p.tifnames) || isempty(p.tifpath)
    [fns, fp] = uigetfile(fullfile(p.defaultpath, '*.tif'), 'Select tiff files', 'MultiSelect', 'on');
else
    fns = p.tifnames;
    fp = p.tifpath;
end

if isempty(p.parapath)
    [fpara_gen, fpara_genfolder] = uigetfile(fullfile(fp, '*param.mat'), 'Select parameter file');
end

if ~iscell(fns)
    fns = {fns};
end

% Number of files
nfiles = length(fns);

% load parameter file
loaded = load(fullfile(fpara_genfolder, fpara_gen), 'n', 'm', 'o');
n = loaded.n;
m = loaded.m;
o = loaded.o;
    
    
%% Loop and process
hwait = waitbar(0, 'Processing');
for i = 1 : nfiles
    % Read
    fn_curr = fns{i};
    
    % Waitbar
    waitbar(i/nfiles, hwait, ['Loading ', fn_curr]);
    
    try
        im = readtiff(fullfile(fp, fn_curr));
    catch
        im = imread(fullfile(fp, fn_curr));
    end
    
    % Current fn
    [~, fn, ~] = fileparts(fn_curr);
    
    % output filename
    fnout = fullfile(fp, [fn, '_ln.tif']);
    fpara = fullfile(fp, [fn, '_param.mat']);
    
    % Waitbar
    waitbar(i/nfiles, hwait, ['Processing ', fn_curr]);
    
    % Make output
    imout = im;
    for j = 1 : size(im, 3)
        imout(:,:,j) = localnormalizecore(im(:,:,j), [n, m], [o, o]);
    end
    
    % Waitbar
    waitbar(i/nfiles, hwait, ['Writing ', fn]);
    
    % Write tiff and parameters
    writetiff(imout, fnout);
    save(fpara, '-v7.3', 'fp', 'fn', 'n', 'm', 'o');

    disp(fnout);
end
close(hwait)
end
