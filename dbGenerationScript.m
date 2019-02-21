%% Script para la generacion automatica de un corpus mergeando distintas bases de datos

clear;
clc;

disp('Comenzando con la creacion del corpus.');

% Directorios de entrada/salida
sourceDirectory = '/home/augusto/Escritorio/Beca/DataBases';
outfile = 'corpusN25.txt';
% outputDirectory = '/home/augusto/Escritorio/Beca/corpusdb';

% Se tomaran N recordings totales entre todas las bases de datos
N = 25;

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

patient_list_INCART = { 'I01' , 'I02';
                        'I03

N = round(N/numel(databases));
aux = '';
sprintf(aux,'Archivos por database = %d',N);
disp(aux)
       
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
        
        archivos = dir([sourceDirectory, databases{count},filesep,auxExt]);
        trueN = min(numel(archivos),N);
        indexes = randperm(numel(archivos),trueN);

        for subCount = 1:numel(indexes)
            disp([databases{count} filesep archivos(indexes(subCount)).name]);
            fprintf(fileHandler,[databases{count}(2:end) filesep archivos(indexes(subCount)).name(1:end-4) newline]);
        end
    end

    fclose(fileHandler);
    disp('Finalizada la creacion del corpus.');
else
    disp('databases ~= formats...');
end
