function extract_HCP_for_denoising_evaluation(index)

%get list of subjects/runs
load('../results/example_groups/groups_INTRAsubjs_peRL_pct40_CensFDDVARS.mat');

%download folder
dest_folder = './DATA';
% HCP release
HCP_release = 'HCP_1200'; 

if nargin == 0
    index = [];
else
   HIGH_GROUP = HIGH_GROUP(index,:);  
   LOW_GROUP  = LOW_GROUP(index,:);  
end

%setup MatlabMailFeedback 
mail = 'danielemascali@gmail.com';
DeltaTime = 60*6; %every 6 hours sends a beacon
sendstatus(mail);

%get the phase encoding (is the same for all runs)
PH = HIGH_GROUP{1,3};

subj_list = HIGH_GROUP{:,1};

% create log
fid = fopen('log.txt','a');
fprintf(fid,['---> Extraction started',char(datetime('now')),'\n']);
fprintf(fid,['---> Indexes: ',num2str(index),'\n']);

for l = 1:size(subj_list,1)
    
    sendbeacon(mail,DeltaTime);
    
    subj = subj_list(l,:);

    FILE = {}; FILE_STATUS = []; TMP = [];% init
    % wmparc
    FILE{end+1} = ['MNINonLinear/wmparc.nii.gz'];
    % RP
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST1_',PH,'/Movement_Regressors.txt'];
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST2_',PH,'/Movement_Regressors.txt'];
    % nifti file without denoising
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST1_',PH,'/rfMRI_REST1_',PH,'.nii.gz'];
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST2_',PH,'/rfMRI_REST2_',PH,'.nii.gz'];
    % gifti file without denoising
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST1_',PH,'/rfMRI_REST1_',PH,'_Atlas.dtseries.nii'];
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST2_',PH,'/rfMRI_REST2_',PH,'_Atlas.dtseries.nii'];
    %files for FIX reconstruction
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST1_',PH,'/rfMRI_REST1_',PH,'_WM.txt'];
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST1_',PH,'/rfMRI_REST1_',PH,'_CSF.txt'];
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST1_',PH,'/rfMRI_REST1_',PH,'_hp2000.ica/.fix']; %noise
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST1_',PH,'/rfMRI_REST1_',PH,'_hp2000.ica/filtered_func_data.ica/melodic_mix']; %ICA components
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST1_',PH,'/rfMRI_REST1_',PH,'_Atlas_hp2000_clean_bias.dscalar.nii']; %bias field
    
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST2_',PH,'/rfMRI_REST2_',PH,'_WM.txt'];
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST2_',PH,'/rfMRI_REST2_',PH,'_CSF.txt'];
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST2_',PH,'/rfMRI_REST2_',PH,'_hp2000.ica/.fix']; %noise
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST2_',PH,'/rfMRI_REST2_',PH,'_hp2000.ica/filtered_func_data.ica/melodic_mix']; %ICA components
    FILE{end+1} = ['MNINonLinear/Results/rfMRI_REST2_',PH,'/rfMRI_REST2_',PH,'_Atlas_hp2000_clean_bias.dscalar.nii']; %bias field

    for f = 1:length(FILE)
        [FILE_STATUS, FILE_RESULT] = HcpDownloadCommand(subj,FILE{f},dest_folder,'HCP_release',HCP_release);
        if FILE_STATUS
            fprintf(fid,['ERR: subj ',subj]);
            fprintf(fid,['\tfile: ',FILE{f}]);
            fprintf(fid,['\tmsg: ',FILE_RESULT]);
        end
    end
    

end

fprintf(fid,['---> Extraction compleated ',char(datetime('now')),'\n']);

fclose(fid);



return
end