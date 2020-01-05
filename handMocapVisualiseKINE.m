function handle = handMocapVisualiseKINE(posVal)

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
      color ='b';

    handle(1) = plot3(posVal(:, 1), posVal(:, 2), posVal(:, 3));
    set(handle(1), 'markersize', markersize,'color',color, 'LineWidth', 3.0);
    %axis on;
    %axis([ -200 200 -400 150 -50 200 ])
    %axis([-150 250  50 350 -150  250 ])
    %axis([-50 150 -250 250 -100 200])% JS6 Raw 
    %view([-90 0]);
    %view([33 36])
      %view([97 -4])
    axis on;
    hold on
    grid on
    for i = 1:1:length(limb) % jitni ungli hain utni bar loop chalega 
       for j = 1:1:size(limb{i},1)% ek ungli ke andar jitne joint hain utni baar chalega 
          %if (i==3 && j>3) || (i==5 && j>3)
          %    set(handle(1), 'markersize', 6);
          %     set(handle(1), 'marker', 's');
          % end
          counter = counter + 1; 
          handle(counter+1) = line(jointMarkerPos(limb{i}(j,:),1),jointMarkerPos(limb{i}(j,:),2), ...
                             jointMarkerPos(limb{i}(j,:),3), 'LineWidth', 2, 'LineStyle', linestyle, ...
                             'Marker', marker, 'markersize', markersize,'color',color);
          %set(handle(counter+1), 'linewidth', 2);
        end  
    end
    %axis equal
    axis([-100 300 -120 110 -110 120]); % in general
    %axis([-100  400 -150 150 -130 150]); % in general
     %axis([-300  600 -300 300 -300 150]); % in general
    %axis([-100 400 -100 400 -50 400]); %for JS6
    %axis([-5 3 -4  6 -2  2]);
    %axis([ 150 600 -600 400  -40 200 ])
    %axis on