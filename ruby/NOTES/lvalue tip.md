while — very unfortunately — this

    irb(main):042:0> x,y=0,0
    => [0, 0]
    irb(main):044:0> if nil then x else y end = 1
    SyntaxError: compile error
    (irb):44: syntax error, unexpected '=', expecting $end
    if nil then x else y end = 1
                              ^
    	from (irb):44
    	from :0

does not work, this

    irb(main):048:0> x,y=[],[]
    => [[], []]
    irb(main):049:0> if nil then x else y end << 1
    => [1]
    irb(main):050:0> x
    => []
    irb(main):051:0> y
    => [1]

performs nicely.

i know the difference, but it's still controversial to me.