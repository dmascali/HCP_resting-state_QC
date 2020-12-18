function create_groups_inter_subjects(metric,N,PhaseEconding)
% Construct two groups of subjects of size N maximazing their
% difference in METRIC. Given a PHASENCONDING, subjects are selected from
% the two runs.
%
% metric = char indicating the variable name in extracted_data
% N = group size
% PhaseEncoding = char indicating the phase enconding direction ('LR' or
% 'RL')

load('QC_database.mat');

%construct the table given the PhaseEconding. 
T = REST(strcmpi(REST.PhaseEncoding,{PhaseEconding}),:);

%find out the column number of the input metric
IND = find(cellfun(@(c)strcmpi(c,metric),T.Properties.VariableNames));

%remove NaNs
T(ismissing(T(:,IND)),:) = [];

%define the maximum N size:
Nmax = floor(height(T)/4);

if N >= Nmax
    error('The size of the group is greater than the maximum allowed.');
end

%we first construct the group with the highest value of the metric
High = sortrows(T,metric,'descend');

HIGH_GROUP = []; USED_ID = [];
Ntemp = 0; count = 0;
ID = str2num(High.ID);
while Ntemp < N
    count = count +1;
    %check if it's the first occurence of the ID
    if not(ismember(ID(count),USED_ID))
        USED_ID(end+1) = ID(count);
        HIGH_GROUP = [HIGH_GROUP; High(count,:)];
        Ntemp = Ntemp +1;
    end
end

% now construct the group with lowest value of the metric 
Low = sortrows(T,metric,'ascend');

LOW_GROUP = [];
Ntemp = 0; count = 0;
ID = str2num(Low.ID);
while Ntemp < N
    count = count +1;
    %check if it's the first occurence of the ID
    if not(ismember(ID(count),USED_ID))
        USED_ID(end+1) = ID(count);
        LOW_GROUP = [LOW_GROUP; Low(count,:)];
        Ntemp = Ntemp +1;
    end
end

[stats_metric.p,stats_metric.h,stats_metric.stats]  = ranksum(HIGH_GROUP{:,IND},LOW_GROUP{:,IND});

stats = []; count = 0;
for l = 4:width(HIGH_GROUP)
    count = count +1;
    stats(count).name = HIGH_GROUP.Properties.VariableNames{l};
    [stats(count).p,stats(count).h,stats(count).stats] =  ranksum(HIGH_GROUP{:,l},LOW_GROUP{:,l});

end


% save groups
output_name = ['groups_INTERsubjs_pe',PhaseEconding,'_n',num2str(N),'_',metric,'.mat'];
save(output_name,'LOW_GROUP','HIGH_GROUP','stats','stats_metric');


return
end