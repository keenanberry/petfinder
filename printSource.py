#!/usr/bin/env python

from selenium import webdriver
import sys, time

url = sys.argv[1]

options = webdriver.ChromeOptions();
options.add_argument('headless');
driver = webdriver.Chrome(options=options)
driver.get(url)

html = driver.page_source
print(html)

driver.close();
driver.quit();
