# -*- coding: utf-8 -*-
# @Author: Arius
# @Email: arius@qq.com
# @Date:   2024-11-14
import sys
import time
import os
import sqlite3
import requests
import re
from datetime import datetime
from bs4 import BeautifulSoup
import logging
from const import DB_FILE, HEADERS, PROXIES

logging.basicConfig(
    # filename='manga.log',
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s %(module)s - %(funcName)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
)


def decode_utf8_for_db(aStr):
    return aStr.encode('utf-8', 'ignore').decode('utf-8').replace("'", "''")


def create_db():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute(
        '''
        CREATE TABLE IF NOT EXISTS WH_DATA(
            id           TEXT,
            key          TEXT,
            str          TEXT,
            num          INTERGER,
            UNIQUE(id, key)
    );
    '''
    )
    print("Table created successfully")
    cursor.close()
    conn.commit()
    conn.close()


# https://w.wallhaven.cc/full/5g/wallhaven-5gq727.jpg
# https://wallhaven.cc/w/5gq727
def parse_detail(html):
    soup = BeautifulSoup(html, 'html.parser')
    main_color = [l['style'].replace('background-color:', '') for l in soup.findAll('li', attrs={"class": "color"})]
    tags = [{"name": a.get_text(), "link": a["href"]} for a in soup.findAll('a', attrs={"rel": "tag"})]

    purity = soup.find('span', attrs={"class": "purity"}).get_text()
    favorites_str = soup.find('dt', string='Favorites').find_next('dd').get_text()
    favorites = int(favorites_str.replace(',', ''))
    views_str = soup.find('dt', string='Views').find_next('dd').get_text()
    views = int(views_str.replace(',', ''))
    upload_str = soup.find('time')['title']
    upload = int(datetime.strptime(upload_str, '%Y-%m-%d %H:%M:%S').timestamp())
    category = soup.find('dt', string='Category').find_next('dd').get_text()
    wallpaper = soup.find('img', attrs={'id': 'wallpaper'})
    width = wallpaper['data-wallpaper-width']
    height = wallpaper['data-wallpaper-height']
    pic_id = wallpaper['data-wallpaper-id']
    src = wallpaper['src']
    thumb = f"https://th.wallhaven.cc/small/{pic_id[:2]}/{pic_id}.jpg"
    values = [['tag', tag['name'], tag['link'], 0] for tag in tags] + [
        [pic_id, 'color', ','.join(main_color), 0],
        [pic_id, 'purity', purity, 0],
        [pic_id, 'thumb', thumb, 0],
        [pic_id, 'src', src, 0],
        [pic_id, 'width', width, int(width)],
        [pic_id, 'height', height, int(height)],
        [pic_id, 'category', category, 0],
        [pic_id, 'upload', upload_str, upload],
    ]
    update_values = [
        [pic_id, 'tag', ','.join([tag['name'] for tag in tags]), 0],
        [pic_id, 'view', views_str, views],
        [pic_id, 'favorite', favorites_str, favorites],
    ]
    return values, update_values


def loop_request(url, cache_key=None, proxies=None):
    with open("handle_url.log", "a", encoding="utf-8") as file:
        file.write(f"{url}\n")

    if cache_key:
        cache_key = f'./cache/{cache_key}'
        if os.path.isfile(cache_key):
            logging.info(f'Load cache: {cache_key}')
            return open(cache_key).read()
    counter = 0
    while True:
        counter += 1
        try:
            logging.info(f'Loading {str(counter).zfill(3)}: {url}')
            response = requests.get(
                url,
                {
                    **HEADERS,
                },
                proxies=proxies,
                timeout=10,
            )
            if response.status_code == 200:
                if cache_key:
                    with open(cache_key, 'w') as f:
                        f.write(response.text)
                return response.text
            else:
                logging.info(f'Request Error {str(counter).zfill(3)}: {url}: {response.status_code}')
        except Exception as e:
            logging.error('request Error', url, e)
            # traceback.print_exc()
            time.sleep(2)


def get_detail(pic_id, refresh=False):
    domain = 'https://wallhaven.cc'
    url = f'/w/{pic_id}'
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute('select id from WH_DATA where id=? COLLATE NOCASE limit 1', (pic_id,))
    check = cursor.fetchall()
    if check and not refresh:
        logging.info(f"[{pic_id}] existed")
        return
    logging.info(f"[{pic_id}] not exist")
    html = loop_request(f'{domain}{url}', cache_key=f'{url}.html', proxies=PROXIES)
    values, update_values = parse_detail(html)
    for row in update_values:
        cursor.execute(
            f'''
        DELETE FROM WH_DATA WHERE id = '{row[0]}' and key = '{row[1]}'
        '''
        )
    values_str = ','.join(
        [
            f"('{row[0]}', '{decode_utf8_for_db(row[1])}', '{decode_utf8_for_db(row[2])}', {row[3]})"
            for row in values + update_values
        ]
    )
    sql = f'''
        INSERT OR IGNORE INTO WH_DATA (
            id,
            key,
            str,
            num
        )
        VALUES {values_str}
    '''
    cursor.execute(sql)
    cursor.close()
    conn.commit()
    conn.close()


def get_next_url(url):
    next_url = f"{url}&page=2"
    page = 1
    if result := re.search('page=([0-9]+)', url):
        page = int(result.group(1))
        next_url = re.sub('(page=[0-9]+)', 'page=' + str(int(page) + 1), url)
    logging.info(f'Done: {page}')
    return next_url


def load_page(url, counter=0):
    html = loop_request(url, proxies=PROXIES)
    soup = BeautifulSoup(html, 'html.parser')
    ls = soup.findAll(
        'figure',
    )
    for i in ls:
        if 'data-wallpaper-id' in i.attrs:
            wallpaper_id = i.attrs['data-wallpaper-id']
            logging.info(f'Loading: {wallpaper_id}')
            get_detail(wallpaper_id)
    if counter != 1 and len(ls) > 1:
        next_url = get_next_url(url)
        # print(result, url, next_url)
        while True:
            try:
                load_page(next_url, counter - 1)
                break
            except Exception as e:
                print(e)
                next_url = get_next_url(next_url)


if __name__ == "__main__":
    # https://wallhaven.cc/search?categories=111&purity=110&atleast=1920x1080&ratios=landscape&sorting=date_added&order=desc&ai_art_filter=1&page=5
    func = sys.argv[1]
    props = ', '.join([f"'{p}'" for p in sys.argv[2:] if p])
    cmd = f"{func}({props})"
    eval(cmd)
