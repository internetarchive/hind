# nice way to make small gifs :)

```sh
brew install  asciinema  agg

asciinema rec hind.cast

# manually chopped out a lot of delay lines in `hind.cast`, then:

cat hind.cast |perl -ne 'chop; print unless m/^\[([\d\.]+)(.*)$/; $x=$1; $x-=8 if ($x>132); $x-=6 if ($x>120); $x-=30 if ($x>75); $x-=45 if ($x>69); $x-=21.5 if ($x>20); print "[$x$2\n";' >| short.cast

# then remove trailing `[` on top line
# I also did just a bit of manual finesse ;-)
# updated the "width" topline

agg --theme asciinema --speed 1.1 short.cast hind.gif
```
