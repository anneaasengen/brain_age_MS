
% Jeg måtte endre variabelen 'calculate' til 'calcResult' forå få
% MATLAB-scriptet til å kjøre (siden scriptet hadde samme navn).

%==========================================================================
% Calculate
%==========================================================================
%
% This script is written as optional help in Asymmetry VBM analyses as 
% described in the manuscript "A 12-Step User's Guide for Analyzing 
% Voxel-wise Gray Matter Asymmetries in SPM" by Florian Kurth, Christian 
% Gaser, and Eileen Luders. It will batch  Steps 2 and 6 of this User's 
% Guide and is available as supplementary material. As part of this
% Guide, the function relies heavily on SPM routines as distributed with
% SPM8 (http://www.fil.ion.ucl.ac.uk/spm).
% 
% The script will first ask if Step 2 (flipping of the tissue setments) or
% Step 6 (Asymmetry Index calculation and discarding of the left
% hemisphere) should be batched.
% 
% Step 2:
% The gray and white matter segments resulting from Step 1 are needed. The 
% script will ask for these segments and write the respective flipped
% images.
% 
% Step 6:
% The script needs the  warped original and warped mirrored gray matter 
% segments (the result of Step 4) as well as the hemispheric mask (the 
% result of Step 5) as input. It will write the Asymmetry Index images (or
% the simple difference images, if needed).
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation. It is is distributed in the hope that it 
% will be useful, but WITHOUT ANY WARRANTY; without even the implied 
% warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%__________________________________________________________________________

% Florian Kurth, 2014


% To do
% =========================================================================
% use SPM's itneractive Window to ask this question
if isempty(spm_figure('FindWin','Interactive'))
spm('CreateIntWin','on');
end
spm_figure('GetWin','Interactive');
spm_figure('Clear','Interactive');

% ask question
calcResult = spm_input('Which Step?','+1','b',{'Step 2','Step 6'},{1,2},1);





% =========================================================================
% STEP 2
% =========================================================================
if calcResult{1} == 1
    
    % Get Data
    % =====================================================================
    % select all images that should be flipped.
    
    IM_orig     = cellstr(spm_select(Inf,'image','Select all images that should be flipped'));
    
    
    
    % Calculate
    % =====================================================================
    % Flip the images.

    % state how many images to track progress
    fprintf('Prepare to work on %d images...\n',numel(IM_orig))
    fprintf('Flip image ')

    for i = 1:numel(IM_orig)
        fprintf('%5.0f',i) % image number to track progress
        
        
        % prepare image for ImCalc
        % ----------------------------------------------------
        % input image
        [p,n,~] = fileparts(IM_orig{i});
        vi      = spm_vol(IM_orig{i});
        
        % output image
        vo      = vi; vo.fname = fullfile(p,[n '_flipped.nii']); % set name
        
        
        % run ImCalc for GM
        % ----------------------------------------------------
        spm_imcalc(vi,vo,'flipud(i1)',{[],[],[],1});    %input, output, expression
        
        
        % clean up
        % ----------------------------------------------------
        clear vi vo p n
        fprintf('\b\b\b\b\b')

    end
    fprintf('\b')
    fprintf('s completed\n\n')
end
        


% =========================================================================
% STEP 6
% =========================================================================
if calcResult{1} == 2
    
    % Get Data
    % =========================================================================
    % select original warped segments, collect the flipped warped
    % automatically, and finally select the mask. Safeguard against missing
    % files.

    % get warped original segments
    GM_orig     = cellstr(spm_select(Inf,'image','Select warped original gray matter segments'));

    % automatically select the flipped images (works only if Guide was followed
    % until this point)
    GM_mirrored = cell(numel(GM_orig),1);
    missingdata = 0;
    for i = 1:numel(GM_orig)
        [p,n,~] = fileparts(GM_orig{i});
        GM_mirrored{i} = spm_select('FPlist',p,['^' n '_flipped.nii']);

        %safeguard against missing files
        if isempty(GM_mirrored{i})
            fprintf('File %s is missing',[n '_flipped.nii']);
            missingdata = 1;
        end
        clear p n 
    end
    if missingdata == 1
        error('Not all files exist - see above')
    end

    % get hemispheric mask
    mask = spm_select(1,'image','Select the right hemispheric mask image');

    clear missingdata directory




    % Calculate what?
    % =========================================================================
    % Figure out if to calculate the AI or the difference. Ask user.

    expr = inputdlg('Input formula as stated in Step 6 (formula for AI is given here):','Calculate Asymmetry',1,{'((i1-i2)./((i1+i2).*0.5)).*i3'});
    expr = expr{1}; % This is the expression that will be used for all.




    % Calculate
    % =========================================================================
    % Calculate what ever the user stated above using ImCalc and the three
    % images (original, flipped, mask) per subject.

    % state how many subjects to track progress
    fprintf('Prepare to work on %d subjects...\n',numel(GM_orig))
    fprintf('Calculate subject ')

    for i = 1:numel(GM_orig)
        fprintf('%4.0f',i) %subject number to track progress

        % prepare input for ImCalc
        % ----------------------------------------------------
        % 3 input images
        [p,n,~] = fileparts(GM_orig{i});
        vi(1) = spm_vol(GM_orig{i});
        vi(2) = spm_vol(GM_mirrored{i});
        vi(3) = spm_vol(mask);

        % 1 output image
        vo = vi(1); vo.fname = fullfile(p,['AI_' n '.nii']);


        % run ImCalc
        % ----------------------------------------------------
        spm_imcalc(vi,vo,expr,{[],[],[],1});


        % clean up
        % ----------------------------------------------------
        clear vi vo p n
        fprintf('\b\b\b\b')

    end
    
    fprintf(repmat('\b',1,10))
    fprintf('ions done\n\n')
end


% state that everything is finished and clean up
% ----------------------------------------------------


clear GM_orig GM_mirrored mask
fprintf(' done\n\n')


