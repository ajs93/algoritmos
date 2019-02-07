% function aip_test
clear
clc

payload_in = [];

%% Config data

%%%%%%%%%%%%%%
% ECG Humano %
%%%%%%%%%%%%%%
% 
% NSR
% filename = '/home/mllamedo/Descargas/seniales_ecg_formato_mit/ecg_3';
% filename = '/home/mllamedo/Descargas/seniales_ecg_formato_mit/ecg_4';
% filename = '/home/mllamedo/mariano/dbs/mitdb/100';
% 
% Afib
% filename = '/home/mllamedo/mariano/dbs/mitdb/219';
% filename = '/home/mllamedo/mariano/dbs/mitdb/222';
% Stress
% filename = '/home/mllamedo/mariano/dbs/E-OTH-12-0927-015/1_PR01_060803_1';
% filename = '/home/mllamedo/mariano/dbs/E-OTH-12-0927-015/642_PR01_040627_2';
% filename = '/home/mllamedo/mariano/dbs/E-OTH-12-0927-015/896_PR01_040913_1';
% Long-term
% filename = '/home/mllamedo/mariano/dbs/ltdb/14046';
% filename = '/home/augusto/Escritorio/Beca/DataBases/ltafdb/24';
% filename = '/home/augusto/Escritorio/Beca/DataBases/edb/e0606';
% filename = '/home/augusto/Escritorio/Beca/DataBases/thew/461_PR01_040505_2';
filename = '/home/augusto/Escritorio/Beca/DataBases/fantasia/f1o05';
% filename = '/home/augusto/Escritorio/Beca/DataBases/ratadb/06012006_182543';
% filename = '/home/augusto/Escritorio/Beca/DataBases/mitdb/222';

%%%%%%%%%%%%
% ECG Rata %
%%%%%%%%%%%%
% % filename = '/home/mllamedo/mariano/research/imbecu/Electro y potencial/dropbox/01012006_013724/01012006_013724_resampled_to_500_Hz_arbitrary_function';
% filename = '/home/mllamedo/mariano/research/imbecu/Electro y potencial/dropbox/01022015_113003/01022015_113003_resampled_to_500_Hz_arbitrary_function';
% % filename = '/home/mllamedo/mariano/research/imbecu/Electro y potencial/dropbox/08012006_180942/08012006_180942_resampled_to_500_Hz_arbitrary_function';
% payload_in.trgt_width = 0.02; % seconds
% payload_in.trgt_min_pattern_separation = 0.12; % seconds
% payload_in.trgt_max_pattern_separation = 2; % seconds
% payload_in.sig_idx = 1; % first signal is the rat pECG


payload.max_patterns_found = 1; % # de morfologías o latidos a buscar


bCached = false;

%% Arbitrary impulsive pseudoperiodic (AIP) detector 

ECGw = ECGwrapper( 'recording_name', filename);
ECGw.ECGtaskHandle = 'arbitrary_function';

% ECG Humano
%payload.ECG_annotations = ECGw.ECG_annotations;
payload.trgt_width = 0.06; % seconds
payload.trgt_min_pattern_separation = 0.3; % seconds
payload.trgt_max_pattern_separation = 2; % seconds
payload.stable_RR_time_win = 2; % seconds
ECGw.ECGtaskHandle.payload = payload;

% Rata
% aux_val = load([filename,'_manual_detections.mat']);
% payload.ECG_annotations = aux_val.manual;
% payload.trgt_width = 60e-3;
% payload.trgt_min_pattern_separation = 200e-3;
% payload.trgt_max_pattern_separation = 2;
% payload.max_patterns_found = 2;
% ECGw.ECGtaskHandle.payload = payload;

% Add a user-string to identify the run
ECGw.user_string = 'AIP_det';

% add your function pointer
ECGw.ECGtaskHandle.function_pointer = @aip_detector;
ECGw.ECGtaskHandle.concate_func_pointer = @aip_detector_concatenate;

ECGw.cacheResults = bCached;

ECGw.Run

cached_filenames = ECGw.Result_files;
QRS_struct = load(cached_filenames{1});

% ECG performance
res = CalculatePerformanceECGtaskQRSdet(QRS_struct, ECGw.ECG_annotations, ECGw.ECG_header, 1);