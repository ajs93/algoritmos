%% Facilidad para poder corregir la carpeta indicada a mano

source_directory = '/home/augusto/Escritorio/NoECGdb/CH2014_PPG_Annotations';

if source_directory(end) ~= filesep
    source_directory = [source_directory,filesep];
end

archivos = dir(source_directory);

for count = 1:numel(archivos)
    if contains(archivos(count).name,'.hea','IgnoreCase',true)
        % Caso de un archivo real para corregir
        ECGw = ECGwrapper('recording_name',[source_directory,archivos(count).name(1:end-4)]);
        ECGw.ECGtaskHandle = 'QRS_corrector';
        
        ECGw.Run();
    end
end

disp('No hay mas archivos por corregir')