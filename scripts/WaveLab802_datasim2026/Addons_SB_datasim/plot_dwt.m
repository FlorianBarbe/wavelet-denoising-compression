function plot_dwt(x,y,J)
% function plot_dwt(x,y,J);
%
% trace le signal x et sa DWT y calculée sur J niveaux
% x : signal
% y : dwt(x)
% J : nb niveaux de décomposition dans y

% S. Bourguignon, 2016

N=length(y);

% tracé des différents niveaux
K = N./(2.^(1:J)); % for j=1:L, K(j)=N/2^j; end;

% combien de subplots : signal, puis détails de 1 à J puis approximation J
P = J+2;

% signal
subplot(P,1,1);
plot(1:N,x);
title('signal');
set(gca,'xlim',[0,N]);


% coefficients de detail
for k = 1:J
    d_k = y(N/2^k+1 : N/2^(k-1));
    subplot(P,1,k+1);
    bar(d_k);
    title(sprintf('Coefficients de detail, niveau %g',k));
    set(gca,'xlim',[0.5,N/2^k+0.5]);
end



% coefficients d'approximation
subplot(P,1,P);
a_J = y(1:N/2^J);
bar(a_J);
title(sprintf('Coefficients d''approximation, niveau %g',k));
set(gca,'xlim',[0.5,N/2^J+0.5]);