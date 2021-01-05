function process_data

data_folder = 'DATA';
cw = pwd; data_folder = [cw,'/',data_folder];

list_subj = dir([data_folder,'/*']);
list_subj(1:2) = [];

n_subj = length(list_subj);

for l = 1:n_subj
    
   subj_path = [data_folder,'/',list_subj(l).name]; 
   
   mkdir([subj_path,'/MNINonLinear'],'nuisance_masks');
   nuisance_mask_creation([subj_path,'/MNINonLinear/wmparc.nii.gz'],[subj_path,'/MNINonLinear/nuisance_masks'],[subj_path,'/MNINonLinear/Results/rfMRI_REST1_RL/rfMRI_REST1_RL.nii.gz']);
       
end

return
end

