%% Facilidad para exportar las tablas de los resultados en formato HTML

function export_tables(results, final_res_directory)
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

    for final_count = 1:numel(results)
        promedios = [];
        
        sub_count = 1;
        for lead_number = 1:numel(results(final_count).lead_names)
            tablas(:,sub_count) = results(final_count).TPR(lead_number,:);
            sub_count = sub_count + 1;
            
            tablas(:,sub_count) = results(final_count).PPV(lead_number,:);
            sub_count = sub_count + 1;
            
            tablas(:,sub_count) = results(final_count).F1(lead_number,:);
            sub_count = sub_count + 1;
        end


        for sub_count = 1:numel(tablas(1,:))
            index = find(tablas(:,sub_count) > -1);
            promedios(1,sub_count) = median(tablas(index,sub_count));
            promedios(2,sub_count) = mad(tablas(index,sub_count));
            promedios(3,sub_count) = mean(tablas(index,sub_count));
            promedios(4,sub_count) = std(tablas(index,sub_count));
            promedios(5,sub_count) = -1;
        end

        fname = strcat('Algoritmo_',results(final_count).pattern_name);
        results(final_count).file_names{end + 1} = 'median';
        results(final_count).file_names{end + 1} = 'mad';
        results(final_count).file_names{end + 1} = 'mean';
        results(final_count).file_names{end + 1} = 'std_dev';

        col_names = [];
        for sub_count = 1:numel(results(final_count).lead_names)
            col_names = [col_names,strcat('TPR_Lead_',results(final_count).lead_names(sub_count)), ...
                            strcat('PPV_Lead_',results(final_count).lead_names(sub_count)), ...
                            strcat('F1_Lead_',results(final_count).lead_names(sub_count))];
        end

        GTHTMLtable(fname,[tablas*100 ; promedios*100],'%1.3f%%', ...
            col_names,strcat('Recording_',results(final_count).file_names),'colormap',mapa_colores,'save');

        destino = [final_res_directory,'Results_',fname,'.html'];
        movefile(strcat('TABLE_',fname,'.html'),destino);
        
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

        tablas_optimas = zeros(numel(results(final_count).file_names) + 1,3);
        tablas_optimas(end,:) = -1;

        % Correccion de los lead_names
        results(final_count).lead_names = strrep(results(final_count).lead_names,results(final_count).pattern_name,'');
        for record = 1:numel(results(final_count).file_names) - 4
            max_TPR_value = 0;
            max_TPR_index = 0;
            max_PPV_value = 0;
            max_PPV_index = 0;
            max_PRO_value = 0;
            max_PRO_index = 0;

            for sub_count = 1:numel(results(final_count).lead_names)
                if (tablas(record,(sub_count * 3) - 2) > max_TPR_value)
                    max_TPR_value = tablas(record,(sub_count * 3) - 2);
                    max_TPR_index = (sub_count * 3) - 2;
                end

                if (tablas(record,(sub_count * 3) - 1) > max_PPV_value)
                    max_PPV_value = tablas(record,(sub_count * 3) - 1);
                    max_PPV_index = (sub_count * 3) - 1;
                end
            end

            if (max_TPR_index == max_PPV_index)
                % Este caso es cuando ambos indices son mayores en algun lead
                % en particular
                tablas_optimas(record,1) = max_TPR_value;
                tablas_optimas(record,2) = max_PPV_value;
                tablas_optimas(record,3) = tablas(record,max_TPR_index + 2);
            else
                % Si el indice donde esta el mayor TPR y PPV es distinto, elijo
                % el que mayor promedio tenga entre los dos parametros
                for sub_count = 1:numel(results(final_count).lead_names)
                    if (tablas(record,(sub_count * 3) - 2) ~= -1)
                        PRO_value = (tablas(record,(sub_count * 3) - 2) + tablas(record,(sub_count * 3) - 2))/2;
                        if PRO_value > max_PRO_value
                            max_PRO_value = PRO_value;
                            max_PRO_index = sub_count;
                        end
                    end
                end

                tablas_optimas(record,1) = tablas(record,(max_PRO_index * 3) - 2); % TPR
                tablas_optimas(record,2) = tablas(record,(max_PRO_index * 3) - 1); % PPV
                tablas_optimas(record,3) = tablas(record,max_PRO_index * 3); % F1
            end
        end

        tablas_optimas(record + 1,1) = median(tablas_optimas(1:end-4,1));
        tablas_optimas(record + 1,2) = median(tablas_optimas(1:end-4,2));
        tablas_optimas(record + 1,3) = median(tablas_optimas(1:end-4,3));

        tablas_optimas(record + 2,1) = mad(tablas_optimas(1:end-4,1));
        tablas_optimas(record + 2,2) = mad(tablas_optimas(1:end-4,2));
        tablas_optimas(record + 2,3) = mad(tablas_optimas(1:end-4,3));

        tablas_optimas(record + 3,1) = mean(tablas_optimas(1:end-4,1));
        tablas_optimas(record + 3,2) = mean(tablas_optimas(1:end-4,2));
        tablas_optimas(record + 3,3) = mean(tablas_optimas(1:end-4,3));

        tablas_optimas(record + 4,1) = std(tablas_optimas(1:end-4,1));
        tablas_optimas(record + 4,2) = std(tablas_optimas(1:end-4,2));
        tablas_optimas(record + 4,3) = std(tablas_optimas(1:end-4,3));

        % En este punto ya tendria las tablas con los mejores valores obtenidos
        fname = strcat('Algoritmo_',results(final_count).pattern_name);

        col_names = {'TPR','PPV', 'F1'};

        GTHTMLtable(fname,tablas_optimas(:,:)*100,'%1.3f%%', ...
            col_names,strcat('Recording_',results(final_count).file_names),'colormap',mapa_colores,'save');

        destino = strcat(final_res_directory,'Optimal_Results_',fname,'.html');
        movefile(strcat('TABLE_',fname,'.html'),destino);

        disp(strcat('Salvado en:',destino));
        disp(newline);


        %% Seleccion en base a un criterio previo a obtener todos los resultados
        % Criterio tomado: Se tomo el lead con mayor cantidad de latidos detetctado

        tablas_C1 = zeros(numel(results(final_count).file_names) + 1,3);
        tablas_C1(end,:) = -1;

        for record = 1:numel(results(final_count).file_names) - 4
            max_beats_value = -1;
            max_beats_index = 1;

            for sub_count = 1:numel(results(final_count).lead_names)
                if max_beats_value < results(final_count).beats(sub_count,record)
                    max_beats_value = results(final_count).beats(sub_count,record);
                    max_beats_index = sub_count;
                end
            end

            tablas_C1(record,1) = results(final_count).TPR(max_beats_index,record);
            tablas_C1(record,2) = results(final_count).PPV(max_beats_index,record);
            tablas_C1(record,3) = results(final_count).F1(max_beats_index,record);
        end

        tablas_C1(record + 1,1) = median(tablas_C1(1:end-4,1));
        tablas_C1(record + 1,2) = median(tablas_C1(1:end-4,2));
        tablas_C1(record + 1,3) = median(tablas_C1(1:end-4,3));

        tablas_C1(record + 2,1) = mad(tablas_C1(1:end-4,1));
        tablas_C1(record + 2,2) = mad(tablas_C1(1:end-4,2));
        tablas_C1(record + 2,3) = mad(tablas_C1(1:end-4,3));

        tablas_C1(record + 3,1) = mean(tablas_C1(1:end-4,1));
        tablas_C1(record + 3,2) = mean(tablas_C1(1:end-4,2));
        tablas_C1(record + 3,3) = mean(tablas_C1(1:end-4,3));

        tablas_C1(record + 4,1) = std(tablas_C1(1:end-4,1));
        tablas_C1(record + 4,2) = std(tablas_C1(1:end-4,2));
        tablas_C1(record + 4,3) = std(tablas_C1(1:end-4,3));

        % En este punto ya tendria las tablas con los mejores valores obtenidos
        fname = strcat('Algoritmo_',results(final_count).pattern_name);

        col_names = {'TPR','PPV', 'F1'};

        GTHTMLtable(fname,tablas_C1(:,:)*100,'%1.3f%%', ...
            col_names,strcat('Recording_',results(final_count).file_names),'colormap',mapa_colores,'save');

        destino = strcat(final_res_directory,'Results_MaxBeats_',fname,'.html');
        movefile(strcat('TABLE_',fname,'.html'),destino);

        disp(strcat('Salvado en:',destino));
        disp(newline);

        % Criterio numero dos: inverso al anterior, tomar el lead con menor
        % cantidad de latidos detectados
        tablas_C2 = zeros(numel(results(final_count).file_names) + 1,3);
        tablas_C2(end,:) = -1;

        for record = 1:numel(results(final_count).file_names) - 4
            min_beats_value = 100e6;
            min_beats_index = 1;

            for sub_count = 1:numel(results(final_count).lead_names)
                if min_beats_value > results(final_count).beats(sub_count,record) && results(final_count).beats(sub_count,record) ~= 0
                    min_beats_value = results(final_count).beats(sub_count,record);
                    min_beats_index = sub_count;
                end
            end

            tablas_C2(record,1) = results(final_count).TPR(min_beats_index,record);
            tablas_C2(record,2) = results(final_count).PPV(min_beats_index,record);
            tablas_C2(record,3) = results(final_count).F1(min_beats_index,record);
        end

        tablas_C2(record + 1,1) = median(tablas_C2(1:end-4,1));
        tablas_C2(record + 1,2) = median(tablas_C2(1:end-4,2));
        tablas_C2(record + 1,3) = median(tablas_C2(1:end-4,3));

        tablas_C2(record + 2,1) = mad(tablas_C2(1:end-4,1));
        tablas_C2(record + 2,2) = mad(tablas_C2(1:end-4,2));
        tablas_C2(record + 2,3) = mad(tablas_C2(1:end-4,3));

        tablas_C2(record + 3,1) = mean(tablas_C2(1:end-4,1));
        tablas_C2(record + 3,2) = mean(tablas_C2(1:end-4,2));
        tablas_C2(record + 3,3) = mean(tablas_C2(1:end-4,3));

        tablas_C2(record + 4,1) = std(tablas_C2(1:end-4,1));
        tablas_C2(record + 4,2) = std(tablas_C2(1:end-4,2));
        tablas_C2(record + 4,3) = std(tablas_C2(1:end-4,3));

        % En este punto ya tendria las tablas con los mejores valores obtenidos
        fname = strcat('Algoritmo_',results(final_count).pattern_name);

        col_names = {'TPR','PPV','F1'};

        GTHTMLtable(fname,tablas_C2(:,:)*100,'%1.3f%%', ...
            col_names,strcat('Recording_',results(final_count).file_names),'colormap',mapa_colores,'save');

        destino = strcat(final_res_directory,'Results_MinBeats_',fname,'.html');
        movefile(strcat('TABLE_',fname,'.html'),destino);

        disp(strcat('Salvado en:',destino));
        disp(newline);

        % Criterio numero tres: MLII o el primero que aparezca
        tablas_C3 = zeros(numel(results(final_count).file_names) + 1,3);
        tablas_C3(end,:,:) = -1;

        for record = 1:numel(results(final_count).file_names) - 4
            str_idx = ismember(results(final_count).lead_names,{'_MLII','_II','_ML2'});
            rec_idx = results(final_count).TPR(:,record) ~= -1;
            rec_idx = rec_idx';
            true_idx = str_idx .* rec_idx;
            true_idx = find(true_idx);
            if ~isempty(true_idx)
                tablas_C3(record,1) = results(final_count).TPR(true_idx,record);
                tablas_C3(record,2) = results(final_count).PPV(true_idx,record);
                tablas_C3(record,3) = results(final_count).F1(true_idx,record);
            else
                flag = 1;
                sub_count = 1;
                while flag == 1
                    if (results(final_count).TPR(sub_count,record) ~= -1) && (contains(results(final_count).lead_names(sub_count),'_RESP') ~= 1)
                        flag = 0;
                    else
                        sub_count = sub_count + 1;
                    end
                end
                tablas_C3(record,1) = results(final_count).TPR(sub_count,record);
                tablas_C3(record,2) = results(final_count).PPV(sub_count,record);
                tablas_C3(record,3) = results(final_count).F1(sub_count,record);
            end
        end

        tablas_C3(record + 1,1) = median(tablas_C3(1:end-4,1));
        tablas_C3(record + 1,2) = median(tablas_C3(1:end-4,2));
        tablas_C3(record + 1,3) = median(tablas_C3(1:end-4,3));

        tablas_C3(record + 2,1) = mad(tablas_C3(1:end-4,1));
        tablas_C3(record + 2,2) = mad(tablas_C3(1:end-4,2));
        tablas_C3(record + 2,3) = mad(tablas_C3(1:end-4,3));

        tablas_C3(record + 3,1) = mean(tablas_C3(1:end-4,1));
        tablas_C3(record + 3,2) = mean(tablas_C3(1:end-4,2));
        tablas_C3(record + 3,3) = mean(tablas_C3(1:end-4,3));

        tablas_C3(record + 4,1) = std(tablas_C3(1:end-4,1));
        tablas_C3(record + 4,2) = std(tablas_C3(1:end-4,2));
        tablas_C3(record + 4,3) = std(tablas_C3(1:end-4,3));

        % En este punto ya tendria las tablas con los mejores valores obtenidos
        fname = strcat('Algoritmo_',results(final_count).pattern_name);

        col_names = {'TPR','PPV','F1'};

        GTHTMLtable(fname,tablas_C3(:,:)*100,'%1.3f%%', ...
            col_names,strcat('Recording_',results(final_count).file_names),'colormap',mapa_colores,'save');

        destino = strcat(final_res_directory,'Results_MLIIorFirst_',fname,'.html');
        movefile(strcat('TABLE_',fname,'.html'),destino);
    end
end