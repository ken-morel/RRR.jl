const TEMPLATES = Dict(
    :jl   => a -> `julia -q $a rrr.jl`,
    :py   => a -> `python -u $a rrr.py`,
    :bash => a -> `bash $a rrr.sh`,
    :zsh  => a -> `zsh $a rrr.sh`,
    :fish => a -> `fish $a rrr.fish`,
    :js   => a -> `node $a rrr.js`,
    :ts   => a -> `ts-node $a rrr.js`
)