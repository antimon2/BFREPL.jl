using BFREPL
using REPL
using Test

struct MockREPL
    t::REPL.Terminals.TTYTerminal
end
(::Type{MockREPL})(inio::IO, outio::IO) = MockREPL(inio, outio, outio)
function (::Type{MockREPL})(inio::IO, outio::IO, errio::IO)
    MockREPL(REPL.Terminals.TTYTerminal(get(ENV, "TERM", Sys.iswindows() ? "" : "dumb"), inio, outio, errio))
end
REPL.outstream(m::MockREPL) = m.t

@testset "Hello, world!" begin
    inio = IOBuffer()
    outio = IOBuffer()
    repl = MockREPL(inio, outio)

    hello_world_code = """
    +++++++++[>++++++++>+++++++++++>+++++<<<-]>.>++.+++++++..+++.>-.
    ------------.<++++++++.--------.+++.------.--------.>+.
    """
    BFREPL.do_cmd(repl, hello_world_code)
    result = String(take!(outio))
    @test result == "Hello, world!"

    I_♥_Julia_code = """
    >++[>++[>+++[>+++>++++++>+<<<-]<-]<-]>>>>+.<----.[<-<---<---<+>>>>-]<++.++++
    <-------.<+++++.<.>>>>>+.<<<<<[>-->->>>+>+<<<<<<-]>>----.>>>++.---.<<<<----.>>>>>++.
    """
    BFREPL.do_cmd(repl, I_♥_Julia_code)
    result = String(take!(outio))
    @test result == "I ♥ Julia."
end

@testset "lc_echo" begin
    lc_echo_code = """
    >>,+[-[-<+<+>>]++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    +<[->->+<[>-]>[>]<[-<<[->+<]++++++++++++++++++++++++++[->>+<[>-]>[>]<[-<<<+++++
    +++++++++++++++++++++++++++>[-]>>]<-<]>>]<<]<.[-]>>,+]
    """
    outio = IOBuffer()

    A2Z_repl = MockREPL(IOBuffer("ABCDEFGHIJKLMNOPQRSTUVWXYZ"), outio)
    BFREPL.do_cmd(A2Z_repl, lc_echo_code)
    result = String(take!(outio))
    @test result == "abcdefghijklmnopqrstuvwxyz"

    I_♥_Julia_repl = MockREPL(IOBuffer("I ♥ Julia."), outio)
    BFREPL.do_cmd(I_♥_Julia_repl, lc_echo_code)
    result = String(take!(outio))
    @test result == "i ♥ julia."
end

@testset "error handlings" begin
    inio = IOBuffer()
    outio = IOBuffer()
    errio = IOBuffer()
    repl = MockREPL(inio, outio, errio)

    BFREPL.do_cmd(repl, "[]]")
    result = String(take!(errio))
    @test startswith(result, "ERROR: syntax: ']' mismatch")

    BFREPL.do_cmd(repl, "[[]")
    result = String(take!(errio))
    @test startswith(result, "ERROR: syntax: '[' mismatch")

    BFREPL.do_cmd(repl, "<+")
    result = String(take!(errio))
    @test startswith(result, "ERROR: BoundsError:")
end