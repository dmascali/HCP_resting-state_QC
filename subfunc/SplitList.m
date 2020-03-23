function SplitList(list_path,group_names,group_sizes)
% SPLITLIST splits a list txt file in multiple sub-lists
%      list_path   = txt file
%      group_names = cell array with the name of the sub-lists
%      group_size  = [optional] size of each group in percentage values (0-1). 
%                    If not provided the sub-lists will have equal size.
%
% NB: the last sub-list may have a longer length to accomodate for
% rounding error. 
%
% E.g.:
% list_path = 'HCPlist.txt';
% sublist_names = {'aristotele_batch1',...
%                  'aristotele_batch2',...
%                  'cygnus_batch1',...
%                  'cygnus_batch2',...
%                  'platone_batch1',...
%                  'platone_batch2',...
%                  'democrito_batch1',...
%                  'democrito_batch2',...
%                  'parmenide_batch1',...
%                  'parmenide_batch2'};
% group_size = [0.11 0.11 0.11 0.11 0.11 0.11 0.06 0.06 0.11 0.11];
%__________________________________________________________________________
%Daniele Mascali - danielemascali@gmail.com

fid = fopen(list_path,'r');
line = fgets(fid);
list = {};
while line > 0
    list{end+1} = line;
    line = fgets(fid);
end
fclose(fid);
%-----------

% remove .txt if present and use it as basename for output
basename = remove_txt_ext(list_path);

N = length(list); %number of element in the list
M = length(group_names); %number of sublists to create

if M == 1
    disp('SplitList - Nothing to do. At least two groups are required.');
    return
end

if nargin == 3 && not(isempty(group_sizes))
   % check if group size sum to 1
   if sum(group_sizes) ~=1
      error('SplitList - group_size must add up to 1.'); 
   end   
   group_sizes = floor(group_sizes*N);
else
   group_sizes = repmat(floor(N/M),[1,M]);
end

start_index = 1;
end_index = group_sizes(1);
for l = 1:M-1
   write_list(list,[start_index:end_index],[basename,'_',remove_txt_ext(group_names{l})])
   start_index = end_index +1;
   end_index = start_index + group_sizes(l+1) -1;
end
% print last group out of the loop due to rounding
write_list(list,[start_index:N],[basename,'_',remove_txt_ext(group_names{l+1})])

return
end

function str = remove_txt_ext(str)

indx = strfind(str,'.txt');
if ~isempty(indx)
   str(indx:end) = []; 
end

return
end

function write_list(LIST,index,filename)
fid = fopen([filename,'.txt'],'w');
for l = index
    fprintf(fid,'%s',LIST{l});
end
fclose(fid);
return
end