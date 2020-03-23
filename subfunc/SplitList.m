function SplitList(list,sublist_names,group_size)

list = 'subject_list.txt';

sublist_names = {'HCPsubList_aristotele_batch1',...
                 'HCPsubList_aristotele_batch2',...
                 'HCPsubList_parmenide_batch1',...
                 'HCPsubList_parmenide_batch2',...
                 'HCPsubList_platone_batch1',...
                 'HCPsubList_platone_batch2',...
                 'HCPsubList_democrito_batch1',...
                 'HCPsubList_democrito_batch2',...
                 'HCPsubList_cygnus_batch1',...
                 'HCPsubList_cygnus_batch2'};

group_size = [0.11 0.11 0.11 0.11 0.11 0.11 0.06 0.06 0.11 0.11];

             
% read the file
fid = fopen(list,'r');
line = fgets(fid);
list = {};
while line > 0
    list{end+1} = line;
    line = fgets(fid);
end
fclose(fid);
%-----------

N = length(list); %number of element in the list
M = length(sublist_names); %number of sublists to create

if M == 1
    disp('SplitList - Nothing to do. At least two groups are required.');
    return
end

if nargin == 3 && not(isempty(group_size))
   % check if group size sum to 1
   if sum(group_size) ~=1
      error('SplitList - group_size must add up to 1.'); 
   end
    
end

group_size = floor(N/M);

start_index = 1;
end_index = group_size;
for l = 1:M-1
   write_list(list,[start_index:end_index],sublist_names{l})
   start_index = end_index +1;
   end_index = start_index + group_size -1;
end
% print last group out of the loop due to rounding
write_list(list,[start_index:N],sublist_names{l+1})



return
end

function write_list(LIST,index,filename)
fid = fopen(filename,'w');
for l = index
    fprintf(fid,'%s',LIST{l});
end
fclose(fid);
return
end