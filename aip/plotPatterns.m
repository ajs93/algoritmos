%% Para plotear patrones
fig = figure(1);

eje_x = (0:(numel(first_pattern_coeffs) - 1))/ECG_header.freq;
eje_x = eje_x * 1000;
plot(eje_x, first_pattern_coeffs / max(abs(first_pattern_coeffs)));
etiquetas = {};
etiquetas{1} = 'First guess';
hold on;

for i = 1 : numel(aux_pat_coe(1,:))
    plot(eje_x, aux_pat_coe(:,i) / max(abs(aux_pat_coe(:,i))));
    etiquetas{1 + i} = sprintf('Refinement %d', i);
    hold on;
end

legend(etiquetas);
grid on;
xlabel('[msegs]');
xlim([min(eje_x), max(eje_x)]);