clear all
close all;
clc

addpath(genpath('WaveLab802_datasim2026'))


%% Ondelettes et fonctions échelles par DWT inverse

N=512;
J=5;

%% fonction échelle en construisant un vecteur avec un seul coef d'approximation
%on construit le coefficient d'approximation à l'échelle J aJ, donc une
%valeur non nulle parmis les N/2^J premiers points
k1=floor(N/(2^(J))/2); %indice où on met le 1 (au milieu du vecteur d'approximation)
DWTx1=zeros(1,N);
DWTx1(k1)=1;

%On en déduit, par transformée inverse, la fonction échelle a correspondant `a la
%transformée de Haar. La tracer et commenter (fonction plot dwt).

h1=MakeONFilter('Haar');
x1=DWTinv_datasim(DWTx1,J,h1);
figure();
plot (x1);

%% fonction ondelette correspondante
k2=N/(2^J)+k1; %indice du détail correspondant à l'indice choisi pour la fonction échelle
DWTx2=zeros(1,N);
DWTx2(k2)=1;%on met donc cette fopis un 1 à la position 16+8=24, ou 8ème position du vecteur de détail d'ordre J=5

%La transformée inverse donne cette fois la fonction ondelette, correspondant à la fonction échelle pour le détail que l'on avait choisi

x2=DWTinv_datasim(DWTx2,J,h1);
figure();
plot (x2);


%% Ondelettes de Daubechies d'ordre 4
D=4;
h2=MakeONFilter('Daubechies',D);
x1deb=DWTinv_datasim(DWTx1,J,h2);
x2deb=DWTinv_datasim(DWTx2,J,h2);


figure;
tiledlayout(2,1);

nexttile;
plot(x1deb);
subtitle("Fonction d'échelle de Daubechies 4 (DTWx(8)=1)")

nexttile;
plot(x2deb);
subtitle("Fonction ondelette de Daubechies 4 (DTWx(24)=1)")

%% Construction successive de vecteurs avec seulement un coefficient non nul
X=cell(1,N);
figure();
DWTx=zeros(1,N);
DWTx(1)=1;
d=[0 1];% impulsion retardée d'une case pour décaler le 1 d'une case à chaque itération
X{1}=DWTinv_datasim(DWTx,J,h1);
plot_dwt(X{1},DWTx,J)
title(sprintf('Coefficient non nul : i=1'));
drawnow;

pause(0.05);
for i=1:(N-1)
    DWTx=conv(DWTx,d);%on décale le 1 d'une position à droite
    DWTx=DWTx(1:N);%on coupe la dernière case qui vient de se rajouter à cause de la convolutiuon
    X{i+1}=DWTinv_datasim(DWTx,J,h1);
    % plot_dwt(X{i+1},DWTx,J)
    % title(sprintf('Coefficient non nul : i=%d / %d', i+1, N));
    % 
    % drawnow;
    % pause(0.05);
    % Quelques affichages représentatifs pour pas que ça dure 3 heures
    if ismember(i+1,[8 24 48 96 192 384 512])
        plot_dwt(X{i+1},DWTx,J);
        sgtitle(sprintf('Coefficient non nul : %d / %d',i+1,N));
        drawnow;
    end
end

%% Débruitage de Blocks et Doppler avec Haar et Daubechies 4

load('blocks.mat','x_blocks');
load('Doppler.mat','x_doppler');

signaux={x_blocks(:).', x_doppler(:).'};
noms_signaux={'Blocks','Doppler'};
filtres={h1,h2};
noms={'Haar','Daubechies 4'};
couleurs=[0 0.4470 0.7410; 0.8500 0.3250 0.0980];
SNR=10;
resultats=struct([]);

for s=1:2

    x=signaux{s};
    N=length(x);
    J=round(log2(N));

    % On ajoute du bruit
    rng(s-1);%graine différente pour les deux signaux bruités
    [xbruit,sigmab]=ajoute_bruit(x,SNR);
    xbruit=xbruit(:).';
    alpha_DJ=sigmab * sqrt(2*log(N));

    for m=1:2%à signal fixxé, on parcours les bruits

        h=filtres{m};

        % DWT correspondante
        DWTx=DWT_datasim(x,J,h);
        figure('Name',[noms_signaux{s} ' - DWT - ' noms{m}]);
        plot_dwt(x,DWTx,J);
        sgtitle([noms_signaux{s} ' : DWT avec ' noms{m}]);

        % DWT bruitée
        DWTxb=DWT_datasim(xbruit,J,h);
        figure('Name',[noms_signaux{s} ' - DWT bruitée - ' noms{m}]);
        plot_dwt(xbruit,DWTxb,J);
        sgtitle([noms_signaux{s} ' bruité : DWT avec ' noms{m}]);

        % Estimation robuste de l'écart-type du bruit
        d1=DWTxb(N/2+1:N);%on va piocher le bruit dans les coefficients de détail
        sigma_MAD=median(abs(d1-median(d1))) / 0.6745;%cf la doc du compte rendu

        % Seuil universel estimé à partir du seul signal bruité
        alpha_stat=sigma_MAD * sqrt(2*log(N));%cf la doc du compte rendu
        alpha_max=max(2*alpha_stat,eps);%cf la doc du compte rendu

        % Débruitage pour une série de seuils
        alphas=unique([linspace(0,alpha_max,400),alpha_stat]); % ajoute le seuil statistique à la grille, trie et supprime les doublons
        erreurs=zeros(size(alphas));

        for k=1:length(alphas)
            DWTseuil=DWTxb.*(abs(DWTxb)>=alphas(k));
            xrec=DWTinv_datasim(DWTseuil,J,h);%le x reconstruit avec le seuillage courant
            xrec=xrec(:).';
            erreurs(k)=norm(x-xrec)/norm(x);%l'erreur  pour le seuillage courant
        end

        % Recherche du meilleur seuil
        [erreur_min,indice_opt]=min(erreurs);
        alpha_opt=alphas(indice_opt);

        % Reconstruction avec le seuil optimal qu'on vient de trouver 
        DWT_opt=DWTxb.*(abs(DWTxb)>=alpha_opt);
        x_opt=DWTinv_datasim(DWT_opt,J,h);
        x_opt=x_opt(:).';

        % Reconstruction avec le seuil de Donoho-Johnstone
        DWT_DJ=DWTxb.*(abs(DWTxb)>=alpha_DJ);
        x_DJ=DWTinv_datasim(DWT_DJ,J,h);
        x_DJ=x_DJ(:).';
        
        %on stocke tout dans la classe résultats
        resultats(s,m).signal=noms_signaux{s};
        resultats(s,m).ondelette=noms{m};
        resultats(s,m).x=x;
        resultats(s,m).xbruit=xbruit;
        resultats(s,m).DWTx=DWTx;
        resultats(s,m).DWTxb=DWTxb;
        resultats(s,m).sigma_MAD=sigma_MAD;
        resultats(s,m).alpha_stat=alpha_stat;
        resultats(s,m).alpha_max=alpha_max;
        resultats(s,m).alpha_DJ=alpha_DJ;
        resultats(s,m).alphas=alphas;
        resultats(s,m).erreurs=erreurs;
        resultats(s,m).alpha_opt=alpha_opt;
        resultats(s,m).erreur_min=erreur_min;
        resultats(s,m).DWT_opt=DWT_opt;
        resultats(s,m).DWT_DJ=DWT_DJ;
        resultats(s,m).x_opt=x_opt;
        resultats(s,m).x_DJ=x_DJ;
        resultats(s,m).erreur_DJ=norm(x-x_DJ)/norm(x);
    end
end

%% Comparaison des débruitages
%on affiche tout pour comparer et conclure en allant piocher dans les résultats
for s=1:2

    figure('Name',['Comparaison des débruitages - ' noms_signaux{s}],'Position',[60 60 1400 850]);
    tiledlayout(3,2,'TileSpacing','compact');
    
    %le signal de base de référence
    nexttile;
    plot(resultats(s,1).x);
    title('Signal original');
    xlabel('Indice temporel');
    ylabel('Amplitude');
    grid on;

    %le signal bruité à 10dB correspondant
    nexttile;
    plot(resultats(s,1).xbruit);
    title('Signal bruité, SNR=10 dB');
    xlabel('Indice temporel');
    ylabel('Amplitude');
    grid on;

    for m=1:2
        % Signal reconstruit avec le seuil minimisant l'erreur sur la grille testée
        nexttile;
        plot(resultats(s,m).x_opt,'Color',couleurs(m,:));
        % couleurs(m,:) sélectionne les trois composantes RGB de l'ondelette m
        % sprintf insère le nom (%s), le seuil et l'erreur relative 
        title(sprintf('%s : optimal, alpha=%.4g, erreur=%.3f',noms{m},resultats(s,m).alpha_opt,resultats(s,m).erreur_min));
        xlabel('Indice temporel');
        ylabel('Amplitude');
        grid on;

        % Signal reconstruit avec le seuil statistique de Donoho-Johnstone
        nexttile;
        plot(resultats(s,m).x_DJ,'Color',couleurs(m,:));
        % couleurs(m,:) sélectionne les trois composantes RGB de l'ondelette m
        %idem
        title(sprintf('%s : DJ, alpha=%.4g, erreur=%.3f',noms{m},resultats(s,m).alpha_DJ,resultats(s,m).erreur_DJ));
        xlabel('Indice temporel');
        ylabel('Amplitude');
        grid on;
    end

    sgtitle(['Comparaison des débruitages de ' noms_signaux{s}]);
end

%% Comparaison des erreurs sur Blocks et Doppler

figure('Name','Erreurs et seuils - Blocks et Doppler','Position',[60 60 1500 700]);
tiledlayout(1,2,'TileSpacing','compact');

for s=1:2

    nexttile;
    hold on;

    for m=1:2
        plot(resultats(s,m).alphas,resultats(s,m).erreurs, ...
            'Color',couleurs(m,:),'LineWidth',1.5, ...
            'DisplayName',noms{m});
    end

    for m=1:2
        plot(resultats(s,m).alpha_opt,resultats(s,m).erreur_min, ...
            'o','Color',couleurs(m,:),'MarkerFaceColor',couleurs(m,:), ...
            'HandleVisibility','off');

        xline(resultats(s,m).alpha_opt,'--', ...
            'Color',couleurs(m,:),'LineWidth',1.2, ...
            'DisplayName',sprintf('Optimal %s : %.4g', ...
            noms{m},resultats(s,m).alpha_opt));

        xline(resultats(s,m).alpha_stat,':', ...
            'Color',couleurs(m,:),'LineWidth',1.5, ...
            'DisplayName',sprintf('DJ estimé MAD %s : %.4g', ...
            noms{m},resultats(s,m).alpha_stat));

        xline(resultats(s,m).alpha_max,'-.', ...
            'Color',couleurs(m,:),'LineWidth',0.8, ...
            'DisplayName',sprintf('Fin du balayage %s : %.4g', ...    
            noms{m},resultats(s,m).alpha_max));
    end

    xline(resultats(s,1).alpha_DJ,'k-.','LineWidth',1.3, ...
        'DisplayName',sprintf('DJ avec sigma connu : %.4g', ...
        resultats(s,1).alpha_DJ));

    grid on;
    xlabel('Seuil \alpha');
    ylabel('Erreur relative');
    title(noms_signaux{s});
    legend('Location','southoutside','FontSize',8,'NumColumns',2);
end
