% Step 7: Smooth AI images
% This script smooths the asymmetry maps using an 8 mm Gaussian kernel

clear; clc;

% Set up SPM
spm('defaults','FMRI');
spm_jobman('initcfg');

% 1. Define paths
base_dir    = '/media/anneaasengen/CEVAULT2TB';
project_dir = fullfile(base_dir, 'VBM_project_HCP');
t1_dir      = fullfile(project_dir, 'T1_scans');

% 2. Find all AI images from Step 6
ai_files = dir(fullfile(t1_dir, '*', 'mri', 'step4_warped', 'AI_mwrp1*.nii'));
if isempty(ai_files)
    error('No AI images found. Did you finish Step 6?');
end
fprintf('Found %d AI images for smoothing.\n', numel(ai_files));

% 3. Start parallel pool
% Use about 80% of the available CPU cores
numCores   = feature('numcores');
maxWorkers = max(1, floor(0.8 * numCores));
if isempty(gcp('nocreate'))
    parpool('local', maxWorkers);
    fprintf('Started parallel pool with %d workers.\n', maxWorkers);
else
    fprintf('Using existing parallel pool.\n');
end

% 4. Smooth all AI images in parallel
parfor i = 1:numel(ai_files)
    in_file = fullfile(ai_files(i).folder, ai_files(i).name);

    % Create output filename by adding the SPM smoothing prefix "s"
    [pdir, n, e] = fileparts(in_file);
    out_file = fullfile(pdir, ['s' n e]);

    % Skip this image if the smoothed version already exists
    if isfile(out_file)
        fprintf('Skipping %s (already smoothed)\n', n);
        continue;
    end

    try
        fprintf('Smoothing %s...\n', n);

        % Set up SPM smoothing batch
        matlabbatch = {};
        matlabbatch{1}.spm.spatial.smooth.data   = {in_file};

        % Smooth using an 8 x 8 x 8 mm full-width at half-maximum kernel
        matlabbatch{1}.spm.spatial.smooth.fwhm   = [8 8 8];

        % Keep the original data type
        matlabbatch{1}.spm.spatial.smooth.dtype  = 0;

        % Do not use implicit masking
        matlabbatch{1}.spm.spatial.smooth.im     = 0;

        % Add "s" to the beginning of the output filename
        matlabbatch{1}.spm.spatial.smooth.prefix = 's';

        % Run smoothing
        spm_jobman('run', matlabbatch);

        fprintf(' Finished smoothing %s\n', n);

    catch ME
        % Continue with the next image if smoothing fails for one subject
        warning('Error smoothing %s: %s', n, ME.message);
    end
end

fprintf('\nStep 7 complete: all AI images smoothed or skipped.\n');

% Close the parallel pool
delete(gcp('nocreate'));

