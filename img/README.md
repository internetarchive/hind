# nice way to make small gifs :)

```sh
brew install  asciinema  agg

asciinema rec hind.cast

# manually chopped out some delay and ending lines in `hind.cast`, then:

cat hind.cast |perl -ne 'chop; print unless m/^\[([\d\.]+)(.*)$/; $x=$1; $x-=5 if ($x>17); $x-=10.5 if ($x>10.5); print "[$x$2\n";' >| short.cast

# manually, for top line remove trailing `[` -- and I updated the "width" and "height".

agg --theme asciinema --speed 1.1 short.cast hind.gif
```
