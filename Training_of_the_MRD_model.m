%%% Get varGPLVM with ARD synergistic representation on EMG and Finger Kinematics
clear all; clc; close all;
%% Load Data Set
load('S1.mat'); % subject name 
%% Set hyperparameter
mrd_iters=1; % number of iterations to optimize the objective function
initVardistIters = 1; %variational model training iteration number
indPoints = 1; % inducing points are crucial, 
ds=30; % Downsampling
latentDimPerModel = [8 23]; % initially set to original dimensionality
%% Combine muscle activation and corresponding kinematics from five trails and all three tasks 
%  one can opt for trials and tasks from this piece of code need to be
%  opted for the further analysis 
    
    trInd =  [1 2 3 4 5];  
    
    Y_raw = [];     Z_raw = [];
    Y_raw_ts = [];     Z_raw_ts = [];
    
    
    for j = 1:7% number of task
        for i = 1:5 %all 5 train trial
            intr = trInd(i);
            Y_raw = [Y_raw; MUSCLE_ACTIVATION{intr,j}];
            Z_raw = [Z_raw; FINGER_KINEMATICS{intr,j}];
        end
    end
    
%% Prprocessing steps like normalizeation and shuffling of the data points
Y_raw_n=(Y_raw - repmat(mean(Y_raw), size(Y_raw,1), 1)) ./ repmat(std(Y_raw), size(Y_raw,1), 1);
Z_raw_n=(Z_raw - repmat(mean(Z_raw), size(Z_raw,1), 1)) ./ repmat(std(Z_raw), size(Z_raw,1), 1); 

% Permuting the data sequence 
idx=randperm(size(Y_raw_n,1));
Y_raw_rn = Y_raw_n(idx,:);
Z_raw_rn =  Z_raw_n(idx,:);
%%  Splitting data in the train and test data (70% 30 %)

total_samples=size(Y_raw_rn,1);
train_samples= floor((total_samples*70)/100);
test_start_count =train_samples+1;
% train data
Y_all_tr_1 = Y_raw_rn(1:train_samples,:);
Y_all_tr_2 = Z_raw_rn(1:train_samples,:);
% test data
Y_all_ts_1 = Y_raw_rn(test_start_count:end,:);
Y_all_ts_2 = Z_raw_rn(test_start_count:end,:);

size(Y_all_tr_1)
size(Y_all_tr_2)
size(Y_all_ts_1)
size(Y_all_ts_2)
%% downsample train and test data

%training data 
Y_ds_tr_1 = Y_all_tr_1(1:ds:end,:);
Y_ds_tr_2 = Y_all_tr_2(1:ds:end,:);
%test data
Y_ds_ts_1 = Y_all_ts_1(1:ds:end,:);
Y_ds_ts_2 = Y_all_ts_2(1:ds:end,:);

size(Y_ds_tr_1)
size(Y_ds_tr_2)
size(Y_ds_ts_1)
size(Y_ds_ts_2)
%%  Assign processed data to the model variable 
% 1. assign data to the model  
    Yall{1} = Y_ds_tr_1;       % emg of subject 1
    Yall{2} = Y_ds_tr_2;       % emg of subject 2
% 2. assign test data to the model
    obsMod = 1;              % one of the involved sub-models (possible values: 1 or 2).% EMG
    infMod = setdiff(1:2, obsMod); 
    Yts{obsMod} = Y_ds_ts_1;
    Yts{infMod} = Y_ds_ts_2;
    Y_test = Y_ds_ts_1;
    Z_test = Y_ds_ts_2;
   
  
   
%% Model parameters setup and optimization part    


%%%2. Set-up var GPLVM model for Y (EMG from subject 1) and Z (EMG from subject 2)
    itNo = [mrd_iters mrd_iters];                       %iteration number for training 2 GPs
 
   
    dynUsed = 0;                             %no dynamics
   
    dynamicKern = {'rbf', 'white', 'bias'}; 
    mappingKern = {'rbfard2', 'white', 'bias'};
    
    % 0.1 gives around 0.5 init.covars. 1.3 biases towards 0.
    vardistCovarsMult=1.3;
    invWidthMultDyn = 100;
    invWidthMult = 5;
    initX ='ppca';
    enableParallelism = 1;
    DgtN = false;
    
    % Create initial X by doing e.g. ppca in the concatenated model.m's or by
    % doing ppca in the model.m's separately and concatenate afterwards?
    initial_X = 'separately';               % Other options: 'together'
    indTr = -1;                             % Which indices to use for training, rest for test
    
    %latentDim = 12;      % Anything > 2 and < 10
    numberOfDatasets = length(Yall);
    
    for i=1:numberOfDatasets
        Y = Yall{i};
        dims{i} = size(Y,2);
        N{i} = size(Y,1);
        if indTr == -1
            indTr = 1:N{i};
        end  
        Ytr{i} = Y(indTr,:);
        d{i} = size(Ytr{i}, 2);
    end
    for i=2:numberOfDatasets
        if N{i} ~= N{i-1}
            error('The number of observations in each dataset must be the same!');
        end
    end
    
    %%%Setup model option for GPLVM on Y and Z separately
    for i=1:numberOfDatasets
        options{i} = vargplvmOptions('dtcvar');
        options{i}.kern = mappingKern; %{'rbfard2', 'bias', 'white'};
        options{i}.numActive = indPoints;
        options{i}.optimiser = 'scg2';
        if ~DgtN
            options{i}.enableDgtN = false;
        end
        %Use the same type of scaling and bias for all models!!!
        options{i}.scaleVal = sqrt(var(Ytr{i}(:)));      %not same as std(Ytr{i}(:))
    end
    
%%%3. Initialize Latent Space
    for i=1:numberOfDatasets
        bias = mean(Ytr{i});
        scale = ones(1, d{i});
        if(isfield(options{i},'scale2var1'))
            if(options{i}.scale2var1)
                scale = std(Ytr{i});
                scale(find(scale==0)) = 1;
                if(isfield(options{i}, 'scaleVal'))
                    warning('Both scale2var1 and scaleVal set for GP');
                end
            end
        end
        if(isfield(options{i}, 'scaleVal'))
            scale = repmat(options{i}.scaleVal, 1, d{i});       %std(tr{i})
        end
        % Remove bias and apply scale.
        m{i} = Ytr{i};
        for j = 1:d{i}
            m{i}(:, j) = m{i}(:, j) - bias(j);           %use the same type of scaling and bias for all models
            if scale(j)
                m{i}(:, j) = m{i}(:, j)/scale(j);        %use the same type of scaling and bias for all models
            end
        end
    end
    %Apply PPCA
        if strcmp(initial_X, 'separately')
            fprintf('# Initialising X by performing ppca in each observed (scaled) dataset separately and then concatenating...\n');
            if ~exist('latentDimPerModel') || length(latentDimPerModel)~=2
                latentDimPerModel = [4 4];      %[7 3]
            end
            [X_init{1}, X_initsigma{1}] = ppcaEmbed(m{1},latentDimPerModel(1));
            [X_init{2}, X_initsigma{2}] = ppcaEmbed(m{2},latentDimPerModel(2));
            X_init = [X_init{1} X_init{2}];
        else
            %fprintf('# Initialising X by performing ppca in concatenated observed (scaled) data...\n');
            %X_init = ppcaEmbed([m{1} m{2}], latentDimPerModel*2);
        end
        latentDim = size(X_init,2)
        clear('Y', 'Ytest');

%4. Create the sub-models: Assume that for each dataset we have one model.
    for i=1:numberOfDatasets
        fprintf(1,'# Creating the model...\n');
        options{i}.initX = X_init;
            model{i} = vargplvmCreate(latentDim, d{i}, Ytr{i}, options{i});
            model{i}.X = X_init;
            model{i} = vargplvmParamInit(model{i}, model{i}.m, model{i}.X);
            model{i}.X = X_init; 
        inpScales = invWidthMult./(((max(model{i}.X)-min(model{i}.X))).^2);     % Default 5
        model{i}.kern.comp{1}.inputScales = inpScales;
        if strcmp(model{i}.kern.type, 'rbfardjit')          %not needed currently
            model{i}.kern.inputScales = model{i}.kern.comp{1}.inputScales;
        end
        params = vargplvmExtractParam(model{i});
        model{i} = vargplvmExpandParam(model{i}, params);
        model{i}.vardist.covars = 0.5*ones(size(model{i}.vardist.covars)) + 0.001*randn(size(model{i}.vardist.covars));
        
        %%%no dynamics: if dynamics is added, add code for variational parameters of dynamics
        
        model{i}.beta=1/(0.01*var(model{i}.m(:)));
        prunedModelInit{i} = vargplvmPruneModel(model{i});    
    end
    
    %%%unify models into 1 structure
        model = svargplvmModelCreate(model);
        modelType = model.type;
        modelType(1) = upper(modelType(1));
    %%%Force kernel computations
        params = svargplvmExtractParam(model);
        model = svargplvmExpandParam(model, params);
    %%%Optimise the models
        %Set optim parameters: do not learn beta and sigma_f for few iterations for intitialization
        display = 1;
        if initVardistIters ~=0
            model.initVardist = 1; model.learnSigmaf = 0;
            model = svargplvmPropagateField(model,'initVardist', model.initVardist);
            model = svargplvmPropagateField(model,'learnSigmaf', model.learnSigmaf);
            fprintf(1,'# Intitiliazing the variational distribution...\n');
            model = svargplvmOptimise(model, display, initVardistIters); % Default: 20
            %fprintf(1,'1/b = %.4d\n',1/model.beta);

            modelInitVardist = model;
            model.initVardistIters=initVardistIters;
        end
        model.initVardist = 0; model.learnSigmaf=1;
        model = svargplvmPropagateField(model,'initVardist', model.initVardist);
        model = svargplvmPropagateField(model,'learnSigmaf', model.learnSigmaf);
        model.iters = 0;
        for i=1:length(itNo)
        iters = itNo(i); % default: 2000
        fprintf(1,'\n# Optimising the model for %d iterations (session %d)...\n',iters,i);
            model = svargplvmOptimise(model, display, iters);
            model.iters = model.iters + iters;
            prunedModel = svargplvmPruneModel(model);
                %fprintf(1,'# Saving %s\n',fileToSave);     %%%save
        end 
%% save the model 
save('MRD_S5.mat');
