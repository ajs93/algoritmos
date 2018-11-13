%% Descripcion
% Testbench unicamente para los registros que necesitan "ayuda" segun el
% algoritmo y umbral proupestos
%% Inicializaciones y declaracion de variables
clear;
clc;
 
recordingNamesFile = fopen('/home/augusto/Escritorio/Beca/Recordings_to_help_aip_patt_1.txt','r'); % Archivo donde estan los archivos que necesitan ayuda
sourceDirectory = '/home/augusto/Escritorio/Beca/DataBases/'; % Lugar donde encontrar las bases de datos
resDirectory = '/home/augusto/Escritorio/Beca/Resultados/corpusN200_helped/'; % Directorio donde guardar los resultados

if sourceDirectory(end) ~= filesep
    sourceDirectory(end + 1) = filesep;
end

if resDirectory(end) ~= filesep
    resDirectory(end + 1) = filesep;
end

if recordingNamesFile == -1
    disp('Error abriendo archivo identificador de los archivos que necesitan ayuda');
    return;
end

eofFound = 1;
counter = 1;
archivos = struct('name',[]);

while eofFound == 1
    auxString = fgetl(recordingNamesFile);
    if auxString == -1
        eofFound = 0;
    else
        archivos(counter).name = auxString;
        counter = counter + 1;
    end
end

fclose(recordingNamesFile);

max_patterns = 2; % Incluyendo el aip_guess
flag_procesamiento = 1;
resultados = struct('file_names',[],'lead_names',[],'TPR',[],'PPV',[],'beats',[],'TP',[], ...
                                    'FP',[],'FN',[],'TN',[],'pattern_name',[]);
algoritmos = 'aip';
aux_alg = 'aip';

resultados.lead_names = 'Lead_corregido';

% Nombres de los patrones a buscar
aip_patterns = {'aip_guess'};
for count = 2:max_patterns
    aip_patterns{end + 1} = ['aip_patt_',num2str(count - 1)];
end

max_patterns = max_patterns - 1;

if max_patterns < 0
    disp('Error en max_patterns, debe ser > 1');
    return;
end

for count = 1:numel(aip_patterns)
    resultados(count).pattern_name = aip_patterns{count};
end

if exist([resDirectory,'Results.mat'], 'file') ~= 0
    % Esto quiere decir que ya habian resultados calculados, tomo
    % directamente el primer archivo que encuentre (deberia haber solo uno
    % por como tengo escrito el script)
    load([resDirectory,'Results.mat'],'resultados');
else
    % No habia ningun archivo de resultados anteriores
    flag_procesamiento = 0;
end

tiempo_total = 0;
bCached = true;

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
            resultados(count).file_names{numel(resultados(count).file_names) + 1} = archivos(file_count).name(1:end);
        end
        
        ECGw.recording_name = [sourceDirectory,archivos(file_count).name];

        % Asigno el algoritmo de deteccion de QRS a utilizar:
        ECGw.ECGtaskHandle = 'arbitrary_function';

        payload = [];

        payload.ECG_annotations = ECGw.ECG_annotations;
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
        
        ECGw.ECGtaskHandle = 'QRS_corrector';
        
        cached_filenames = ECGw.GetCahchedFileName({'QRS_corrector' 'arbitrary_function'});
        ECGw.ECGtaskHandle.payload = load(cached_filenames{1});
        
        ECGw.Run();

        % Tomo el resultado de correr el detector:
        file = ECGw.GetCahchedFileName({'QRS_corrector' 'arbitrary_function'});
        
        resInt = load(cell2mat(file(1)));
        
        for count = 1:numel(file)
            delete(file{count}); % Borro archivos cacheados
        end
        
        res = CalculatePerformanceECGtaskQRSdet(resInt, ECGw.ECG_annotations, ECGw.ECG_header, 1);
        
        % Indices que correspondan a cada patron y distintos resultados
        % para cada uno
        indexes = [];
        for count = 1:numel(res.series_quality.AnnNames(:,1))
            if contains(res.series_quality.AnnNames(count,1),'corrected')
                % El elemento es uno de los que busco
                
                % Guardo los cuatro parametros para tener mas info
                resultados.TP(file_count) = res.series_performance.conf_mat(1,1,count);
                resultados.FP(file_count) = res.series_performance.conf_mat(1,2,count);
                resultados.FN(file_count) = res.series_performance.conf_mat(2,1,count);
                resultados.TN(file_count) = res.series_performance.conf_mat(2,2,count);

                % Obtengo resultados:
                % TPR = TP/(TP+FN)
                % PPV = TP/(TP+FP)
                TPR = res.series_performance.conf_mat(1,1,count) / ...
                    (res.series_performance.conf_mat(1,1,count) + res.series_performance.conf_mat(1,2,count));

                PPV = res.series_performance.conf_mat(1,1,count) / ...
                    (res.series_performance.conf_mat(1,1,count) + res.series_performance.conf_mat(2,1,count));

                resultados.TPR(file_count) = TPR;
                resultados.PPV(file_count) = PPV;
                resultados.beats(file_count) = sum(res.series_performance.conf_mat(:,1,count));
            end
        end
    end
    
    tiempo_total = toc;
else
    disp('Ya se realizo este procesamiento');
end

% Guardo los resultados para no tener que repetir todo el proceso:
save([resDirectory,'Results.mat'],'resultados');

%% Exporto los resultados a tablas:
disp('Escribiendo y exportando tablas...');
disp(newline);

mapa_colores = [0 0 0; ...
                0 0 0; ...
                0 0 0; ...
                0 0 0; ...
                0 0 0; ...
                0 0 0; ...
                1 0 0; ...
                1 104/255 71/255; ...
                1 127/255 80/255; ...
                1 1 0; ...
                173/255 1 47/255; ...
                154/255 205/255 50/255; ...
                0 1 0];

promedios = [];

sub_count = 1;
sub_count2 = 1;
while sub_count < numel(resultados.lead_names)*2
    tablas(:,sub_count) = resultados.TPR(sub_count2,:);
    sub_count = sub_count + 1;
    tablas(:,sub_count) = resultados.PPV(sub_count2,:);
    sub_count = sub_count + 1;
    sub_count2 = sub_count2 + 1;
end

for sub_count = 1:numel(tablas(1,:))
    index = find(tablas(:,sub_count) > -1);
    promedios(1,sub_count) = median(tablas(index,sub_count));
    promedios(2,sub_count) = mad(tablas(index,sub_count));
    promedios(3,sub_count) = mean(tablas(index,sub_count));
    promedios(4,sub_count) = std(tablas(index,sub_count));
    promedios(5,sub_count) = -1;
end

fname = aip_patterns{1};
resultados.file_names{end + 1} = 'median';
resultados.file_names{end + 1} = 'mad';
resultados.file_names{end + 1} = 'mean';
resultados.file_names{end + 1} = 'std_dev';

col_names = [];
for sub_count = 1:numel(resultados.lead_names)
    col_names = [col_names,strcat('TPR_Lead_',resultados.lead_names(sub_count)), ...
                    strcat('PPV_Lead_',resultados.lead_names(sub_count))];
end

GTHTMLtable(fname,[tablas*100 ; promedios*100],'%1.3f%%', ...
    col_names,strcat('Recording_',resultados.file_names),'colormap',mapa_colores,'save');

destino = [resDirectory,'Results_helped_',fname,'.html'];
movefile(strcat('TABLE_',fname,'.html'),destino);

disp(strcat('Algoritmo:',algoritmos,' terminado'));
disp(strcat('Salvado en:',destino));
disp(newline);

clear ans;
disp(strcat('Procesamiento y salvado de archivos terminado.' ));