function lvmVisualiseGeneralEmgMocap(model, YLbls, dim1, dim2,subject, ...
            visualiseFunctionKINE, visualiseModifyKINE,...
             visualiseFunctionEMG_BAR, visualiseModifyEMG_BAR,...
            showVariance, Y_ds_tr_1,xlim)
%lvmVisualiseGeneralEmgMocap
% LVMVISUALISEGENERAL Visualise the manifold.
% This is a copy of lvmVisualise where the classVisualise function depends on the
% model type. Additionally, there is a flag showVariance which, when set to
% false, does not plot the variance of the inputs in the scatter plot,
% something which saves a lot of computational time for high-dimensional
% data.
% lvmVisualiseGeneralEmgMocap
% COPYRIGHT: Neil D. Lawrence, Andreas C, Damianou, 2012
% SEEALSO : lvmVisualise, lvmClassVisualise, lvmScatterPlot,
% lvmScatterPlotNoVar
%
% MLTOOLS

global visualiseInfo

if nargin < 7
	showVariance = 1;
end

visualiseInfo.showVariance = showVariance;                %vargin : {height width 0 0 1}   
lvmClassVisualiseFunc = [model.comp{1}.type 'ClassVisualiseEmgMocap'];   %vargplvmClassVisualiseEmgMocap

 
%lvmClassVisualiseFunc = [model.type 'ClassVisualiseEmgMocap']; 
%%% chage this if you want to view other dimension
    visualiseInfo.dim1 = dim1;
    visualiseInfo.dim2 = dim2;
    visualiseInfo.latentPos = zeros(1, model.comp{1}.q);              %model.q = dim of latent X = 10
    %visualiseInfo.latentPos = zeros(1, model.q);              %model.q = dim of latent X = 10
    %visualiseInfo.model = model;        %%% we want to reconstruct finger kinematics
    visualiseInfo.model_1 = model.comp{1};        %%% we want to reconstruct finger kinematics
                                                %%% change to model.comp{1} if we want to recon EMG
    visualiseInfo.model_2 = model.comp{2};   
     visualiseInfo.model = model.comp{1};                                               
   visualiseInfo.lbls = YLbls;                               %[]
   visualiseInfo.EMG = Y_ds_tr_1;
    visualiseInfo.subject  = subject;

%%% Start figure 1: plot Latent Space
    figure(1)
    clf

    if showVariance
        %visualiseInfo.plotAxes = lvmScatterPlot(model, YLbls, [], [visualiseInfo.dim1 visualiseInfo.dim2]);
        visualiseInfo.plotAxes = lvmScatterPlot(model.comp{1}, YLbls, [], [visualiseInfo.dim1 visualiseInfo.dim2]);
        %vargplvmSetPlot;
    else
        visualiseInfo.plotAxes = lvmScatterPlotNoVar(model.comp{1}, YLbls, [], [visualiseInfo.dim1 visualiseInfo.dim2]);
        %visualiseInfo.plotAxes = lvmScatterPlotNoVar(model, YLbls, [], [visualiseInfo.dim1 visualiseInfo.dim2]);
        %lvmSetPlotNoVar(lvmClassVisualiseFunc);              %sliders and dimension defined  
    end

    visualiseInfo.latentHandle = line(0, -5, 'markersize', 50, 'color', [0 0 0], 'marker', '.', 'visible', 'on', 'erasemode', 'xor');
    visualiseInfo.clicked = 0;
    visualiseInfo.digitAxes = [];
    visualiseInfo.digitIndex = [];
    visualiseInfo.runDynamics = false;
    % Set the callback function
        set(gcf, 'WindowButtonMotionFcn', [lvmClassVisualiseFunc '(''move'')']) 
        set(gcf, 'WindowButtonDownFcn', [lvmClassVisualiseFunc '(''click'')'])
xlabel(['Latent dimension-',+ num2str(visualiseInfo.dim1)],'FontSize',20,'Fontweight','Bold');   
ylabel(['Latent dimension-',+ num2str(visualiseInfo.dim2)],'FontSize',20,'Fontweight','Bold');
        

%% figure (2)
 figure (2)
 clf;
 
 visualiseInfo.visualiseAxes = subplot(1, 1, 1);
 visDataKINE = zeros(1,size(model.comp{2}.y,2));  
 visualiseInfo.visualiseFunctionKINE = str2func(visualiseFunctionKINE) ;            
 visHandleKINE = visualiseInfo.visualiseFunctionKINE(visDataKINE);     %initialize figure1 and 2 with imageMRDVisualise : 0 (black image)
 
 handleType = get(visHandleKINE, 'type');
    if ~strcmp(handleType, 'figure')
        set(visHandleKINE, 'erasemode', 'xor');
    end
    
    %visualiseInfo.model = model.comp{2};

    %visualiseInfo
    visualiseInfo.visualiseModifyKINE = str2func(visualiseModifyKINE);
    visualiseInfo.visHandleKINE = visHandleKINE;
  %%  
  figure (3)
  visualiseInfo.visualiseAxes = subplot(1, 1, 1);
 visDataEMG_BAR = zeros(1,size(model.comp{1}.y,2));  
 visualiseInfo.visualiseFunctionEMG_BAR = str2func(visualiseFunctionEMG_BAR) ;            
 visHandleEMG_BAR = visualiseInfo.visualiseFunctionEMG_BAR(visDataEMG_BAR);     %initialize figure1 and 2 with imageMRDVisualise : 0 (black image)
 
 handleType = get(visHandleEMG_BAR, 'type');
    if ~strcmp(handleType, 'figure')
        set(visHandleEMG_BAR, 'erasemode', 'xor');
    end
    
    %visualiseInfo.model = model.comp{2};

    %visualiseInfo
    visualiseInfo.visualiseModifyEMG_BAR = str2func(visualiseModifyEMG_BAR);
    visualiseInfo.visHandleEMG_BAR = visHandleEMG_BAR;
  
  

hold off
