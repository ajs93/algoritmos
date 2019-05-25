%% Facilidades para plotear
clear;
clc;

max_values_file = '/home/augusto/Escritorio/GIBIO/VDoPPP_2019/ltstdb_s20571_max_values.mat';

load(max_values_file);

fprintf('Cargando %s\nque correspondiente al recording ltstdb/s20571, canal 2\n', max_values_file);

% Si estas debuggeando, copia desde aca para abajo ------------------------

% Variables para cambiar cosas del ploteo rapidamente:
ancho_linea = 2; % Puntos
size_fuente_leyenda = 14;
limites_x = [0 15];
% ----------------------------------------------------

figure(10);

modificadores = [0.004,1,20];
legends_grillas = {{'$e(l)$','$0.004 * h_s$'},{'$e(l)$','$h_s$'},{'$e(l)$','$25 * h_s$'}};

d_prctile_grid = prctile(max_values,1:100);

for ii = 1:3
    d_grid_step = median(diff(d_prctile_grid))*modificadores(ii);
    d_thr_grid = actual_thr:d_grid_step:max(max_values);

    d_hist_max_values = histcounts(max_values, d_thr_grid);
    
    [d_thr_idx, d_thr_max ] = modmax(colvec(d_hist_max_values),1, 0, 0, [], [] );
    
    d_thr_idx_expected = floor(rowvec(d_thr_idx) * colvec(d_thr_max) *1/sum(d_thr_max));

    d_aux_seq = 1:length(d_thr_grid);
    d_min_hist_max_values = min(d_hist_max_values(d_aux_seq >= 1 & d_aux_seq < d_thr_idx_expected) );
    d_thr_min_idx = round(mean(find(d_aux_seq >= 1 & d_aux_seq < d_thr_idx_expected & [d_hist_max_values 0] == d_min_hist_max_values)));

    d_actual_thr = d_thr_grid(d_thr_min_idx);

    subplot(3,2,1 + 2*(ii-1));
    plot(diff(d_prctile_grid),'LineWidth',ancho_linea);
    line([1,numel(diff(d_prctile_grid))],[d_grid_step,d_grid_step],'Color','red','LineStyle','--','LineWidth',ancho_linea);
    ylim([0,median(diff(d_prctile_grid))*(modificadores(end) * 1.1)]);
    lgd = legend(legends_grillas{ii},'Interpreter','latex');
    lgd.FontSize = size_fuente_leyenda;
    lgd.Location = 'South';
    set(gca,'XTick', [],'YTick', []);

    subplot(3,2,2 + 2*(ii-1));
    
    if ii < 3
        plot(d_thr_grid(1:end-1),d_hist_max_values,'LineWidth',ancho_linea);
    else
        bar(d_thr_grid(1:end-1),d_hist_max_values);
    end
    
    line([d_actual_thr,d_actual_thr], [min(d_hist_max_values),max(d_hist_max_values)],'Color','magenta','LineStyle','--','LineWidth',ancho_linea);
    line([d_thr_grid(d_thr_idx_expected),d_thr_grid(d_thr_idx_expected)],[min(d_hist_max_values),max(d_hist_max_values)],'Color','black','LineStyle','--','LineWidth',ancho_linea);
    xlim(limites_x);
    lgd = legend({'$h_b$','$t_b$','$\tilde{f}$'},'Interpreter','latex');
    lgd.FontSize = size_fuente_leyenda;
    set(gca,'XTick', [],'YTick', []);
end