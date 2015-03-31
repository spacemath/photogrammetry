#!vanilla

# retrieve image pixels
pix = $blab.image.getPixels() #;

# brightness change
del = 0 

# brighten filter
brighten = (n) ->
    pix[i] += del for i in [n..n+2]

# runner
filter = (f) ->
    f(k) for k in [0...pix.length] by 4

# apply filter
filter brighten #;

# insert pixels
$blab.image.putPixels(pix)
