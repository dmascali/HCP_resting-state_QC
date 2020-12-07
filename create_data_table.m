function create_data_table

subjs = load ("HCPlist.txt"); %it should be in the path if you ran SetPath


output_folder = 'results';
if ~exist(output_folder, 'dir');mkdir(output_folder);end

REST1_LR = extract_run('REST1_LR',subjs);
REST1_RL = extract_run('REST1_RL',subjs);
REST2_LR = extract_run('REST2_LR',subjs);
REST2_RL = extract_run('REST2_RL',subjs);

save([output_folder,'/extracted_data'],'REST1_LR','REST1_RL','REST2_LR','REST2_RL');

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
            % Burges2016: to remove the impact of baseline differences in 
            % thermal noice across participants and focus on transient fluctuations
            [maskDVARS,censDVARS] = fmri_censoring_mask(dvars,thr.DVARS,'verbose',0);
            
            censFDDVARS = sum(not(maskFD.*maskDVARS));
            nvol = length(maskFD);% just in case of different lenght
  
            y = table(y.relRMS.mean,y.FDJenk.mean,y.FDPower.mean,... FD metrics
                censFD/nvol, censDVARS/nvol, censFDDVARS/nvol,... Percentage above thr metrics
                'VariableNames',{'relRMS','FDJenk','FDPower', ...
                                 'censFD', 'censDVARS',  'censFDDVARS' });
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