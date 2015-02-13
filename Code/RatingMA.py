#!/usr/bin/env python
from __future__ import unicode_literals
import pandas as pd
import numpy as np
import os
import glob
import datetime as dt
import matplotlib.pylab as plt

os.chdir('.\\reviews')
path =os.getcwd()
allFiles = glob.glob(path + "/*.csv")

restaurantReviews = pd.DataFrame()
list = []
for file in allFiles:
    df = pd.read_csv(file,encoding='utf-8',header=0)
    df = df[df.review_date.notnull()]
    df = df[-df['review_date'].isin(['Updated review','Previous review'])]    
    list.append(df)
restaurantReviews = pd.concat(list, ignore_index=True)

restaurantReviews['review_date']     = pd.to_datetime(restaurantReviews['review_date'])
restaurantReviews['gold_reviewDate'] = pd.to_datetime(restaurantReviews['gold_reviewDate'])

restaurantReviews['days_after_Gold'] = restaurantReviews['review_date'] - restaurantReviews['gold_reviewDate']
restaurantReviews['days_after_Gold'] =(restaurantReviews['days_after_Gold'] / np.timedelta64(1, 'D')).astype(int)
restaurantReviews = restaurantReviews[(restaurantReviews.days_after_Gold >= -50) & (restaurantReviews.days_after_Gold <= 50)]

restaurantReviews['week_date'] = [date - dt.timedelta(date.weekday()) for date in restaurantReviews['review_date']]
restaurantReviews['year_month'] = [dt.date(revdate.year,revdate.month,1) for revdate in restaurantReviews['review_date']]

#print(restaurantReviews['rating_review'].describe())
#print(restaurantReviews['days_after_Gold'].describe())

#grouped = restaurantReviews.groupby(['week_date'])
#restaurantAggregate = grouped['rating_review'].agg(['mean', 'count'])

#grouped = restaurantReviews.groupby(['year_month'])
#restaurantAggregate = grouped['rating_review'].agg(['mean', 'count'])

grouped = restaurantReviews.groupby(['days_after_Gold'])
restaurantAggregate = grouped['rating_review'].agg(['mean', 'count'])

x1 = restaurantAggregate.index
x2 = restaurantAggregate.index
print(x1)
y1 = restaurantAggregate['mean']
y2 = restaurantAggregate['count']

plt.subplot(2, 1, 1)
plt.plot(x1, y1, 'k-')
#jGoldDate = dt.datetime(2011,9,22) - dt.timedelta((dt.datetime(2011,9,22)).weekday())
#print(jGoldDate)
#plt.plot(['2011-09-19',0], ['2011-09-19', 5], 'b-')
plt.title('Count and Average Yelp! Ratings')
plt.ylabel('Average Rating')

plt.subplot(2, 1, 2)
plt.plot(x2, y2, 'r-')
plt.ylabel('Number of Reviews')
plt.show()
