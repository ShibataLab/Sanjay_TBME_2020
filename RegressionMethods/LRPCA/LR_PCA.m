%%%% Evaluating on different regression methods

%clear all; clc; close all;
 function [corr_tr,corr_ts,rmse_tr,rmse_ts,corr_et,rmse_et,r_tr,r_ts_et,oneSampleTime,net,idx]=  LR_PCA(dsfilt_musAct, lpfilt_trc_p23rot)
    %%% training: get the first trial of each set
    %% get all data in 
    disp('insdie')
    trInd =  [1 2 3 4 5];  
    ds = 30;
    rng(1234)
    Y_raw = [];     Z_raw = [];
    Y_raw_ts = [];     Z_raw_ts = [];
        mcp_idx = [1 2 3 4 5 6 7 8 9 10 11 12 49 50 51];
    pip_idx = [13 14 15 22 23 24 31 32 33 40 41 42 52 53 54];  
    for j = 1:7% task
        for i = 1:5 %all 5 train trial
            intr = trInd(i);
            Y_raw = [Y_raw; dsfilt_musAct{intr,j}];
            Z_raw = [Z_raw; lpfilt_trc_p23rot{intr,j}];
        end
%       
    end

%Z_raw =Z_raw(:,pip_idx);
%% permuting the data sequence

% idx=randperm(size(Y_raw,1));
% Y_raw = Y_raw(idx,:);
% Z_raw =  Z_raw(idx,:);  
%% normalizeation
 [Y_raw_n, muY, sigmaY] = featureNormalize(Y_raw);
 [Z_raw_n, muZ, sigmaZ] = featureNormalize(Z_raw);
 

%% Apply pca

    [Uy, Sy] = pca(Y_raw_n);
    Y_raw_n_proj = projectData(Y_raw_n, Uy, 5);        % project to 5-dimension 
  
    [Uz, Sz] = pca(Z_raw_n);
    Z_raw_n_proj = projectData(Z_raw_n, Uz, 9);        % project to 9-dimension 
 [mz nz]= size(Z_raw_n_proj)
    
       Z_ds_tr_n_proj_r_pred_rec       =  recoverData(Z_raw_n_proj, Uz, 9);    %recover to full dimension
    Z_ds_tr_n_proj_r_pred_rec_dn    = (Z_ds_tr_n_proj_r_pred_rec .* repmat(sigmaZ, mz,1)) + repmat(muZ, mz,1);
    
    
%%  train and test data (70% 30 %)
total_samples=size(Y_raw_n_proj,1);
train_samples= floor((total_samples*70)/100);
test_start_count =train_samples+1;
% train data
Y_all_tr_n_proj = Y_raw_n_proj(1:train_samples,:);
Z_all_tr_n_proj = Z_raw_n_proj(1:train_samples,:);
% test data
Y_all_ts_n_proj = Y_raw_n_proj(test_start_count:end,:);
Z_all_ts_n_proj = Z_raw_n_proj(test_start_count:end,:);

% size(Y_all_tr)
% size(Z_all_tr)
% size(Y_all_ts)
% size(Z_all_ts)
%% downsample train and test data

%training data 
Y_ds_tr_n_proj = Y_all_tr_n_proj(1:ds:end,:);
Z_ds_tr_n_proj = Z_all_tr_n_proj(1:ds:end,:);
%test data
Y_ds_ts_n_proj = Y_all_ts_n_proj(1:ds:end,:);
Z_ds_ts_n_proj = Z_all_ts_n_proj(1:ds:end,:);


%% Permuting the data sequence 
%idx1=randperm(size(Y_ds_tr_n_proj,1));
Y_ds_tr_n_proj_r = Y_ds_tr_n_proj;
Z_ds_tr_n_proj_r =  Z_ds_tr_n_proj;  

%% Prepareing test data set
 % all data excpet train
 idx1 = ismember(Y_raw_n_proj, Y_ds_tr_n_proj);
 Y_raw_n_proj_except_train = Y_raw_n_proj(~idx1(:,1),:); 
 Z_raw_et = Z_raw(~idx1(:,1),:); 


 
 % Fullldata test part
Z_raw_test_all = Z_raw(test_start_count:end,:);
% Downsample test data
Z_raw_ds_test  = Z_raw_test_all(1:ds:end,:);
% Downsample train data original but random permuted
Z_raw_tr=   Z_raw(1:train_samples,:);
Z_raw_tr_ds = Z_raw_tr(1:ds:end,:);


 
%% size check
[my ny] = size(Y_ds_tr_n_proj_r);        [mz nz] = size(Z_ds_tr_n_proj_r);
[myts nyts] = size(Y_ds_ts_n_proj);    [mzts nzts] = size(Z_ds_ts_n_proj);
[my_et ny_et] = size(Y_raw_n_proj_except_train); 
[my_full_ts,ny_full_ts] = size(Y_all_ts_n_proj);
%     disp(['Size of Y_train = ' int2str(my) ' x ' int2str(ny) ' ...']);
%     disp(['Size of Z_train = ' int2str(mz) ' x ' int2str(nz) ' ...']);
%     disp(['Size of Y_test = ' int2str(myts) ' x ' int2str(nyts) ' ...']);
%     disp(['Size of Z_test = ' int2str(mzts) ' x ' int2str(nzts) ' ...']);


%%    
%%%% 1. NN Regression on normalized data

w_tr = [ones(my,1) Y_ds_tr_n_proj_r]\Z_ds_tr_n_proj_r; %Y\Z
  
%% Prediction

Z_ds_tr_n_proj_r_pred = [ones(mz,1)  Y_ds_tr_n_proj_r]*w_tr;
tic;
Z_ds_ts_n_proj_pred = [ones(mzts,1) Y_ds_ts_n_proj]*w_tr; 
total_time =toc;


Z_raw_n_proj_except_train_pred = [ones(my_et,1) Y_raw_n_proj_except_train]*w_tr; 


Z_all_ts_n_proj_pred = [ones(my_full_ts,1) Y_all_ts_n_proj]*w_tr; 


     
 
    %% Recover original data from project data 
    
    Z_ds_tr_n_proj_r_pred_rec       =  recoverData(Z_ds_tr_n_proj_r_pred, Uz, 9);    %recover to full dimension
    Z_ds_tr_n_proj_r_pred_rec_dn    = (Z_ds_tr_n_proj_r_pred_rec .* repmat(sigmaZ, mz,1)) + repmat(muZ, mz,1);

    Z_ds_ts_pred_rec =  recoverData(Z_ds_ts_n_proj_pred, Uz, 9);    %recover to full dimension
    Z_ds_ts_pred_rec_dn = (Z_ds_ts_pred_rec .* repmat(sigmaZ, mzts,1)) + repmat(muZ, mzts,1);
   
    
    Z_all_ts_n_proj_pred_rec =  recoverData(Z_all_ts_n_proj_pred, Uz, 9);    %recover to full dimension
    Z_all_ts_n_proj_pred_rec_dn = (Z_all_ts_n_proj_pred_rec .* repmat(sigmaZ, my_full_ts,1)) + repmat(muZ, my_full_ts,1);
    
    Z_raw_n_proj_except_train_pred_rec =  recoverData(Z_raw_n_proj_except_train_pred, Uz, 9);    %recover to full dimension
    Z_raw_n_proj_except_train_pred_rec_dn = (Z_raw_n_proj_except_train_pred_rec .* repmat(sigmaZ, my_et,1)) + repmat(muZ, my_et,1);
  noOfSamples= size(Y_ds_ts_n_proj,1);
oneSampleTime =  total_time/noOfSamples;               
    
    [corr_tr, rmse_tr]      =       performance(Z_raw_tr_ds,      Z_ds_tr_n_proj_r_pred_rec_dn);
    [corr_ts,rmse_ts]       =       performance(Z_raw_ds_test,      Z_ds_ts_pred_rec_dn);
    [corr_t_a,rmse_t_a]     =       performance(Z_raw_test_all,     Z_all_ts_n_proj_pred_rec_dn);
    [corr_et,rmse_et]       =       performance(Z_raw_et,           Z_raw_n_proj_except_train_pred_rec_dn);
    r_tr                    =       rsquare(Z_raw_tr_ds,      Z_ds_tr_n_proj_r_pred_rec_dn);
    r_ts_et                 =       rsquare(Z_raw_et,      Z_raw_n_proj_except_train_pred_rec_dn); 
    
 end