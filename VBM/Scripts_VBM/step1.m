% Step 1: CAT12 segmentation of T1-weighted MRI scans

% This script runs the first step of the VBM pipeline. Each T1-weighted image
% is segmented with CAT12/SPM12 to generate gray matter, white matter and
% partial volume estimate images, as well as deformation fields needed in
% later preprocessing steps.

% The script is written so that it can be restarted if it is interrupted.
% Subjects with the expected output files already present are skipped.

% 1. Define the main project folders and the symmetric tissue probability map
base_dir    = '/media/anneaasengen/CEVAULT2TB'; 
project_dir = fullfile(base_dir, 'VBM_project_HCP');
t1_outdir   = fullfile(project_dir, 'T1_scans'); 
tpm_file    = fullfile(project_dir, 'TPM_symmetric.nii'); 


% 2. Find all HCP T1-weighted images stored in the expected folder structure
% Each subject has its own subfolder inside T1_scans
t1_files = dir(fullfile(t1_outdir, '*', 'T1w_acpc_dc_restore.nii'));
t1_paths = arrayfun(@(f) fullfile(f.folder, f.name), t1_files, 'UniformOutput', false);

fprintf('Found %d T1-weighted images.\n', numel(t1_paths));

% 3. Initialize SPM before running CAT12 batch jobs
spm('defaults','FMRI');
spm_jobman('initcfg');


% 4. Start a parallel pool to process several subjects at the same time
% The number of workers is limited to avoid overloading the computer
maxWorkers = 4;
p = gcp('nocreate');
if isempty(p)
    parpool('Processes', maxWorkers);
    fprintf('Started parallel pool with %d workers.\n', maxWorkers);
elseif p.NumWorkers > maxWorkers
    delete(p);
    parpool('Processes', maxWorkers);
    fprintf('Restarted parallel pool with %d workers.\n', maxWorkers);
else
    fprintf('Using existing parallel pool with %d workers.\n', p.NumWorkers);
end


% 5. Run CAT12 segmentation for each subject
parfor i = 1:numel(t1_paths)
    subj_file = t1_paths{i};

    % Extract the subject ID from the subject folder name
    [subj_root, ~, ~] = fileparts(subj_file);
    [~, subj_id, ~]   = fileparts(subj_root);

    % CAT12 stores its output files in an 'mri' subfolder
    subj_out_dir = fullfile(subj_root, 'mri');
    if ~exist(subj_out_dir, 'dir')
        mkdir(subj_out_dir);
    end

    % The T1 image has the same base filename for all subjects
    base_name = 'T1w_acpc_dc_restore';

    % Expected output files
    % These files are checked before processing so that completed subjects
    % are not processed again.
    rp1_file = fullfile(subj_out_dir, ['rp1' base_name '_affine.nii']);
    rp2_file = fullfile(subj_out_dir, ['rp2' base_name '_affine.nii']);
    p0_file  = fullfile(subj_out_dir, ['p0' base_name '.nii']);
    y_file   = fullfile(subj_out_dir, ['y_' base_name '.nii']);

    % Skip if all outputs already exist
    if isfile(rp1_file) && isfile(rp2_file) && isfile(p0_file) && isfile(y_file)
        fprintf('Skipping %s – already processed.\n', subj_id);
        continue
    end

    fprintf('Processing %d/%d: %s\n', i, numel(t1_paths), subj_id);


    % Run CAT12 segmentation
    try
        % Set up a CAT12 segmentation batch for the current subject
        matlabbatch = {};
        matlabbatch{1}.spm.tools.cat.estwrite.data = {subj_file};

        % Use the symmetric tissue probability map so that the later
        % asymmetry analysis is not biased by an asymmetric template.
        matlabbatch{1}.spm.tools.cat.estwrite.opts.tpm = {[tpm_file ',1']};

        % Output options
        % Save native-space and affine-registered gray matter outputs
        matlabbatch{1}.spm.tools.cat.estwrite.output.GM.native   = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.GM.dartel   = 2; % affine
        
        % Save native-space and affine-registered white matter outputs
        matlabbatch{1}.spm.tools.cat.estwrite.output.WM.native   = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.WM.dartel   = 2; % affine

        % Save label/partial volume estimate outputs used in later steps
        matlabbatch{1}.spm.tools.cat.estwrite.output.label.native = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.label.dartel = 2; % affine (rp0)

        
        % Run CAT12 segmentation for the current subject.
        spm_jobman('run', matlabbatch);
        fprintf('Finished segmentation for %s\n', subj_id);

    catch ME
        % Continue with the next subject if segmentation fails for one case
        warning('Segmentation failed for %s: %s', subj_id, ME.message); 
    end
end

fprintf('------------------------------------------------------------\n');
fprintf('Step 1 complete: all available subjects processed or skipped.\n');
fprintf('------------------------------------------------------------\n');

