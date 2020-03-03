# BFREPL.jl

Brainf**k REPL in Julia.

## Installation

On Pkg REPL-mode:

```jl
(@v1.4) pkg> add https://github.com/antimon2/BFREPL.jl.git#for_julia_v14
```

And edit (or add 1 line to) `~/.julia/config/startup.jl` as below:

```
isnothing(Base.locate_package(Base.PkgId(Base.UUID("051b4cde-c4a9-11e8-16f0-4944cc387625"), "BFREPL"))) || using BFREPL
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
