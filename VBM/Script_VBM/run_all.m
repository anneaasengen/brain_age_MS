function run_all()


% RUN_ALL
%
% This script automatically runs the full VBM pipeline from
% Step 1 to Step 7 by executing each MATLAB script in sequence.
%
% Pipeline order:
%   step1.m
%   step2.m
%   step3.m
%   step4.m
%   step5.m
%   step6.m
%   step7.m
%
% Run from the MATLAB command window using:
%   >> run_all


clc;
fprintf('\n====================================================\n');
fprintf('         STARTING FULL VBM PIPELINE\n');
fprintf('====================================================\n\n');

% 1. Define all pipeline steps
% Each row contains:
% Column 1 = script/function name
% Column 2 = short description shown in the terminal
steps = {
    "step1",  "CAT12 segmentation (Step 1)";
    "step2",  "Flipping warped GM/WM–files (Step 2)";
    "step3",  "Create a symmetric DARTEL template (Step 3)";
    "step4",  "Normalization / modulation (Step 4)";
    "step5",  "Create a right-hemisphere mask (Step 5)";
    "step6",  "Calculating Asymmetry Index / Asymetry maps (Step 6)";
    "step7",  "FSmoothing (Step 7)"
    };

total_steps = size(steps,1);

% Start total runtime timer
tic; 

% 2. Run all steps sequentially
for i = 1:total_steps
    step_name = steps{i,1};
    step_desc = steps{i,2};

    fprintf('\n----------------------------------------------------\n');
    fprintf(' [%d/%d] Running %s — %s\n', i, total_steps, step_name, step_desc);
    fprintf('----------------------------------------------------\n');

    % Start timer for this individual step
    t_step = tic;

    try
        % Execute the current script/function
        feval(step_name);
        fprintf(' %s completed på %.1f seconds.\n', step_name, toc(t_step));

    catch ME
        % Print error message if one step fails
        fprintf(' ERROR in %s:\n   %s\n', step_name, ME.message);
        % Continue to the next step even if one fails
        fprintf('   Pipeline continues to the next step.\n');
    end
end

fprintf('\n====================================================\n');
fprintf('          PIPELINE COMPLETED (Step 1 → Step 7)\n');
fprintf('====================================================\n');

% Print total runtime in minutes
fprintf('\nTotal runtime: %.1f minutes\n', toc/60);
fprintf('====================================================\n\n');

end

