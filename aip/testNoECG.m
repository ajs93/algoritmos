clear;
clc;

ECGw = ECGwrapper();

%ECGw.recording_name = '/home/augusto/Escritorio/Beca/DataBases/mitdb/100';
%ECGw.recording_name = '/home/augusto/Escritorio/NoECGdb/CH2014/100';
%ECGw.recording_name = '/home/augusto/Escritorio/NoECGdb/CEBS/b001';
ECGw.recording_name = '/home/augusto/Escritorio/NoECGdb/WRIST/s1_high_resistance_bike';

% Asigno el algoritmo de deteccion de QRS a utilizar:
ECGw.ECGtaskHandle = 'arbitrary_function';

payload = [];

%aux_val = load('/home/augusto/Escritorio/NoECGdb/BIDMC/bidmc53.breath');

payload.ECG_annotations = ECGw.ECG_annotations;
payload.trgt_width = 60e-3;
payload.trgt_min_pattern_separation = 300e-3;
payload.trgt_max_pattern_separation = 2;
payload.max_patterns_found = 2;
ECGw.ECGtaskHandle.payload = payload;

ECGw.user_string = 'AIP_det';

% add your function pointer
ECGw.ECGtaskHandle.function_pointer = @aip_detector;
ECGw.ECGtaskHandle.concate_func_pointer = @aip_detector_concatenate;

ECGw.cacheResults = false; 

ECGw.Run();

% Tomo el resultado de correr el detector:
file = ECGw.GetCahchedFileName('arbitrary_function');

resInt = load(cell2mat(file));
delete(file{1}); % Borro archivo cacheado

res = CalculatePerformanceECGtaskQRSdet(resInt, ECGw.ECG_annotations, ECGw.ECG_header, 1);