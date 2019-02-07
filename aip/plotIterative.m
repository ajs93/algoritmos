% Ejemplo de uso: plotIterative(ECGw, 2, 3, 1000, res.aip_guess_ECG.time, res)
% Ejemplo de uso 2: plotIterative(ECGw, 2, 4, 1000, res.aip_patt_1_ECG.time, res)

% sign_chan: Canal a visualizar
% aip_round: Canal del algoritmo a visualizar (Debe coincidir con las
% anotaciones del algoritmo pasadas)

function [] = plotIterative(ECGw, sign_chan, alg_chann, delta_t, ann, res)
    counter = 1;
    
    while counter < ECGw.ECG_header.nsamp
        plotAux(ECGw, sign_chan, counter, delta_t, ann, ECGw.ECG_annotations.time(res.series_performance.conf_mat_details{alg_chann,3}));
        
        counter = counter + delta_t;
    end
end