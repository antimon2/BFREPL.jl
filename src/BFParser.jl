module BFParser

import REPL
using REPL.TerminalMenus

struct ParseError <: Exception
    msg::AbstractString
    stacktrace::Base.StackTraces.StackTrace
end
struct ErrorWrapper <: Exception
    err::Exception
    backtraces::Vector
end

abstract type AbstractBF end
tosource(t::AbstractBF) = sprint(tosource, t)

tosource(terms::Vector{AbstractBF}) = sprint(tosource, terms)
function tosource(io::IO, terms::Vector{AbstractBF})
    for line in terms
        tosource(io, line)
    end
end

# BF Script
struct BF <: AbstractBF
    lines::Vector{AbstractBF}
end
tosource(io::IO, t::BF) = tosource(io, t.lines)

# BF Loop
struct BFLE <: AbstractBF
    lines::Vector{AbstractBF}
    lineno::Int
end
_lineno(t::BFLE) = t.lineno
function tosource(io::IO, t::BFLE)
    print(io, '[')
    tosource(io, t.lines)
    print(io, ']')
end

# BF Increment Pointer
struct BFI{N} <: AbstractBF
    lineno::Int
end
_lineno(t::BFI) = t.lineno
function tosource(io::IO, ::BFI{N}) where N
    for _=1:N
        print(io, '>')
    end
end

# BF Decrement Pointer
struct BFD{N} <: AbstractBF
    lineno::Int
end
_lineno(t::BFD) = t.lineno
function tosource(io::IO, ::BFD{N}) where N
    for _=1:N
        print(io, '<')
    end
end

# BF Increment Value
struct BFP{N} <: AbstractBF
    lineno::Int
end
_lineno(t::BFP) = t.lineno
function tosource(io::IO, ::BFP{N}) where N
    for _=1:N
        print(io, '+')
    end
end

# BF Decrement Value
struct BFM{N} <: AbstractBF
    lineno::Int
end
_lineno(t::BFM) = t.lineno
function tosource(io::IO, ::BFM{N}) where N
    for _=1:N
        print(io, '-')
    end
end

# BF Input
struct BFR <: AbstractBF
    lineno::Int
end
_lineno(t::BFR) = t.lineno
tosource(io::IO, ::BFR) = print(io, ',')

# BF Output
struct BFW <: AbstractBF
    lineno::Int
end
_lineno(t::BFW) = t.lineno
tosource(io::IO, ::BFW) = print(io, '.')

function parseBF(::Type{BF}, src::String)
    _lines = AbstractBF[]
    _stack = Tuple{Int, Vector{AbstractBF}}[]
    re = r"\[|\]|<+|>+|\++|-+|,|\."
    for m in eachmatch(re, src)
        if m.match == "["
            push!(_stack, (m.offset, _lines))
            _lines = AbstractBF[]
        elseif m.match == "]"
            isempty(_stack) && throw(ParseError("syntax: ']' mismatch", [Base.StackTraces.StackFrame("]", src, m.offset)]))
            _lnum, __lines = pop!(_stack)
            bf = BFLE(_lines, _lnum)
            _lines = __lines
            push!(_lines, bf)
        elseif startswith(m.match, '>')
            push!(_lines, BFI{length(m.match)}(m.offset))
        elseif startswith(m.match, '<')
            push!(_lines, BFD{length(m.match)}(m.offset))
        elseif startswith(m.match, '+')
            push!(_lines, BFP{length(m.match)}(m.offset))
        elseif startswith(m.match, '-')
            push!(_lines, BFM{length(m.match)}(m.offset))
        elseif m.match == ","
            push!(_lines, BFR(m.offset))
        elseif m.match == "."
            push!(_lines, BFW(m.offset))
        end
    end
    if !isempty(_stack)
        _src = "[" * tosource(_lines)
        stacktrace = [Base.StackTraces.StackFrame("[", _src, 1)]
        _fn = _src
        _lnum, _lines = pop!(_stack)
        while !isempty(_stack)
            _src = "[" * tosource(_lines) * _fn
            __lnum, __lines = pop!(_stack)
            push!(stacktrace, Base.StackTraces.StackFrame(_fn, _src, _lnum - __lnum + 1))
            _fn = _src
            _lnum = __lnum
            _lines = __lines
        end
        _src = tosource(_lines) * _fn
        push!(stacktrace, Base.StackTraces.StackFrame(_fn, _src, _lnum))
        throw(ParseError("syntax: '[' mismatch", stacktrace))
    end
    BF(_lines)
end

# BF terms which has length
const BFN = Union{BFI, BFD, BFP, BFM}

# BF terms which has no length
const BFS = Union{BFLE, BFR, BFW}

# BF terms
const BFT = Union{BFN, BFS}

offset(t1::BFT, t2::BFT) = _lineno(t1) - _lineno(t2)

# BF Interpreter
mutable struct BFInterpreter{I <: IO, O <: IO}
    tape::Vector{UInt8}
    ptr::Int
    inio::I
    outio::O
    (::Type{BFInterpreter})(inio::I, outio::O, n::Int=30000) where {I <: IO, O <: IO} = 
        new{I, O}(zeros(UInt8, n), 1, inio, outio)
end
(::Type{BFInterpreter})(input::AbstractString, n::Int=30000) = 
    BFInterpreter(IOBuffer(input), IOBuffer(), n)
(::Type{BFInterpreter})(input::AbstractVector{UInt8}, n::Int=30000) = 
    BFInterpreter(IOBuffer(input), IOBuffer(), n)
(::Type{BFInterpreter})(io::IO, n::Int=30000) = 
    BFInterpreter(stdin, io, n)
(::Type{BFInterpreter})(n::Int=30000) = 
    BFInterpreter(stdin, stdout, n)

# BF Execute Increment Pointer
function Base.run(bfi::BFInterpreter, ::BFI{N}) where {N}
    bfi.ptr += N
end

# BF Execute Decrement Pointer
function Base.run(bfi::BFInterpreter, ::BFD{N}) where {N}
    bfi.ptr -= N
end

# BF Execute Increment Value
function Base.run(bfi::BFInterpreter, ::BFP{N}) where {N}
    try
        bfi.tape[bfi.ptr] += N % UInt8
    catch ex
        isa(ex, BoundsError) && throw(ErrorWrapper(ex, Base.StackTraces.backtrace()))
        rethrow()
    end
end

# BF Execute Decrement Value
function Base.run(bfi::BFInterpreter, ::BFM{N}) where {N}
    try
        bfi.tape[bfi.ptr] -= N % UInt8
    catch ex
        isa(ex, BoundsError) && throw(ErrorWrapper(ex, Base.StackTraces.backtrace()))
        rethrow()
    end
end

# BF Execute Input
function Base.run(bfi::BFInterpreter, ::BFR)
    try
        bfi.tape[bfi.ptr] = eof(bfi.inio) ? 0xff : read(bfi.inio, UInt8)
    catch ex
        isa(ex, EOFError) && return 0xff
        isa(ex, BoundsError) && throw(ErrorWrapper(ex, Base.StackTraces.backtrace()))
        rethrow()
    end
end

# BF Execute Output
function Base.run(bfi::BFInterpreter, ::BFW)
    try
        write(bfi.outio, bfi.tape[bfi.ptr])
    catch ex
        isa(ex, BoundsError) && throw(ErrorWrapper(ex, Base.StackTraces.backtrace()))
        rethrow()
    end
end

# BF Execute Loop
function Base.run(bfi::BFInterpreter, bfle::BFLE)
    while bfi.tape[bfi.ptr] != 0
        for bf in bfle.lines
            run(bfi, bf)
        end
    end
end

# BF Execute Script
function Base.run(bfi::BFInterpreter, bfs::BF)
    for bf in bfs.lines
        run(bfi, bf)
    end
end

end # module
