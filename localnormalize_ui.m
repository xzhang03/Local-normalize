function imout = localnormalize_ui(varargin)
%localnormalize_ui uses a ui to locally normalize images

%% Parse
if nargin < 1
    varargin = {'tifpath', ''};
end

% Debug
% varargin{2} = 'F:\2p\stephen\SZ336\SZ336\SZ336\AVG_SZ336_200303_001_pmt0_midi.tif';

p = inputParser;

addOptional(p, 'tifpath', ''); % Give direct path
addOptional(p, 'defaultpath', '\\nasquatch\data\2p'); % Give default path for ui
addOptional(p, 'gausssizes', [8 30]);
addOptional(p, 'medsizes', 2);
addOptional(p, 'loadprevparameters', true);    

% Unpack if needed
if iscell(varargin) && size(varargin,1) * size(varargin,2) == 1
    varargin = varargin{:};
end

parse(p, varargin{:});
p = p.Results;

%% IO
% Path parsing
if isempty(p.tifpath)
    [fn, fp] = uigetfile(fullfile(p.defaultpath, '*.tif'));
    [~, fn, ext] = fileparts(fn);
else
    [fp, fn, ext] = fileparts(p.tifpath);
end

% Read
im = readtiff(fullfile(fp, [fn, ext]));

% size
sizevec = size(im);

% output filename
fnout = fullfile(fp, [fn, '_ln.tif']);
fpara = fullfile(fp, [fn, '_param.mat']);

% Get parameters
if exist(fpara, 'file') && p.loadprevparameters
    loaded = load(fpara, 'n', 'm', 'o');
    n = loaded.n;
    m = loaded.m;
    o = loaded.o;
    disp('Parameters loaded from previous setting')
else
    n = p.gausssizes(1);
    m = p.gausssizes(2);
    o = p.medsizes;
end

%% Make figure
% Get z
z = round(sizevec(3)/2);

im2show = im(:,:,z);
im2showln = localnormalizecore(im2show, [n, m], [o, o]);

hfig = figure('Position', [100 200 1600 700]);

% Left
subplot(1,2,1);
wleft = imagesc(im2show);
title('Raw image')

% Right
subplot(1,2,2);
wright = imagesc(im2showln);
title('Local normalized')


%% UIs
% Offsets
uioffsetx = 150;

% Text for z
hztext = uicontrol(hfig, 'Style', 'text', 'String', ['Z: ', num2str(z)],...
    'Position', [20+uioffsetx 18 60 20]);

% Slider for z
hzslide = uicontrol(hfig, 'Style', 'slider', 'Value', z, 'Min', 1,...
    'Max', sizevec(3), 'SliderStep', [0.05 0.2], 'Position', [70+uioffsetx 20 200 20],...
    'callback', @zslidercallback);

    function zslidercallback(~, ~)
        % Update counter
        z = round(hzslide.Value);
        hztext.String = ['Z: ', num2str(z)];
        
        % Update images
        im2show = im(:,:,z);
        im2showln = localnormalizecore(im2show, [n, m], [o, o]);
        
        % Upate panels
        wleft.CData = im2show;
        wright.CData = im2showln;
        
    end

% Text for n
hnmtext = uicontrol(hfig, 'Style', 'text', 'String', ['N: ', num2str(n), ...
    ' M: ', num2str(m)], 'Position', [290+uioffsetx 18 100 20]);

% Slider for n
hnslide = uicontrol(hfig, 'Style', 'slider', 'Value', n, 'Min', 1,...
    'Max', 50, 'SliderStep', [0.02 0.1], 'Position', [370+uioffsetx 20 200 20],...
    'callback', @nslidercallback);

    function nslidercallback(~, ~)
        % Update counter
        n = round(hnslide.Value);
        hnmtext.String = ['N: ', num2str(n), ' M: ', num2str(m)];
        
        % Update images
        im2showln = localnormalizecore(im2show, [n, m], [o, o]);
        
        % Upate panels
        wright.CData = im2showln;
        
    end

% Slider for m
hmslide = uicontrol(hfig, 'Style', 'slider', 'Value', m, 'Min', 1,...
    'Max', 500, 'SliderStep', [0.02 0.1], 'Position', [580+uioffsetx 20 200 20],...
    'callback', @mslidercallback);

    function mslidercallback(~, ~)
        % Update counter
        m = round(hmslide.Value);
        hnmtext.String = ['N: ', num2str(n), ' M: ', num2str(m)];
        
        % Update images
        im2showln = localnormalizecore(im2show, [n, m], [o, o]);
        
        % Upate panels
        wright.CData = im2showln;
        
    end

% Text for o
hotext = uicontrol(hfig, 'Style', 'text', 'String', ['O: ', num2str(o)],...
    'Position', [790+uioffsetx 18 100 20]);

% Slider for o
hoslide = uicontrol(hfig, 'Style', 'slider', 'Value', o, 'Min', 1,...
    'Max', 50, 'SliderStep', [0.02 0.1], 'Position', [860+uioffsetx 20 200 20],...
    'callback', @oslidercallback);

    function oslidercallback(~, ~)
        % Update counter
        o = round(hoslide.Value);
        hotext.String = ['O: ', num2str(o)];
        
        % Update images
        im2showln = localnormalizecore(im2show, [n, m], [o, o]);
        
        % Upate panels
        wright.CData = im2showln;
        
    end

% Button for apply all
hbuttonapply = uicontrol(hfig, 'Style', 'pushbutton', 'String', ...
    ['Apply to all ' , num2str(sizevec(3)), ' sections'],...
    'Position', [1080+uioffsetx 20 200 20], 'callback', @buttoncallback);

    function buttoncallback(~,~)
        % Update string
        hbuttonapply.String = 'Calculating...';
        
        % Make output
        imout = im;
        for i = 1 : sizevec(3)
            imout(:,:,i) = localnormalizecore(im(:,:,i), [n, m], [o, o]);
        end
        
        % Update
        hbuttonapply.String = 'Saving...';
        
        % Write tiff and parameters
        writetiff(imout, fnout);
        save(fpara, '-v7.3', 'fp', 'fn', 'n', 'm', 'o');
        
        hbuttonapply.String = 'Data saved';
    end
end
