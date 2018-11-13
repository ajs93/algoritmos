function [positions_single_lead, position_multilead] = thi(ECG_matrix, ECG_header, ~, payload_in)
        % thi Threshold Independent QRS detection
    % Implementation of a threshold independent algorithm for QRS detection
    % in ECGs. Based on the paper:
    % Threshold-Independent QRS Detection Using the Dynamic Plosion Index
    % A. G. Ramakrishnan, Senior Member, IEEE, A. P. Prathosh, and
    % T. V. Ananthapadmanabha
    
    % High-pass filter con frecuencia de corte en 8Hz:
    f1= 8 / (ECG_header.freq/2);
    [d_num,d_den] = butter(2,f1,'high');

    % Dynamic Plotion Index (DPI):
    DPI_window_size = payload_in.DPI_window_size;
    N = ceil(DPI_window_size * ECG_header.freq);
    DPI = zeros(1,N);

    % Parametros del algoritmo:
    m1 = -2;
    p = 2;
    
    % Raiz p-ava de m2:
    p_arr = power(1:N,1/p);

    % Periodo refractario:
    refr_period = ceil(payload_in.refr_period * ECG_header.freq);
    
    % Maximo tamanio del QRS/2:
    max_lenght_QRS = payload_in.max_lenght_QRS;
    max_lenght_QRS = max_lenght_QRS / 2;

    positions_single_lead = cell(1,ECG_header.nsig);
    position_multilead = cell(0);
    
    % Optimizacion de tiempo, para que llamar tantas veces a la funcion
    % "numel(...)" si siempre va a dar el mismo resultado.
    samp_size = numel(ECG_matrix(:,1));
    
    %HECG = filtfilt(d_num, d_den, ECG_matrix);

    for canal = 1:ECG_header.nsig
        % Maximos latidos por minuto: 300bpm
        % Por segundo... 5bps
        % En principio entonces, no pueden haber mas de (5*cant_segs) latidos
        arr_n0 = zeros(1,ceil(5*(ECG_header.nsamp / ECG_header.freq))); % Pre-Alocacion de la memoria para que sea efectiva
        % Si bien es excesivamente grande, segun la sugerencia de MatLab,
        % es mas eficiente que ir agrandando el array en el loop.
        k = 1;
        
        % Filtrado con fase cero:
        HECG = ECG_matrix(:,canal);
        HECG = HECG';
        HECG = filtfilt(d_num,d_den,HECG);
        HHECG = subplus(HECG); % Rectificacion

        % El primer n0 lo obtengo obteniendo el maximo de HECG en una
        % ventana de:
        % Menor cantidad de latidos por minuto: 26bpm
        % En segundos: (26/60)bps
        window_size = ceil((60/26)*ECG_header.freq);
        
        % Tomo del ECG ya filtrado el pedazo a analizar:
        ECG_local = HECG(1:window_size);
        
        % Maximo en la senial local:
        [~,n_R] = max(abs(ECG_local));
        
        n0 = n_R;
        
        if(n0 < abs(m1))
            n0 = abs(m1)+1;
        end
        
        % Tamanio de la ventana a usar dentro del loop (~maximo largo del
        % QRS/2):
        window_size = ceil(max_lenght_QRS * ECG_header.freq);

        while n0 < samp_size - N
            % Agrego el n0 al array donde los voy juntando
            arr_n0(k) = n0;
            
            estimate_found = 0;
            
            while estimate_found == 0 && n0 < samp_size - N
                % Nota sobre la zona comentariada de aca abajo: La cambie
                % por la primer linea no comentada hacia abajo, para
                % optimizar el tiempo de procesamiento del algoritmo, lo
                % cual mejoro muchisimo la velocidad del mismo.
%                for m2 = 1:N
%                    y2avg = sum(abs(HHECG(n0+m1+1:n0+m1+m2)));
%                    y2avg = y2avg/power(m2,1/p);
%                    if y2avg ~= 0
%                        DPI(m2) = abs(HECG(n0))/y2avg;
%                    end
%                end

                % Nota: En esta linea, utilizaba un if que era redundante
                % con el while, preguntaba lo mismo, en un lugar donde no
                % era necesario, al eliminarlo, se optimizo de manera
                % drastica (x50) la velocidad del algoritmo.
                
                DPI = ((ones(1,N) * abs(HECG(n0))) ./ cumsum(HHECG(n0+m1+1:n0+m1+N))) .* p_arr;
                
                % Obtengo los picos tanto negativos como positivos (valleys
                % y peaks) del DPI, a partir de 250mseg (periodo
                % refractario) luego del pico anterior detectado:
%                [~,DPI_peaks_loc] = findpeaks(DPI(refr_period:end));
%                [~,DPI_valleys_loc] = findpeaks(-DPI(refr_period:end));
                [DPI_peaks_loc,~] = modmax(DPI(refr_period:end)', 1, 0, 0);
                [DPI_valleys_loc,~] = modmax((-DPI(refr_period:end) - min(-DPI(refr_period:end)))', 1, 0, 0);

                DPI_peaks_loc = DPI_peaks_loc';
                DPI_valleys_loc = DPI_valleys_loc';

                if ~isempty(DPI_peaks_loc) && ~isempty(DPI_valleys_loc)
                   estimate_found = 1;
                else
                    % Si no encontro un lugar para estimar el proximo
                    % complejo QRS, tomo una ventana de 10 segundos hacia
                    % atras para ver cual fue el intervalo RR promedio en
                    % ese intervalo temporal.
                    beats_after10s = arr_n0(arr_n0 > (n0 - round(10 * ECG_header.freq)));
                    beats_difference = abs(diff(beats_after10s)); % Intervalos R-R
                    % Tomando la mediana:
                    RR_avg_10s = ceil(median(beats_difference));

                    if isnan(RR_avg_10s) || (RR_avg_10s == 0)
                        RR_avg_10s = 1;
                    end

                    n0 = n0 + RR_avg_10s;

                    while HECG(n0) == 0
                        n0 = n0 + 1;
                    end
                end
            end
            
            if n0 < samp_size - N
                DPI_peaks_loc = DPI_peaks_loc + refr_period;
                DPI_valleys_loc = DPI_valleys_loc + refr_period;

                % El primero tiene que ser un pico
                if DPI_valleys_loc(1) < DPI_peaks_loc(1)
                    DPI_valleys_loc = DPI_valleys_loc(2:end);
                end

                % Calculo la diferencia de la DPI entre peak y valley ("swing")
                cant_peaks = numel(DPI_peaks_loc);
                cant_valleys = numel(DPI_valleys_loc);
                if cant_peaks ~= cant_valleys
                    % Igualo tamanios al que menor cantidad de elementos tenga:
                    DPI_valleys_loc = DPI_valleys_loc(1:min([numel(DPI_valleys_loc) numel(DPI_peaks_loc)]));
                    DPI_peaks_loc = DPI_peaks_loc(1:min([numel(DPI_valleys_loc) numel(DPI_peaks_loc)]));
                end

                swing = DPI(DPI_peaks_loc) - DPI(DPI_valleys_loc);

                % Maximo swing:
                [~,n_swing] = max(swing);

                % Se obtiene el estimativo inicial:
                initial_estimate = n0 + DPI_valleys_loc(n_swing);

                if initial_estimate < (window_size + 1)
                    initial_estimate = window_size + 1;
                end

                % Pedazo del ECG ya filtrado con el filtro de Fc = 8Hz:
                ECG_local = HECG(initial_estimate-window_size:initial_estimate+window_size);

                % Maximo absoluto en la senial local:
                [~,n_R] = max(abs(ECG_local));

                % Proximo n0:
                n0 = initial_estimate + (n_R - window_size);

                % Incremento indice
                k = k + 1;
            end
        end
        
        % Ultimo n0 detectado al salir del loop:
        if(~isempty(n0))
            arr_n0(k) = n0;
        end
        
        % 'Shrinkeo' el array arr_n0:
        arr_n0 = arr_n0(arr_n0 ~= 0);

        positions_single_lead{canal} = arr_n0;
    end
end