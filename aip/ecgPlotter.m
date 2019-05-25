%% Facilidad para graficar ECG + Rise Detector y detecciones

% Variables para cambiar cosas del ploteo rapidamente:
ancho_linea = 2; % Puntos
size_fuente_leyenda = 14;
size_marker = 10;
% ----------------------------------------------------

figure(10);

d_offset_en_segundos = 20;
d_segundos_a_plotear = 4;

d_offset_en_muestras = d_offset_en_segundos * ECG_header.freq;
d_muestras_a_plotear = d_segundos_a_plotear * ECG_header.freq;

d_t = linspace(d_offset_en_segundos, d_offset_en_segundos + d_segundos_a_plotear, d_muestras_a_plotear);

% Maximos en el rise detector
d_actual_thr = prctile(rise_detector, 0);
% [d_indices_maximos, ~]= modmax(rise_detector, 1, d_actual_thr, 1, round(payload_in.trgt_min_pattern_separation * ECG_header.freq));
[d_indices_maximos, ~]= modmax(rise_detector, 1, d_actual_thr, 1);

d_maximos_mayores_a_umbral = d_indices_maximos(rise_detector(d_indices_maximos) >= actual_thr & ... 
    d_indices_maximos >= (d_offset_en_muestras + 1) & d_indices_maximos < (d_offset_en_muestras + 1 + d_muestras_a_plotear));
d_maximos_menores_a_umbral = d_indices_maximos(rise_detector(d_indices_maximos) < actual_thr & ... 
    d_indices_maximos >= (d_offset_en_muestras + 1) & d_indices_maximos < (d_offset_en_muestras + 1 + d_muestras_a_plotear));

d_indices_maximos = d_indices_maximos(d_indices_maximos >= (d_offset_en_muestras + 1) & ...
    d_indices_maximos < (d_offset_en_muestras + 1 + d_muestras_a_plotear));

subplot(2,1,1);
plot(d_t, ECG_matrix(d_offset_en_muestras + 1:d_offset_en_muestras + d_muestras_a_plotear,this_sig_idx),'LineWidth',ancho_linea);
lgd = legend({'$s(n)$'},'Interpreter','latex');
lgd.FontSize = size_fuente_leyenda;
set(gca,'XTick',[], 'YTick', []);

subplot(2,1,2);
plot(d_t, rise_detector(d_offset_en_muestras + 1:d_offset_en_muestras + d_muestras_a_plotear),'LineWidth',ancho_linea);
hold on;
plot(d_t(d_maximos_mayores_a_umbral - d_offset_en_muestras),rise_detector(d_maximos_mayores_a_umbral),'g*','MarkerSize',size_marker);
% plot(d_t(d_indices_maximos - d_offset_en_muestras),rise_detector(d_indices_maximos),'g*','MarkerSize',size_marker);
hold on;
line([d_t(1),d_t(end)],[actual_thr,actual_thr],'LineWidth',ancho_linea,'Color','black','LineStyle','--');
plot(d_t(d_maximos_menores_a_umbral - d_offset_en_muestras),rise_detector(d_maximos_menores_a_umbral),'rx','MarkerSize',size_marker);
lgd = legend({'$a(\theta)$','$\mathbf{d}$','$h_s$','$not \, \mathbf{d}$'},'Interpreter','latex');
lgd.FontSize = size_fuente_leyenda;
set(gca,'XTick',[], 'YTick', []);