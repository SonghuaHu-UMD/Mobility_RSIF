"""Plot statistics from the same exported full GAM fit."""
import numpy as np


def adjusted_r2_label(frame, response):
    required = {'Model_R2_adj', 'Model_Response', 'Model_Statistic_Source', 'Model_Evaluation'}
    if not required.issubset(frame.columns):
        raise ValueError('Legacy prediction CSV lacks model statistics; rerun Final_GAM2.R')
    if set(frame.Model_Response) != {response} or set(frame.Model_Statistic_Source) != {'mgcv::summary.gam'} or set(frame.Model_Evaluation) != {'in_sample_full_fit'}:
        raise ValueError('Prediction CSV and full model statistics do not match')
    values = frame.Model_R2_adj.unique()
    if len(values) != 1 or not np.isfinite(values[0]):
        raise ValueError('Missing or inconsistent adjusted R-squared')
    return f'In-sample R-sq.(adj): {values[0]:.3f}'


def plot_grid(frame, plt):
    count = frame.loc[frame.Enforcement > 0, 'STNAME'].nunique()
    columns = 9
    rows = max(1, int(np.ceil((count + 1) / columns)))
    fig, ax = plt.subplots(nrows=rows, ncols=columns, sharey=True,
                           figsize=(18, max(3, 2 * rows)), squeeze=False)
    axes = ax.ravel()
    national = axes[count]
    for unused in axes[count+1:]:
        unused.set_visible(False)
    return fig, axes[:count], national
