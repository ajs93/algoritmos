%% Prueba para el toolkit ECGkit
clear
clc

% Donde estan las muestras:
sourceDirectory = '/home/augusto/Escritorio/Beca/DataBases/';
resSourceDirectory = '/home/augusto/Escritorio/Beca/Resultados/';
dbName = 'ratadb';

if sourceDirectory(end) ~= filesep
    sourceDirectory(end + 1) = filesep;
end

if resSourceDirectory(end) ~= filesep
    resSourceDirectory(end + 1) = filesep;
end

archivos = dir([sourceDirectory,dbName,filesep,'*.dat']);

flag_procesamiento = 1;
resultados = struct('file_names',[],'lead_names',[],'TPR',[],'PPV',[],'beats',[]);
algoritmos = 'pantom';
aux_alg = 'pantom';

payload.DPI_window_size = 1000e-3;
payload.refr_period = 120e-3;
payload.max_lenght_QRS = 40e-3;


final_res_directory = [resSourceDirectory,dbName,'_',algoritmos,filesep];

if exist([final_res_directory,'Results.mat'], 'file') ~= 0
    % Esto quiere decir que ya habian resultados calculados, tomo
    % directamente el primer archivo que encuentre (deberia haber solo uno
    % por como tengo escrito el script)
    load([final_res_directory,'Results.mat'],'resultados');
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
            resultados(count).file_names{end + 1} = archivos(file_count).name(1:end);
        end
        
        ECGw.recording_name = [sourceDirectory,dbName,filesep,archivos(file_count).name];

        % Asigno el algoritmo de deteccion de QRS a utilizar:
        ECGw.ECGtaskHandle = 'QRS_detection';
        ECGw.ECGtaskHandle.detectors = {algoritmos};
        ECGw.ECGtaskHandle.payload = payload;

        % Paso las anotaciones manuales
        aux_val = load([sourceDirectory,dbName,filesep,archivos(file_count).name(1:end-4),'_manual_detections.mat']);
        ECGw.ECG_annotations = aux_val.manual;
        
        ECGw.ECGtaskHandle.CalculatePerformance = true;
        ECGw.cacheResults = bCached;

        ECGw.Run();

        % Tomo el resultado de correr el detector:
        file = ECGw.GetCahchedFileName('QRS_detection');

        res = load(cell2mat(file));
        delete(file{1}); % Borro archivo cacheado
        
        % Indices que correspondan a cada patron y distintos resultados
        % para cada uno
        indexes = [];
        for count = 1:numel(res.series_quality.AnnNames(:,1))
            if contains(res.series_quality.AnnNames(count,1),'pantom')
                % El elemento es uno de los que busco
                if isempty(resultados(1).lead_names)
                    index = [];
                else
                    index = find(contains(resultados(1).lead_names,res.series_quality.AnnNames{count,1}));
                end

                if isempty(index)
                    % Hay que agregar el lead, no habia sido encontrado
                    % antes
                    resultados(1).lead_names{end + 1} = res.series_quality.AnnNames{count,1};
                    index = numel(resultados(1).lead_names);
                    resultados(1).TPR(index,1:numel(archivos)) = -1;
                    resultados(1).PPV(index,1:numel(archivos)) = -1;
                end

                % En index tengo el lugar donde poner el TPR y el PPV
                % del recording y del canal
                % Obtengo resultados:
                % TPR = TP/(TP+FN)
                % PPV = TP/(TP+FP)
                TPR = res.series_performance.conf_mat(1,1,count) / ...
                    (res.series_performance.conf_mat(1,1,count) + res.series_performance.conf_mat(1,2,count));

                PPV = res.series_performance.conf_mat(1,1,count) / ...
                    (res.series_performance.conf_mat(1,1,count) + res.series_performance.conf_mat(2,1,count));

                resultados(1).TPR(index,file_count) = TPR;
                resultados(1).PPV(index,file_count) = PPV;
                resultados(1).beats(index,file_count) = sum(res.series_performance.conf_mat(:,1,count));
            end
        end
    end
    
    tiempo_total = toc;
else
    disp('Ya se realizo este procesamiento');
end

% Guardo los resultados para no tener que repetir todo el proceso:
save([final_res_directory,'Results.mat'],'resultados');

disp('Resultado guardado en:');
disp([final_res_directory,'Results.mat']);
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

for final_count = 1:numel(resultados)
    promedios = [];

    sub_count = 1;
    sub_count2 = 1;
    while sub_count < numel(resultados(final_count).lead_names)*2
        tablas(:,sub_count) = resultados(final_count).TPR(sub_count2,:);
        sub_count = sub_count + 1;
        tablas(:,sub_count) = resultados(final_count).PPV(sub_count2,:);
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
    
    fname = strcat('Algoritmo_',algoritmos);
    resultados(final_count).file_names{end + 1} = 'median';
    resultados(final_count).file_names{end + 1} = 'mad';
    resultados(final_count).file_names{end + 1} = 'mean';
    resultados(final_count).file_names{end + 1} = 'std_dev';

    col_names = [];
    for sub_count = 1:numel(resultados(final_count).lead_names)
        col_names = [col_names,strcat('TPR_Lead_',resultados(final_count).lead_names(sub_count)), ...
                        strcat('PPV_Lead_',resultados(final_count).lead_names(sub_count))];
    end

    GTHTMLtable(fname,[tablas*100 ; promedios*100],'%1.3f%%', ...
        col_names,strcat('Recording_',resultados(final_count).file_names),'colormap',mapa_colores,'save');

    destino = [final_res_directory,'Results_',fname,'.html'];
    movefile(strcat('TABLE_',fname,'.html'),destino);

    disp(strcat('Algoritmo:',algoritmos,' terminado'));
    disp(strcat('Salvado en:',destino));
    disp(newline);

    clear ans;
    disp(strcat('Procesamiento y salvado de archivos terminado.' ));

    %% Seleccion de los mejores resultados
    % Criterio de seleccion para los resultados optimos:
    % 1) Si ambos parametros (PPV y TPR) son mayores para un lead que para
    % cualquier otro, se lo toma como mejor.
    % 2) En el caso que no suceda lo anterior, se promedia el TPR y PPV y se
    % toma el que mayor promedio tenga

    tablas_optimas = zeros(numel(resultados(final_count).file_names) + 1,2);
    tablas_optimas(end,:) = -1;

    % Correccion de los lead_names
    resultados(final_count).lead_names = strrep(resultados(final_count).lead_names,algoritmos,'');
    for record = 1:numel(resultados(final_count).file_names) - 4
        max_TPR_value = 0;
        max_TPR_index = 0;
        max_PPV_value = 0;
        max_PPV_index = 0;
        max_PRO_value = 0;
        max_PRO_index = 0;

        for sub_count = 1:numel(resultados(final_count).lead_names)
            if (tablas(record,(sub_count * 2) - 1) > max_TPR_value)
                max_TPR_value = tablas(record,(sub_count * 2) - 1);
                max_TPR_index = (sub_count * 2) - 1;
            end

            if (tablas(record,sub_count * 2) > max_PPV_value)
                max_PPV_value = tablas(record,sub_count * 2);
                max_PPV_index = (sub_count * 2) - 1;
            end
        end

        if (max_TPR_index == max_PPV_index)
            % Este caso es cuando ambos indices son mayores en algun lead
            % en particular
            tablas_optimas(record,1) = max_TPR_value;
            tablas_optimas(record,2) = max_PPV_value;
        else
            % Si el indice donde esta el mayor TPR y PPV es distinto, elijo
            % el que mayor promedio tenga entre los dos parametros
            sub_count = 1;

            for sub_count = 1:numel(resultados(final_count).lead_names)
                if (tablas(record,(sub_count * 2) - 1) ~= -1)
                    PRO_value = (tablas(record,(sub_count * 2) - 1) + tablas(record,sub_count * 2))/2;
                    if PRO_value > max_PRO_value
                        max_PRO_value = PRO_value;
                        max_PRO_index = sub_count;
                    end
                end
            end

            tablas_optimas(record,1) = tablas(record,(max_PRO_index * 2) - 1);
            tablas_optimas(record,2) = tablas(record,max_PRO_index * 2);
        end
    end

    tablas_optimas(record + 1,1) = median(tablas_optimas(1:end-4,1));
    tablas_optimas(record + 1,2) = median(tablas_optimas(1:end-4,2));
    
    tablas_optimas(record + 2,1) = mad(tablas_optimas(1:end-4,1));
    tablas_optimas(record + 2,2) = mad(tablas_optimas(1:end-4,2));

    tablas_optimas(record + 3,1) = mean(tablas_optimas(1:end-4,1));
    tablas_optimas(record + 3,2) = mean(tablas_optimas(1:end-4,2));

    tablas_optimas(record + 4,1) = std(tablas_optimas(1:end-4,1));
    tablas_optimas(record + 4,2) = std(tablas_optimas(1:end-4,2));

    % En este punto ya tendria las tablas con los mejores valores obtenidos
    fname = strcat('Algoritmo_',algoritmos);

    col_names = {'TPR','PPV'};

    GTHTMLtable(fname,tablas_optimas(:,:)*100,'%1.3f%%', ...
        col_names,strcat('Recording_',resultados(final_count).file_names),'colormap',mapa_colores,'save');

    destino = strcat(final_res_directory,'Optimal_Results_',fname,'.html');
    movefile(strcat('TABLE_',fname,'.html'),destino);

    disp(strcat('Algoritmo:',algoritmos,' terminado'));
    disp(strcat('Salvado en:',destino));
    disp(newline);


    %% Seleccion en base a un criterio previo a obtener todos los resultados
    % Criterio tomado: Se tomo el lead con mayor cantidad de latidos detetctado

    tablas_C1 = zeros(numel(resultados(final_count).file_names) + 1,2);
    tablas_C1(end,:) = -1;

    for record = 1:numel(resultados(final_count).file_names) - 4
        max_beats_value = 0;
        max_beats_index = 0;

        for sub_count = 1:numel(resultados(final_count).lead_names)
            if max_beats_value < resultados(final_count).beats(sub_count,record)
                max_beats_value = resultados(final_count).beats(sub_count,record);
                max_beats_index = sub_count;
            end
        end

        tablas_C1(record,1) = resultados(final_count).TPR(max_beats_index,record);
        tablas_C1(record,2) = resultados(final_count).PPV(max_beats_index,record);
    end

    tablas_C1(record + 1,1) = median(tablas_C1(1:end-4,1));
    tablas_C1(record + 1,2) = median(tablas_C1(1:end-4,2));

    tablas_C1(record + 2,1) = mad(tablas_C1(1:end-4,1));
    tablas_C1(record + 2,2) = mad(tablas_C1(1:end-4,2));
    
    tablas_C1(record + 3,1) = mean(tablas_C1(1:end-4,1));
    tablas_C1(record + 3,2) = mean(tablas_C1(1:end-4,2));

    tablas_C1(record + 4,1) = std(tablas_C1(1:end-4,1));
    tablas_C1(record + 4,2) = std(tablas_C1(1:end-4,2));

    % En este punto ya tendria las tablas con los mejores valores obtenidos
    fname = strcat('Algoritmo_',algoritmos);

    col_names = {'TPR','PPV'};

    GTHTMLtable(fname,tablas_C1(:,:)*100,'%1.3f%%', ...
        col_names,strcat('Recording_',resultados(final_count).file_names),'colormap',mapa_colores,'save');

    destino = strcat(final_res_directory,'Results_MaxBeats_',fname,'.html');
    movefile(strcat('TABLE_',fname,'.html'),destino);

    disp(strcat('Algoritmo:',algoritmos,' terminado'));
    disp(strcat('Salvado en:',destino));
    disp(newline);

    % Criterio numero dos: inverso al anterior, tomar el lead con menor
    % cantidad de latidos detectados
    tablas_C2 = zeros(numel(resultados(final_count).file_names) + 1,2);
    tablas_C2(end,:) = -1;

    for record = 1:numel(resultados(final_count).file_names) - 4
        min_beats_value = inf;
        min_beats_index = 0;

        for sub_count = 1:numel(resultados(final_count).lead_names)
            if min_beats_value > resultados(final_count).beats(sub_count,record) && resultados(final_count).beats(sub_count,record) ~= 0
                min_beats_value = resultados(final_count).beats(sub_count,record);
                min_beats_index = sub_count;
            end
        end

        tablas_C2(record,1) = resultados(final_count).TPR(min_beats_index,record);
        tablas_C2(record,2) = resultados(final_count).PPV(min_beats_index,record);
    end

    tablas_C2(record + 1,1) = median(tablas_C2(1:end-4,1));
    tablas_C2(record + 1,2) = median(tablas_C2(1:end-4,2));
    
    tablas_C2(record + 2,1) = mad(tablas_C2(1:end-4,1));
    tablas_C2(record + 2,2) = mad(tablas_C2(1:end-4,2));

    tablas_C2(record + 3,1) = mean(tablas_C2(1:end-4,1));
    tablas_C2(record + 3,2) = mean(tablas_C2(1:end-4,2));

    tablas_C2(record + 4,1) = std(tablas_C2(1:end-4,1));
    tablas_C2(record + 4,2) = std(tablas_C2(1:end-4,2));

    % En este punto ya tendria las tablas con los mejores valores obtenidos
    fname = strcat('Algoritmo_',algoritmos);

    col_names = {'TPR','PPV'};

    GTHTMLtable(fname,tablas_C2(:,:)*100,'%1.3f%%', ...
        col_names,strcat('Recording_',resultados(final_count).file_names),'colormap',mapa_colores,'save');

    destino = strcat(final_res_directory,'Results_MinBeats_',fname,'.html');
    movefile(strcat('TABLE_',fname,'.html'),destino);

    disp(strcat('Algoritmo:',algoritmos,' terminado'));
    disp(strcat('Salvado en:',destino));
    disp(newline);

    % Criterio numero tres: MLII o el primero que aparezca
   tablas_C3 = zeros(numel(resultados(final_count).file_names) + 1,2);
    tablas_C3(end,:,:) = -1;

    for record = 1:numel(resultados(final_count).file_names) - 4
        str_idx = ismember(resultados(final_count).lead_names,{'_MLII','_II','_ML2'});
        rec_idx = resultados(final_count).TPR(:,record) ~= -1;
        rec_idx = rec_idx';
        true_idx = str_idx .* rec_idx;
        true_idx = find(true_idx);
        if ~isempty(true_idx)
            tablas_C3(record,1) = resultados(final_count).TPR(true_idx,record);
            tablas_C3(record,2) = resultados(final_count).PPV(true_idx,record);
        else
            flag = 1;
            sub_count = 1;
            while flag == 1
                if resultados(final_count).TPR(sub_count,record) ~= -1
                    flag = 0;
                else
                    sub_count = sub_count + 1;
                end
            end
            tablas_C3(record,1) = resultados(final_count).TPR(sub_count,record);
            tablas_C3(record,2) = resultados(final_count).PPV(sub_count,record);
        end
    end

    tablas_C3(record + 1,1) = median(tablas_C3(1:end-4,1));
    tablas_C3(record + 1,2) = median(tablas_C3(1:end-4,2));

    tablas_C3(record + 2,1) = mad(tablas_C3(1:end-4,1));
    tablas_C3(record + 2,2) = mad(tablas_C3(1:end-4,2));
    
    tablas_C3(record + 3,1) = mean(tablas_C3(1:end-4,1));
    tablas_C3(record + 3,2) = mean(tablas_C3(1:end-4,2));

    tablas_C3(record + 4,1) = std(tablas_C3(1:end-4,1));
    tablas_C3(record + 4,2) = std(tablas_C3(1:end-4,2));

    % En este punto ya tendria las tablas con los mejores valores obtenidos
    fname = strcat('Algoritmo_',algoritmos);

    col_names = {'TPR','PPV'};

    GTHTMLtable(fname,tablas_C3(:,:)*100,'%1.3f%%', ...
        col_names,strcat('Recording_',resultados(final_count).file_names),'colormap',mapa_colores,'save');

    destino = strcat(final_res_directory,'Results_MLIIorFirst_',fname,'.html');
    movefile(strcat('TABLE_',fname,'.html'),destino);

    disp(strcat('Algoritmo:',algoritmos,' terminado'));
    disp(strcat('Salvado en:',destino));
    disp(newline);
end