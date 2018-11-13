% Script para corregir el formato de la base de datos de stress

clear
clc

disp('Comenzando.');

% Carpetas de entrada y salida
sourceDirectory = '/home/augusto/Escritorio/Beca/DataBases/thew';
outputDirectory = '/home/augusto/Escritorio/Beca/DataBases/stdb_corrected';

% Archivos a corregir
archivos = dir(strcat(sourceDirectory,filesep,'*.mat'));

for count = 1:numel(archivos)
    disp(sprintf('Count = %d/%d',count, numel(archivos)));
    % Cargo archivo a corregir
    aux = load(strcat(archivos(count).folder, filesep, archivos(count).name));
    
    % Extraigo parametros con los que me quiero quedar
    signal = aux.signal;
    header = aux.header;
    header.bdate = header.date;
    header = rmfield(header, 'date');
    
    ann = aux.ann;
    
    % Guardo variables en el archivo de salida
    save(strcat(outputDirectory, filesep, archivos(count).name), 'signal', 'header', 'ann');
    
    clear signal;
    clear header;
    clear ann;
    clear aux;
end

disp('Finalizado.');