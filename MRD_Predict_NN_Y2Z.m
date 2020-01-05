function [ZpredAll_test, X_star_init_NN, corr_this, rmse_this,meanPose, svargplvm] = MRD_Predict_NN_Y2Z(model, testDataY,testDataZ)
%%% In general Z-- refers to the Kinematics modality
%%% In general Y-- referes to the EMG modality
%%% model--refers to the already trained model 
%%% testDataY -- variable which holds the muscle activatoin values for
%%% which kinematics has to be predicted 
%%% testDataZ -- variable holds the ground truth kinematics corresponding
%%% to the muscle activations stored in testDataY
%%% ZpredALL stores all the predicted kinematics corresponding to the
%%% muscle activation in variable -- testDataY 
%%% X_star_init_NN
%% Finding shared and private dimensions 

obsMod = 1; % one of the involved sub-models (possible values: 1 or 2).
infMod = setdiff(1:2, obsMod);
% Find the dimensions that are shared for obsMod and infMod
if ~exist('sharedDims')
    s1 = model.comp{obsMod}.kern.comp{1}.inputScales;
    s2 = model.comp{infMod}.kern.comp{1}.inputScales;
    % Normalise values between 0 and 1
    s1 = s1 / max(s1);
    s2 = s2 / max(s2);
    
    %  thresh = max(model.comp{obsMod}.kern.comp{1}.inputScales) * 0.001;
    thresh = 0.04; %% need to be tuned
    
    retainedScales{obsMod} = find(s1 > thresh);
    %thresh = max(model.comp{infMod}.kern.comp{1}.inputScales) * 0.001;
    retainedScales{infMod} = find(s2  > thresh);
    sharedDims = intersect(retainedScales{obsMod}, retainedScales{infMod});
    %sharedDims = [1,9] 
end
% Find X_* only for the shared dimensions (Xs*):
if ~exist('privateDims')
    privateDims = setdiff(1:model.comp{obsMod}.q, sharedDims);
end
%%
obsMod=1;
infMod=2;
testInd                 =       1:size(testDataY,1); %% number of samples
y_star_test = testDataY; %% muscle activations
z_star_test = testDataZ; %% ground truth

y_star_train= model.comp{obsMod}.y;
z_star_train =model.comp{infMod}.y;
disp("------------------------")
disp(['Number of DataPoints used to Train this Model: ' num2str(size(model.comp{obsMod}.y,1))]);
disp(['Given Test Data Size : ' num2str(size(testDataY))]);



%% Initilize the latent points corresponding to the given muscle activation inputs using nearest neighbour strategy 
for i=1:length(testInd)
        curInd = testInd(i); 
        %Find a point in the training data which is closest to the point
        %being represented by variable -- curInd using NN strategy
        dst2 = dist2(y_star_test(curInd,:), model.comp{obsMod}.y); 
        [mind2, mini2] = min(dst2);  %get the index of that point  
        miniAll2(i) = mini2;         %store that index   
        %get the corresponding vardist  from the model for the point being
        %represented by mini2   
        InitZ(i,:) = model.vardist.means(mini2,:);  
        X_star_init_NN(i,:) = InitZ(i,:); 
end
%% Find a latent point closest to initialized latent points in the shared dimensions  
for i=1:length(testInd)
     x_star              =   X_star_init_NN(i,:);  
     [ind, distInd]      =   nn_class(model.X(:,sharedDims), x_star(:,sharedDims), 1, 'euclidean');
     X_ss(i,:)           =   model.X(ind(1),:);
            
end
%% Calculate the posterior for the latent points -- P(Z|X)
for i=1:length(testInd)
      curInd = testInd(i);
      numberOfNN = 1;
      x_ss = X_ss(i,:);
      ZpredAll_test(i,:) = vargplvmPosteriorMeanVar(model.comp{infMod}, x_ss); %(P(Z|X) 
end
%% Calculate RMSE, Correlation and R-square metric between original and predicted kinematics 
disp("----------------Estimation Results -----------")
[corr_this,rmse_this] = performance(z_star_test, ZpredAll_test);
rsquare_value = rsquare(z_star_test, ZpredAll_test);
disp(['mean correlation coefficient value is: ' num2str(mean(corr_this))]);
disp(['mean RMSE value is: ' num2str(mean(rmse_this))]);
disp(['mean R-Square value is: ' num2str(mean(rsquare_value))]);
        
end