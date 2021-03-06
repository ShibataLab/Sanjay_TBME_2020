function [X, varX, model, grChek] = vargplvmOptimisePoint(model, vardistx, y,  display, iters, varargin)

% VARGPLVMOPTIMISEPOINT Optimise the postion of one or more latent points.
% FORMAT
% DESC optimises the location of a group of points in latent space
% given an initialisation and the corresponding observed data point.
% ARG model : the model for which the point will be optimised.
% ARG vardistx : the initialisation of the points in the latent space.
% ARG y : the observed data points for which the latent points are to
% be optimised.
% ARG display : whether or not to display the iterations of the
% optimisation (default: true)
% ARG iters : maximum number of iterations for the optimisation
% (default 2000).
% RETURN x : the optimised means in the latent space.
% RETURN varx : the optimised variances in the latent space.
% RETURN model: the model which is augmented to also include the new test
% points and the quantities that change because of these, as there is
% coupling in the dynamics case.

%
% COPYRIGHT :  Michalis K. Titsias and Neil D. Lawrence, 2009-2011
%
% SEEALSO : vargplvmCreate, vargplvmOptimiseSequence, vargplvmPointObjective, vargplvmPointGradient

% VARGPLVM

grChek = [];

if nargin < 5
    iters = 2000;
    %if nargin < 5
    display = true;
    %end
end

options = optOptions;
if display
    options(1) = 1;
   % options(9) = 1; % gradchek
end
options(14) = iters;


if isfield(model, 'optimiser')
    optim = str2func(model.optimiser);
else
    optim = str2func('scg');
end


if isfield(model, 'dynamics') && ~isempty(model.dynamics)
    % augment the training and testing variational distributions
    vardist = vardistCreate(zeros(model.N+size(y,1), model.q), model.q, 'gaussian');
 
   % vardist.means = [model.dynamics.vardist.means; vardistx.means]; % TO BE REMOVED if the following works
    
    %%%%% --NEW
   % TEMPmeans1 = vardist.means; save 'TEMPmeans1.mat' 'TEMPmeans1'; %%%%%%% TEMP
    % Initialize mu_* with the training means
    mini = model.mini;
    model.mini = []; model = rmfield(model, 'mini');
    vardistx2 = vardistCreate(model.vardist.means(mini,:), model.q, 'gaussian');
    %vardistx2.means = vardistx2.means + 0.5*randn(size(vardistx2.means)); 
    
    N = model.dynamics.N;
    Nstar = size(y,1);
    Kt = zeros(N+Nstar, N+Nstar);
    Kt(1:N,1:N) = model.dynamics.Kt;
    % new diagonal block
    Kt(N+1:end, N+1:end) = kernCompute(model.dynamics.kern, model.dynamics.t_star);
    % cross block
    Kt(1:N, N+1:end) = kernCompute(model.dynamics.kern, model.dynamics.t(1:N), model.dynamics.t_star);
    Kt(N+1:end, 1:N) = Kt(1:N, N+1:end)';
    % [mu_bar mu_bar_*] = Kt^{-1} [mu mu_*]

    % If Kt is ill-conditioned do the standard initialization
    if  cond(Kt) < 1e+15 && ~strcmp(model.dynamics.kern.comp{1}.type, 'rbfperiodic') %%% New (the periodic part)
        vardist.means = Kt \ [model.vardist.means; vardistx2.means]; 
    else 
        vardist.means = [model.dynamics.vardist.means; vardistx.means]; 
    end   
    
    
%     % TEMP_
%     TEMPmeans2 = vardist.means; 
%     save 'TEMPmeans2.mat' 'TEMPmeans2';
%     for i=1:model.q 
%         % big figure
%         scrsz = get(0,'ScreenSize');
%         figure('Position',[scrsz(3)/4.86 scrsz(4)/6.666 scrsz(3)/1.6457 scrsz(4)/1.4682])
%         plot(TEMPmeans1(:,i)); 
%         hold on;
%         plot(TEMPmeans2(:,i),'r');
%         plot(prunedModelUpdated.dynamics.vardist.means(:,i),'c');
%         hold off
%     end  
%     % _TEMP
    
    %%%%% --_NEW
    
    
    
    
    vardist.covars = [model.dynamics.vardist.covars; vardistx.covars];
    vardist.numData = size(vardist.means,1);
    vardist.nParams = 2*prod(size(vardist.means));
    x = modelExtractParam(vardist);
    if strcmp(func2str(optim), 'optimiMinimize')
        fprintf(1,'!!! Warning!!! OptimiMinimize may not work correctly for the dynamic case!!\n');
    end
    
    %%% RE-OPT-CODE-NEW_
    % Now we should include also the ind. points and the theta_t params.
    % x will no longer be used to denote the means and covars, but instead,
    % all these params (vardistMeansAugm, vardistCovarsAugm, theta_t, X_u)
    % where Augm means that they have been augmented to include test points.
    if isfield(model.dynamics, 'reoptimise') && model.dynamics.reoptimise
        paramsOrig = vargplvmExtractParam(model);
        % Get theta_t which is after the vardist. params
        startVal = model.dynamics.vardist.nParams+1;
        endVal = startVal + model.dynamics.kern.nParams - 1;
        theta_t = paramsOrig(startVal:endVal);
        % Get X_u which is after theta_t
        startVal = endVal+1;
        endVal = endVal + model.q*model.k;
        X_u = paramsOrig(startVal:endVal);   
        x = [x theta_t X_u];
    end
    %%% _RE-OPT-CODE-NEW
else
    x = vardistExtractParam(vardistx);
end

if ~(isfield(model, 'dynamics') && ~isempty(model.dynamics))
    % Perform precomputations which will result in faster execution. This
    % happens in two stages:
    % a) Precomputing constants only once here, instead in every call of
    % the objective and grad
    % b) Replace model.m with a reduced rank representation, since it only
    % appears in the expression model.m * model.m'. This is the same tricks
    % used in vargplvmCreate for DgtN flag.
    % TODO: Do the same for dynamics case
    model.DgtN_test = true;
    if isfield(model, 'DgtN') && model.DgtN
        mOrig = model.m;
    end
    model.testPrecomp.indexMissing = find(isnan(y(1,:)));
    indexPresent = setdiff(1:model.d, model.testPrecomp.indexMissing );
    y = y(:,indexPresent);   
    % This assumes that model.m is set to model.mOrig prior to calling this
    % function (vargplvmOptimisePoint), in case model.m is the reduced rank
    % matrix instead of model.mOrig. So, if you get an error here, probably
    % you forgot to set model.m = model.mOrig outside of this function.
    P = model.P1 * (model.Psi1' * model.m(:,model.testPrecomp.indexMissing));
    model.testPrecomp.TrPP = sum(sum(P .* P));
    model.testPrecomp.TrYY = sum(sum(model.m(:,model.testPrecomp.indexMissing) .* model.m(:,model.testPrecomp.indexMissing)));
    y = y - repmat(model.bias(indexPresent),size(y,1),1);
    y = y./repmat(model.scale(indexPresent),size(y,1),1);
    mPres = model.m(:, indexPresent);
    mPres = [mPres; y];    
    YYT = mPres * mPres'; % NxN
    if isfield(model, 'DgtN') && model.DgtN
        [U S V]=svd(YYT);
        model.testPrecomp.mReduced=U*sqrt(abs(S));
    end
    model.testPrecomp.TrYY2 = sum(diag(YYT)); % scalar
    
    % For grads
    mPresGrad = [y; model.m(:, indexPresent)];
    YYT = mPresGrad * mPresGrad'; % NxN
    if isfield(model, 'DgtN') && model.DgtN
        [U S V]=svd(YYT);
        model.testPrecomp.mReducedGrad=U*sqrt(abs(S));
    end
    model.testPrecomp.mY = mPresGrad*y';
    if isfield(model, 'DgtN') && model.DgtN
        model.m = []; % Less overhead in passing arguments (pass by value)
    end
else
    model.DgtN_test = false;
end


if length(varargin) == 2
    if strcmp(varargin{1}, 'gradcheck')
        assert(islogical(varargin{2}));
        %options(9) = varargin{2};
        doGradchek = varargin{2};
        if doGradchek
            [gradient, delta] = feval('gradchek', vardistExtractParam(vardistx), @vargplvmPointObjective, @vargplvmPointGradient, model, y);
            deltaf = gradient - delta;
            d=norm(deltaf - gradient)/norm(gradient + deltaf); %%
            d1=norm(deltaf - gradient,1)/norm(gradient + deltaf,1); %%
            grRatio = sum(abs(gradient ./ deltaf)) / length(deltaf);
            fprintf(1,' Norm1 difference: %d\n Norm2 difference: %d\n Ratio: %d\n',d1,d, grRatio);
            grChek = {delta, gradient, deltaf, d, d1};
        else
            grChek = [];
        end
    end
end

if iters > 0
    if strcmp(func2str(optim), 'optimiMinimize')
        % Carl Rasmussen's minimize function
        x = optim('vargplvmPointObjectiveGradient', x, options, model, y);
    else
        % NETLAB style optimization.
        x = optim('vargplvmPointObjective', x,  options, ...
            'vargplvmPointGradient', model, y);
    end
end

if isfield(model, 'dynamics') && ~isempty(model.dynamics)
    if isfield(model.dynamics, 'reoptimise') && model.dynamics.reoptimise   %%% RE-OPT-CODE-NEW
        % Expand and update the model.                                      %%% RE-OPT-CODE-NEW
        % In this case, x is [mu_bar lambda theta_t X_u]                    %%% RE-OPT-CODE-NEW
        [vardistx, model] = vargplvmPartExpand(model, x, 1);                %%% RE-OPT-CODE-NEW
    else %%% RE-OPT-CODE-NEW
        % now separate the variational disribution into the training part and the
        % testing part and update the original training model (only with the new training
        % variational distribution) and the test variational distribution
        % this is doing the expand
        x = reshape(x, vardist.numData, model.dynamics.q*2);
        xtrain = x(1:model.N,:);
        xtest = x(model.N+1:end,:);
        model.dynamics.vardist = vardistExpandParam(model.dynamics.vardist, xtrain);
        vardistx = vardistExpandParam(model.vardistx, xtest);
    end %%% RE-OPT-CODE-NEW
else
    vardistx = vardistExpandParam(vardistx,x);
end

X = vardistx.means;
varX = vardistx.covars;

if isfield(model, 'DgtN_test') && model.DgtN_test
    model = rmfield(model, 'testPrecomp');
    model = rmfield(model, 'DgtN_test');
    if isfield(model, 'DgtN') && model.DgtN
        model.m = mOrig;
    end
end
