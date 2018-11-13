%% Prueba para el toolkit ECGkit
clear
clc

% Donde estan las muestras:
recFile = 'corpusN200';
recordingNamesFile = fopen(['/home/augusto/Escritorio/Beca/Algoritmos/', recFile, '.txt'],'r');
sourceDirectory = '/home/augusto/Escritorio/Beca/DataBases/';
resSourceDirectory = '/home/augusto/Escritorio/Beca/Resultados/';

if recordingNamesFile == -1
    disp('Error abriendo archivo identificador de las db');
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

% Algoritmos a usar:
% Se pueden agregar la cantidad de algoritmos que se desee
algoritmos = {'user:thip'};

        ECGw.user_string = 'AIP_det';

        % add your function pointer
        ECGw.ECGtaskHandle.function_pointer = @aip_detector;
        ECGw.ECGtaskHandle.concate_func_pointer = @aip_detector_concatenate;
aux_alg = {'thip'};

% Flag para identificar si ya hubo un procesamiento similar previamente
% hecho o no
flag_procesamiento = 1;
resultados = struct('file_names',[],'lead_names',[],'TPR',[],'PPV',[],'beats',[]);

if exist(strcat(resSourceDirectory,recFile,'_',aux_alg{1}), 'dir') == 0
    disp('Creating directory...')
    mkdir(strcat(resSourceDirectory,recFile,'_',aux_alg{1}));
    flag_procesamiento = 0;
else
    if exist(strcat(resSourceDirectory,recFile,'_',aux_alg{1},filesep,'Results.mat'), 'file') ~= 0
        % Esto quiere decir que ya habian resultados calculados, tomo
        % directamente el primer archivo que encuentre (deberia haber solo uno
        % por como tengo escrito el script)
        load(strcat(resSourceDirectory,recFile,'_',aux_alg{1},filesep,'Results.mat'),'resultados');
    else
        % No habia ningun archivo de resultados anteriores
        flag_procesamiento = 0;

        for count = 1:numel(archivos)
            flag_nombre = 0;
            ECGw = ECGwrapper('recording_name',[sourceDirectory archivos(count).name]);
            
            % Filtrado por si los leads se llaman iguales:
            flag_name = 0;
            countb = 1;
            if numel(ECGw.ECG_header.desc(:,1)) > 1
                while countb < numel(ECGw.ECG_header.desc(:,1)) && flag_name == 0
                    if strcmp(ECGw.ECG_header.desc(countb,:),ECGw.ECG_header.desc(countb+1,:))
                        % Salgo del loop
                        flag_name = 1;
                        % "Corrijo" el header
                        aux = repmat(' ',size(ECGw.ECG_header.desc) + [0 1]);
                        for sub_count = 1:numel(ECGw.ECG_header.desc(:,1))
                            aux(sub_count,:) = [ECGw.ECG_header.desc(sub_count,:) int2str(sub_count)];
                        end
                        ECGw.ECG_header.desc = aux;
                    end
                    countb = countb + 1;
                end
            end

            % Borrado de los caracteres que no son ni numeros ni letras
            index = ismember(ECGw.ECG_header.desc(1,:),['A':'Z' 'a':'z' '0':'9']);
            index = find(index);

            if (numel(resultados.lead_names) == 0)
               resultados.lead_names{1} = ECGw.ECG_header.desc(1,index);
            end

            for file_count = 1:numel(resultados.lead_names)
                for lead_count = 1:numel(ECGw.ECG_header.desc(:,1))
                    index = ismember(ECGw.ECG_header.desc(lead_count,:),['A':'Z' 'a':'z' '0':'9']);
                    index = find(index);

                    if (isempty(find(strcmp(resultados.lead_names,ECGw.ECG_header.desc(lead_count,index)),1)))
                        % Guardar el nuevo nombre del lead encontrado
                        resultados.lead_names{numel(resultados.lead_names) + 1} = ECGw.ECG_header.desc(lead_count,index);
                    end
                end
            end
        end
    end
end

tiempo_total = 0;

if flag_procesamiento == 0
    % Ordenamiento por orden alfabetico de los nombres de los leads:
    resultados(1).lead_names = sort(resultados.lead_names);
    resultados(1:numel(algoritmos)) = resultados(1);
    
    for algorithm_count = 1:numel(algoritmos)
        tic;
        % Parametros internos
        total_beats = 0;
        
        % True positive rate (sensibilidad):
        TPR = 0;

        % Positive predictive value (presicion):
        PPV = 0;
        
        resultados(algorithm_count).TPR(1:numel(resultados(algorithm_count).lead_names),1:numel(archivos)) = -1;
        resultados(algorithm_count).PPV(1:numel(resultados(algorithm_count).lead_names),1:numel(archivos)) = -1;

        for file_count = 1:numel(archivos)
            ECGw = ECGwrapper();
            resultados(algorithm_count).file_names{numel(resultados(algorithm_count).file_names) + 1} = archivos(file_count).name(1:end);
            ECGw.recording_name = [sourceDirectory,archivos(file_count).name];

            % Asigno el algoritmo de deteccion de QRS a utilizar:
            ECGw.ECGtaskHandle= 'QRS_detection';
            payload = [];

            payload.DPI_window_size = 1800e-3;
            payload.refr_period = 250e-3;
            payload.max_lenght_QRS = 285e-3;
            payload.RR_avg_seed = 1;
            ECGw.ECGtaskHandle.detectors = {algoritmos{algorithm_count}};
            if (strcmp(algoritmos{algorithm_count},'user:thi') || strcmp(algoritmos{algorithm_count},'user:thip') ...
                    || strcmp(algoritmos{algorithm_count},'user:thir'))
                ECGw.ECGtaskHandle.payload = payload;
            end
            ECGw.ECGtaskHandle.CalculatePerformance = true;
            ECGt_QRSd.bRecalculateNewDetections = true;

            ECGw.Run();

            % Tomo el resultado de correr el detector:
            file = ECGw.GetCahchedFileName('QRS_detection');

            res = load(cell2mat(file));
            delete(file{1}); % Borro archivo cacheado

            % Busco en que lugar tengo que poner cada uno de los resultados
            % obtenidos por el detector:
            % Filtrado por si los leads se llaman iguales:
            flag_name = 0;
            count = 1;
            if numel(ECGw.ECG_header.desc(:,1)) > 1
                while count < numel(ECGw.ECG_header.desc(:,1)) && flag_name == 0
                    if strcmp(ECGw.ECG_header.desc(count,:),ECGw.ECG_header.desc(count+1,:))
                        % Salgo del loop
                        flag_name = 1;
                        % "Corrijo" el header
                        aux = repmat(' ',size(ECGw.ECG_header.desc) + [0 1]);
                        for sub_count = 1:numel(ECGw.ECG_header.desc(:,1))
                            aux(sub_count,:) = [ECGw.ECG_header.desc(sub_count,:) int2str(sub_count)];
                        end
                        ECGw.ECG_header.desc = aux;
                    end
                    count = count + 1;
                end
            end
            
            for count = 1:ECGw.ECG_header.nsig
                index = ismember(ECGw.ECG_header.desc(count,:),['A':'Z' 'a':'z' '0':'9']);
                index = find(index);
                
                str_idx = find(strcmp(resultados(algorithm_count).lead_names,ECGw.ECG_header.desc(count,index)));
                
                % Obtengo resultados:
                % TPR = TP/(TP+FN)
                % PPV = TP/(TP+FP)
                TPR = res.series_performance.conf_mat(1,1,count) / ...
                    (res.series_performance.conf_mat(1,1,count) + res.series_performance.conf_mat(1,2,count));
                
                PPV = res.series_performance.conf_mat(1,1,count) / ...
                    (res.series_performance.conf_mat(1,1,count) + res.series_performance.conf_mat(2,1,count));
                
                resultados(algorithm_count).TPR(str_idx,file_count) = TPR;
                resultados(algorithm_count).PPV(str_idx,file_count) = PPV;
                resultados(algorithm_count).beats(str_idx,file_count) = sum(res.series_performance.conf_mat(:,1,count));
            end
        end
    end
    
    tiempo_total = toc;
else
    disp('Ya se realizo este procesamiento');
end

% Guardo los resultados para no tener que repetir todo el proceso:
save(strcat([resSourceDirectory,recFile,'_',aux_alg{1}],[filesep 'Results.mat']),'resultados');

disp('Resultado guardado en:');
disp(strcat([resSourceDirectory,recFile,'_',aux_alg{1}],[filesep 'Results.mat']));
%% Exporto los resultados a tablas:
disp('Escribiendo y exportando tablas...');
disp(newline);

promedios = [];
for count = 1:numel(algoritmos)
    % Elimino el 'user:' del nombre del algoritmo en caso de haberlo
    algoritmos{count} = strrep(algoritmos{count},'user:','');
    
    sub_count = 1;
    sub_count2 = 1;
    while sub_count < numel(resultados(count).lead_names)*2
        tablas(:,sub_count,count) = resultados(count).TPR(sub_count2,:);
        sub_count = sub_count + 1;
        tablas(:,sub_count,count) = resultados(count).PPV(sub_count2,:);
        sub_count = sub_count + 1;
        sub_count2 = sub_count2 + 1;
    end
    
    for sub_count = 1:numel(tablas(1,:,count))
        index = find(tablas(:,sub_count,count) > -1);
        promedios(1,sub_count,count) = median(tablas(index,sub_count,count));
        promedios(2,sub_count,count) = mean(tablas(index,sub_count,count));
        promedios(3,sub_count,count) = std(tablas(index,sub_count,count));
        promedios(4,sub_count,count) = -1;
    end
end

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
            
for count = 1:numel(algoritmos)
    fname = strcat('Algoritmo_',algoritmos{count});
    resultados(count).file_names{numel(resultados(count).file_names) + 1} = 'median';
    resultados(count).file_names{numel(resultados(count).file_names) + 1} = 'mean';
    resultados(count).file_names{numel(resultados(count).file_names) + 1} = 'std_dev';
    
    col_names = [];
    for sub_count = 1:numel(resultados(count).lead_names)
        col_names = [col_names,strcat('TPR_Lead_',resultados(count).lead_names(sub_count)), ...
                        strcat('PPV_Lead_',resultados(count).lead_names(sub_count))];
    end
    
    GTHTMLtable(fname,[tablas(:,:,count)*100 ; promedios(:,:,count)*100],'%1.3f%%', ...
        col_names,strcat('Recording_',resultados(count).file_names),'colormap',mapa_colores,'save');
    
    destino = [resSourceDirectory,recFile,'_',algoritmos{count},filesep,'Results_',fname,'.html'];
    movefile(strcat('TABLE_',fname,'.html'),destino);
    
    disp(strcat('Algoritmo:',algoritmos{count},' terminado'));
    disp(strcat('Salvado en:',destino));
    disp(newline);
end

clear ans;
disp(strcat('Procesamiento y salvado de archivos terminado.' ));

%% Seleccion de los mejores resultados
% Criterio de seleccion para los resultados optimos:
% 1) Si ambos parametros (PPV y TPR) son mayores para un lead que para
% cualquier otro, se lo toma como mejor.
% 2) En el caso que no suceda lo anterior, se elije el LEAD_MLII o el
% primero que encuentre

tablas_optimas = zeros(numel(resultados(1).file_names) + 1,2,numel(algoritmos));
tablas_optimas(end,:,:) = -1;

for count = 1:numel(algoritmos)
    for record = 1:numel(resultados(count).file_names) - 3
        max_TPR_value = 0;
        max_TPR_index = 0;
        max_PPV_value = 0;
        max_PPV_index = 0;
        max_PRO_value = 0;
        max_PRO_index = 0;
        
        for sub_count = 1:numel(resultados(count).lead_names)
            if (tablas(record,(sub_count * 2) - 1,count) > max_TPR_value)
                max_TPR_value = tablas(record,(sub_count * 2) - 1,count);
                max_TPR_index = (sub_count * 2) - 1;
            end
            
            if (tablas(record,sub_count * 2,count) > max_PPV_value)
                max_PPV_value = tablas(record,sub_count * 2,count);
                max_PPV_index = (sub_count * 2) - 1;
            end
        end
        
        if (max_TPR_index == max_PPV_index)
            % Este caso es cuando ambos indices son mayores en algun lead
            % en particular
            tablas_optimas(record,1,count) = max_TPR_value;
            tablas_optimas(record,2,count) = max_PPV_value;
        else
            % Si el indice donde esta el mayor TPR y PPV es distinto, elijo
            % el que mayor promedio tenga entre los dos parametros
            sub_count = 1;
            
            for sub_count = 1:numel(resultados(count).lead_names)
                if (tablas(record,(sub_count * 2) - 1,count) ~= -1)
                    PRO_value = (tablas(record,(sub_count * 2) - 1,count) + tablas(record,sub_count * 2,count))/2;
                    if PRO_value > max_PRO_value
                        max_PRO_value = PRO_value;
                        max_PRO_index = sub_count;
                    end
                end
            end
            
            tablas_optimas(record,1,count) = tablas(record,(max_PRO_index * 2) - 1,count);
            tablas_optimas(record,2,count) = tablas(record,max_PRO_index * 2,count);
        end
    end
    
    tablas_optimas(record + 1,1,count) = median(tablas_optimas(1:end-4,1,count));
    tablas_optimas(record + 1,2,count) = median(tablas_optimas(1:end-4,2,count));
    
    tablas_optimas(record + 2,1,count) = mean(tablas_optimas(1:end-4,1,count));
    tablas_optimas(record + 2,2,count) = mean(tablas_optimas(1:end-4,2,count));
    
    tablas_optimas(record + 3,1,count) = std(tablas_optimas(1:end-4,1,count));
    tablas_optimas(record + 3,2,count) = std(tablas_optimas(1:end-4,2,count));
end

% En este punto ya tendria las tablas con los mejores valores obtenidos
for count = 1:numel(algoritmos)
    fname = strcat('Algoritmo_',algoritmos{count});
    
    col_names = {'TPR','PPV'};
    
    GTHTMLtable(fname,tablas_optimas(:,:,count)*100,'%1.3f%%', ...
        col_names,strcat('Recording_',resultados(count).file_names),'colormap',mapa_colores,'save');
    
    destino = strcat(resSourceDirectory,recFile,'_',algoritmos{count},filesep,'Optimal_Results_',fname,'.html');
    movefile(strcat('TABLE_',fname,'.html'),destino);
    
    disp(strcat('Algoritmo:',algoritmos{count},' terminado'));
    disp(strcat('Salvado en:',destino));
    disp(newline);
end

%% Seleccion en base a un criterio previo a obtener todos los resultados
% Criterio tomado: Se tomo el lead con mayor cantidad de latidos detetctado

tablas_C1 = zeros(numel(resultados(1).file_names) + 1,2,numel(algoritmos));
tablas_C1(end,:,:) = -1;

for count = 1:numel(algoritmos)
    for record = 1:numel(resultados(count).file_names) - 3
        max_beats_value = 0;
        max_beats_index = 0;
        
        for sub_count = 1:numel(resultados(count).lead_names)
            if max_beats_value < resultados(count).beats(sub_count,record)
                max_beats_value = resultados(count).beats(sub_count,record);
                max_beats_index = sub_count;
            end
        end
        
        tablas_C1(record,1,count) = resultados(count).TPR(max_beats_index,record);
        tablas_C1(record,2,count) = resultados(count).PPV(max_beats_index,record);
    end
    
    tablas_C1(record + 1,1,count) = median(tablas_C1(1:end-4,1,count));
    tablas_C1(record + 1,2,count) = median(tablas_C1(1:end-4,2,count));
    
    tablas_C1(record + 2,1,count) = mean(tablas_C1(1:end-4,1,count));
    tablas_C1(record + 2,2,count) = mean(tablas_C1(1:end-4,2,count));
    
    tablas_C1(record + 3,1,count) = std(tablas_C1(1:end-4,1,count));
    tablas_C1(record + 3,2,count) = std(tablas_C1(1:end-4,2,count));
end

% En este punto ya tendria las tablas con los mejores valores obtenidos
for count = 1:numel(algoritmos)
    fname = strcat('Algoritmo_',algoritmos{count});
    
    col_names = {'TPR','PPV'};
    
    GTHTMLtable(fname,tablas_C1(:,:,count)*100,'%1.3f%%', ...
        col_names,strcat('Recording_',resultados(count).file_names),'colormap',mapa_colores,'save');
    
    destino = strcat(resSourceDirectory,recFile,'_',algoritmos{count},filesep,'Results_MaxBeats_',fname,'.html');
    movefile(strcat('TABLE_',fname,'.html'),destino);
    
    disp(strcat('Algoritmo:',algoritmos{count},' terminado'));
    disp(strcat('Salvado en:',destino));
    disp(newline);
end

% Criterio numero dos: inverso al anterior, tomar el lead con menor
% cantidad de latidos detectados
tablas_C2 = zeros(numel(resultados(1).file_names) + 1,2,numel(algoritmos));
tablas_C2(end,:,:) = -1;

for count = 1:numel(algoritmos)
    for record = 1:numel(resultados(count).file_names) - 3
        min_beats_value = inf;
        min_beats_index = 0;
        
        for sub_count = 1:numel(resultados(count).lead_names)
            if min_beats_value > resultados(count).beats(sub_count,record) && resultados(count).beats(sub_count,record) ~= 0
                min_beats_value = resultados(count).beats(sub_count,record);
                min_beats_index = sub_count;
            end
        end
        
        tablas_C2(record,1,count) = resultados(count).TPR(min_beats_index,record);
        tablas_C2(record,2,count) = resultados(count).PPV(min_beats_index,record);
    end
    
    tablas_C2(record + 1,1,count) = median(tablas_C2(1:end-4,1,count));
    tablas_C2(record + 1,2,count) = median(tablas_C2(1:end-4,2,count));
    
    tablas_C2(record + 2,1,count) = mean(tablas_C2(1:end-4,1,count));
    tablas_C2(record + 2,2,count) = mean(tablas_C2(1:end-4,2,count));
    
    tablas_C2(record + 3,1,count) = std(tablas_C2(1:end-4,1,count));
    tablas_C2(record + 3,2,count) = std(tablas_C2(1:end-4,2,count));
end

% En este punto ya tendria las tablas co3 los mejores valores obtenidos
for count = 1:numel(algoritmos)
    fname = strcat('Algoritmo_',algoritmos{count});
    
    col_names = {'TPR','PPV'};
    
    GTHTMLtable(fname,tablas_C2(:,:,count)*100,'%1.3f%%', ...
        col_names,strcat('Recording_',resultados(count).file_names),'colormap',mapa_colores,'save');
    
    destino = strcat(resSourceDirectory,recFile,'_',algoritmos{count},filesep,'Results_MinBeats_',fname,'.html');
    movefile(strcat('TABLE_',fname,'.html'),destino);
    
    disp(strcat('Algoritmo:',algoritmos{count},' terminado'));
    disp(strcat('Salvado en:',destino));
    disp(newline);
end

% Criterio numero tres: MLII o el primero que aparezca
tablas_C3 = zeros(numel(resultados(1).file_names) + 1,2,numel(algoritmos));
tablas_C3(end,:,:) = -1;

for count = 1:numel(algoritmos)
    str_idx = find(strcmp(resultados(count).lead_names,'MLII'));
    
    for record = 1:numel(resultados(count).file_names) - 3
        if resultados(count).TPR(str_idx,record) ~= -1
            tablas_C3(record,1,count) = resultados(count).TPR(str_idx,record);
            tablas_C3(record,2,count) = resultados(count).PPV(str_idx,record);
        else
            flag = 1;
            sub_count = 1;
            while flag == 1
                if resultados(count).TPR(sub_count,record) ~= -1
                    flag = 0;
                else
                    sub_count = sub_count + 1;
                end
            end
            tablas_C3(record,1,count) = resultados(count).TPR(sub_count,record);
            tablas_C3(record,2,count) = resultados(count).PPV(sub_count,record);
        end
    end
    
    tablas_C3(record + 1,1,count) = median(tablas_C3(1:end-4,1,count));
    tablas_C3(record + 1,2,count) = median(tablas_C3(1:end-4,2,count));
    
    tablas_C3(record + 2,1,count) = mean(tablas_C3(1:end-4,1,count));
    tablas_C3(record + 2,2,count) = mean(tablas_C3(1:end-4,2,count));
    
    tablas_C3(record + 3,1,count) = std(tablas_C3(1:end-4,1,count));
    tablas_C3(record + 3,2,count) = std(tablas_C3(1:end-4,2,count));
end

% En este punto ya tendria las tablas con los mejores valores obtenidos
for count = 1:numel(algoritmos)
    fname = strcat('Algoritmo_',algoritmos{count});
    
    col_names = {'TPR','PPV'};
    
    GTHTMLtable(fname,tablas_C3(:,:,count)*100,'%1.3f%%', ...
        col_names,strcat('Recording_',resultados(count).file_names),'colormap',mapa_colores,'save');
    
    destino = strcat(resSourceDirectory,recFile,'_',algoritmos{count},filesep,'Results_MLIIorFirst_',fname,'.html');
    movefile(strcat('TABLE_',fname,'.html'),destino);
    
    disp(strcat('Algoritmo:',algoritmos{count},' terminado'));
    disp(strcat('Salvado en:',destino));
    disp(newline);
end