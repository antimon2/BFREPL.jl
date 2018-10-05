# BFREPL.jl

Brainf**k REPL in Julia.

## Installation

On Pkg REPL-mode:

```jl
(v1.0) pkg> add https://github.com/antimon2/BFREPL.jl.git
```

And edit (or add 1 line to) `~/.julia/config/startup.jl` as below:

```
using Pkg; haskey(Pkg.installed(), "BFREPL") && using BFREPL
```

## Example

```
$ julia
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.0.1 (2018-09-29)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia> # type `Ctrl` + `B`

bf> >++[>++[>+++[>+++>++++++>+<<<-]<-]<-]>>>>+.<----.[<-<---<---<+>>>>-]<++.++++<-------.<+++++.<.>>>>>+.<<<<<[>-->->>>+>+<<<<<<-]>>----.>>>++.---.<<<<----.>>>>>++.
I ♥ Julia.

julia > # ↓ lc_echo

bf> >>,+[-[-<+<+>>]++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    +<[->->+<[>-]>[>]<[-<<[->+<]++++++++++++++++++++++++++[->>+<[>-]>[>]<[-<<<+++++
    +++++++++++++++++++++++++++>[-]>>]<-<]>>]<<]<.[-]>>,+]
aBcDe  # ← input line
abcde  # ← output
^D  # `Ctr`l+`D` to exit

julia> 
```

## Limitations

BFREPL.jl can work with Julia 1.0.
