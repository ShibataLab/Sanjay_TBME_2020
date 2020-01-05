function [value] = rsquare(x, y) % (original  predicted)

[m n] = size(x);
explained_var = x-repmat(mean(x), size(x,1), 1);
explained_var_2   = (explained_var).^2;
 
diff          = x - y;

squaredDiff   = (diff).^2;
size(squaredDiff);
errorDistance = squaredDiff ;
size(errorDistance);

sst =sum(explained_var_2,1);
sse= sum(errorDistance,1);


r = 1-( sse / sst);
size(r);
value = r;



end