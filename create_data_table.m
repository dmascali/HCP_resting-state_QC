function create_data_table

subjs = load ("HCPlist.txt"); %it should be in the path if you ran SetPath


output_folder = 'results';
if ~exist(output_folder, 'dir');mkdir(output_folder);end

REST1_LR = extract_run('REST1_LR',subjs);
REST1_RL = extract_run('REST1_RL',subjs);
REST2_LR = extract_run('REST2_LR',subjs);
REST2_RL = extract_run('REST2_RL',subjs);

save([output_folder,'/QC_database.mat'],'REST1_LR','REST1_RL','REST2_LR','REST2_RL');

% Create a table that contains all runs (redundant but handy)
% add run number as double
REST1_LR.Run = ones(height(REST1_LR),1);
REST1_RL.Run = ones(height(REST1_LR),1);
REST2_LR.Run = 2*ones(height(REST1_LR),1);
REST2_RL.Run = 2*ones(height(REST1_LR),1);
% add PhaseEncoding
REST1_LR.PhaseEncoding = repmat('LR',height(REST1_LR),1);
REST1_RL.PhaseEncoding = repmat('RL',height(REST1_LR),1);
REST2_LR.PhaseEncoding = repmat('LR',height(REST1_LR),1);
REST2_RL.PhaseEncoding = repmat('RL',height(REST1_LR),1);
% combine and reordinate table
REST = [REST1_LR(:,[1 end-1:end 2:end-2]); ...
        REST1_RL(:,[1 end-1:end 2:end-2]); ...
        REST2_LR(:,[1 end-1:end 2:end-2]); ...
        REST2_RL(:,[1 end-1:end 2:end-2])];

save([output_folder,'/QC_database.mat'],'REST','-append');
    
return
end


function T = extract_run(run,subjs)

flag_RP = 1;
flag_IB_stats = 1; %ImageBased stats
flag_struct = 0;   %aseg.stats

Tid = table(num2str(subjs),'VariableNames',{'ID'});

thr.FD = 0.39; %Burges2016, FDPower
thr.DVARS = 4.9; %Burges2016, median centered DVARS 


Tstats = [];
Trp = [];
total = length(subjs);
reverseStr  = '';
for l = 1:total 
    
    
    if flag_RP
        RP = load(['./DATA/',num2str(subjs(l)),'_QC_RP.mat']);
        eval(['y=RP.',run,';']);
        if not(isempty(y))
            % Define percentage of censored volumes according to FD and
            % DVARS
            [maskFD,censFD] = fmri_censoring_mask(y.FDPower.series,thr.FD,'verbose',0);
            
            TCs = load(['./DATA/',num2str(subjs(l)),'_QC_IB_tcs.mat']);
            eval(['TCs=TCs.',run,';']);
            if not(isempty(TCs))
                %this might be empty because 6 subjs do not have the
                %atlas.dtseries
                dvars = TCs.TCs.OrigDV - median(TCs.TCs.OrigDV);
                % Burges2016: to remove the impact of baseline differences in 
                % thermal noice across participants and focus on transient fluctuations
                [maskDVARS,censDVARS] = fmri_censoring_mask(dvars,thr.DVARS,'verbose',0);

                censFDDVARS = sum(not(maskFD.*maskDVARS));
                nvol = length(maskFD);% just in case of different lenght
            else
                censDVARS = NaN;
                censFDDVARS = NaN;
            end
  
            y = table(y.relRMS.mean,y.FDJenk.mean,y.FDPower.mean,... FD metrics
                censFD/nvol, censDVARS/nvol, censFDDVARS/nvol,... Percentage above thr metrics
                'VariableNames',{'RelRMS','FDJenk','FDPower', ...
                                 'CensFD', 'CensDVARS',  'CensFDDVARS' });
            Trp = cat(1,Trp,y);
        else
            varnames = Trp.Properties.VariableNames;
            y = array2table(nan(1,length(varnames)), 'VariableNames',varnames);
            Trp = cat(1,Trp,y);
        end
    end
    
   
    if flag_IB_stats
        IB = load(['./DATA/',num2str(subjs(l)),'_QC_IB_stats.mat']);
        eval(['y=IB.',run,';']);
        if not(isempty(y))
            y = y.stats;
            y = struct2table(y);
            Tstats = cat(1,Tstats,y(1,2:end));
        else
            varnames = Tstats.Properties.VariableNames;
            y = array2table(nan(1,length(varnames)), 'VariableNames',varnames);
            Tstats = cat(1,Tstats,y);
        end
    end
    percentDone = 100 * l / total;
    msg = sprintf('Percent done: %3.1f (%s)', percentDone,run);
    fprintf([reverseStr, msg]);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));   
end

fprintf('\n');

T = [Tid,Trp,Tstats];

return
end