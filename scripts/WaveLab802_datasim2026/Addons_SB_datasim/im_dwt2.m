function im_dwt2(DWT_I,J)
% function im_dwt2(DWT_I,J);
%
% trace la DWT 2D contenue dans la matrice DWT_I, calculée sur J niveaux
% Chaque ensemble carré de coefficients est normalisé pour l'affichage

% S. Bourguignon, 2016


[Nc,Nr] = size(DWT_I);

if Nc ~= Nr
    error('attention image non carrée');
else
    N = Nc;
end

DWT_I_scale = zeros(N);

% coefficients de detail
for k = 1:J
    DWT_utile = DWT_I(1:N/2^(k-1),1:N/2^(k-1));
    Nk = N/2^k;
    
    partie =  DWT_utile(Nk+1:end,Nk+1:end);
    DWT_I_coefs(k).detc_detl = partie;    
    DWT_I_scale(Nk+1:2*Nk,Nk+1:2*Nk) = 0.5 + partie/max(max(abs(partie)));
    
    partie =  DWT_utile(Nk+1:end,1:Nk);
    DWT_I_coefs(k).detc_approxl = partie;
    DWT_I_scale(Nk+1:2*Nk,1:Nk) = 0.5 + partie/max(max(abs(partie)));
    
    partie =  DWT_utile(1:Nk,Nk+1:end);    
    DWT_I_coefs(k).detl_approxc = partie;
    DWT_I_scale(1:Nk,Nk+1:2*Nk) = 0.5 +  partie/max(max(abs(partie)));

end

% manque l'approximation echelle J
partie =  DWT_utile(1:Nk,1:Nk);
DWT_I_scale(1:Nk,1:Nk) = partie/max(max(abs(partie)));

figure;
imagesc(DWT_I_scale); colormap gray; axis square; colorbar