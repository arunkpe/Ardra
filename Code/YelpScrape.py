#!/usr/bin/env python
#encoding = utf-8

from lxml import html  
import requests  
import csv
import time
import os
import bs4.dammit
from bs4.dammit import UnicodeDammit
import sys

def yelpRestaurauntList():
    yelpBusinessID = []
    goldReviewDate =[]
    with open('yelp_infile.csv', 'r') as fyelp:
        reader = csv.reader(fyelp, delimiter = ',')
        for row in reader:
            yelpBusinessID.append(row[2])
            goldReviewDate.append(row[5])
    return yelpBusinessID, goldReviewDate



def yelpReviewDetails(yelpBusinessID):
    #If you want to use proxy servers!
    auth = requests.auth.HTTPProxyAuth('proxyman007', '')
    http_proxy  = "http://open.proxymesh.com:31280"
    proxyDict = { 
                  "http"  : http_proxy 
                  #"https" : https_proxy, 
                  #"ftp"   : ftp_proxy
                }
    #open a csv file per restauraunt and generate a header
    reviewFile = 'review_' + yelpBusinessID + '.csv'
    with open(reviewFile, 'w',newline = '') as fin:
        writer = csv.writer(fin, delimiter = ',')
        writer.writerow(['reviewer_name','reviewer_id','review_date','rating_review','friends_count','total_reviews','useful_count','funny_count','cool_count','recommend_by_yelp','review_text'])
    fin.close()
    
    #Get number of pages, restauraunt type, cost of a meal etc.
    webPage = 'http://www.yelp.com/biz/' + yelpBusinessID + '?sort_by=date_desc'
    #page = requests.get(webPage,proxies = proxyDict,auth=auth)
    page = requests.get(webPage)
    tree = html.fromstring(page.text)
    avgRate     = tree.xpath('.//meta[@itemprop="ratingValue"]/@content')[0]
    numReviews  = tree.xpath('.//span[@itemprop="reviewCount"]/text()')[0]
    cusineType  = tree.xpath('//span[@class="category-str-list"]/a/text()')
    
    #This will get the number of pages of review
    num_pages = ''.join(tree.xpath('//div[@class="page-of-pages"]/text()'))
    start = num_pages.find('of') + 3
    last_page = int(num_pages[start:])
    
    #Generate a list of review URLs
    url_part1   = 'http://www.yelp.com/biz/' + yelpBusinessID 
    url_part2   = '?start='
    url_list    = [webPage]
    sort_by     = '&sort_by=date_desc'
    for i in range(2,last_page+1):
        url_next = url_part1 + url_part2 + str((i-1)*40) + sort_by 
        url_list.append(url_next)
    #Generate the CSV files with the details on reviews!    
    getRecommmendedReviews(url_list,reviewFile)    


    #Get number of Not recommended reviews
    webPage = 'http://www.yelp.com/not_recommended_reviews/' + yelpBusinessID
    page = requests.get(webPage)
    tree = html.fromstring(page.text)
    
    #This will get the number of pages of Not recommended reviews
    num_pages = ''.join(tree.xpath('//div[@class="page-of-pages"]/text()'))
    start = num_pages.find('of') + 3
    last_page = int(num_pages[start:start+4])
    
    #Generate a list of review URLs
    url_part1   = webPage
    url_part2   = '?not_recommended_start='
    url_list    = [webPage]
    for i in range(2,last_page+1):
        url_next = url_part1 + url_part2 + str((i-1)*10) 
        url_list.append(url_next)
    #Generate the CSV files with the details on not recommended reviews!    
    getNotRecommendedReviews(url_list,reviewFile)    
    return


def getRecommmendedReviews(url_list,reviewFile):
    #Crawl thru all the review URLs and get the review details    
    for links in url_list:
        review =[]
        #tree = html.parse(pages)
        getPage = requests.get(links)
        pages   = UnicodeDammit(getPage.text,is_html=True)
        #tree    = html.fromstring((pages.unicode_markup).encode("utf-8","ignore"))
        tree    = html.fromstring(pages.unicode_markup)
        
        reviewer    = tree.xpath('.//li[@class="user-name"]/a/text()')
        #reviewerID  = [name[21:] for name in (tree.xpath('.//li[@class="user-name"]/a//@href'))]#Yelp makes it difficult to extract this for Non recommended reviews!
        reviewerID  = tree.xpath('.//li[@class="user-name"]/a//@data-hovercard-id') #Use the Hovercard ID in lieu of userID - this is available for all reviews!
        reviewDate  = tree.xpath('.//meta[@itemprop="datePublished"]/@content')
        #eliteStatus = tree.xpath('.//li[@class="is-elite"]/a/text()')
        ratings     = tree.xpath('.//meta[@itemprop="ratingValue"]/@content')[1::1] #skip the first meta tag - that is the average rating over all users
        friendCount = tree.xpath('.//span[@class ="i-wrap ig-wrap-common i-friends-orange-common-wrap"]//text()')[1::3] #every third reading is the actual friend count
        reviewCount = tree.xpath('.//span[@class ="i-wrap ig-wrap-common i-star-orange-common-wrap"]//text()')[1::3] #every third reading is the actual sum count of all reviews
        #User reputation: We first extract all the elements within the jscript and then get the text from it 
        usefulCount = [u.text for u in (tree.xpath('.//div[@class = "review-footer clearfix"]//span[@class ="i-wrap ig-wrap-common i-ufc-useful-common-wrap button-content"]//span[@class="count"]'))]
        funnyCount  = [u.text for u in (tree.xpath('.//div[@class = "review-footer clearfix"]//span[@class ="i-wrap ig-wrap-common i-ufc-funny-common-wrap button-content"]//span[@class="count"]'))]
        coolCount   = [u.text for u in (tree.xpath('.//div[@class = "review-footer clearfix"]//span[@class ="i-wrap ig-wrap-common i-ufc-cool-common-wrap button-content"]//span[@class="count"]'))]
        recommend   =  [1 for i in range(len(reviewer))]    
        for reviewUnstruct in tree.xpath('//p[@itemprop="description"]'):
            review.append(reviewUnstruct.text_content())
        consolidateReview = zip(reviewer,reviewerID,reviewDate,ratings,friendCount,reviewCount,usefulCount,funnyCount,coolCount,recommend,review)    
        time.sleep(5)
        #Write review details to CSV file
        with open(reviewFile, 'a',newline = '',encoding='utf-8-sig') as fin:
            writer = csv.writer(fin, delimiter = ',')
            writer.writerows(consolidateReview)
        fin.close()
    return

def getNotRecommendedReviews(url_list,reviewFile):
    #Crawl thru all the review URLs and get the not recommended review details    
    review =[]
    for links in url_list:
        tree        = html.parse(links)   
        reviewer    = tree.xpath('.//span[@class="user-display-name"]//text()')[:10]
        #reviewerID  = [name[21:] for name in (tree.xpath('.//li[@class="user-name"]/a//@href'))]#Yelp makes it difficult to extract this for Non recommended reviews!
        reviewerID  = tree.xpath('.//span[@class="user-display-name"]//@data-hovercard-id')[:10] #Use the Hovercard ID in lieu of userID - this is available for all reviews!
        reviewDate  = [rdate.strip() for rdate in (tree.xpath('.//span[@class="rating-qualifier"]//text()'))][:10] 
        #eliteStatus = tree.xpath('.//li[@class="is-elite"]/a/text()')
        ratings     = [int(rating[:1]) for rating in (tree.xpath('.//img[@class="offscreen"]/@alt'))][:10] #Strip unwanted String - "rating" etc.!
        friendCount = tree.xpath('.//span[@class ="i-wrap ig-wrap-common i-friends-orange-common-wrap"]//text()')[1::3][:10] #every third reading is the actual friend count
        reviewCount = tree.xpath('.//span[@class ="i-wrap ig-wrap-common i-star-orange-common-wrap"]//text()')[1::3][:10] #every third reading is the actual sum count of all reviews
        #User reputation: Yelp strips out the usefulness of a review for those reviews which it does not recommend! 
        usefulCount = [0 for i in range(len(reviewer))]
        funnyCount  = [0 for i in range(len(reviewer))]
        coolCount   = [0 for i in range(len(reviewer))]
        recommend   = [0 for i in range(len(reviewer))]
        for reviewUnstruct in tree.xpath('//p[@lang="en"]'):
            review.append(reviewUnstruct.text_content())
        consolidateReview = zip(reviewer,reviewerID,reviewDate,ratings,friendCount,reviewCount,usefulCount,funnyCount,coolCount,recommend,review)    
        time.sleep(5)    
        #Write review details to CSV file
        with open(reviewFile, 'a',newline = '',encoding='utf-8-sig') as fin:
            writer = csv.writer(fin, delimiter = ',')
            writer.writerows(consolidateReview)
        fin.close()
    return

def appendGoldDate(yelpBusinessID,jgReviewDate) :
    csvfile        = 'review_' + yelpBusinessID + '.csv'
    new_csvfile     = 'new_review_' + yelpBusinessID + '.csv'
    goldReviewDate = jgReviewDate
   
    with open(csvfile,'r',encoding='utf-8-sig') as csvinput:
        with open(new_csvfile, 'w',encoding='utf-8-sig') as csvoutput:
            writer = csv.writer(csvoutput, lineterminator='\n')
            reader = csv.reader(csvinput)
            all = []
            row = next(reader)
            row.append('gold_reviewDate')
            all.append(row)
    
            for row in reader:
                row.append(goldReviewDate)
                all.append(row)
                
            writer.writerows(all)
            
    os.remove(csvfile) # not needed on unix
    os.rename('new_'+csvfile, csvfile)
    return
        

def generateReviewFiles():
    yelpBusinessID, goldReviewDate = yelpRestaurauntList()
    for restauraunt in yelpBusinessID:
        jgReviewDate = goldReviewDate[yelpBusinessID.index(restauraunt)]
        yelpReviewDetails(restauraunt)
        print(restauraunt)
        appendGoldDate(restauraunt,jgReviewDate)
        time.sleep(120)
    return    
    
generateReviewFiles()