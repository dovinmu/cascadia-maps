atom src/washington_ecoregions.coffee
coffee -o lib/ -cw src/ &
python -m http.server 8013 &
xdg-open http://127.0.0.1:8013
