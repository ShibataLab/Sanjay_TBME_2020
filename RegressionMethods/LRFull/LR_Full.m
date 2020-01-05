function [corr_tr,corr_ts,rmse_tr,rmse_ts,corr_et,rmse_et,r_tr,r_ts_et,oneSampleTime, net,idx]=LR_Full(dsfilt_musAct, lpfilt_trc_p23rot)
  %% get all data in 
  rng(1234);
    trInd =  [1 2 3 4 5];  
    ds = 30;
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
Z_raw =Z_raw(:,pip_idx);
%% normalizeation
 [Y_raw_n, muY, sigmaY] = featureNormalize(Y_raw);
 [Z_raw_n, muZ, sigmaZ] = featureNormalize(Z_raw);

%% Permuting the data sequence 

idx=randperm(size(Y_raw_n,1));

Y_raw_rn = Y_raw_n(idx,:);

Z_raw_rn =  Z_raw_n(idx,:);

 
%%  train and test data (70% 30 %)
total_samples=size(Y_raw_rn,1);
train_samples= floor((total_samples*70)/100);
test_start_count =train_samples+1;
% train data
Y_all_tr = Y_raw_rn(1:train_samples,:);
Z_all_tr = Z_raw_rn(1:train_samples,:);
% test data
Y_all_ts = Y_raw_rn(test_start_count:end,:);
Z_all_ts = Z_raw_rn(test_start_count:end,:);

% size(Y_all_tr)
% size(Z_all_tr)
% size(Y_all_ts)
% size(Z_all_ts)
%% downsample train and test data

%training data 
Y_ds_tr = Y_all_tr(1:ds:end,:);
Z_ds_tr = Z_all_tr(1:ds:end,:);
%test data
Y_ds_ts = Y_all_ts(1:ds:end,:);
Z_ds_ts = Z_all_ts(1:ds:end,:);
       
%% size check
    [my ny] = size(Y_ds_tr);        [mz nz] = size(Z_ds_tr);
    [myts nyts] = size(Y_ds_ts);    [mzts nzts] = size(Z_ds_ts);
%     disp(['Size of Y_train = ' int2str(my) ' x ' int2str(ny) ' ...']);
%     disp(['Size of Z_train = ' int2str(mz) ' x ' int2str(nz) ' ...']);
%     disp(['Size of Y_test = ' int2str(myts) ' x ' int2str(nyts) ' ...']);
%     disp(['Size of Z_test = ' int2str(mzts) ' x ' int2str(nzts) ' ...']);


%%    

w_tr = [ones(my,1) Y_ds_tr]\Z_ds_tr; %Y\Z
  
%% training data prediction
 Z_ds_tr_pred = [ones(mz,1)  Y_ds_tr]*w_tr;
 tic;
 Z_ds_ts_pred = [ones(mzts,1) Y_ds_ts]*w_tr; 
total_time =toc;
 %% test Data except training Data 
idx1 = ismember(Y_raw_rn, Y_ds_tr);
Y_raw_et = Y_raw_rn(~idx1(:,1),:);
Z_raw_et = Z_raw_rn(~idx1(:,1),:);
 my_et= size(Y_raw_et,1);
Z_raw_et_pred = [ones(my_et,1) Y_raw_et]*w_tr; 
  
%%  denormalizing operation
    
    Z_tr                 =   (Z_ds_tr.* repmat(sigmaZ,mz,1)) +  repmat(muZ, mz,1);
    Z_ts                 =   (Z_ds_ts.* repmat(sigmaZ,mzts,1)) +  repmat(muZ, mzts,1);
    Z_tr_predict         =   (Z_ds_tr_pred .* repmat(sigmaZ,mz,1)) +  repmat(muZ, mz,1);
    Z_ts_predict         =   (Z_ds_ts_pred .* repmat(sigmaZ,mzts,1)) +  repmat(muZ, mzts,1);
    Z_raw_et_dn         =   (Z_raw_et .* repmat(sigmaZ,my_et,1)) +  repmat(muZ, my_et,1);
    Z_raw_et_pred_dn         =   (Z_raw_et_pred .* repmat(sigmaZ,my_et,1)) +  repmat(muZ, my_et,1);
   
 
%% evaluate performance in original space

 
    noOfSamples= size(Y_ds_ts,1);

    [corr_tr, rmse_tr]  = performance(Z_tr,Z_tr_predict);
    [corr_ts,rmse_ts]   = performance(Z_ts,Z_ts_predict);
    [corr_et,rmse_et]   = performance(Z_raw_et_dn,Z_raw_et_pred_dn);
    r_tr = rsquare(Z_tr, Z_tr_predict);
    r_ts_et = rsquare(Z_raw_et_dn, Z_raw_et_pred_dn);
    oneSampleTime =  total_time/noOfSamples;

 

end