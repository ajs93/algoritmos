%% Script para la generacion automatica de un corpus mergeando distintas bases de datos

clear;
clc;

disp('Comenzando con la creacion del corpus.');

% Directorios de entrada/salida
sourceDirectory = '/home/augusto/Escritorio/Beca/DataBases';
outfile = 'corpus_final.txt';
% outputDirectory = '/home/augusto/Escritorio/Beca/corpusdb';

% Se tomaran N recordings totales entre todas las bases de datos
N = 200;

databases = {[filesep 'edb'], ...
             [filesep 'fantasia'], ...
             [filesep 'INCART'], ...
             [filesep 'ltafdb'], ...
             [filesep 'ltdb'], ...
             [filesep 'ltstdb'], ...
             [filesep 'mitdb'], ...
             [filesep 'nsrdb'], ...
             [filesep 'sddb'], ...
             [filesep 'stdb'], ...
             [filesep 'svdb'], ...
             [filesep 'thew']};
         
formats = {'MIT', ...
           'MIT', ...
           'MIT', ...
           'MIT', ...
           'MIT', ...
           'MIT', ...
           'MIT', ...
           'MIT', ...
           'MIT', ...
           'MIT', ...
           'MIT', ...
           'MAT'};

patient_list_INCART = { {'I01' , 'I02'};
                        {'I03' , 'I04' , 'I05'};
                        {'I06' , 'I07'};
                        {'I08'};
                        {'I09' , 'I10' , 'I11'};
                        {'I12' , 'I13' , 'I14'};
                        {'I15'};
                        {'I16' , 'I17'};
                        {'I18' , 'I19'};
                        {'I20' , 'I21' , 'I22'};
                        {'I23' , 'I24'};
                        {'I25' , 'I26'};
                        {'I27' , 'I28'};
                        {'I29' , 'I30' , 'I31' , 'I32'};
                        {'I33' , 'I34'};
                        {'I35' , 'I36' , 'I37'};
                        {'I38' , 'I39'};
                        {'I40' , 'I41'};
                        {'I42' , 'I43'};
                        {'I44' , 'I45' , 'I46'};
                        {'I47' , 'I48'};
                        {'I49' , 'I50'};
                        {'I51' , 'I52' , 'I53'};
                        {'I54' , 'I55' , 'I56'};
                        {'I57' , 'I58'};
                        {'I59' , 'I60' , 'I61'};
                        {'I62' , 'I63' , 'I64'};
                        {'I65' , 'I66' , 'I67'};
                        {'I68' , 'I69'};
                        {'I70' , 'I71'};
                        {'I72' , 'I73'};
                        {'I75' , 'I75'}; };

% La INCART es un caso aparte porque no hay un recording por paciente
already_taken_patients_INCART = zeros(numel(patient_list_INCART), 1);

N = round(N/numel(databases));
aux = sprintf('Archivos por database = %d',N);
disp(aux);
       
if numel(databases) == numel(formats)
    % Archivos en cada dataBase y generacion de los indices aleatorios de c/u
    fileHandler = fopen(['.' filesep outfile],'w');
    
    for count = 1:numel(databases)
        auxExt = [];
        
        switch(formats{count})
            case 'MIT'
                auxExt = '*.hea';
            case 'MAT'
                auxExt = '*.mat';
        end
        
        if strcmp(databases{count},[filesep,'INCART'])
            archivos = dir([sourceDirectory, databases{count},filesep,auxExt]);
            trueN = min(numel(archivos),N);
            
            INCART_round = 1;
            
            indexes = cell(numel(patient_list_INCART),floor(trueN / numel(patient_list_INCART)) + 1);
            
            while trueN > 0
                if trueN < numel(patient_list_INCART)
                    indexes = mat2cell(colvec(sort(randperm(numel(patient_list_INCART),trueN))),ones(1,trueN));
                    trueN = 0;
                else
                    disp('Todavia no esta bancado esto... Borrar el archivo creado porque quedo incompleto.')
                    
                    fclose(fileHandler);
                    return
                    
                    indexes(:,INCART_round) = mat2cel(sort(randperm(numel(patient_list_INCART),trueN)));
                    INCART_round = INCART_round + 1;
                    trueN = trueN - numel(patient_list_INCART);
                end
            end
        else
            archivos = dir([sourceDirectory, databases{count},filesep,auxExt]);
            trueN = min(numel(archivos),N);
            indexes = sort(randperm(numel(archivos),trueN));
        end

        for subCount = 1:numel(indexes)
            if strcmp(databases{count},[filesep,'INCART'])
                disp([databases{count} filesep patient_list_INCART{indexes{subCount}}{1}]);
                fprintf(fileHandler,[databases{count}(2:end) filesep patient_list_INCART{indexes{subCount}}{1} newline]);
            else
                disp([databases{count} filesep archivos(indexes(subCount)).name]);
                fprintf(fileHandler,[databases{count}(2:end) filesep archivos(indexes(subCount)).name(1:end-4) newline]);
            end
        end
    end

    fclose(fileHandler);
    disp('Finalizada la creacion del corpus.');
else
    disp('databases ~= formats...');
end
