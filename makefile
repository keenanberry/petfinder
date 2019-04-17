CITY = austin
STATE = tx
URL = https://www.petfinder.com/search/dogs-for-adoption/us/$(STATE)/$(CITY)/

#all: petfinder.tsv
#petfinder_timestamped.tsv: dogs/treats
	#find dogs -name '*.txt' | xargs egrep

dogs/treats: fetch_puppers.sh
	bash fetch_puppers.sh; touch $@

fetch_puppers.sh: | dogs
	find pages -name '*.txt' | xargs egrep -h 'petCard-link' | egrep -o 'href="[^"]+"' | sed 's/href="\(https:\/\/www\.petfinder\.com\/dog\/\)\([^/]*\)\([^"]*\)"/wget \1\2\3 -O dogs\/\2.txt\nsleep 15/' > $@

dogs: pages/paws
	mkdir -p $@

pages/paws: fetch_pages.sh
	bash fetch_pages.sh; touch $@

fetch_pages.sh: pages/html.txt
	@echo 'n=$$(cat pages/home.txt | egrep -o "Select Page, PAGE 1/[0-9]+" | sed "s/[^/]*\/\([0-9]*\)/\1/") ;\
	for ((i=2;i<=n;i++)); do python3 printSource.py $(URL)?page="$$i" > pages/page"$$i".txt; sleep 15; done' > $@	

pages/home.txt: | pages
	python3 printSource.py $(URL) > $@

pages: printSource.py
	mkdir -p $@

