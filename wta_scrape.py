import requests
from bs4 import BeautifulSoup
import time
import re
from pandas import DataFrame
'''
Scrape all 3365 hikes from wta.org at one every 5 seconds (for a total runtime of ~4.5 hours) to get a dataset.
'''

try:
    df = DataFrame.from_csv('wta_hikes.csv')
    hike_dict = df.T.to_dict()
    with open('start_idx') as f:
        start = int(f.read())
except:
    hike_dict = {}
    start = 0

total = 3365
for i in range(start, total, 30):
    r = requests.get('http://www.wta.org/go-hiking/hikes?b_start:int={}'.format(i))
    soup = BeautifulSoup(r.text, 'lxml')
    for item in soup.findAll('div', attrs={'class':'search-result-item'}):
        #name = item.findAll('div')[9].find('span').text
        try:
            name = item.find('a', attrs={'class':'listitem-title'}).text.strip()
        except:
            name = 'UNKNOWN'
        link = item.find('a').get('href')
        try:
            trail_r = requests.get(link)
        except:
            time.sleep(5)
            trail_r = requests.get(link)
        trail_soup = BeautifulSoup(trail_r.text, 'lxml')
        try:
            coords = trail_soup.find(text=re.compile('Co-ordinates')).parent()[0:2]
            coords = [float(coord.text) for coord in coords]
        except:
            coords = [float('nan'), float('nan')]
        try:
            rating = float(trail_soup.find('div', attrs={'class':'current-rating'}).text.split(' ')[0])
        except:
            rating = float('nan')
        try:
            ratingCount = trail_soup.find('div', attrs={'class':'rating-count'}).text.split(' ')[0].replace('(', '')
        except:
            ratingCount = float('nan')
        try:
            region = item.find('h3', attrs={'class':'region'}).text
        except:
            region = 'region not found'
        hike_dict[name] = (link, region, rating, ratingCount, coords[0], coords[1])
        #print(len(hike_dict), name + ':', region, '\n', rating, ',', ratingCount, 'votes', coords)
        print('{}. {}: {}\n\t{} from {} votes. {}'.format(len(hike_dict), name, region, rating, ratingCount, coords))
        #scrape gently
        time.sleep(5)
    df = DataFrame(hike_dict, index=['link', 'region', 'rating', 'ratingCount', 'lat', 'lon']).T
    df.to_csv('wta_hikes.csv')
    with open('start_idx','w') as f:
        f.write(str(i + 30))
    print('\n\twrote out {} hikes\n'.format(len(df)))
