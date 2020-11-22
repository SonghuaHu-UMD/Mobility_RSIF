import pandas as pd
import os
import matplotlib.pyplot as plt
import geopandas as gp
from pandas.tseries.holiday import USFederalHolidayCalendar
import datetime

# url = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv'
# case_num = pd.read_csv(url, error_bad_lines=False, dtype={'FIPS': str}).rename(
#     columns={'Confirmed': 'Confirmed Cases', 'FIPS': 'CTFIPS'})
# case_num = case_num[case_num['Country/Region'] == 'US']

# data_range = pd.date_range('2020-01-01', '2020-04-13', freq='d').strftime("%m%d")

os.chdir(r'C:\Users\Songhua Hu\Desktop\CVO-19\COVID19_Paper')
# Read directly from state_data
State_Data_Raw = pd.read_csv(r'C:\Users\Songhua Hu\Desktop\CVO-19\COVID19_Paper\State_Data.csv')

# Read shapefile
State_shp = gp.GeoDataFrame.from_file(
    r"C:\Users\Songhua Hu\Desktop\CVO-19\COVID19_Paper\cb_2018_us_state_500k.shp")  # open file
State_shp = State_shp.drop_duplicates(subset='STATEFP').reset_index(drop=True)
State_shp["NEIGHBORS"] = None  # add NEIGHBORS column
ALL_NEG = pd.DataFrame()
for index, country in State_shp.iterrows():
    # get 'not disjoint' countries
    neighbors = State_shp[~State_shp.geometry.disjoint(country.geometry)].STATEFP.tolist()
NEG = pd.DataFrame({'STFIPS': [country.STATEFP] * len(neighbors), 'Near_STFIPS': neighbors})
ALL_NEG = ALL_NEG.append(NEG)
ALL_NEG = ALL_NEG[ALL_NEG['STFIPS'] != ALL_NEG['Near_STFIPS']].reset_index(drop=True)
ALL_NEG = ALL_NEG.astype(int)

# Merge with case_num
State_case = State_Data_Raw[['STFIPS', '#COVID-19 cases', 'date']]
State_case = State_case.sort_values(by=['STFIPS', 'date']).reset_index(drop=True)
State_case['Sum_Cases'] = State_case.groupby(['STFIPS']).cumsum()['#COVID-19 cases']

State_case_1 = State_case.merge(ALL_NEG, on='STFIPS')
State_case_near = State_case.rename(
    {'STFIPS': 'Near_STFIPS', '#COVID-19 cases': '#ADJ_COVID-19 cases', 'Sum_Cases': 'ADJ_Sum_Cases'}, axis=1)
State_case_1 = State_case_1.merge(State_case_near, on=['Near_STFIPS', 'date'])
State_case_2 = State_case_1.groupby(['STFIPS', 'date']).sum()[['#ADJ_COVID-19 cases', 'ADJ_Sum_Cases']].reset_index()
State_case = State_case.merge(State_case_2, on=['STFIPS', 'date'], how='left')
State_case = State_case.fillna(0)

# plt.plot(State_case['#ADJ_COVID-19 cases'], State_case['#COVID-19 cases'], 'o', color='k', alpha=0.5)
# plt.show()
# State_case[(State_case['date'] == '03/23/2020') & (State_case['STFIPS'].isin([26, 18, 21, 54, 42]))].sum()

# Read other data
state_level_variables = pd.read_csv(r'state_level_variables (1).csv')
state_level_variables['date'] = pd.to_datetime(state_level_variables['date'])
State_case.info()
State_case['date'] = pd.to_datetime(State_case['date'])
state_level_variables = state_level_variables.merge(State_case, on=['STFIPS', 'date'], how='left')
state_level_variables.info()

# plt.plot(state_level_variables['#COVID-19 cases'], state_level_variables['Number of Trips'])
# plt.show()

state_level_variables.describe().T
state_level_variables['Number of Non-Work Trips'] = state_level_variables['Number of Non-Work Trips'] / 1e4
state_level_variables['Number of Out-of-county Trips'] = state_level_variables['Number of Out-of-county Trips'] / 1e4
state_level_variables['Number of Trips'] = state_level_variables['Number of Trips'] / 1e4
state_level_variables['Number of Work Trips'] = state_level_variables['Number of Work Trips'] / 1e4
state_level_variables['total_PMT'] = state_level_variables['total_PMT'] / 1e4

state_level_variables.columns = ['STFIPS', 'STNAME', 'Date', 'Stay_at_home', 'Enforcement', 'FEMA', 'Num_Trips',
                                 'Num_Work', 'Num_Non_Work', 'Num_Out_of_county', 'TPMT',
                                 'ANum_Trips', 'ANum_Work', 'ANum_Non_Work', 'APMT',
                                 'Cases', 'Sum_Cases', 'Adj_Cases', 'Adj_Sum_Cases']

state_level_variables['Cases'] = state_level_variables['Cases'] / 1e3
state_level_variables['Sum_Cases'] = state_level_variables['Sum_Cases'] / 1e3
state_level_variables['Adj_Cases'] = state_level_variables['Adj_Cases'] / 1e3
state_level_variables['Adj_Sum_Cases'] = state_level_variables['Adj_Sum_Cases'] / 1e3

state_level_variables['Week'] = state_level_variables['Date'].dt.dayofweek
state_level_variables['Is_Weekend'] = state_level_variables['Week'].isin([5, 6]).astype(int)
state_level_variables['Time_Index'] = (state_level_variables['Date'] - datetime.datetime(2020, 2, 1)).dt.days
state_level_variables['Enforcement'] = state_level_variables['Enforcement'] + 1
state_level_variables = state_level_variables[state_level_variables['Time_Index'] >= 0]
state_level_variables['Enforcement'].value_counts()
state_level_variables['Week'].value_counts()

# Add approval
Approval = pd.read_csv(r'C:\Users\Songhua Hu\Desktop\CVO-19\approval_2019_Q3(1).csv')
State_Name = pd.read_csv(r'C:\Users\Songhua Hu\Desktop\CVO-19\50_us_states_all_data.csv')
Approval = Approval.merge(State_Name, on='State')
Approval = Approval[['STNAME', 'Approval (percent)']]
Approval.columns = ['STNAME', 'Approval']

state_level_variables = state_level_variables.merge(Approval, on='STNAME', how='left')
state_level_variables['Population'] = state_level_variables['Num_Trips'] / state_level_variables['ANum_Trips']
state_level_variables['Approval'] = state_level_variables['Approval'] / 100
state_level_variables.loc[state_level_variables['STNAME'] == 'OK(N)', 'Approval'] = \
    list(Approval[Approval['STNAME'] == 'OK']['Approval'])[0]
state_level_variables.loc[state_level_variables['STNAME'] == 'OK(Y)', 'Approval'] = \
    list(Approval[Approval['STNAME'] == 'OK']['Approval'])[0]
state_level_variables.loc[state_level_variables['STNAME'] == 'UT(N)', 'Approval'] = \
    list(Approval[Approval['STNAME'] == 'UT']['Approval'])[0]
state_level_variables.loc[state_level_variables['STNAME'] == 'UT(Y)', 'Approval'] = \
    list(Approval[Approval['STNAME'] == 'UT']['Approval'])[0]

# Add total cases
ALLcases = State_Data_Raw.groupby(['date']).sum()['#COVID-19 cases'].reset_index()
ALLcases['Date'] = pd.to_datetime(ALLcases['date'])
state_level_variables = state_level_variables.merge(ALLcases, on='Date')
state_level_variables['#COVID-19 cases'] = state_level_variables['#COVID-19 cases'] / 1e3
state_level_variables = state_level_variables.rename({'#COVID-19 cases': 'National_Cases'}, axis=1)

# cal = USFederalHolidayCalendar()
# holidays = cal.holidays(start='2020-01-01', end='2020-05-01').to_pydatetime()
state_level_variables.to_csv('state_level_variables_to_R1.csv', index=False)
# plt.hist(state_level_variables['ANum_Trips'])
# plt.show()
#
# state_level_variables.drop_duplicates(subset=['STNAME']).describe()

# Describe
state_level_variables = pd.read_csv('state_level_variables_to_R1.csv', index_col=0)
state_level_variables.describe().T.to_csv('state_level_variables_desc.csv')
