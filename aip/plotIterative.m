function [] = plotIterative(ECGw, chan, delta_t, ann, res)
    counter = 1;
    
    while counter < ECGw.ECG_header.nsamp
        plotAux(ECGw, chan, counter, delta_t, ann, ECGw.ECG_annotations.time(res.series_performance.conf_mat_details{chan,3}));
        
        counter = counter + delta_t;
    end
end