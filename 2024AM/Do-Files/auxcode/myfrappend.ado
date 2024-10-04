program myfrappend
    version 16

    syntax varlist, from(string)

    confirm frame `from'

    foreach var of varlist `varlist' {
        confirm var `var'
        frame `from' : confirm var `var'
    }

    frame `from': local obstoadd = _N

    local startn = _N+1
    set obs `=_N+`obstoadd''

    foreach var of varlist `varlist' {
        replace `var' = _frval(`from',`var',_n-`startn'+1) in `startn'/L
    }
end
