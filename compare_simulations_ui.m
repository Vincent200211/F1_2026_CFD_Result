function compare_simulations_ui()
    % 1. Create UI Interface
    hFig = figure('Name', 'CFD Field Difference Comparator (Physical Difference)', 'NumberTitle', 'off', ...
                  'Units', 'pixels', 'Position', [0, 0, 1150, 780], ...
                  'Resize', 'on', 'Toolbar', 'figure', 'WindowStyle', 'normal');
    movegui(hFig, 'center'); 
    
    % ================= Left Panel =================
    hPanelLeft = uipanel('Parent', hFig, 'Position', [0.02, 0.02, 0.28, 0.96]);
    
    uicontrol('Parent', hPanelLeft, 'Style', 'text', 'String', 'Current Case Slice_X Dir', 'Position', [10, 690, 200, 20], 'HorizontalAlignment', 'left');
    hEditCurrent = uicontrol('Parent', hPanelLeft, 'Style', 'edit', 'Position', [10, 665, 180, 25], 'String', '');
    uicontrol('Parent', hPanelLeft, 'Style', 'pushbutton', 'String', 'Browse', 'Position', [200, 665, 60, 25], 'Callback', @(~,~) selectDir(hEditCurrent));
    
    uicontrol('Parent', hPanelLeft, 'Style', 'text', 'String', 'Reference Case Slice_X Dir', 'Position', [10, 625, 200, 20], 'HorizontalAlignment', 'left');
    hEditRef = uicontrol('Parent', hPanelLeft, 'Style', 'edit', 'Position', [10, 600, 180, 25], 'String', '');
    uicontrol('Parent', hPanelLeft, 'Style', 'pushbutton', 'String', 'Browse', 'Position', [200, 600, 60, 25], 'Callback', @(~,~) selectDir(hEditRef));
    
    uicontrol('Parent', hPanelLeft, 'Style', 'text', 'String', 'Export Directory', 'Position', [10, 560, 200, 20], 'HorizontalAlignment', 'left');
    hEditExport = uicontrol('Parent', hPanelLeft, 'Style', 'edit', 'Position', [10, 535, 180, 25], 'String', '');
    uicontrol('Parent', hPanelLeft, 'Style', 'pushbutton', 'String', 'Browse', 'Position', [200, 535, 60, 25], 'Callback', @(~,~) selectDir(hEditExport));
    
    uicontrol('Parent', hPanelLeft, 'Style', 'text', 'String', 'Variable Selection', 'Position', [10, 495, 200, 20], 'HorizontalAlignment', 'left');
    hCheckCPT = uicontrol('Parent', hPanelLeft, 'Style', 'checkbox', 'String', 'CPT', 'Position', [10, 470, 60, 25], 'Value', 1);
    hCheckCOP = uicontrol('Parent', hPanelLeft, 'Style', 'checkbox', 'String', 'COP', 'Position', [80, 470, 60, 25], 'Value', 1);
    
    % Global Colormap Selection
    hPopColormap = uicontrol('Parent', hPanelLeft, 'Style', 'popupmenu', 'String', {'jet', 'parula', 'turbo', 'hsv', 'hot', 'gray'}, 'Position', [10, 405, 250, 25], 'Callback', @updateDisplay);
    hBtnCompute = uicontrol('Parent', hPanelLeft, 'Style', 'pushbutton', 'String', 'Start Computing Difference', 'Position', [10, 350, 250, 35], 'Callback', @computeDiff);
    hBtnExportDiff = uicontrol('Parent', hPanelLeft, 'Style', 'pushbutton', 'String', 'Export All Difference Images', 'Position', [10, 305, 250, 35], 'Callback', @exportDiff);
    
    % Color Limit (Clim) Adjustment
    uicontrol('Parent', hPanelLeft, 'Style', 'text', 'String', 'Value Range (Clim)', 'Position', [10, 260, 200, 20], 'HorizontalAlignment', 'left', 'FontWeight', 'bold');
    hEditMin = uicontrol('Parent', hPanelLeft, 'Style', 'edit', 'Position', [50, 230, 70, 25]);
    hEditMax = uicontrol('Parent', hPanelLeft, 'Style', 'edit', 'Position', [170, 230, 70, 25]);
    uicontrol('Parent', hPanelLeft, 'Style', 'pushbutton', 'String', 'Apply Range', 'Position', [10, 190, 110, 30], 'Callback', @applyColorRange);
    uicontrol('Parent', hPanelLeft, 'Style', 'pushbutton', 'String', 'Reset Auto', 'Position', [140, 190, 110, 30], 'Callback', @resetColorRange);
    
    hStatus = uicontrol('Parent', hPanelLeft, 'Style', 'text', 'String', 'Ready', 'Position', [10, 120, 250, 30], 'HorizontalAlignment', 'left', 'BackgroundColor', 'w');
    hTextAutoRange = uicontrol('Parent', hPanelLeft, 'Style', 'text', 'String', '--', 'Position', [10, 50, 250, 40], 'HorizontalAlignment', 'left', 'BackgroundColor', [0.9 0.9 0.9]);
    
    % ================= Right Panel =================
    hPanelRight = uipanel('Parent', hFig, 'Position', [0.32, 0.02, 0.66, 0.96]);
    hAx = axes('Parent', hPanelRight, 'Units', 'normalized', 'Position', [0.1, 0.28, 0.8, 0.65]);
    
    hGroup = uibuttongroup('Parent', hPanelRight, 'Units', 'pixels', 'Position', [20, 20, 180, 80], 'Title', 'Switch Variable', 'SelectionChangedFcn', @updateDisplay);
    hRadioCPT = uicontrol('Parent', hGroup, 'Style', 'radiobutton', 'String', 'CPT', 'Position', [10, 30, 60, 25], 'Value', 1);
    hRadioCOP = uicontrol('Parent', hGroup, 'Style', 'radiobutton', 'String', 'COP', 'Position', [80, 30, 60, 25]);
    
    hSlider = uicontrol('Parent', hPanelRight, 'Style', 'slider', 'Units', 'pixels', 'Position', [300, 53, 350, 25], 'Callback', @updateDisplay);
    hTextDist = uicontrol('Parent', hPanelRight, 'Style', 'text', 'String', '0.00', 'Units', 'pixels', 'Position', [660, 55, 60, 20]);
    
    % ================= Logic Implementation =================
    data = struct(); rangeMode = 'auto'; manualMin = 0; manualMax = 1;

    function selectDir(hEdit)
        p = uigetdir(pwd, 'Select Folder'); if p ~= 0, set(hEdit, 'String', p); end
    end

    function computeDiff(~,~)
        set(hFig, 'Pointer', 'watch'); set(hStatus, 'String', 'Scanning directories...'); drawnow;
        currP = get(hEditCurrent, 'String'); refP = get(hEditRef, 'String');
        if isempty(currP) || isempty(refP), set(hStatus, 'String', 'Error: Please select directories'); enableButtons(); return; end

        % 1. Auto Path Correction Logic
        function p = checkPath(base)
            subFolders = {'CPT_Gray', 'COP_Gray', 'CPT', 'COP'};
            p = base;
            [~, lastFolder] = fileparts(base);
            if any(strcmpi(lastFolder, subFolders)), p = fileparts(base); end
        end
        currP = checkPath(currP); refP = checkPath(refP);

        % 2. Scan Files (Supports multiple extensions and fuzzy folder names)
        function [fList, fullPath] = scanFiles(base, varType)
            dInfo = dir(base);
            fName = '';
            for k=1:length(dInfo)
                if dInfo(k).isdir && contains(dInfo(k).name, varType, 'IgnoreCase', true)
                    fName = dInfo(k).name; break;
                end
            end
            if isempty(fName), fList = []; fullPath = ''; return; end
            fullPath = fullfile(base, fName);
            fList = [dir(fullfile(fullPath, '*.png')); dir(fullfile(fullPath, '*.jpg')); dir(fullfile(fullPath, '*.tif'))];
        end

        [fCurrCPT, pCurrCPT] = scanFiles(currP, 'CPT'); [fRefCPT, pRefCPT] = scanFiles(refP, 'CPT');
        [fCurrCOP, pCurrCOP] = scanFiles(currP, 'COP'); [fRefCOP, pRefCOP] = scanFiles(refP, 'COP');

        % 3. Extract Distances
        dCurrCPT = extractD(fCurrCPT); dRefCPT = extractD(fRefCPT);
        dCurrCOP = extractD(fCurrCOP); dRefCOP = extractD(fRefCOP);
        
        commonCPT = intersect(dCurrCPT, dRefCPT);
        commonCOP = intersect(dCurrCOP, dRefCOP);
        allD = union(commonCPT, commonCOP);
        
        if isempty(allD)
            set(hStatus, 'String', 'No matching data found (check file names for numbers)');
            enableButtons(); return;
        end

        % 4. Compute and Store (Optimized: Direct filename mapping)
        data.commonDist = allD;
        n = length(allD); data.physDiffCPT = cell(n,1); data.physDiffCOP = cell(n,1);

        for i = 1:n
            d = allD(i);
            set(hStatus, 'String', sprintf('Computing: %.2f (%d/%d)', d, i, n)); drawnow;
            % CPT Calculation
            if ismember(d, commonCPT)
                imC = double(readImgByDist(fCurrCPT, pCurrCPT, d)); 
                imR = double(readImgByDist(fRefCPT, pRefCPT, d));
                if ~isempty(imC) && ~isempty(imR), data.physDiffCPT{i} = flipud((imC/255) - (imR/255)); end
            end
            % COP Calculation
            if ismember(d, commonCOP)
                imC = double(readImgByDist(fCurrCOP, pCurrCOP, d)); 
                imR = double(readImgByDist(fRefCOP, pRefCOP, d));
                if ~isempty(imC) && ~isempty(imR)
                    data.physDiffCOP{i} = flipud(((imC/255)*2-1) - ((imR/255)*2-1));
                end
            end
        end
        
        set(hSlider, 'Min', min(allD), 'Max', max(allD), 'Value', min(allD), 'SliderStep', [1/max(1,n-1), 5/max(1,n-1)]);
        updateDisplay(); set(hStatus, 'String', 'Computation Finished');
        enableButtons();
    end

    % Improved distance extraction supporting integers and floats
    function d = extractD(list)
        d = []; if isempty(list), return; end
        for k=1:length(list)
            t = regexp(list(k).name, '(\d+\.?\d*)', 'match');
            if ~isempty(t), d = [d, str2double(t{end})]; end
        end
        d = unique(d);
    end

    % Read image by nearest distance match
    function im = readImgByDist(fList, base, targetD)
        im = []; if isempty(fList), return; end
        dists = zeros(length(fList), 1);
        for k=1:length(fList)
            t = regexp(fList(k).name, '(\d+\.?\d*)', 'match');
            dists(k) = str2double(t{end});
        end
        [minVal, idx] = min(abs(dists - targetD));
        if minVal > 0.001, return; end 
        
        im = imread(fullfile(base, fList(idx).name));
        if size(im,3)>1, im = rgb2gray(im); end
    end

    % ---------------- Display and Export ----------------
    function updateDisplay(~,~)
        if ~isfield(data, 'commonDist') || isempty(data.commonDist), return; end
        [~, idx] = min(abs(data.commonDist - get(hSlider, 'Value')));
        curD = data.commonDist(idx); set(hTextDist, 'String', sprintf('%.2f', curD));
        
        if get(hRadioCPT, 'Value'), pd = data.physDiffCPT{idx}; var = 'CPT'; else, pd = data.physDiffCOP{idx}; var = 'COP'; end
        if isempty(pd), cla(hAx); title(hAx, 'No matching physical data'); return; end
        
        imagesc(pd, 'Parent', hAx); axis(hAx, 'equal', 'tight'); set(hAx, 'YDir', 'normal'); 
        cmapNames = get(hPopColormap, 'String'); colormap(hAx, cmapNames{get(hPopColormap, 'Value')}); 
        colorbar(hAx, 'eastoutside');
        
        if strcmp(rangeMode, 'auto'), clim = [min(pd(:)), max(pd(:))]; else, clim = [manualMin, manualMax]; end
        if clim(1)==clim(2), clim = [clim(1)-0.01, clim(1)+0.01]; end
        caxis(hAx, clim);
        set(hTextAutoRange, 'String', sprintf('Variable: %s\nRange: [%.3f, %.3f]', var, clim(1), clim(2)));
        title(hAx, sprintf('%s Diff (X=%.2f)', var, curD));
    end

    function exportDiff(~,~)
        outP = get(hEditExport, 'String'); if isempty(outP), set(hStatus, 'String', 'Select export path first'); return; end
        set(hFig, 'Pointer', 'watch'); set(hStatus, 'String', 'Batch exporting...'); drawnow;
        cmapNames = get(hPopColormap, 'String'); cmap = colormap(cmapNames{get(hPopColormap, 'Value')});
        nColors = size(cmap, 1);
        vNames = {'CPT', 'COP'};
        for v = 1:2
            subD = fullfile(outP, [vNames{v} '_diff']); if ~exist(subD, 'dir'), mkdir(subD); end
            diffs = data.(['physDiff' vNames{v}]);
            for i = 1:length(data.commonDist)
                pd = diffs{i}; if isempty(pd), continue; end
                if strcmp(rangeMode,'auto'), cl = [min(pd(:)), max(pd(:))]; else, cl = [manualMin, manualMax]; end
                if cl(2)>cl(1), t = max(0, min(1, (pd-cl(1))/(cl(2)-cl(1)))); idx = round(t*(nColors-1)+1); else, idx = ones(size(pd)); end
                imwrite(uint8(ind2rgb(idx, cmap)*255), fullfile(subD, sprintf('%s_diff_%.2f.png', vNames{v}, data.commonDist(i))));
            end
        end
        set(hStatus, 'String', 'Batch Export Completed'); enableButtons();
    end

    function applyColorRange(~,~), rangeMode='manual'; manualMin=str2double(get(hEditMin,'String')); manualMax=str2double(get(hEditMax,'String')); updateDisplay(); end
    function resetColorRange(~,~), rangeMode='auto'; updateDisplay(); end
    function enableButtons(), set([hBtnCompute, hBtnExportDiff], 'Enable', 'on'); set(hFig, 'Pointer', 'arrow'); end
end