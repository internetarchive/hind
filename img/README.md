# nice way to make small gifs :)

```sh
brew install  asciinema  agg

asciinema rec hind.cast

# manually chopped out a lot of delay lines in `hind.cast`, then:

cat hind.cast |perl -ne 'chop; print unless m/^\[([\d\.]+)(.*)$/; $x=$1; $x-=20 if ($x>86); $x-=7 if ($x>62); $x-=36.5 if ($x>50); $x-=3 if ($x>7.3); print "[$x$2\n";' >| short.cast

# then remove trailing `[` on top line
# I also did just a bit of manual finesse ;-)
# updated the "width" topline

agg --theme asciinema --speed 1.1 short.cast hind.gif
```
