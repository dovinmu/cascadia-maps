import requests
from bs4 import BeautifulSoup
import time
import re
from pandas import DataFrame
'''
Scrape all 3365 hikes from wta.org at one every 10 seconds (for a total runtime of ~9 hours) to get a dataset.
'''

hike_dict = {}
total = 3365
total = 30
for i in range(0, total, 30):
    r = requests.get('http://www.wta.org/go-hiking/hikes?b_start:int={}'.format(i))
    soup = BeautifulSoup(r.text, 'lxml')
    for item in soup.findAll('div', attrs={'class':'search-result-item'}):
        name = item.findAll('div')[9].find('span').text
        link = item.find('a').get('href')
        trail_r = requests.get(link)
        trail_soup = BeautifulSoup(trail_r.text, 'lxml')
        coords = trail_soup.find(text=re.compile('Co-ordinates')).parent()[0:2]
        coords = [coord.text for coord in coords]
        hike_dict[name] = (link, coords[0], coords[1])
        print(name)
        #scrape gently
        time.sleep(10)
df = DataFrame(hike_dict, index=['link', 'lat', 'lon'])
