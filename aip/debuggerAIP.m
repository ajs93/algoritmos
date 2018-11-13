%aux para plotear lo piola en nsamples samples

nsamples = 1000;
offset = 40000;

eje_x = 1:nsamples;

sign = ECG_matrix(offset:offset + nsamples - 1, 1);
rd = rise_detector(offset:offset + nsamples - 1);
auxDet = first_detection_idx(first_detection_idx > offset & first_detection_idx < offset + nsamples - 1);
auxMax = max_idxes(max_idxes > offset & max_idxes < offset + nsamples - 1);

for i = 1 : numel(auxDet)
    if auxMax(i) == auxDet(i)
       auxMax(i) = []; 
    end
end

fig = figure(1);
sp1 = subplot(2,2,3);
plot(hist_max_values,thr_grid(2:end));
title('Maxes histogram');
set(sp1, 'xticklabel', {});
set(sp1, 'yticklabel', {});
hold on;
plot([min(hist_max_values), max(hist_max_values)],[actual_thr, actual_thr], 'k--');
grid on;

sp2 = subplot(2,2,2);
plot(eje_x + offset, sign);
title('mitdb/101');
set(sp2, 'xticklabel', {});
set(sp2, 'yticklabel', {});
legend(sp2, 'ECG');
grid on;

sp3 = subplot(2,2,4);
plot(eje_x + offset, rd);
hold on;
plot(auxDet, rise_detector(auxDet), 'g*');
hold on;
plot(auxMax, rise_detector(auxMax), 'rx');
hold on;
plot([min(eje_x + offset), max(eje_x + offset)],[actual_thr, actual_thr], 'k--');
set(sp3, 'xticklabel', {});
set(sp3, 'yticklabel', {});
legend(sp3, 'Analytic signal', 'Real detections', 'Ignored detections');
grid on;

ylim(sp1, [0, 40]);
ylim(sp3, [0, 40]);