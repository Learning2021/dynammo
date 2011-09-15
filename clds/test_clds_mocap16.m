DATAFILE='../motion16-labeled.1.mat';

%% test on the mocap data
clear;
load(DATAFILE);
classind = [find(class==2); find(class==3)];
% 2 = walking, 3 = running
% random permutation
classind = classind(randperm(length(classind)));
trueclass = class(classind);

% build data in X
X9 = motion_dim{9}(:, classind);  %lhipjoint.z
X15 = motion_dim{15}(:, classind);  %ltibia.z
X18 = motion_dim{18}(:, classind);  %lfoot.z
X24 = motion_dim{24}(:, classind);  %rhipjoint.z
X33 = motion_dim{33}(:, classind);  % rfoot.z


X = X33';
%X = X33(1:50, :)';
%X = X33(1:100, :)';

[model_train, LL] = learn_clds(X, 'Hidden', 4, 'MaxIter', 10000);
features = abs(model_train.C);
pred = kmeans(features, 2, 'distance', 'correlation', 'replicates', 10);
cm = confusionmat(pred, trueclass);
ce = condentropy(pred, trueclass);

disp('CLDS conditional entropy');
disp(ce);

[coeff1, score1] = princomp(features(:, 1:end), 'econ');

figure;
hold all;
scatter(score1(trueclass==2, 1), score1(trueclass==2, 2), 'd', 'DisplayName', 'walking');
scatter(score1(trueclass==3, 1), score1(trueclass==3, 2), 'r*', 'DisplayName', 'running');
legend('show', 'Location', 'best');
export_fig 'scatter-mocap16-rfootz-clds.pdf' '-pdf'


%% for baseline: PCA + kmean
[coeff, score] = princomp(X, 'econ');
figure;
hold all;
scatter(score(trueclass==2, 1), score(trueclass==2, 2), 'bd');
scatter(score(trueclass==3, 1), score(trueclass==3, 2), 'r*');
axis equal;
xlabel('PC1');
ylabel('PC2');
export_fig 'scatter-mocap16-rfootz-pca.pdf' '-pdf'

pred_pca = kmeans(score(:, 1:2), 2, 'distance', 'correlation', 'replicates', 10);
cm_pca = confusionmat(pred_pca, trueclass);
ce_pca = condentropy(pred_pca, trueclass);

disp('PCA+Kmeans conditional entropy');
disp(ce_pca);

%% FFT
xft = fft(X');
xft = xft';
[coeff_ft, score_ft] = princomp(abs(xft));
ggg = kmeans(score_ft(:, 1:2), 2, 'Distance', 'correlation', 'Display','final', 'replicates', 10);
cm_fft = confusionmat(ggg, trueclass);
ce_fft = condentropy(cm2);

figure;
hold all;
scatter(score_ft(trueclass==2, 1), score_ft(trueclass==2, 2), 'd', 'DisplayName', 'walking');
scatter(score_ft(trueclass==3, 1), score_ft(trueclass==3, 2), 'r*', 'DisplayName', 'running');
legend('show', 'Location', 'best');
export_fig 'scatter-mocap16-rfootz-fft.pdf' '-pdf'

disp('FFT+Kmeans conditional entropy');
disp(ce_fft);


%% LDS
[model_lds, LL_lds ] = learn_lds(X, 'Hidden', 8, 'MaxIter', 100);
[coeff_lds, score_lds] = princomp(model_lds.C, 'econ');
pred_lds = kmeans(score_lds(:,1:2), 2, 'distance', 'correlation');
cm_lds= confusionmat(pred_lds, trueclass);
ce_lds = condentropy(pred_lds, trueclass);

figure;
hold all;
scatter(score_lds(trueclass==2, 1), score_lds(trueclass==2, 2), 'bd');
scatter(score_lds(trueclass==3, 1), score_lds(trueclass==3, 2), 'r*');

export_fig 'scatter-mocap16-rfootz-lds.pdf' '-pdf'
disp('LDS conditional entropy');
disp(ce_fft);

%% DTW
[f_dtw, cm_dtw, cmh_dtw] = dtw_cluster(X', trueclass);