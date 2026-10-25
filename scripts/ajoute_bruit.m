% ajoute du bruit blanc gaussien à un signal donné y, de rapport signal sur bruit RSB (en dB)
% renvoie le signal bruité yb et l'écart type du bruit associé sigmab

function [yb,sigmab] = ajoute_bruit(y,RSB)

N = numel(y);
my = mean(y);
y = y-my;
sigmab = sqrt(sum(y(:).^2) * 10^(-RSB/10) / N);
yb = y + sigmab*randn(size(y));
yb = yb +my;