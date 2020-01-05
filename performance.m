function [correlation, rmse, pvalue, sigma] = performance(x,y)

    [m n] = size(x);

    diff          = x - y;
    squaredDiff   = (diff).^2;
        size(squaredDiff);
    errorDistance = squaredDiff ;
        size(errorDistance);

    rmse = sqrt( sum( errorDistance) / m);
        size(rmse);
    sigma  =  std(errorDistance);   %standard deviation
        size(sigma);
    
    for angle = 1:n
        [buff1 buff2] = corrcoef( x(:,angle), y(:,angle) );
        correlation(:,angle) = buff1(2);
        pvalue(:,angle) = buff2(2);
    end
    
end