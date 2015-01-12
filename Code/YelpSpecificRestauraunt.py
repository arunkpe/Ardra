from yelpapi import YelpAPI
import argparse


consumer_key    =  'Xe2o3ORIw4qVZukzPb9Xjg'
consumer_secret =  'bWTI8gdDAvWFpQHPnteBDggQiEI'
token 		=  'O0q9O1_ugLaulzJeQm71jOSAPnSYLaCE'
token_secret    =  'S8Qsgy2mGZU8klGaB2Oz26AbFx4'

yelp_api = YelpAPI(consumer_key,consumer_secret,token,token_secret)
#
#Example search by location text and term. Take a look at http://www.yelp.com/developers/documentation/v2/search_api for
#the various options available.

print('***** 5 best rated restauraunts in Los Angeles, CA *****\n%s\n' % "yelp_api.search_query(term='restauraunts', location='los angeles, ', sort=2, limit=5)")
response = yelp_api.search_query(term='restauraunts',location='los angeles, ca', sort=2, limit=5)
print('region center (lat,long): %f,%f\n' % (response['region']['center']['latitude'], response['region']['center']['longitude']))
for business in response['businesses']:
    print('%s\n\tYelp ID: %s\n\trating: %g (%d reviews)\n\taddress: %s' % (business['name'], business['id'], business['rating'],business['review_count'], ', '.join(business['location']['display_address'])))           
print('\n-------------------------------------------------------------------------\n')

print("***** selected reviews for The Black Fig *****\n%s\n" % "yelp_api.business_query(id='the-black-fig-los-angeles')")
business = yelp_api.business_query(id='the-black-fig-los-angeles')
for review in business['reviews']:
    print('rating: %d\nexcerpt: %s\n' % (review['rating'], review['excerpt']))
print('\n-------------------------------------------------------------------------\n')

