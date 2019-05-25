%% Facilidad para cortar segmentos de recordings

% Limpieza
clear;
clc;

% Lugar donde estan los recordings a segmentar
source_directory = '/home/augusto/Escritorio/GIBIO/DataBases/ratadb/';
destination_directory = '/home/augusto/Escritorio/GIBIO/DataBases/ratadb_segmentada/';

% Archivo de texto con los recordings a segmentar
recording_file_handler = fopen('/home/augusto/Escritorio/GIBIO/Algoritmos/algoritmos/recordings_rata.txt','r');

if recording_file_handler == -1
    disp('Error abriendo archivo de recordings a segmentar.');
    return;
end

if source_directory(end) ~= filesep
    source_directory = [source_directory, filesep];
end

if ~exist(destination_directory, 'dir')
    mkdir(destination_directory);
end

eof_found = 1;
counter = 1;
archivos = struct('name',[]);

while eof_found == 1
    aux_string = fgetl(recording_file_handler);
    if aux_string == -1
        eof_found = 0;
    else
        archivos(counter).name = aux_string;
        counter = counter + 1;
    end
end

fclose(recording_file_handler);

for counter = 1:numel(archivos)
    ECGw = ECGwrapper();
    ECGw.recording_name = [source_directory,archivos(counter).name];
    aux_val = load([source_directory,archivos(counter).name,'_manual_detections.mat']);
    ECGw.ECG_annotations = aux_val.manual;

    plot_ecg_strip(ECGw,'start_time',0,'end_time',floor(ECGw.ECG_header.nsamp / ECGw.ECG_header.freq));

    desde_muestra = input('Desde donde recortar? (En segundos)\n');
    desde_muestra = round(desde_muestra * ECGw.ECG_header.freq);
    
    hasta_muestra = input('Hasta donde recortar? (En segundos)\n');
    hasta_muestra = round(hasta_muestra * ECGw.ECG_header.freq);

    a_morir = input('Cerra el plot_ecg_strip.\n');
    
    sign = ECGw.read_signal(desde_muestra, hasta_muestra);

    header = ECGw.ECG_header;
    header.nsamp = numel(sign(:,1));

    ann = [];
    ann.time = ECGw.ECG_annotations.time - desde_muestra;

    a_guardar = [];
    a_guardar.sig = sign;
    a_guardar.ann = ann;
    a_guardar.header = header;

    save([destination_directory,archivos(counter).name,'.mat'],'-struct','a_guardar');
end