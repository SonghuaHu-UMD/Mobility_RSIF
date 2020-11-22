import pandas as pd
import os
import matplotlib.pyplot as plt
import webcolors
from matplotlib.offsetbox import AnchoredText
import numpy as np
from sklearn.metrics import mean_squared_error
from math import sqrt

os.chdir(r'D:\COVID-19\First_Paper_State_Stay_at_Home')
Plot_R = pd.read_csv(r'Output_R_For_Plot.csv', index_col=0).reset_index(drop=True)
Plot_R['Date'] = Plot_R['Date'].astype(str).str[5:]
# Plot
fig, ax = plt.subplots(nrows=5, ncols=9, sharey=True, figsize=(18, 10))
plt.tight_layout()
gs = ax[4, 8].get_gridspec()
axs = ax.ravel()
axs[44].remove()
axs[43].remove()
axbig = fig.add_subplot(gs[4:, -2:])
axbig.set_yticklabels([''] * 5)
ALL_PLOT = Plot_R.groupby('Date').mean().reset_index()
# ALL_PLOT = ALL_PLOT[ALL_PLOT['Date'] > '02-17']
ALL_PLOT.loc[ALL_PLOT['Date'] == '02-17', 'ANum_Trips'] = -0.18307
axbig.plot(ALL_PLOT['Date'], ALL_PLOT['ANum_Trips'], '--o', color='gray', alpha=0.6, markersize=0.5,
           label='Observation')
axbig.plot(ALL_PLOT['Date'], ALL_PLOT['predict_noEnforce'], '-o', color=webcolors.rgb_to_hex((46, 71, 199)),
           alpha=0.9, markersize=0.5, label='Without Stay-at-home order')
axbig.plot(ALL_PLOT['Date'], ALL_PLOT['predict'], '-^', color='r',  # webcolors.rgb_to_hex((252, 180, 150))
           alpha=0.9, markersize=0.5, label='With Stay-at-home order')
axbig.plot([0, 70], [0, 0], '--', color='k', alpha=0.6)
axbig.plot(['03-13', '03-13'], [min(Plot_R['predict']), max(Plot_R['predict'])], '-', color='k', alpha=0.9, linewidth=2)
axbig.fill_between(ALL_PLOT['Time_Index'], ALL_PLOT['predict_noEnforce'], ALL_PLOT['predict'],
                   color=webcolors.rgb_to_hex((46, 71, 199)), alpha=.05)
axbig.set_xticks(range(0, len(ALL_PLOT), 20))
axbig.set_xticklabels(ALL_PLOT['Date'][::20], rotation=0)
axbig.set_title('U.S.')
axbig.set_ylim([min(Plot_R['predict']), max(Plot_R['predict'])])
axbig.legend(framealpha=0.0, loc=0)

# fig.subplots_adjust(top=0.963, bottom=0.04, left=0.03, right=0.992, hspace=0.454, wspace=0.216)
ccount = -1
all_mean1 = []
all_RMSE = []
State_Name = Plot_R.drop_duplicates(subset=['STNAME']).sort_values(by='STNAME')
for eachstate in list(State_Name['STNAME']):
    tem = Plot_R[(Plot_R['STNAME'] == eachstate) & (Plot_R['Cases'] > 0)].reset_index(drop=True)
    if len(tem[tem['Enforcement'] > 0]) > 0:
        ccount += 1
        axs[ccount].plot(tem['Date'], tem['ANum_Trips'], '--o', color='gray',
                         alpha=0.6, markersize=0.5, label='Observation')
        axs[ccount].plot(tem['Date'], tem['predict_noEnforce'], '-o', color=webcolors.rgb_to_hex((46, 71, 199)),
                         alpha=0.9, markersize=0.5, label='No Enforcement')
        axs[ccount].set_xticks(range(0, len(tem), 20))
        axs[ccount].set_xticklabels(tem['Date'][::20], rotation=0)
        axs[ccount].plot(tem['Date'], tem['predict'], '-^', color='r',
                         alpha=0.9, markersize=0.5, label='With Enforcement')
        axs[ccount].plot([tem['Date'][0], tem['Time_Index'][len(tem['Time_Index']) - 1]], [0, 0], '--', color='k',
                         alpha=0.6)
        axs[ccount].plot([tem.loc[tem[tem['Enforcement'] > 0]['Date'].index[0] - 1, 'Date'],
                          tem.loc[tem[tem['Enforcement'] > 0]['Date'].index[0] - 1, 'Date']],
                         [min(Plot_R['predict']), max(Plot_R['predict'])], '-', color='k', alpha=0.9, linewidth=2)
        axs[ccount].fill_between(tem['Date'], tem['predict_noEnforce'], tem['predict'],
                                 color=webcolors.rgb_to_hex((46, 71, 199)), alpha=.1)
        tem1 = tem[tem['Diff_Enforce'] > 0]
        at = AnchoredText(
            "Policy Effect:" + str(round((tem1['predict_noEnforce'] - tem1['predict']).mean(), 3)),
            prop=dict(size=10), frameon=False, loc='lower left')
        axs[ccount].add_artist(at)
        # at = AnchoredText(
        #     "RMSE:" + str(round(sqrt(mean_squared_error(tem['ANum_Trips'], tem['predict'])), 3)),
        #     prop=dict(size=10), frameon=False, loc='upper left')
        # axs[ccount].add_artist(at)
        plt.ylim([min(Plot_R['predict']), max(Plot_R['predict'])])
        axs[ccount].set_title(eachstate)
        all_mean1.append((tem1['predict_noEnforce'] - tem1['predict']).mean())
        all_RMSE.append(sqrt(mean_squared_error(tem['ANum_Trips'], tem['predict'])))

at = AnchoredText("Policy Effect:" + str(round(np.mean(all_mean1), 3)), prop=dict(size=10), frameon=False,
                  loc='upper right')
axbig.add_artist(at)
# at = AnchoredText(
#     "MAPE:" + str(round(np.median(np.abs((Plot_R['ANum_Trips'] - Plot_R['predict']) / Plot_R['ANum_Trips'])), 3)),
#     prop=dict(size=10), frameon=False, loc='upper left')
at = AnchoredText("R-sq.(adj): " + str(0.882), prop=dict(size=10), frameon=False, loc='upper left')
axbig.add_artist(at)
plt.tight_layout()
plt.savefig('TripNum.png', dpi=1200)
plt.savefig('TripNum.pdf', dpi=1200)

# Plot APMT
import pandas as pd
import os
import matplotlib.pyplot as plt
import webcolors
from matplotlib.offsetbox import AnchoredText
import numpy as np

# os.chdir(r'C:\Users\Songhua Hu\Desktop\CVO-19\COVID19_Paper')
os.chdir(r'D:\COVID-19\First_Paper_State_Stay_at_Home')
Plot_R = pd.read_csv(r'Output_R_For_Plot_PMT.csv', index_col=0).reset_index(drop=True)
Plot_R['Date'] = Plot_R['Date'].astype(str).str[5:]

fig, ax = plt.subplots(nrows=5, ncols=9, sharey=True, figsize=(18, 10))
plt.tight_layout()
fig.subplots_adjust(top=0.963, bottom=0.04, left=0.03, right=0.992, hspace=0.454, wspace=0.216)
gs = ax[4, 8].get_gridspec()
axs = ax.ravel()
axs[44].remove()
axs[43].remove()
axbig = fig.add_subplot(gs[4:, -2:])
axbig.set_yticklabels([''] * 5)
ALL_PLOT = Plot_R.groupby('Date').mean().reset_index()
ALL_PLOT.loc[ALL_PLOT['Date'] == '02-17', 'APMT'] = -2.03307
axbig.plot(ALL_PLOT['Date'], ALL_PLOT['APMT'], '--o', color='gray', alpha=0.6, markersize=0.5, label='Observation')
axbig.plot(ALL_PLOT['Date'], ALL_PLOT['predict_noEnforce'], '-o', color=webcolors.rgb_to_hex((46, 71, 199)),
           alpha=0.9, markersize=0.5, label='Without Stay-at-home order')
axbig.plot(ALL_PLOT['Date'], ALL_PLOT['predict'], '-^', color='r',
           alpha=0.9, markersize=0.5, label='With Stay-at-home order')
axbig.plot([0, 70], [0, 0], '--', color='k', alpha=0.6)
axbig.plot(['03-13', '03-13'], [min(Plot_R['predict']), max(Plot_R['predict'])], '-', color='k', alpha=0.9,
           linewidth=2)
axbig.fill_between(ALL_PLOT['Time_Index'], ALL_PLOT['predict_noEnforce'], ALL_PLOT['predict'],
                   color=webcolors.rgb_to_hex((46, 71, 199)), alpha=.05)
axbig.set_xticks(range(0, len(ALL_PLOT), 20))
axbig.set_xticklabels(ALL_PLOT['Date'][::20], rotation=0)
axbig.set_title('U.S.')
axbig.set_ylim([min(Plot_R['predict']), max(Plot_R['predict'])])
axbig.legend(framealpha=0.0, loc=0)

ccount = -1
all_mean = []
all_RMSE = []
all_state = []
State_Name = Plot_R.drop_duplicates(subset=['STNAME']).sort_values(by='STNAME')
for eachstate in list(State_Name['STNAME']):
    tem = Plot_R[(Plot_R['STNAME'] == eachstate) & (Plot_R['Cases'] > 0)].reset_index(drop=True)
    if len(tem[tem['Enforcement'] > 0]) > 0:
        ccount += 1
        axs[ccount].plot(tem['Date'], tem['APMT'], '--o', color='gray',
                         alpha=0.6, markersize=0.5, label='Observation')
        axs[ccount].plot(tem['Date'], tem['predict_noEnforce'], '-o', color=webcolors.rgb_to_hex((46, 71, 199)),
                         alpha=0.9, markersize=0.5, label='No Enforcement')
        axs[ccount].set_xticks(range(0, len(tem), 20))
        axs[ccount].set_xticklabels(tem['Date'][::20], rotation=0)
        axs[ccount].plot(tem['Date'], tem['predict'], '-^', color='r',
                         alpha=0.9, markersize=0.5, label='With Enforcement')
        axs[ccount].plot([tem['Date'][0], tem['Time_Index'][len(tem['Time_Index']) - 1]], [0, 0], '--', color='k',
                         alpha=0.6)
        axs[ccount].plot([tem.loc[tem[tem['Enforcement'] > 0]['Date'].index[0] - 1, 'Date'],
                          tem.loc[tem[tem['Enforcement'] > 0]['Date'].index[0] - 1, 'Date']],
                         [min(Plot_R['predict']), max(Plot_R['predict'])], '-', color='k', alpha=0.9, linewidth=2)
        axs[ccount].fill_between(tem['Date'], tem['predict_noEnforce'], tem['predict'],
                                 color=webcolors.rgb_to_hex((46, 71, 199)), alpha=.1)
        tem1 = tem[tem['Enforcement'] > 0]
        at = AnchoredText(
            "Policy Effect:" + str(round((tem1['predict_noEnforce'] - tem1['predict']).mean(), 3)),
            prop=dict(size=10), frameon=False, loc='lower left', )
        axs[ccount].add_artist(at)
        # at = AnchoredText(
        #     "RMSE:" + str(round(sqrt(mean_squared_error(tem['APMT'], tem['predict'])), 3)),
        #     prop=dict(size=10), frameon=False, loc='upper left')
        # axs[ccount].add_artist(at)
        plt.ylim([min(Plot_R['predict']), max(Plot_R['predict'])])
        axs[ccount].set_title(eachstate)
        all_mean.append((tem1['predict_noEnforce'] - tem1['predict']).mean())
        all_state.append(eachstate)
        all_RMSE.append(sqrt(mean_squared_error(tem['APMT'], tem['predict'])))

at = AnchoredText("Policy Effect:" + str(round(np.mean(all_mean), 3)), prop=dict(size=10), frameon=False,
                  loc='upper right')
axbig.add_artist(at)
# at = AnchoredText("RMSE:" + str(round(np.mean(all_RMSE), 3)),
#                   prop=dict(size=10), frameon=False, loc='upper left')
# at = AnchoredText(
#     "MAPE:" + str(round(np.median(np.abs((Plot_R['APMT'] - Plot_R['predict']) / Plot_R['APMT'])), 3)),
#     prop=dict(size=10), frameon=False, loc='upper left')
at = AnchoredText("R-sq.(adj): " + str(0.919), prop=dict(size=10), frameon=False, loc='upper left')
axbig.add_artist(at)
plt.tight_layout()
plt.savefig('APMT.png', dpi=1200)
plt.savefig('APMT.pdf', dpi=1200)

# plt.plot(Plot_R['APMT'], Plot_R['predict'], 'o', color='k', alpha=0.3)
# plt.hist(np.abs((Plot_R['APMT'] - Plot_R['predict']) / Plot_R['APMT']))
#
# Plot_R['MAPE']=np.abs((Plot_R['APMT'] - Plot_R['predict']) / Plot_R['APMT'])
# Plot_R=Plot_R.sort_values(by='MAPE')

# The policy rank
Rank = pd.DataFrame({'State': all_state, 'Mean_TTP': all_mean1, 'Mean_PMT': all_mean})
Rank = Rank.sort_values(by='Mean_TTP').reset_index(drop=True)
Rank['Rank_TTP'] = range(1, len(Rank) + 1)
Rank = Rank.sort_values(by='Mean_PMT').reset_index(drop=True)
Rank['Rank_PMT'] = range(1, len(Rank) + 1)
Rank = Rank.sort_values(by='Mean_TTP').reset_index(drop=True)
Rank.to_csv('Rank.csv')
