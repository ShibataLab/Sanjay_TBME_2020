function y = normalize_cell(signal, signal_max, signal_min)

   [m, n] = size(signal);
   normSignal = signal_max - signal_min;
       
   normMin = repmat(signal_min, m,1);
   normSignal = repmat(normSignal, m,1);
       
y = (signal - normMin)./normSignal;