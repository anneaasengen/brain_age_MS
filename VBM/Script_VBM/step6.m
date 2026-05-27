% Step 6: Calculate Asymmetry Index / Create Asymmetry maps
% This script calculates voxel-wise asymmetry maps by comparing each warped
% gray matter image with its mirrored version. The calculation is restricted
% to the right hemisphere mask.

% 1. Define paths
base_dir     = '/media/anneaasengen/CEVAULT2TB';
project_dir  = fullfile(base_dir, 'VBM_project_HCP');
subjects_dir = fullfile(project_dir, 'T1_scans');
mask_file    = fullfile(project_dir, 'masks', 'right_mask.nii');

% 2. Find warped gray matter images
% Only original images are used here. Flipped images are excluded from this list.
gm_files = dir(fullfile(subjects_dir, '*', 'mri', 'step4_warped', 'mwrp1*.nii'));
GM_all   = fullfile({gm_files.folder}, {gm_files.name})';

is_flipped = contains(GM_all, 'flipped');
GM_orig    = GM_all(~is_flipped);

fprintf('Found %d warped ORIGINAL GM images.\n', numel(GM_orig));



fprintf('Found %d warped GM images.\n', numel(GM_orig));

if isempty(GM_orig)
    error('No warped GM images found. Did you finish Step 4?');
end


% 3. Create file lists for mirrored images and AI output files
GM_mirrored = cell(numel(GM_orig),1);
AI_files    = cell(numel(GM_orig),1);

for i = 1:numel(GM_orig)
    [p,n,~] = fileparts(GM_orig{i});

    % Expected name of the flipped version of the same gray matter image
    GM_mirrored{i} = fullfile(p, [n '_flipped.nii']);

    % Output filename for the asymmetry index map
    AI_files{i}    = fullfile(p, ['AI_' n '.nii']);
end

% 4. Check that all flipped images exist
missing = ~cellfun(@isfile, GM_mirrored);
if any(missing)
    fprintf('Missing flipped files for %d subjects.\n', sum(missing));
    error('Aborting due to missing flipped files. Did you run Step 2 + Step 4 correctly?');
end

% 5. Set up SPM
spm('defaults','FMRI');

% 6. Load the right hemisphere mask once
mask_vol = spm_vol(mask_file); 

% 7. Start parallel pool
% Use about 80% of the available CPU cores
numCores   = feature('numcores');
maxWorkers = max(1, floor(0.8 * numCores));

pool = gcp('nocreate');
if isempty(pool)
    parpool('local', maxWorkers);
    fprintf('Started parallel pool with %d workers (of %d available cores).\n', maxWorkers, numCores);
else
    fprintf('Using existing parallel pool with %d workers.\n', pool.NumWorkers);
end


% 8. Define the asymmetry index formula
% i1 = original warped gray matter image
% i2 = mirrored warped gray matter image
% i3 = right hemisphere mask

% The formula calculates:
% AI = (original - mirrored) / mean(original, mirrored)

% Multiplication by the mask restricts the output to the selected hemisphere.
expr = '((i1 - i2)./((i1 + i2).*0.5)).*i3';
numSubs = numel(GM_orig);
fprintf('Starting parallel AI calculation for %d subjects...\n', numSubs);

% 9. Calculate AI maps in parallel
parfor i = 1:numSubs
    try
        orig_file = GM_orig{i};
        flip_file = GM_mirrored{i};
        ai_file   = AI_files{i};

        % Skip subject if the AI map already exists
        if isfile(ai_file)
            fprintf('Skipping subject %d (AI already exists).\n', i);
            continue
        end


        % Load original image, flipped image and mask
        vi1 = spm_vol(orig_file);
        vi2 = spm_vol(flip_file);
        vi3 = spm_vol(mask_file);
        vi  = [vi1; vi2; vi3];

        % Output image
        % Use the original image as template for the output AI image
        vo = vi1;
        vo.fname = ai_file;

        % Run SPM ImCalc to calculate and save the AI map
        spm_imcalc(vi, vo, expr, {[],[],[],1});

    catch ME
        % Continue with the next subject if one subject fails
        warning('Subject %d failed: %s', i, ME.message);
    end
end

fprintf('Step 6 complete: Parallel AI calculation finished.\n');

