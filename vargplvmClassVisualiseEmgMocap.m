function vargplvmClassVisualiseEmgMocap(call)

% LVMCLASSVISUALISE Callback function for visualising data.
% FORMAT
% DESC contains the callback functions for visualizing points from the
% latent space in the higher dimension space.
% ARG call : either 'click', 'move', 'toggleDynamics',
% 'dynamicsSliderChange'
%
% COPYRIGHT : Neil D. Lawrence, 2003, 2009
%
% SEEALSO : lvmResultsDynamic

% VARGPLVM 

global visualiseInfo
   initial = [];

switch call
 case 'click'
  
  [x, y]  = localCheckPointPosition(visualiseInfo);  
  if ~isempty(x) 
    visualiseInfo.latentPos(visualiseInfo.dim1) = x;
    visualiseInfo.latentPos(visualiseInfo.dim2) = y;
  end
  visualiseInfo.clicked = ~visualiseInfo.clicked;
 
  
         
 case 'move'
  if visualiseInfo.clicked & ~visualiseInfo.runDynamics
    [x, y]  = localCheckPointPosition(visualiseInfo);  
    if ~isempty(x) 
      % This should be changed to a model specific visualisation.
      visualiseInfo.latentPos(visualiseInfo.dim1) = x;
      visualiseInfo.latentPos(visualiseInfo.dim2) = y;
      
      %fprintf('[x y] = [%d %d]\n',x,y)%%%%%%%%%%5
      set(visualiseInfo.latentHandle, 'xdata', x, 'ydata', y);
      fhandle1 = str2func([visualiseInfo.model_1.type 'PosteriorMeanVarPar']);
      
      fhandle2 = str2func([visualiseInfo.model_2.type 'PosteriorMeanVarPar']);
      
      %[mu, varsigma] = fhandle(visualiseInfo.model,visualiseInfo.latentPos); %%%
      mu_EMG = fhandle1(visualiseInfo.model_1,visualiseInfo.latentPos);        %%% varsigma = 0; %%%
      mu_KINE  = fhandle1(visualiseInfo.model_2,visualiseInfo.latentPos);
      
      Y = mu_EMG;
      Z = mu_KINE;
  
      visualiseInfo.visualiseModifyKINE(visualiseInfo.visHandleKINE, Z);      %%%vargin : {height width 0 0 1} 
      visualiseInfo.visualiseModifyEMG_BAR(visualiseInfo.visHandleEMG_BAR, Y);
    
      hold on;
    end
  end
 
 
 case 'updateLatentRepresentation'
  visualiseInfo.dim1 = get(visualiseInfo.xDimension, 'value');
  visualiseInfo.dim2 = get(visualiseInfo.yDimension, 'value');
  vargplvmSetPlot;
  visualiseInfo.latentHandle = line(visualiseInfo.latentPos(visualiseInfo.dim1), ...
                                    visualiseInfo.latentPos(visualiseInfo.dim2), ...
                                    'markersize', 20, 'color', [0.5 0.5 0.5], ...
                                    'marker', '.', 'visible', 'on', ...
                                    'erasemode', 'xor');

  
  


end




function point = localGetNormCursorPoint(figHandle)

point = get(figHandle, 'currentPoint');
figPos = get(figHandle, 'Position');
% Normalise the point of the curstor
point(1) = point(1)/figPos(3);
point(2) = point(2)/figPos(4);

function [x, y] = localGetNormAxesPoint(point, axesHandle)

position = get(axesHandle, 'Position');
x = (point(1) - position(1))/position(3);
y = (point(2) - position(2))/position(4);
lim = get(axesHandle, 'XLim');
x = x*(lim(2) - lim(1));
x = x + lim(1);
lim = get(axesHandle, 'YLim');
y = y*(lim(2) - lim(1));
y = y + lim(1);


function [x, y] = localCheckPointPosition(visualiseInfo)

% Get the point of the cursor
point = localGetNormCursorPoint(gcf);

% get the position of the axes
position = get(visualiseInfo.plotAxes, 'Position');


% Check if the pointer is in the axes
if point(1) > position(1) ...
      & point(1) < position(1) + position(3) ...
      & point(2) > position(2) ...
      & point(2) < position(2) + position(4);
  
  % Rescale the point according to the axes
  [x y] = localGetNormAxesPoint(point, visualiseInfo.plotAxes);

  % Find the nearest point
else
  % Return nothing
  x = [];
  y = [];
end





function channels = Ytochannels(Y)
  
% YTOCHANNELS Convert Y to channel values.

xyzInd = [2];
xyzDiffInd = [1 3];
rotInd = [4 6];
rotDiffInd = [5];
generalInd = [7:38 41:47 49:50 53:59 61:62];
startInd = 1;
endInd = length(generalInd);
channels(:, generalInd) = 180*Y(:, startInd:endInd)/pi;
startInd = endInd + 1;
endInd = endInd + length(xyzDiffInd);
channels(:, xyzDiffInd) = cumsum(Y(:, startInd:endInd), 1);
startInd = endInd + 1;
endInd = endInd + length(xyzInd);
channels(:, xyzInd) = Y(:, startInd:endInd);
startInd = endInd + 1;
endInd = endInd + length(xyzDiffInd);
channels(:, xyzDiffInd) = cumsum(Y(:, startInd:endInd), 1);
startInd = endInd + 1;
endInd = endInd + length(rotInd);
channels(:, rotInd) = asin(Y(:, startInd:endInd))*180/pi;
channels(:, rotInd(end)) = channels(:, rotInd(end))+270;
startInd = endInd + 1;
endInd = endInd + length(rotDiffInd);
channels(:, rotDiffInd) = 0;%cumsum(asin(Y(:, startInd:endInd)), 1))*180/pi;


