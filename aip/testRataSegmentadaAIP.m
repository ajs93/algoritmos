%% Testbench armado para las bases de datos NO ECG
clear
clc

% Delete cached?
delete_cached = false;

% Check cached?
bCached = false;

% Donde estan las muestras:
source_directory = '/home/augusto/Escritorio/GIBIO/DataBases/ratadb_segmentada/';
res_source_directory = '/home/augusto/Escritorio/GIBIO/Resultados_articulo_AIP/ratadb_segmentada_results_aip_mal_parametrosa/';

% Archivo de texto con los recordings a segmentar
recording_file_handler = fopen('/home/augusto/Escritorio/GIBIO/Algoritmos/algoritmos/recordings_rata.txt','r');

if recording_file_handler == -1
    disp('Error abriendo archivo de recordings a segmentar.');
    return;
end

if source_directory(end) ~= filesep
    source_directory(end + 1) = filesep;
end

if res_source_directory(end) ~= filesep
    res_source_directory(end + 1) = filesep;
end

if ~exist(res_source_directory, 'dir')
    mkdir(res_source_directory);
end

eof_found = 1;
counter = 1;
archivos = struct('name',[]);

while eof_found == 1
    aux_string = fgetl(recording_file_handler);
    if aux_string == -1
        eof_found = 0;
    else
        archivos(counter).name = aux_string;
        counter = counter + 1;
    end
end

fclose(recording_file_handler);

max_patterns = 1; % Incluyendo el aip_guess
flag_procesamiento = 1;
resultados(max_patterns) = struct('file_names',[],'lead_names',[],'TPR',[],'PPV',[],'F1',[],'beats',[],'TP',[], ...
                                    'FP',[],'FN',[],'TN',[],'pattern_name',[]);
algoritmos = 'aip';
aux_alg = 'aip';

% Nombres de los patrones a buscar
aip_patterns = {'aip_guess'};
for count = 2:max_patterns
    aip_patterns{end + 1} = ['aip_patt_',num2str(count - 1)];
end

for count = 1:numel(aip_patterns)
    resultados(count).pattern_name = aip_patterns{count};
end

if exist([res_source_directory,'Results.mat'], 'file') ~= 0
    % Esto quiere decir que ya habian resultados calculados, tomo
    % directamente el primer archivo que encuentre (deberia haber solo uno
    % por como tengo escrito el script)
    load([res_source_directory,'Results.mat'],'resultados');
else
    % No habia ningun archivo de resultados anteriores
    flag_procesamiento = 0;
end

tiempo_total = 0;

if flag_procesamiento == 0
    % Comienzo conteo
    tic;

    % Parametros internos
    total_beats = 0;

    % True positive rate (sensibilidad):
    TPR = 0;

    % Positive predictive value (precision):
    PPV = 0;

    for file_count = 1:numel(archivos)
        ECGw = ECGwrapper();

        for count = 1:numel(resultados)
            resultados(count).file_names{numel(resultados(count).file_names) + 1} = archivos(file_count).name;
        end

        ECGw.recording_name = [source_directory,archivos(file_count).name];

        % Asigno el algoritmo de deteccion de QRS a utilizar:
        ECGw.ECGtaskHandle = 'arbitrary_function';

        payload = [];

        payload.trgt_width = 60e-3;
        payload.trgt_min_pattern_separation = 300e-3;
        payload.trgt_max_pattern_separation = 2;
        payload.max_patterns_found = max_patterns;
        ECGw.ECGtaskHandle.payload = payload;

        ECGw.user_string = 'AIP_det';

        % add your function pointer
        ECGw.ECGtaskHandle.function_pointer = @aip_detector;
        ECGw.ECGtaskHandle.concate_func_pointer = @aip_detector_concatenate;

        ECGw.cacheResults = bCached; 

        ECGw.Run();

        % Tomo el resultado de correr el detector:
        file = ECGw.GetCahchedFileName('arbitrary_function');

        resInt = load(cell2mat(file));

        if delete_cached == true
            delete(file{1}); % Borro archivo cacheado
        end
        
        res = CalculatePerformanceECGtaskQRSdet(resInt, ECGw.ECG_annotations, ECGw.ECG_header, 1);

%         ECGw.ECGtaskHandle = 'QRS_corrector';
        
%         resInt.anotaciones_posta = ECGw.ECG_annotations;
%         resInt.series_quality.AnnNames(end + 1,:) = {'anotaciones_posta','time'};
%         resInt.series_quality.ratios(end + 1) = 0;
%         
%         ECGw.ECGtaskHandle.payload = resInt;
%         
%         ECGw.Run();
        
        % Indices que correspondan a cada patron y distintos resultados
        % para cada uno
        indexes = [];
        for count = 1:numel(res.series_quality.AnnNames(:,1))
            for sub_count = 1:max_patterns
                if contains(res.series_quality.AnnNames(count,1),aip_patterns(sub_count))
                    % El elemento es uno de los que busco
                    if isempty(resultados(sub_count).lead_names)
                        index = [];
                    else
                        index = find(contains(resultados(sub_count).lead_names,res.series_quality.AnnNames{count,1}));
                    end

                    if isempty(index)
                        % Hay que agregar el lead, no habia sido encontrado
                        % antes
                        resultados(sub_count).lead_names{end + 1} = res.series_quality.AnnNames{count,1};
                        index = numel(resultados(sub_count).lead_names);
                        resultados(sub_count).TP(index,1:numel(archivos)) = -1;
                        resultados(sub_count).FP(index,1:numel(archivos)) = -1;
                        resultados(sub_count).FN(index,1:numel(archivos)) = -1;
                        resultados(sub_count).TN(index,1:numel(archivos)) = -1;
                        resultados(sub_count).TPR(index,1:numel(archivos)) = -1;
                        resultados(sub_count).PPV(index,1:numel(archivos)) = -1;
                        resultados(sub_count).F1(index,1:numel(archivos)) = -1;
                    end

                    % En index tengo el lugar donde poner el TPR y el PPV
                    % del recording y del canal
                    % Guardo los cuatro parametros para tener mas info
                    TP = res.series_performance.conf_mat(1,1,count);
                    FP = res.series_performance.conf_mat(2,1,count);
                    FN = res.series_performance.conf_mat(1,2,count);
                    TN = res.series_performance.conf_mat(2,2,count);
                    
                    resultados(sub_count).TP(index,file_count) = TP;
                    resultados(sub_count).FP(index,file_count) = FP;
                    resultados(sub_count).FN(index,file_count) = FN;
                    resultados(sub_count).TN(index,file_count) = TN;

                    % Obtengo resultados:
                    % TPR = TP/(TP+FN)
                    % PPV = TP/(TP+FP)
                    TPR = TP / (TP + FN);

                    PPV = TP / (TP + FP);

                    F1 = (2*TP)/(2*TP+FP+FN);

                    resultados(sub_count).TPR(index,file_count) = TPR;
                    resultados(sub_count).PPV(index,file_count) = PPV;
                    resultados(sub_count).F1(index,file_count) = F1;
                    resultados(sub_count).beats(index,file_count) = sum(res.series_performance.conf_mat(:,1,count));
                end
            end
        end
    end
    
    tiempo_total = toc;
else
    disp('Ya se realizo este procesamiento');
end

% Guardo los resultados para no tener que repetir todo el proceso:
save([res_source_directory,'Results.mat'],'resultados');

disp('Resultado guardado en:');
disp([res_source_directory,'Results.mat']);

export_tables(resultados, res_source_directory);