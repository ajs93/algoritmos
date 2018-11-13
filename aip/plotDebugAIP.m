sign = ECG_matrix(:,this_sig_idx);
time = numel(sign);

figure(1);
plot(time,sign);
hold on;
plot(first_detection_idx, sign(first_detection_idx), 'r*');
hold on;
grid on;