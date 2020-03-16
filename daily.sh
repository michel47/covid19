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
# old way ...

if grep -q -e '^Switzerland$' covid.md; then
echo '/Switzerland/+1,/Switzerland/+7p' | ed covid.md | sed -e 's/,//' > covid.dat
if tail -1 covid.dat | grep -q "^[+0-9]" ; then
 tail -1 covid.dat
  grep -e '^[+0-9]' covid.dat > covid.data
  rename covid.data covid.dat
fi
# new way (one-line table)
else
grep -e '^  Switzerland' covid.md | sed -e 's/,//g' -e 's/  */\n/g' | tail +3 | tee covid.dat
fi
n=$(wc -l covid.dat | cut -d' ' -f1)
if expr "$n" = 5 ; then
paste -d' ' - covid.dat <<EOT | eyml > covid.yml
cases:
deaths:
recovered:
active:
densit:
EOT
else
echo n: $n
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
# snapshot of page...
wget -P coronavirus -S -N -nd -nH -E -H  -k -K -p  -o ${mdfile%/*}/log.txt $url 
sed -e 's/index.php.html/index.html/g' coronavirus/index.php.html > coronavirus/index.html
rm coronavirus/robots.txt.*
qm1=$(ipfs add -Q -r coronavirus)
echo "- \\[$date]: ${active}/${cases}cases [$qm0](https://cloudflare-ipfs.com/ipfs/$qm1) [data](covid.yml),[csv](covid.csv)" >> covid19u.md
echo url: https://yoogle.com:8197/ipfs/$qm
cat covid19u.md | sort -r | uniq > $mdfile
# -------------------------
# filing
cd ${mdfile%/*}
eval $(perl -S fullname.pl -a $qm1 | eyml)
git config user.name "$fullname"
git config user.email $user@$domain
echo "gituser: $(git config user.name) <$(git config user.email)>"

git add $mdfile covid19u.md covid.md covid.json covid.yml covid.csv
pandoc -f markdown -t html $HOME/github.com/covid19/covid19.md -o covid19.html
qm=$(ipfs add -Q -w covid19.html)
pwd
cat > README.md <<EOF
# README: corona virus daily status in Switzerland ...

## on $(date +"%D %T") ([snapshot](https://ipfs.io/ipfs/$qm1))

 $densit cases per 1M pop,<br>
 $cases Total cases in Switzerland ($active actives)

 $deaths deaths,
 $recovered recovered (resurected ?)

last update : <https://ipfs.blockringtm.ml/ipfs/$qm/covid19.html>

 csv file [covid.csv](covid.csv)<br>
 yaml file [covid.yml](covid.yml)

sources:
  - <https://twitter.com/BAG_OFSP_UFSP>
  - <https://www.bag.admin.ch/bag/fr/home/krankheiten/ausbrueche-epidemien-pandemien/aktuelle-ausbrueche-epidemien/novel-cov/situation-schweiz-und-international.html>
  - <https://en.wikipedia.org/wiki/2020_coronavirus_pandemic_in_Switzerland>
  - <https://www.worldometers.info/coronavirus/>
  - <https://duckduckgo.com/?q=switzerland+progression+coronavirus>
  - <https://gateway.ipfs.io/ipfs/$qm0>
  - <https://gateway.ipfs.io/ipfs/$qm1>
  - <https://gateway.ipfs.io/ipfs/$qm>
  

EOF
git add README.md
git status -uno .
datetime=$(date +"%D %T")
git commit -a -m "pandemy status on $datetime"
git push
echo $tic: $qm >> $HOME/etc/mutables/covid.log
# -------------------------
