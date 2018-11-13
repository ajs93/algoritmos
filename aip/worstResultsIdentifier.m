%% Descripcion
% Script para detectar mediante un indice de error, los resultados que son
% peores que el umbral establecido en un set de resultados.
%% Definicion de parametros de entrada/salida
clear;
clc;

% Archivo a analizar
results_file = '/home/augusto/Escritorio/Beca/Resultados/corpusN200_aip/Results.mat';

% Umbral de separacion, basado en el parametro TE = (FP + FN) / (TP + FN)
% (Tasa de error, ponele...)
TE_threshold = 0.1;

% Directorio de salida
output_directory = '/home/augusto/Escritorio/Beca';

if output_directory(end) ~= filesep
    output_directory(end + 1) = filesep;
end

%% Procesamiento

% Leo el archivo seleccionado
load('/home/augusto/Escritorio/Beca/Resultados/corpusN200_aip/Results.mat');

% Seleccion de detecciones para quedarse
tabla_MLII_or_first(numel(resultados), numel(resultados(1).file_names)) = struct('file_names',[],'TP',[],'FP',[],'FN',[],'TN',[]);

for final_count = 1:numel(resultados)
    for record = 1:numel(resultados(final_count).file_names)
        tabla_MLII_or_first(final_count,record).file_names = resultados(final_count).file_names{record};
        
        str_idx = ismember(resultados(final_count).lead_names,{'_MLII','_II','_ML2'});
        rec_idx = resultados(final_count).TPR(:,record) ~= -1;
        rec_idx = rec_idx';
        true_idx = str_idx .* rec_idx;
        true_idx = find(true_idx);
        if ~isempty(true_idx)
            tabla_MLII_or_first(final_count,record).TP = resultados(final_count).TP(true_idx,record);
            tabla_MLII_or_first(final_count,record).FP = resultados(final_count).FP(true_idx,record);
            tabla_MLII_or_first(final_count,record).TN = resultados(final_count).TN(true_idx,record);
            tabla_MLII_or_first(final_count,record).FN = resultados(final_count).FN(true_idx,record);
        else
            flag = 1;
            sub_count = 1;
            while flag == 1
                if (resultados(final_count).TPR(sub_count,record) ~= -1) && (contains(resultados(final_count).lead_names(sub_count),'_RESP') ~= 1)
                    flag = 0;
                else
                    sub_count = sub_count + 1;
                end
            end
            
            tabla_MLII_or_first(final_count,record).TP = resultados(final_count).TP(sub_count,record);
            tabla_MLII_or_first(final_count,record).FP = resultados(final_count).FP(sub_count,record);
            tabla_MLII_or_first(final_count,record).TN = resultados(final_count).TN(sub_count,record);
            tabla_MLII_or_first(final_count,record).FN = resultados(final_count).FN(sub_count,record);
        end
    end
end

% Archivo/s de salida
output_files = cell(numel(resultados),1);

for count = 1:numel(output_files)
    % Generacion de la ruta completa
    output_files{count} = strcat(output_directory,'Recordings_to_help_',resultados(count).pattern_name,'.txt');
end

% Marcador de los que superan el umbral indicado
worst_marker = zeros(numel(tabla_MLII_or_first(:,1)),numel(tabla_MLII_or_first(1,:)));

% Por cada registro analizo el parametro TE y marco los que superan el
% umbral indicado
TE = zeros(numel(tabla_MLII_or_first(:,1)),numel(tabla_MLII_or_first(1,:)));

for final_count = 1:numel(tabla_MLII_or_first(:,1))
    for record = 1:numel(tabla_MLII_or_first(1,:))
        TE(final_count,record) = (tabla_MLII_or_first(final_count,record).FP + tabla_MLII_or_first(final_count,record).FN) / ...
                                    (tabla_MLII_or_first(final_count,record).TP + tabla_MLII_or_first(final_count,record).FN);
        
        if(TE(final_count,record) > TE_threshold)
            worst_marker(final_count,record) = 1;
        end
    end
end

% Creacion del/de los archivos de salida con el listado de todos los
% registros que superaron el umbral indicado
for final_count = 1:numel(tabla_MLII_or_first(:,1))
    fileID = fopen(output_files{final_count},'w');
    
    for record = 1:numel(tabla_MLII_or_first(final_count,:))
        if(worst_marker(final_count,record) == 1)
            fprintf(fileID,strcat(tabla_MLII_or_first(final_count,record).file_names,'\n'));
        end
    end
end