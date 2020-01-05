function handle = handMocapVisualiseEMG_BAR(posVal, Y_ds_tr_1)
tickLabels = {'APL','FCR','FDS','FDP','ED','EI','ECU','ECR'};
handle = bar(posVal);
ylim([0,1]);
xlim([0 9]);
grid on;
grid minor;
ylabel('muscle activations ( 0 - 1)','Fontweight','Bold');
xlabel('Muscle Names','Fontweight','Bold');
set(gca, 'XTickLabel', tickLabels,'Fontweight','Bold','Fontsize',11);
set(gca,'XTickLabelRotation',90,'Fontweight','Bold','Fontsize',11)
%title([ 'Latent Dimension -', num2str(dim(i))]);%,'-Across subjects'
    

      
end