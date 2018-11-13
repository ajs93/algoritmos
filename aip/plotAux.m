function [] = plotAux(ECGw, chan, t_ini, delta_t, ann, FPAnn)
    t = t_ini:t_ini + delta_t;
    t(t >= ECGw.ECG_header.nsamp) = [];
    
    sign = ECGw.read_signal(min(t),max(t));
    sign = sign(:,chan);
    
    algAnn = ann(ann >= t_ini & ann <= t_ini + delta_t);
    
    FPAnn = FPAnn(FPAnn >= t_ini & FPAnn <= t_ini + delta_t);
    
    okAnn = ECGw.ECG_annotations.time;
    okAnn = okAnn(okAnn >= t_ini & okAnn <= t_ini + delta_t);
    
    if ~isempty(FPAnn)
        f = figure(1);
        plot(t, sign);
        grid on;
        hold on;
        plot(okAnn, sign(okAnn - t_ini + 1), 'ms');
        hold on;
        plot(algAnn, sign(algAnn - t_ini + 1), 'bx');
        hold on;
        plot(FPAnn, sign(FPAnn - t_ini + 1), 'r*');
        
        set(gcf,'units','normalized','outerposition',[0 0 1 1])

        while waitforbuttonpress == 0
        end

        delete(f);
    end
end