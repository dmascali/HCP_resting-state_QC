function explore_results

close all

load('extracted_data.mat');

col =7 ;

Y{1} = table2array(REST1_LR(:,col ));
Y{2} = table2array(REST1_RL(:,col ));
Y{3} = table2array(REST2_LR(:,col ));
Y{4} = table2array(REST2_RL(:,col ));
labels = {'REST1 LR','REST1 RL', 'REST2 LR', 'REST2 RL'};

figure;
nbins = 100;
subplot(3,1,1);

histogram(Y{1},nbins);
hold on;
histogram(Y{2},nbins);
legend('LR','RL');
title('REST1');

subplot(3,1,2);

histogram(Y{3},nbins);
hold on;
histogram(Y{4},nbins);
title('REST2');
legend('LR','RL');

subplot(3,1,3);
boxplot([Y{1},Y{2},Y{3},Y{4}]);
set(gca,'XtickLabel',labels);
camroll(-90)

[h,p,ci,stats] = ttest(Y{3},Y{4})

figure; 
subplot(1,6,1)
scatter(Y{1},Y{2});
subplot(1,6,2)
scatter(Y{1},Y{3});
subplot(1,6,3)
scatter(Y{1},Y{4});
subplot(1,6,4)
scatter(Y{2},Y{3});
subplot(1,6,5)
scatter(Y{2},Y{4});
subplot(1,6,6)
scatter(Y{3},Y{4});


% [mindist_LR,min_indx] = min([Y{1},Y{3}],[],2);
% [maxdist_LR,max_indx] = max([Y{1},Y{3}],[],2);
% 
% Nsubj = 350;
good = find(Y{1} < prctile(Y{1},20));
bad  = find(Y{1} > prctile(Y{1},80)); bad(end) = [];

Z = [];
count = 1;
indx = [8 9 10];
for l = indx
    
    Z{1,count} = [table2array(REST1_LR(good,l)),table2array(REST1_LR(bad,l))];
    count = count +1;
end
figure; boxplotGroup(Z)

Z = [];
Z{1,1} = [table2array(REST1_LR(good,8))./table2array(REST1_LR(good,10)),table2array(REST1_LR(bad,8))./table2array(REST1_LR(bad,10))];
Z{1,2} = [table2array(REST1_LR(good,9))./table2array(REST1_LR(good,10)),table2array(REST1_LR(bad,9))./table2array(REST1_LR(bad,10))];
figure; boxplotGroup(Z)


figure; boxplot([REST1_LR.CNR(good),REST1_LR.CNR(bad)]);

figure; boxplot([REST1_LR.MotionVar(good),REST1_LR.MotionVar(bad)]);


return
end