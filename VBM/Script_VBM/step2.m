% VBM Step 2: Create left-right flipped versions of the affine CAT12 outputs

% This script takes the affine tissue images from Step 1 and flips them along
% the left-right image dimension. The flipped images are needed later when the
% original and mirrored hemispheres are compared to calculate asymmetry maps.

% For this dataset, the left-right direction has been verified to correspond
% to dimension 1 for rp0, rp1 and rp2 images.

% 1. Define the main project folders
base_dir    = '/media/anneaasengen/CEVAULT2TB';
project_dir = fullfile(base_dir, 'VBM_project_HCP');
t1_dir      = fullfile(project_dir, 'T1_scans');


% 2. Find the affine CAT12 output images from Step 1
% rp0 contains the partial volume estimate/label image, rp1 contains gray matter,
% and rp2 contains white matter.
files_rp0 = dir(fullfile(t1_dir, '*', 'mri', 'rp0*_affine.nii'));
files_rp1 = dir(fullfile(t1_dir, '*', 'mri', 'rp1*_affine.nii'));
files_rp2 = dir(fullfile(t1_dir, '*', 'mri', 'rp2*_affine.nii'));

% Combine all tissue files into one list so they can be processed together
affine_files = [files_rp0; files_rp1; files_rp2];


% Stop the script if no input files were found. This usually means that Step 1
% has not been completed, or that the folder path does not match the data structure.
if isempty(affine_files)
    error('No affine rp0/rp1/rp2 files found. Did you finish Step 1?');
end

fprintf('Found %d affine images to check for flipping.\n', numel(affine_files));


% 3. Configure parallel pool automatically:
% Use most of the available CPU cores, but leave some resources free so the
% computer remains responsive while the script is running.
numCores   = feature('numcores');
maxWorkers = max(1, floor(0.8 * numCores)); % use 80% of cores

% Start a parallel pool if one is not already running
p = gcp('nocreate');
if isempty(p)
    parpool('Processes', maxWorkers);
    fprintf('Started parallel pool with %d workers (of %d available cores).\n', maxWorkers, numCores);
else
    fprintf('Using existing parallel pool with %d workers.\n', p.NumWorkers);
end

% 4. Parallel flipping:
fprintf('\nFlipping images in parallel along dim1 (Left–Right)...\n');

% Process all affine tissue images in parallel
parfor i = 1:numel(affine_files)
    in_file = fullfile(affine_files(i).folder, affine_files(i).name);
    [pdir, n, e] = fileparts(in_file);

    % The flipped image is saved in the same folder as the original image
    out_file = fullfile(pdir, [n '_flipped' e]);

    % Skip files that have already been flipped
    % This makes the script safe to restart if it was interrupted before all subjects were processed.
    if isfile(out_file)
        fprintf('Skipping %s (already flipped)\n', n);
        continue;
    end

    try
        % Read the NIfTI header and voxel data using SPM
        V = spm_vol(in_file);
        X = spm_read_vols(V);
        
        % Copy the original header and update the filename and description for
        % the new flipped image.
        Vout = V;
        Vout.fname   = out_file;
        Vout.descrip = [V.descrip ' (flipped dim1)'];

        % Remove private SPM metadata to avoid conflicts inside the parfor loop
        Vout.private = []; % avoid parfor conflicts
        
        % Flip the voxel matrix along dimension 1, corresponding to the
        % left-right axis in this dataset, and write it as a new NIfTI file.
        spm_write_vol(Vout, flip(X,1));
        fprintf(' Flipped %s\n', n);
    
    catch ME
        % Continue with the remaining files if one image fails
        warning('Error flipping %s: %s', n, ME.message);
    end
end

fprintf('\nStep 2 complete: All rp0/rp1/rp2 images flipped along dim 1 (LR).\n');


fprintf('\nVerification step complete.\n');

