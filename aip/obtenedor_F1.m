% Correccion de los lead names
results = resultados;

S_MLII = zeros(numel(results.file_names), 1);
S_MLII(end,:,:) = -1;
P_MLII = zeros(numel(results.file_names), 1);
P_MLII(end,:,:) = -1;
F1_MLII = zeros(numel(results.file_names), 1);
F1_MLII(end,:,:) = -1;

results.lead_names = strrep(results.lead_names,results.pattern_name,'');

for record = 1:numel(results.file_names)
    str_idx = ismember(results.lead_names,{'_MLII','_II','_ML2'});
    rec_idx = results.TPR(:,record) ~= -1;
    rec_idx = rec_idx';
    true_idx = str_idx .* rec_idx;
    true_idx = find(true_idx);
    
    if ~isempty(true_idx)
        S_MLII(record) = results.TPR(true_idx,record);
        P_MLII(record) = results.PPV(true_idx,record);
        F1_MLII(record) = results.F1(true_idx,record);
    else
        flag = 1;
        sub_count = 1;
        while flag == 1
            if (results.TPR(sub_count,record) ~= -1) && (contains(results.lead_names(sub_count),'_RESP') ~= 1)
                flag = 0;
            else
                sub_count = sub_count + 1;
            end
        end
        S_MLII(record) = results.TPR(sub_count,record);
        P_MLII(record) = results.PPV(sub_count,record);
        F1_MLII(record) = results.F1(sub_count,record);
    end
end

S_BEST = zeros(numel(results.file_names), 1);
S_BEST(end,:,:) = -1;
P_BEST = zeros(numel(results.file_names), 1);
P_BEST(end,:,:) = -1;
F1_BEST = zeros(numel(results.file_names), 1);
F1_BEST(end,:,:) = -1;

promedios = [];
        
sub_count = 1;
for lead_number = 1:numel(results.lead_names)
    tablas(:,sub_count) = results.TPR(lead_number,:);
    sub_count = sub_count + 1;

    tablas(:,sub_count) = results.PPV(lead_number,:);
    sub_count = sub_count + 1;

    tablas(:,sub_count) = results.F1(lead_number,:);
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

for record = 1:numel(results.file_names)
    max_TPR_value = 0;
    max_TPR_index = 0;
    max_PPV_value = 0;
    max_PPV_index = 0;
    max_PRO_value = 0;
    max_PRO_index = 0;
    
    for sub_count = 1:numel(results.lead_names)
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
        S_BEST(record) = tablas(record,max_TPR_index);
        P_BEST(record) = tablas(record,max_TPR_index + 1);
        F1_BEST(record) = tablas(record,max_TPR_index + 2);
    else
        % Si el indice donde esta el mayor TPR y PPV es distinto, elijo
        % el que mayor promedio tenga entre los dos parametros
        for sub_count = 1:numel(results.lead_names)
            if (tablas(record,(sub_count * 3) - 2) ~= -1)
                PRO_value = (tablas(record,(sub_count * 3) - 2) + tablas(record,(sub_count * 3) - 2))/2;
                if PRO_value > max_PRO_value
                    max_PRO_value = PRO_value;
                    max_PRO_index = sub_count;
                end
            end
        end

        S_BEST(record) = tablas(record,max_PRO_index * 3 - 2);
        P_BEST(record) = tablas(record,max_PRO_index * 3 - 1);
        F1_BEST(record) = tablas(record,max_PRO_index * 3); % F1
    end
end

signrank(F1_BEST,F1_MLII,'tail','right')