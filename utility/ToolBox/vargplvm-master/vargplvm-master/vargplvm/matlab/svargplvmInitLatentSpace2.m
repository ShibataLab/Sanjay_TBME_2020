function [X_init, m] = svargplvmInitLatentSpace2(Ytr, globalOpt, options)
% SVARGPLVMINITLATENTSPACE2 Initialise the latent space for a SVARGPLVM
% model
% FORMAT
% DESC Initialise the latent space for a SVARGPLVM model.
% ARG Ytr : A cell array containing the different datasets for the
% sub-models.
% ARG d : A cell array with the dimensionalities of the elements of Ytr
% ARG options : A cell array with each element being the options for the
% corresponding sub-model of the svargplvm model.
% ARG initLatent : How to initialise the latent space. Possible options include
% pca in the concatenated datasets, pca in each dataset and then
% concatenation, ncca etc.
% ARG varargin : Additional parameters, depending on the initialisation
% type.
% RETURN X_init : the initial latent points.
%
% SEEALSO : demSharedVargplvm1
%
% COPYRIGHT : Andreas C. Damianou, Carl Henrik Ek, 2011

% VARGPLVM

latentDim = globalOpt.latentDim;
latentDimPerModel = globalOpt.latentDimPerModel;
%numSharedDims = globalOpt.numSharedDims;
initX = globalOpt.initX;
initLatent = globalOpt.initial_X;

mAll=[];
%-- Create the normalised version of the datasets and concatenate
%!!!! Doesn't work if Y{i}'s have different sizes!!
for i=1:length(Ytr)
    d{i} = size(Ytr{i},2);
    % Compute m, the normalised version of Ytr (to be used for
    % initialisation of X)
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
        scale = repmat(options{i}.scaleVal, 1, d{i});
    end
    
    % Remove bias and apply scale.
    m{i} = Ytr{i};
    for j = 1:d{i}
        m{i}(:, j) = m{i}(:, j) - bias(j);
        if scale(j)
            m{i}(:, j) = m{i}(:, j)/scale(j);
        end
    end
    clear('bias')
    clear('scale')
    if strcmp(initLatent,'concatenated')
        mAll = [mAll m{i}]; % Concatenation (doesn't work if different sizes)
    end
end


if size(globalOpt.initX,1) ~= 1 % Check if initial X is already given as a matrix
    X_init = globalOpt.initX;
else
    % %-- Create shared X:
    % initFunc = str2func([initX 'Embed']);
    % X = initFunc(mAll, latentDim);
    if ~isstr(initLatent)
        X_init = initLatent;
    elseif strcmp(initLatent, 'ncca')
        %-- Learn Initialisation through NCCA ( FOR TWO DATASETS only) %%%!!!
        if size(Ytr) ~= 2
            error('ncca initialization only when there are two datasets!');
        end
        [Xsy Xsz Xy Xz] = nccaEmbed(Ytr{1},Ytr{2},uint8([7 7]),uint8(1),uint8([2 2]),true);
        Xs = (1/2).*(Xsy+Xsz);
        X_init = [Xy Xs Xz]; % sizes: 2,1,2
        X_init = (X_init-repmat(mean(X_init),size(X_init,1),1))./repmat(std(X_init),size(X_init,1),1);
    elseif strcmp(initLatent,'separately')
        X_init = [];
        
        initFunc{i} = cell(1,length(Ytr));
        for i = 1:length(Ytr)
            if ~iscell(initX)
                initFunc{i} = str2func([initX 'Embed']);
            else
                initFunc{i} = str2func([initX{i} 'Embed']);
            end
        end
        
        if iscell(initX)
            initXprint = ['{' sprintf('%s ', initX{:}) '}'];
        else
            initXprint = initX;
        end
        fprintf(['# Initialising the latent space with ' initXprint ' separately for each modality, with Q=['])
        if iscell(latentDimPerModel)
            for i=1:length(Ytr), fprintf('%d ', latentDimPerModel{i}); end
        else
            fprintf('%d', latentDimPerModel);
        end
        fprintf(']...\n')
        
            
        for i=1:length(Ytr)
            if iscell(latentDimPerModel)
                X_init_cur = initFunc{i}(m{i},latentDimPerModel{i}, options{i}.initFuncOptions{:});
            elseif isscalar(latentDimPerModel)
                X_init_cur = initFunc{i}(m{i},latentDimPerModel, options{i}.initFuncOptions{:});
            else
                error('Unrecognised format for latentDimPerModel')
            end
            X_init = [X_init X_init_cur];
        end
    elseif strcmp(initLatent,'concatenated')
        initFunc = str2func([initX 'Embed']);
        fprintf(['# Initialising the latent space with ' initX ' after concatenating modalities in Q = %d ...\n'], latentDim)
        X_init = initFunc(mAll, latentDim, options{1}.initFuncOptions{:});
    elseif strcmp(initLatent, 'custom')
        % Like pca initialisation but favour the first model compared to the
        % second
        % assert(length(Ytr)==2, 'Custom initialisation only for 2 submodels!')
        try
            latDims = zeros(1, length(latentDimPerModel));
            for ld = 1:length(latentDimPerModel)
                if latentDimPerModel{ld} == 0
                    latDims(ld) = size(m{ld},2);
                else
                    latDims(ld) = latentDimPerModel{ld};
                end
            end
            X_init = [];
            
            initFunc{i} = cell(1,length(Ytr));
            for i = 1:length(Ytr)
                if ~iscell(initX)
                    initFunc{i} = str2func([initX 'Embed']);
                else
                    initFunc{i} = str2func([initX{i} 'Embed']);
                end
            end
            
            if iscell(initX)
                initXprint = ['{' sprintf('%s ', initX{:}) '}'];
            else
                initXprint = initX;
            end
            fprintf(['# Initialising the latent space with ' initXprint ' separately, with (%s) dims. for each modality...\n'], num2str(latDims))
             
            for ld = 1:length(latentDimPerModel)
                if latentDimPerModel{ld} ~= 0
                    X_init_cur = initFunc{ld}(m{ld},latentDimPerModel{ld}, options{ld}.initFuncOptions{:});
                else
                    % For some aplications, we do not want embedding...(e.g. when
                    % one of the modalities are the labels for classification)
                    X_init_cur = m{ld};
                end
                X_init = [X_init X_init_cur];
            end
        catch e
            if strcmp(e.identifier, 'MATLAB:nomem')
                warning(['Not enough memory to initialise with ' initX '! Initialising with PPCA instead...']);
            else
                e.getReport
            end
            initFunc = str2func('ppcaEmbed');
            X_init{1} = initFunc(m{1}, latentDimPerModel{1}, options{1}.initFuncOptions{:});
            X_init{2} = initFunc(m{2},latentDimPerModel{2}, options{1}.initFuncOptions{:});
            X_init = [X_init{1} X_init{2}];
        end
    else
        error('Unrecognised option for latent space initialisation.')
    end
end
clear mAll
