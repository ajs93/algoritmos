clear;
clc;

plot_legends = {'width = 30ms','width = 60ms','width = 180ms'};

sampling_freq = 1000;
pattern_width_sec = [30e-3, 60e-3, 180e-3];

pattern_coeffs = cell(1,numel(pattern_width_sec));
padded_coeffs = cell(1,numel(pattern_width_sec));

t = cell(1,numel(pattern_width_sec));
f = cell(1,numel(pattern_width_sec));
pattern_coeffs_fft = cell(1,numel(pattern_width_sec));

for ii = 1:numel(pattern_width_sec)
    pattern_size = 2*round(pattern_width_sec(ii)/2*sampling_freq)+1;

    first_pattern_coeffs = diff(gausswin(pattern_size+1)) .* gausswin(pattern_size);
    first_pattern_coeffs = first_pattern_coeffs / max(abs(first_pattern_coeffs));
    pattern_coeffs{ii} = first_pattern_coeffs;
    
    padded_coeffs{ii} = padarray(first_pattern_coeffs, 50000);
    t{ii} = linspace(0,pattern_width_sec(ii),numel(pattern_coeffs{ii}));
    
    L = numel(padded_coeffs{ii});
    y = fft(padded_coeffs{ii});
    P2 = abs(y) * 2/L;
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2 * P1(2:end-1);
    pattern_coeffs_fft{ii} = P1 / max(abs(P1)); 
    f{ii} = sampling_freq * (0:(L/2))/L;
end

% Ploteo de patrones por un lado
figure(1);

for ii = 1:numel(pattern_width_sec)
    plot(t{ii},pattern_coeffs{ii},'LineWidth',3);
    hold on;
end

box off;
legend(plot_legends);
xlabel('t [s]');
set(gca,'YTick',[]);
set(gca,'FontSize',24);

% Ploteo de respuesta en frecuencia por otro
figure(2);

for ii = 1:numel(pattern_width_sec)
    plot(f{ii},pattern_coeffs_fft{ii},'LineWidth',3);
    hold on;
end

xlim([0 150]);
box off;
legend(plot_legends);
xlabel('f [Hz]');
set(gca,'YTick',[]);
set(gca,'FontSize',24);