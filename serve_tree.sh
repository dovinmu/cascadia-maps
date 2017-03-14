atom src/washington_ecoregions.coffee
coffee -o lib/ -cw src/ &
python -m http.server &
xdg-open http://127.0.0.1:8000
