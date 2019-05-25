clear;
clc;

ECGw = ECGwrapper();

ECGw.recording_name = '/home/augusto/Escritorio/NoECGdb/CH2014_BP_Annotations/100';

% Asigno el algoritmo de deteccion de QRS a utilizar:
ECGw.ECGtaskHandle = 'arbitrary_function';

payload = [];

aux_val = load('/home/augusto/Escritorio/NoECGdb/CH2014_BP_Annotations/100_reviewed_annotations.mat');

ECGw.ECG_annotations = aux_val.manual_1;
payload.trgt_width = 60e-3;
payload.trgt_min_pattern_separation = 300e-3;
payload.trgt_max_pattern_separation = 2;
payload.max_patterns_found = 1;
ECGw.ECGtaskHandle.payload = payload;

ECGw.user_string = 'AIP_det';

% Function pointer
ECGw.ECGtaskHandle.function_pointer = @aip_detector;
ECGw.ECGtaskHandle.concate_func_pointer = @aip_detector_concatenate;

ECGw.cacheResults = false; 

ECGw.Run();

% Tomo el resultado de correr el detector:
file = ECGw.GetCahchedFileName('arbitrary_function');

resInt = load(cell2mat(file));
delete(file{1}); % Borro archivo cacheado

res = CalculatePerformanceECGtaskQRSdet(resInt, ECGw.ECG_annotations, ECGw.ECG_header, 1);