

function handMocapModifyEMG_BAR(handle, posVal)
global reEMG;
 set(handle, 'YData', posVal);
%save('synergy1', 'reEMG.store');
end