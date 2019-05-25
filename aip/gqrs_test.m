clear;
clc;

tic

ECGw = ECGwrapper();

ECGw.ECGtaskHandle = 'QRS_detection';
ECGw.recording_name = '/home/augusto/Escritorio/GIBIO/DataBases/ltafdb/114';
ECGw.ECGtaskHandle.detectors = 'wavedet';
ECGw.Run();

toc