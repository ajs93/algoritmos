% function aip_test
clear
clc

%% Config data

%%%%%%%%%
% Ruido %
%%%%%%%%%
% 
% Noise recording generator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % heasig.freq = 250;
% % heasig.nsamp = 10000;
% % heasig.nsig = 3;
% % heasig.gain = 2^12 * ones(heasig.nsig,1);
% % heasig.adczero = zeros(heasig.nsig,1);
% % heasig.recname = '1';
% % db_path_local = '/home/mllamedo/mariano/dbs/my_noise/';
% % 
% % MIT_filename = [ db_path_local heasig.recname '.dat' ];
% % fidECG = fopen(MIT_filename, 'w');
% % try
% %     ECG = bsxfun(@times, randn([heasig.nsig heasig.nsamp]), heasig.gain);
% %     fwrite(fidECG, ECG, 'int16', 0 );
% %     fclose(fidECG);
% % catch MEE
% %     fclose(fidECG);
% %     rethrow(MEE);
% % end
% % writeheader(db_path_local, heasig);   
% 
% 
% filename = '/home/mllamedo/mariano/dbs/my_noise/1';

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
filename = '/home/augusto/Escritorio/GIBIO/DataBases/ltafdb/114';
% filename = '/home/augusto/Escritorio/GIBIO/DataBases/mitdb/101';
% filename = '/home/augusto/Escritorio/GIBIO/DataBases/thew/243_PR01_040204_9';
% filename = '/home/augusto/Escritorio/GIBIO/DataBases/ratadb/08012006_180942';
% filename = '/home/augusto/Escritorio/GIBIO/DataBases/nsrdb/16272';

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

tic;

%% Arbitrary impulsive pseudoperiodic (AIP) detector 

ECGw = ECGwrapper( 'recording_name', filename);
ECGw.ECGtaskHandle = 'arbitrary_function';

% ECG Humano
payload.ECG_annotations = ECGw.ECG_annotations;
payload.trgt_width = 0.12; % seconds
payload.trgt_min_pattern_separation = 0.3; % seconds
payload.trgt_max_pattern_separation = 2; % seconds
payload.stable_RR_time_win = 2; % seconds
ECGw.ECGtaskHandle.payload = payload;

% Rata
% aux_val = load([filename,'_manual_detections.mat']);
% ECGw.ECG_annotations = aux_val.manual;
% payload.trgt_width = 80e-3;
% payload.trgt_min_pattern_separation = 150e-3;
% payload.trgt_max_pattern_separation = 2;
% payload.max_patterns_found = 2;
% ECGw.ECGtaskHandle.payload = payload;

% Add a user-string to identify the run
ECGw.user_string = 'AIP_det';

% add your function pointer
ECGw.ECGtaskHandle.function_pointer = @aip_detector;
ECGw.ECGtaskHandle.concate_func_pointer = @aip_detector_concatenate;

ECGw.cacheResults = bCached;

ECGw.Run();

toc;

% Tomo el resultado de correr el detector:
file = ECGw.GetCahchedFileName('arbitrary_function');

resInt = load(cell2mat(file));

res = CalculatePerformanceECGtaskQRSdet(resInt, ECGw.ECG_annotations, ECGw.ECG_header, 1);

% cached_filenames = ECGw.Result_files;
% QRS_struct = load(cached_filenames{1});
% 
% % ECG performance
% res = CalculatePerformanceECGtaskQRSdet(QRS_struct, ECGw.ECG_annotations, ECGw.ECG_header, 1);