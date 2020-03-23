function extract_HCP_data(list_path)

%---------------------------- Input variables -----------------------------
%download folder
dest_folder = './DATA';
% HCP release
HCP_release = 'HCP_1200'; 
%block to execute
flag_RP = 0;
flag_stats = 0;
flag_IB = 1; %ImageBased
% parameters for IB
TR = 0.72;
HP = 2000; 
WBCOMMAND = 'wb_command';
BCMODE = 'CORRECT';
OUTSTR
%--------------------------------------------------------------------------

%setup MatlabMailFeedback 
mail = 'danielemascali@gmail.com';
DeltaTime = 60*12; %every 12 hours send a beacon
sendstatus(mail);

%subject list file
fid = fopen(list_path);

ING = 'stats_dm'; %it is not used for loading stats, just to doublecheck results

subj = fgetl(fid); %get first subj ID
while subj > 0
    disp(['Doing subj: ',subj])
    subj_local_path = [dest_folder,'/',subj];
 
    if flag_RP
        % each block has a separate output file
        output_path = [dest_folder,'/',subj,'_QC_RP.mat'];
        
        %------------download files------------
        FILE = []; FILE_STATUS = []; TMP = [];% init
        FILE{1}     = 'MNINonLinear/Results/rfMRI_REST1_LR/Movement_Regressors.txt';
        FILE{end+1} = 'MNINonLinear/Results/rfMRI_REST2_LR/Movement_Regressors.txt';
        FILE{end+1} = 'MNINonLinear/Results/rfMRI_REST1_RL/Movement_Regressors.txt';
        FILE{end+1} = 'MNINonLinear/Results/rfMRI_REST2_RL/Movement_Regressors.txt';
         
        FILE{end+1} = 'MNINonLinear/Results/rfMRI_REST1_LR/Movement_RelativeRMS.txt';
        FILE{end+1} = 'MNINonLinear/Results/rfMRI_REST2_LR/Movement_RelativeRMS.txt';
        FILE{end+1} = 'MNINonLinear/Results/rfMRI_REST1_RL/Movement_RelativeRMS.txt';
        FILE{end+1} = 'MNINonLinear/Results/rfMRI_REST2_RL/Movement_RelativeRMS.txt';
         
        FILE{end+1} = 'MNINonLinear/Results/rfMRI_REST1_LR/rfMRI_REST1_LR_SBRef.nii.gz';
        FILE{end+1} = 'MNINonLinear/Results/rfMRI_REST2_LR/rfMRI_REST2_LR_SBRef.nii.gz';
        FILE{end+1} = 'MNINonLinear/Results/rfMRI_REST1_RL/rfMRI_REST1_RL_SBRef.nii.gz';
        FILE{end+1} = 'MNINonLinear/Results/rfMRI_REST2_RL/rfMRI_REST2_RL_SBRef.nii.gz';
%         
%         FILE{end+1} = ['unprocessed/3T/rfMRI_REST1_LR/',subj,'_3T_rfMRI_REST1_LR_SBRef.nii.gz'];
%         FILE{end+1} = ['unprocessed/3T/rfMRI_REST1_LR/',subj,'_3T_rfMRI_REST1_LR_SBRef.nii.gz'];
%         FILE{end+1} = ['unprocessed/3T/rfMRI_REST2_RL/',subj,'_3T_rfMRI_REST2_RL_SBRef.nii.gz'];
%         FILE{end+1} = ['unprocessed/3T/rfMRI_REST2_RL/',subj,'_3T_rfMRI_REST2_RL_SBRef.nii.gz'];
        
        for l = 1:length(FILE)
            FILE_STATUS(l) = hcp_download_command(subj,FILE{l},dest_folder,'HCP_release',HCP_release);
        end
        %--------------------------------------
        
        %-------------process files------------
        for l = 1:4 % four runs
            if ~FILE_STATUS(l)
                %load RP and save first 6 columns (discard expantion terms)
                rp = load([subj_local_path,'/',FILE{l}]);
                TMP(l).RP = rp(:,1:6); 
                %RelativeRMS
                TMP(l).relRMS.series = load([subj_local_path,'/',FILE{l+4}]);
                TMP(l).relRMS.mean = mean(TMP(l).relRMS.series);
                
                %Compute FDJenk and FDPower
                FDtmp = fmri_rp_metrics(rp,'HCP',[subj_local_path,'/',FILE{l+8}]);
                TMP(l).FDJenk.series = FDtmp.FDjenk;
                TMP(l).FDJenk.mean = mean(FDtmp.FDjenk);
                TMP(l).FDPower.series = FDtmp.FDpower;
                TMP(l).FDPower.mean = mean(FDtmp.FDpower);
            end
        end
        %--------------------------------------
        
        %-----------save extracted info--------
        if ~FILE_STATUS(1); REST1_LR = TMP(1); else REST1_LR = []; end
        if ~FILE_STATUS(2); REST2_LR = TMP(2); else REST2_LR = []; end
        if ~FILE_STATUS(3); REST1_RL = TMP(3); else REST1_RL = []; end
        if ~FILE_STATUS(4); REST2_RL = TMP(4); else REST2_RL = []; end
    
        try 
            save(output_path,'REST1_LR','REST2_LR','REST1_RL','REST2_RL','-append');
        catch 
            save(output_path,'REST1_LR','REST2_LR','REST1_RL','REST2_RL');
        end
        %--------------------------------------
    end
    
    if flag_stats
        % each block has a separate output file
        output_path = [dest_folder,'/',subj,'_QC_ImageBased.mat'];
        
        %------------download files------------
        FILE = []; FILE_STATUS = []; TMP = [];% init
        FILE{1}     = 'MNINonLinear/Results/rfMRI_REST1_LR/rfMRI_REST1_LR_Atlas_stats.txt';
        FILE{end+1} = 'MNINonLinear/Results/rfMRI_REST2_LR/rfMRI_REST2_LR_Atlas_stats.txt';
        FILE{end+1} = 'MNINonLinear/Results/rfMRI_REST1_RL/rfMRI_REST1_RL_Atlas_stats.txt';
        FILE{end+1} = 'MNINonLinear/Results/rfMRI_REST2_RL/rfMRI_REST2_RL_Atlas_stats.txt';
              
        for l = 1:length(FILE)
            FILE_STATUS(l) = hcp_download_command(subj,FILE{l},dest_folder,'HCP_release',HCP_release);
        end
        
        %--------------------------------------
        
        %-------------process files------------
        for l = 1:4 % four runs
            if ~FILE_STATUS(l)
                %load stats
                stats = readtable([subj_local_path,'/',FILE{l}]);
%                 % replace HCP processing path with subjID
%                 stats.TCSName = subj; 
                %table2struct
                stats = table2struct(stats);
                TMP(l).stats= stats; 
            end
        end
        %--------------------------------------
        
        %-----------save extracted info--------
        if ~FILE_STATUS(1); REST1_LR = TMP(1); else REST1_LR = []; end
        if ~FILE_STATUS(2); REST2_LR = TMP(2); else REST2_LR = []; end
        if ~FILE_STATUS(3); REST1_RL = TMP(3); else REST1_RL = []; end
        if ~FILE_STATUS(4); REST2_RL = TMP(4); else REST2_RL = []; end
         
        try 
            save(output_path,'REST1_LR','REST2_LR','REST1_RL','REST2_RL','-append');
        catch 
            save(output_path,'REST1_LR','REST2_LR','REST1_RL','REST2_RL');
        end
        %--------------------------------------
    end
    
    
    if flag_IB
        % each block has a separate output file
        output_path = [dest_folder,'/',subj,'_stats.mat'];
        
        %------------download files------------
        FILE = {}; FILE_STATUS = []; TMP = [];% init
        count = 0;
        for run = {'1'}%{'1','2'}
            for phase = {'LR'}%{'LR','RL'}
                count = count + 1;
                run_name = ['rfMRI_REST',run{1},'_',phase{1}];        
                FILE{end+1} = ['MNINonLinear/Results/',run_name,'/',run_name,'_Atlas.dtseries.nii'];
                FILE{end+1} = ['MNINonLinear/Results/',run_name,'/Movement_Regressors.txt'];  %re-download just in case RP was not run
                FILE{end+1} = ['MNINonLinear/Results/',run_name,'/',run_name,'_WM.txt'];
                FILE{end+1} = ['MNINonLinear/Results/',run_name,'/',run_name,'_CSF.txt'];
                FILE{end+1} = ['MNINonLinear/Results/',run_name,'/',run_name,'_hp2000.ica/.fix']; %noise
                FILE{end+1} = ['MNINonLinear/Results/',run_name,'/',run_name,'_hp2000.ica/filtered_func_data.ica/melodic_mix']; %ICA components
                FILE{end+1} = ['MNINonLinear/Results/',run_name,'/',run_name,'_Atlas_hp2000_clean_bias.dscalar.nii']; %bias field
                %FILE{end+1} = ['MNINonLinear/Results/',run_name,'/',run_name,'_Atlas_stats.txt'];
                % count the number of files per run
                if count == 1; NfilesPerRun = length(FILE); end
            end
        end
              
        for l = 1:length(FILE)
            %FILE_STATUS(l) = hcp_download_command(subj,FILE{l},dest_folder,'HCP_release',HCP_release);
            FILE_STATUS(l) = 0;
        end
        %--------------------------------------
        
%         %-------------process files------------
        for l = 1:1%4 % four runs
            if ~FILE_STATUS( (NfilesPerRun*(l-1) + 1) )
                sendbeacon(mail,DeltaTime);
                tic;
                % Run a modified version of the HCP's RestingStateStats
                TCs = RestingStateStats_mod( [subj_local_path,'/',FILE{(NfilesPerRun*(l-1) + 2)}] ,...
                  HP,...%HP
                  TR,...%TR
                  [subj_local_path,'/',FILE{(NfilesPerRun*(l-1) + 6)}],...
                  [subj_local_path,'/',FILE{(NfilesPerRun*(l-1) + 5)}],...%NOISE components
                  WBCOMMAND,...%WB command 
                  [subj_local_path,'/',FILE{(NfilesPerRun*(l-1) + 1)}],... %input series
                  [subj_local_path,'/',FILE{(NfilesPerRun*(l-1) + 7)}],...%BIAS
                  '',...output prefix
                  '',...dlabel
                  BCMODE,...bcmode
                  OUTSTRING,...outstring
                  [subj_local_path,'/',FILE{(NfilesPerRun*(l-1) + 3)}],...
                  [subj_local_path,'/',FILE{(NfilesPerRun*(l-1) + 4)}]); t=toc; readsec(t);
              
                TMP(l).TCs= TCs; 
            end
        end
%         %--------------------------------------
%         
%         %-----------save extracted info--------
        if ~FILE_STATUS(1); REST1_LR = TMP(1); else REST1_LR = []; end
        if ~FILE_STATUS(2); REST2_LR = TMP(2); else REST2_LR = []; end
        if ~FILE_STATUS(3); REST1_RL = TMP(3); else REST1_RL = []; end
        if ~FILE_STATUS(4); REST2_RL = TMP(4); else REST2_RL = []; end
         
        try 
            save(output_path,'REST1_LR','REST2_LR','REST1_RL','REST2_RL','-append');
        catch 
            save(output_path,'REST1_LR','REST2_LR','REST1_RL','REST2_RL');
        end
        %--------------------------------------
    end 
       
    %--------------remove files------------
    % remove the whole subj folder
    system(['rm -r ',subj_local_path]);
    %--------------------------------------
    
    %get next subj ID
    subj = fgetl(fid);
end


fclose(fid);






return
end