function create_groups_intra_subjects(metric,Pct,PhaseEconding)
% Construct two groups of repeted scans form the same subjects for intra-subject
% comparisons.
%
% metric = string indicating the variable name in extracted_data to use for
%          selecting subjs
% Pct = [0-100] percentile value used for dividing the distribution of the
%       metric: low where ( metric < Pct ) and high where metric > (100-Pct) 
%       Subjs with runs having metric values falling in the two sets 
%       will be selected. 
% PhaseEncoding = string indicating the phase enconding direction ('LR' or
%                 'RL')

load('QC_database.mat');

% add run number as double
REST1_LR.Run = ones(height(REST1_LR),1);
REST1_RL.Run = ones(height(REST1_LR),1);
REST2_LR.Run = 2*ones(height(REST1_LR),1);
REST2_RL.Run = 2*ones(height(REST1_LR),1);

switch PhaseEconding
    case {'lr','LR'}
        REST1_LR.PhaseEncoding = repmat('LR',height(REST1_LR),1);
        REST2_LR.PhaseEncoding = repmat('LR',height(REST1_LR),1);
        T1 = REST1_LR;
        T2 = REST2_LR;
        
    case {'rl','RL'}
        REST1_RL.PhaseEncoding = repmat('RL',height(REST1_LR),1);
        REST2_RL.PhaseEncoding = repmat('RL',height(REST1_LR),1);
        T1 = REST1_RL;
        T2 = REST2_RL;
end
%reordinate table
T1 = T1(:,[1 end-1:end 2:end-2]);
T2 = T2(:,[1 end-1:end 2:end-2]);


%find out the column number of the input metric
IND = find(cellfun(@(c)strcmpi(c,metric),T1.Properties.VariableNames));

% construct combined distribution
X = table2array([T1(:,IND);T2(:,IND)]);
LIMIT_LOW = prctile(X,Pct);
LIMIT_HIGH = prctile(X,100-Pct);

count = 0;
HIGH_GROUP = [];
LOW_GROUP = [];
for l = 1:height(T1)
   count = count +1;
   if ismissing(T1(l,IND)) || ismissing(T2(l,IND)) 
       continue;
   end
   if T1{l,IND} <= LIMIT_LOW && T2{l,IND} >= LIMIT_HIGH
       LOW_GROUP = [LOW_GROUP; T1(l,:)];
       HIGH_GROUP = [HIGH_GROUP; T2(l,:)];
   elseif T2{l,IND} <= LIMIT_LOW && T1{l,IND} >= LIMIT_HIGH
       LOW_GROUP = [LOW_GROUP; T2(l,:)];
       HIGH_GROUP = [HIGH_GROUP; T1(l,:)];
   end
end
% figure; boxplot([LOW_GROUP{:,IND},HIGH_GROUP{:,IND}]);
% DIFF = [LOW_GROUP{:,IND} - HIGH_GROUP{:,IND}];
% figure; boxplot(DIFF);

[stats_metric.p,stats_metric.h,stats_metric.stats]  = signrank(HIGH_GROUP{:,IND},LOW_GROUP{:,IND});

stats = []; count = 0;
for l = 4:width(HIGH_GROUP)
    count = count +1;
    stats(count).name = HIGH_GROUP.Properties.VariableNames{l};
    [stats(count).p,stats(count).h,stats(count).stats] =  signrank(HIGH_GROUP{:,l},LOW_GROUP{:,l});

end

% save groups
output_name = ['groups_INTRAsubjs_pe',PhaseEconding,'_pct',num2str(Pct),'_',metric,'.mat'];
save(output_name,'LOW_GROUP','HIGH_GROUP','stats','stats_metric');


return
end