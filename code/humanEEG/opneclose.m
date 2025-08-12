>>eeglab
>> file_4open= ‘D:\k\4-open-3.CSV’
file_4close= ‘D:\k\4-close-3.CSV’
fs = 1000;

locfile = which('standard-10-5-cap385.elp')
locs = readlocs(locfile);

>> % ヘッダー処理
fid = fopen(file_4open, 'r'); for i = 1:3, fgetl(fid); end
header = fgetl(fid); fclose(fid);
labels = strsplit(header, ',');
chan_labels = labels(3:21);
for i = 1:length(chan_labels)
    chan_labels{i} = strrep(chan_labels{i}, '"', '');
    chan_labels{i} = strrep(chan_labels{i}, '　', '');
    chan_labels{i} = regexprep(chan_labels{i}, '\s+', '');
end

% データ読み込み
opts = detectImportOptions(file_4open, 'NumHeaderLines', 4);
tbl_open = readtable(file_4open, opts);
data_open = tbl_open{:, 3:21};

opts = detectImportOptions(file_4close, 'NumHeaderLines', 4);
tbl_close = readtable(file_4close, opts);
data_close = tbl_close{:, 3:21};

% チャネル位置取得
my_chanlocs = [];
for i = 1:length(chan_labels)
    idx = find(strcmpi({locs.labels}, chan_labels{i}));
    if ~isempty(idx)
        my_chanlocs = [my_chanlocs locs(idx)];
    end
end
>> % 開眼
EEG_open = pop_importdata('dataformat','array','data',data_open', ...
    'srate', fs, 'chanlocs', my_chanlocs);
EEG_open = pop_eegfiltnew(EEG_open, 59, 61, [], 1);
EEG_open = pop_eegfiltnew(EEG_open, 0.5, 80);
EEG_open = pop_runica(EEG_open, 'extended', 1, 'interrupt', 'on');
EEG_open = pop_iclabel(EEG_open, 'default');
eye_idx_open = find(EEG_open.etc.ic_classification.ICLabel.classifications(:,3) > 0.9);
EEG_open = pop_subcomp(EEG_open, eye_idx_open, 0);

% 閉眼
EEG_close = pop_importdata('dataformat','array','data',data_close', ...
    'srate', fs, 'chanlocs', my_chanlocs);
EEG_close = pop_eegfiltnew(EEG_close, 59, 61, [], 1);
EEG_close = pop_eegfiltnew(EEG_close, 0.5, 80);
EEG_close = pop_runica(EEG_close, 'extended', 1, 'interrupt', 'on');
EEG_close = pop_iclabel(EEG_close, 'default');
eye_idx_close = find(EEG_close.etc.ic_classification.ICLabel.classifications(:,3) > 0.9);
EEG_close = pop_subcomp(EEG_close, eye_idx_close, 0);

>> % ----------- スペクトル計算（dB → µV²/Hz に戻す） -----------
[spec_open, f] = spectopo(EEG_open.data, 0, fs, 'plot','off');
[spec_close, ~] = spectopo(EEG_close.data, 0, fs, 'plot','off');
spec_open = 10.^(spec_open / 10);
spec_close = 10.^(spec_close / 10);

% ----------- アルファ帯域パワー（8-13Hz） -----------
alpha_idx = find(f >= 8 & f <= 13);
open_alpha = mean(spec_open(:, alpha_idx), 2);
close_alpha = mean(spec_close(:, alpha_idx), 2);
diff_alpha = close_alpha - open_alpha;

% ----------- カラースケール調整 -----------
cmin = min([open_alpha; close_alpha]);
cmax = max([open_alpha; close_alpha]);

% ----------- トポプロット表示 -----------
figure('Position', [100, 100, 1400, 500]);

subplot(1,3,1);
topoplot(open_alpha, EEG_open.chanlocs, 'maplimits', [cmin cmax], 'electrodes', 'labelpoint');
cb = colorbar; ylabel(cb, 'Power (\muV^2/Hz)');
title('Open Eyes Alpha Power');

subplot(1,3,2);
topoplot(close_alpha, EEG_close.chanlocs, 'maplimits', [cmin cmax], 'electrodes', 'labelpoint');
cb = colorbar; ylabel(cb, 'Power (\muV^2/Hz)');
title('Closed Eyes Alpha Power');

subplot(1,3,3);
topoplot(diff_alpha, EEG_open.chanlocs, 'maplimits', 'maxmin', 'electrodes', 'labelpoint');
cb = colorbar; ylabel(cb, '\Delta Power (\muV^2/Hz)');
title('Closed - Open Alpha Difference');
Computing spectra
Signal processing toolbox (SPT) absent: spectrum computed using the pwelch()
function from Octave which is supposedly 100% compatible with the Matlab pwelch function
 (window length 1000; fft length: 1000; overlap 0):

>> % ----------- スペクトル計算（dB → µV²/Hz に戻す） -----------
[spec_open, f] = spectopo(EEG_open.data, 0, fs, 'plot','off');
[spec_close, ~] = spectopo(EEG_close.data, 0, fs, 'plot','off');
spec_open = 10.^(spec_open / 10);
spec_close = 10.^(spec_close / 10);

% ----------- ベータ帯域パワー（13-30Hz） -----------
beta_idx = find(f >= 20& f <= 30);
open_beta = mean(spec_open(:, beta_idx), 2);
close_beta = mean(spec_close(:, beta_idx), 2);
diff_beta = close_beta - open_beta;

% ----------- カラースケール調整 -----------
cmin = min([open_beta; close_beta]);
cmax = max([open_beta; close_beta]);

% ----------- トポプロット表示 -----------
figure('Position', [100, 100, 1400, 500]);

subplot(1,3,1);
topoplot(open_beta, EEG_open.chanlocs, 'maplimits', [cmin cmax], 'electrodes', 'labelpoint');
cb = colorbar; ylabel(cb, 'Power (\muV^2/Hz)');
title('Open Eyes Beta2 Power');

subplot(1,3,2);
topoplot(close_beta, EEG_close.chanlocs, 'maplimits', [cmin cmax], 'electrodes', 'labelpoint');
cb = colorbar; ylabel(cb, 'Power (\muV^2/Hz)');
title('Closed Eyes Beta2 Power');

subplot(1,3,3);
topoplot(diff_beta, EEG_open.chanlocs, 'maplimits', 'maxmin', 'electrodes', 'labelpoint');
cb = colorbar; ylabel(cb, '\Delta Power (\muV^2/Hz)');
title('Closed - Open Beta2 Difference');
