%% load the trained model 
load('MRD_JS1_Tasks_6.mat')

%% Draw ARD weights  (fig 4a in the manuscript )
% ARD weights bascially let us know the improtance of a latent dimension in
% reconstruction of the higher dimensional spaces.
figure;
svargplvmShowScales(model); % prints the combined ARD weights plot 
set(gca, 'YTick',0.1:0.1:1,'FontSize', 15,'Fontweight','Bold');
set(gca, 'XTick',1:5:35, 'FontSize',20,'Fontweight','Bold');
set(gca, 'XLim', [0 32], 'XGrid', 'off');
xlabel('Latent dimension in shared space(X)','FontSize',20,'Fontweight','Bold');   
ylabel('Scaled ARD Weights','FontSize',20,'Fontweight','Bold');
legend('EMG','Kinematics');
%% Show Signal to noise ratio ( atleast it should be greater than 10 ) 
SNR = svargplvmSNR(model)

%% muscle activation and kinematics reconstruction from the latent space (Fig- 4 and Fig 5 and fig 6 in the manuscript)
%%% change the value of dim1 and dim2 to the desired latent dimension to reconstruct the higher dimensional spaces  
clf;
Y_task_wise = ones(4000,8)*5; %% dummy, just to manage code
% set the value below variables accordingly 
%%%%
subject_no = 1
dim1=  9;     dim2 = 10;
 %%%
background_plot  = Y_task_wise(1:30:end,:);
lvmVisualiseGeneralEmgMocap(model, [], dim1, dim2,subject_no , ...
                                        'handMocapVisualiseKINE','handMocapModifyKINE',...
                                        'handMocapVisualiseEMG_BAR','handMocapModifyEMG_BAR',...
                                         true, background_plot);


%% calculate time for one prediction
tic
[ZpredAll_test, testLatentPoints] =  MRD_Predict_NN_Y2Z(model, Y_ds_tr_1,Y_ds_tr_2);
total_time = toc;
noOfSamples= size(Y_ds_ts_1,1);
oneSampleTime =  total_time/noOfSamples;
%% Predict the training error from the muscle activations
% Y_ds_tr_1 represetns trainng muscle activation values 
% Y_ds_tr_2 represents testing muscle activation values 
[ZpredAll_test, testLatentPoints] =  MRD_Predict_NN_Y2Z(model, Y_ds_tr_1,Y_ds_tr_2);
%% Predict test data points 
[ZpredAll_test, testLatentPoints] =  MRD_Predict_NN_Y2Z(model, Y_ds_ts_1,Y_ds_ts_2);
%% Predict all points except training data points 
index_of_training_points = ismember(Y_raw, Y_ds_tr_1);
Y_raw_except_train = Y_raw(~index_of_training_points(:,1),:);
Z_raw_except_train = Z_raw(~index_of_training_points(:,1),:);
tic;
[ZpredAll_test, testLatentPoints] =  MRD_Predict_NN_Y2Z(model, Y_raw_except_train,Z_raw_except_train);
total_time = toc;
%% 