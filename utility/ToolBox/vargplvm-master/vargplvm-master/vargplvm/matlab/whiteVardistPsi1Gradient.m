function [gKern, gVarmeans, gVarcovars, gInd] = whiteVardistPsi1Gradient(whitekern, vardist, Z, covGrad, learnInducing)

% WHITEVARDISTPSI1GRADIENT Compute gradient of white variational Psi1.
% FORMAT
% DESC description here.
% RETURN gKern :
% RETURN gVarmeans :
% RETURN gVarcovars :
% RETURN gInd :
% ARG whitekern : the kernel structure associated with the white kernel.
% ARG vardist :
% ARG Z : 
% ARG covGrad : 
%
% SEEALSO : 
%
% COPYRIGHT : Michalis K. Titsias, 2009
%

% VARGPLVM
  
gKern = 0;
gVarmeans = zeros(1,prod(size(vardist.means))); 
gInd = zeros(1,prod(size(Z))); 
gVarcovars = zeros(1,prod(size(vardist.covars))); 
