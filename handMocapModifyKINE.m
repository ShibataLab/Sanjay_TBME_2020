function handMocapModifyKINE(handle, posVal)

% handMocapVisualise For drawing a stick representation of 3-D mocap data.

limb{1} = [20 17;17 18;18 19]; %thumb
limb{2} = [20 1;1 5;5 6;6 7];  %index
limb{3} = [20 2;2 8;8 9;9 10]; %middle
limb{4} = [20 3;3 11;11 12;12 13]; %ring
limb{5} = [20 4;4 14;14 15;15 16]; %little
limb{6} = [21 22;22 23;23 21]; %wrist

% Convert positions for plotting.
    jointMarkerPos = handJointPosExtract(posVal);
    counter = 0;
      linestyle = '-';
      markersize = 20;
      marker = '.';

%disp([num2str(posVal)]);
    set(handle(1), 'Xdata', posVal(:, 1), 'Ydata', posVal(:, 2), 'Zdata', posVal(:, 3));
    set(handle(1), 'markersize', markersize);
    for i = 1:1:length(limb)
       for j = 1:1:size(limb{i},1)
          counter = counter + 1; 
          set(handle(counter+1), 'Xdata', jointMarkerPos(limb{i}(j,:),1), 'Ydata', jointMarkerPos(limb{i}(j,:),2), ...
                                 'Zdata', jointMarkerPos(limb{i}(j,:),3) );
        end  
    end
   
    