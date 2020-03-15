#

domain=kintm.gq
url=https://www.worldometers.info/coronavirus/index.php
mdfile=$HOME/github.com/covid19/covid19.md
echo ${mdfile%/*}

# -------------------------
# get the data ...
date=$(date +%D)
tic=$(date +%s)
qm0=$(ipfs add -Q $url)
echo tic: $tic
echo url: https://ipfs.blockringtm.ml/ipfs/$qm0
# -------------------------
wget -P coronavirus -S -N -nd -nH -E -H  -k -K -p  -o ${mdfile%/*}/log.txt $url 
mv coronavirus/index.php.html coronavirus/index.html
rm coronavirus/robots.txt.*
qm=$(ipfs add -Q -r coronavirus)
echo "- \\[$date]: [$qm0](https://cloudflare-ipfs.com/ipfs/$qm)" >> $mdfile;
echo url: https://yoogle.com:8197/ipfs/$qm
cat $mdfile | uniq > $mdfile~
mv $mdfile~ $mdfile
# -------------------------
if [ -e covid.htm ]; then
mtime=$(stat -c "%Y" covid.htm)
if expr $tic - $mtime \> 21600; then
 echo "info: tic - mtime > 21600"
 rm covid.htm
else
 echo "reuse: covid.htm $(stat -c '%y' covid.htm)"
fi
fi
if [ ! -e covid.htm ]; then
curl -s $url > covid.htm
qm=$(ipfs add -Q covid.htm)
echo qm: $qm
fi
# -------------------------
# extract data
pandoc -f html -t json covid.htm > covid.json
case=$(cat covid.json | xjson blocks.1.c.1.2.c.1.0.c.1.2.c.1.71.c.0.c)
pandoc -f html -t markdown covid.htm > covid.md
#data="$(echo '/Switzerland/+1,/Switzerland/+5p' | ed covid.md)"
echo '/Switzerland/+1,/Switzerland/+7p' | ed covid.md | sed -e 's/,//' > covid.dat
if tail -1 covid.dat | grep -q "/^[+0-9]/"; then
 tail -1 covid.dat
paste -d' ' - covid.dat <<EOT | eyml > covid.yml
cases:
deaths:
recovered:
active:
densit:
EOT
else
paste -d' ' - covid.dat <<EOT | eyml > covid.yml
cases:
ncases:
deaths:
ndeaths:
recovered:
active:
densit:
EOT
fi
eval $(cat covid.yml)
echo "$tic,$cases,$ncases,$deaths,$ndeaths,$recovered,$active,$densit" >> covid.csv

# -------------------------
# filing
cd ${mdfile%/*}
eval $(perl -S fullname.pl -a $qm | eyml)
git config user.name "$fullname"
git config user.email $user@$domain
echo "gituser: $(git config user.name) <$(git config user.email)>"

git add $mdfile covid.md covid.json covid.yml covid.csv
pandoc -f markdown -t html $HOME/github.com/covid19/covid19.md -o covid19.html
qm=$(ipfs add -Q -w covid19.html)
pwd
cat > README.md <<EOF
# README: corona virus daily status ...

 $densit cases per 1M pop,\
 $cases Total cases in Switzerland ($active actives)

 $deaths deaths,
 $recovered recovered

last update : <https://ipfs.blockringtm.ml/ipfs/$qm/covid19.html>

source:
  - <https://www.bag.admin.ch/bag/fr/home/krankheiten/ausbrueche-epidemien-pandemien/aktuelle-ausbrueche-epidemien/novel-cov/situation-schweiz-und-international.html>
  - <https://twitter.com/BAG_OFSP_UFSP>
  - <https://www.worldometers.info/coronavirus/>
  - <https://duckduckgo.com/?q=switzerland+progression+coronavirus>
  

EOF
git add README.md
git commit -m "pandemy status on $date"
git push
echo $tic: $qm >> $HOME/etc/mutables/covid.log
# -------------------------
