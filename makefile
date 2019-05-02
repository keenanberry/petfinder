CITY=austin
STATE=tx
URL=https://www.petfinder.com/search/dogs-for-adoption/us/$(STATE)/$(CITY)/
DATE=$(shell date +%x | sed 's/\//-/g')

all: petfinder.tsv

pages: printSource.py
	mkdir -p $@

pages/home.txt: | pages
	python2.7 printSource.py $(URL) > $@

fetch_pages.sh: pages/home.txt
	echo 'n=$$(cat pages/home.txt | egrep -o "Select Page, PAGE 1/[0-9]+" | sed "s/[^/]*\/\([0-9]*\)/\1/") ;\
	for ((i=2;i<=n;i++)); do python2.7 printSource.py $(URL)?page="$$i" > pages/page"$$i".txt; sleep 15; done' > $@

pages/paws: fetch_pages.sh
	bash fetch_pages.sh; touch $@

dogs: pages/paws
	mkdir -p $@

fetch_puppers.sh: | dogs
	find pages -name '*.txt' | xargs egrep -h 'petCard-link' | egrep -o 'href="[^"]+"' | sed 's/href="\(https:\/\/www\.petfinder\.com\/dog\/\)\([^/]*\)\([^"]*\)"/wget \1\2\3 -O dogs\/\2.txt\nsleep 10/' > $@

dogs/treats: fetch_puppers.sh
	bash fetch_puppers.sh; touch $@

dog_data: dogs/treats
	mkdir -p $@

dog_data/$(DATE)_petfinder.txt: | dog_data
	echo -e 'id|distance|primary_breed|secondary_breed|is_mixed_breed|primary_color|age|sex|size|coat_length|name|description|primary_photo_url|photo_urls|adoption_status|attributes|special_needs_notes|good_with_children|good_with_dogs|good_with_cats|good_with_other_animals|public_adoption_fee|adoption_fee_waived|organization|label' > $@ ;\ 
	find dogs/ -name '*.txt' | xargs egrep -h 'global.PF.pageConfig' | egrep -o '"distance":.+$$' | sed -e 's/\("primary_breed"\):null/\1:{"id":000,"name":"null"}/' | sed -e 's/\("secondary_breed"\):null/\1:{"id":000,"name":"null"}/' | sed -e 's/\("description"\):null/\1:"null"/' | sed -e 's/"distance":\([^,]*\),"animal":{"id":\([^,]*\),"type":{[^}]*},"species":{[^}]*},"primary_breed":{[^,]*,"name":\([^}]*\)},"secondary_breed":{[^,]*,"name":\([^}]*\)},"is_mixed_breed":\([^,]*\),[^,]*,"primary_color":\([^,]*\),[^,]*,[^,]*,"age":\([^,]*\),"sex":\([^,]*\),/\2|\1|\3|\4|\5|\6|\7|\8|/' -e 's/"size":\([^,]*\),"coat_length":\([^,]*\),"name":\([^,]*\),"description":"\([^"]*\)",[^,]*,"primary_photo_url":\([^,]*\),[^,]*,"photo_urls":\[\([^]]*\)\],[^,]*,"adoption_status":\([^,]*\),"attributes":\[\([^]]*\)\],/\1|\2|\3|"\4"|\5|\6|\7|\8|/' -e 's/"special_needs_notes":\([^,]*\),[^{]*{"good_with_children":\([^,]*\),"good_with_dogs":\([^,]*\),"good_with_cats":\([^,]*\),"good_with_other_animals":\([^,]*\),[^,]*,[^,]*,"public_adoption_fee":\([^,]*\),"adoption_fee_waived":\([^,]*\),[^}]*}[^}]*}[^}]*}[^}]*}[^}]*}[^}]*},"organization":{"name":"\([^"]*\)"\(.*$$\)/\1|\2|\3|\4|\5|\6|\7|\8/' | awk 'BEGIN{FS="|";}{if(NF==24) print $$0;}' | sort -t '|' -k 1,1 >> $@

.PHONY: FORCE
FORCE:dog_data/$(DATE)_petfinder.txt

petfinder.tsv: FORCE
	c=$$(ls dog_data/ | wc -l); if ((c > 1)) ;\ 
	then prev=$$(ls dog_data/ | egrep -v '$(DATE)'); sed -i 's/|..*/|not-adopted/' dog_data/$(DATE)_petfinder.txt; join -a 1 -t '|' dog_data/$$prev dog_data/$(DATE)_petfinder.txt | awk 'BEGIN{FS="|";}{if(NF < 25){print $$0"|adopted"}else{print $$0}}' | cut -d '|' -f26 --complement | tr "|" "\t" > $@ ;\
	else cat dog_data/*.txt | tr "|" "\t" > $@; fi;

.PHONY: clean
clean: petfinder.tsv
	rm -r pages dogs; rm -f *.sh
