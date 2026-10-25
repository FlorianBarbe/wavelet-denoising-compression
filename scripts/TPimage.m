clear all
close all;
clc

addpath(genpath('WaveLab802_datasim2026'))

% im2double donne des valeurs entre 0 et 1
I = im2double(imread('cameraman.tif'));

figure;
imagesc(I);
colormap gray;
axis image;
title('Image originale');

J = 4;
classes = 200;

%Transformée par Daubechies 4
h = MakeONFilter('Daubechies',4);
DWT_I =DWT2_datasim(I,J,h);

% Affichage de la DWT sous forme d'image
im_dwt2(DWT_I,J);

% Erreur en fonction du seuil
[~,indices]=sort(abs(DWT_I(:)),'descend');
tau = 5;%fraction des coefficients à garder
nb=floor(length(indices)*tau/100);%nombre de coefficients à garder

indices=indices(1:nb);
DWT_nb=zeros(size(DWT_I));
DWT_nb(indices)=DWT_I(indices);

%image issue de la transformée inverse à tau%
Itau = DWT2inv_datasim(DWT_nb,J,h);


%% Processus de compression en bouclant

% im2double donne des valeurs entre 0 et 1
I = im2double(imread('cameraman.tif'));
J = 4;

figure;
tiledlayout;
nexttile;
imagesc(I);
colormap gray;
axis image;
title('Image originale');

%Transformée par Daubechies 4
h = MakeONFilter('Daubechies',4);
DWT_I =DWT2_datasim(I,J,h);

% On tri les coefficients de la DWT
[tri,indices]=sort(abs(DWT_I(:)),'descend');

% Compression avec une fraction des coefficients
taus=[0.01,0.1,1,5,10,25,75];
DicoIndices=cell(1,9);
DWT1=cell(1,9);
I1=cell(1,9);

for i=1:(length(taus))
    tau=taus(i);
    nb=floor(length(indices)*tau/100);%nombre de coefficients à garder
    DicoIndices{i}=indices(1:nb);
    DWT1{i} = zeros(size(DWT_I)); 
    DWT1{i}(DicoIndices{i})=DWT_I(DicoIndices{i});
    %calcul de l'image par transformée inverse
    I1{i}=DWT2inv_datasim(DWT1{i},J,h);
    nexttile
    imagesc(I1{i});
    title(sprintf('Compression à %.2f%% de coefficients', tau));
    colormap gray;
    axis image;
end


%% Erreur en fonctin de tau
taus=linspace(0,100,100);
erreurs = zeros(size(taus));

for i=1:length(erreurs)
    tau=taus(i);
    nb=floor(length(indices)*tau/100);%nombre de coefficients à garder
    DicoIndices=indices(1:nb);
    DWT= zeros(size(DWT_I)); 
    DWT(DicoIndices)=DWT_I(DicoIndices);
    %calcul de l'image par transformée inverse
    I1=DWT2inv_datasim(DWT,J,h);
    erreurs(i) = norm(I - I1,'fro') / norm(I,'fro');
end

erreurs_db4=erreurs;
taus_courbe=taus;

%% avec Harr 
h=MakeONFilter('Haar');
% im2double donne des valeurs entre 0 et 1
I = im2double(imread('cameraman.tif'));
J = 4;
classes = 200;

figure;
tiledlayout;
nexttile;
imagesc(I);
colormap gray;
axis image;
title('Image originale');

DWT_I =DWT2_datasim(I,J,h);

% On tri les coefficients de la DWT
[tri,indices]=sort(abs(DWT_I(:)),'descend');

% Compression avec une fraction des coefficients
taus=[0.01,0.1,1,5,10,25,75];
DicoIndices=cell(1,9);
DWT1=cell(1,9);
I1=cell(1,9);
for i=1:(length(taus))
    tau=taus(i);
    nb=floor(length(indices)*tau/100);%nombre de coefficients à garder
    DicoIndices{i}=indices(1:nb);
    DWT1{i} = zeros(size(DWT_I)); 
    DWT1{i}(DicoIndices{i})=DWT_I(DicoIndices{i});
    %calcul de l'image par transformée inverse
    I1{i}=DWT2inv_datasim(DWT1{i},J,h);
    nexttile
    imagesc(I1{i});
    title(sprintf('Compression à %.2f%% de coefficients', tau));
    colormap gray;
    axis image;
end
%erreur en fonction de tau

taus=linspace(0,100,100);
erreurs = zeros(size(taus));

for i=1:length(erreurs)
    tau=taus(i);
    nb=floor(length(indices)*tau/100);%nombre de coefficients à garder
    DicoIndices=indices(1:nb);
    DWT= zeros(size(DWT_I)); 
    DWT(DicoIndices)=DWT_I(DicoIndices);
    %calcul de l'image par transformée inverse
    I1=DWT2inv_datasim(DWT,J,h);
    erreurs(i) = norm(I - I1,'fro') / norm(I,'fro');
end

erreurs_haar = erreurs;

%% Comparaison des erreurs
figure;
plot(taus_courbe,erreurs_db4,'LineWidth',1.5);
hold on;
plot(taus_courbe,erreurs_haar,'LineWidth',1.5);
grid on;
xlabel('Coefficients conservés (%)');
ylabel('Erreur relative');
legend('Daubechies 4','Haar');
title('Comparaison des erreurs de compression');

%% Distribution des coefficients et images d'erreur
filtres = {MakeONFilter('Daubechies',4),MakeONFilter('Haar')};
noms = {'Daubechies 4','Haar'};
taux = [1 5 25];

for m = 1:2

    h = filtres{m};
    C = DWT2_datasim(I,J,h);
    [valeurs,indices] = sort(abs(C(:)),'descend');

    figure;
    tiledlayout
    nexttile
    histogram(C(:),200);
    title(['Histogramme : ' noms{m}]);
    xlabel('Coefficient');
    ylabel('Effectif');

    nexttile
    plot(valeurs);
    grid on;
    title('Coefficients triés en valeur absolue');
    xlabel('Rang');
    ylabel('Valeur absolue');

    figure;

    for k = 1:length(taux)

        nb = floor(numel(C)*taux(k)/100);
        Cseuil = zeros(size(C));
        Cseuil(indices(1:nb)) = C(indices(1:nb));

        Irec = DWT2inv_datasim(Cseuil,J,h);

        subplot(2,3,k);
        imagesc(Irec,[0 1]);
        axis image off;
        title(sprintf('Reconstruction : %g %%',taux(k)));

        subplot(2,3,k+3);
        imagesc(abs(I-Irec),[0 1]);
        axis image off;
        title('Erreur absolue');
    end

    colormap gray;
    sgtitle(noms{m});
end

