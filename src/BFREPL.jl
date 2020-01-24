module BFREPL

import REPL
import REPL.LineEdit

include(joinpath(@__DIR__(), "BFParser.jl"))

do_cmd(repl, input) = do_cmd(repl, String(input))
function do_cmd(repl, input::String)
    terminal = REPL.outstream(repl)
    bfi = BFParser.BFInterpreter(terminal, terminal)
    try
        bfs = BFParser.parseBF(BFParser.BF, input)
        BFParser.run(bfi, bfs)
    catch ex
        err_stream = isa(terminal, REPL.Terminals.TTYTerminal) ? terminal.err_stream : stderr
        if isa(ex, BFParser.ParseError)
            print(err_stream, "ERROR: ")
            Base.showerror(IOContext(err_stream, :limit => true), ErrorException(ex.msg), ex.stacktrace)
        elseif isa(ex, BFParser.ErrorWrapper)
            Base.display_error(err_stream, ex.err, ex.backtraces)
        elseif !isa(ex, InterruptException)
            rethrow()
        end
    end
end

function create_mode(repl, main_mode)
    bf_mode = LineEdit.Prompt("bf> ";
        prompt_prefix = Base.text_colors[:magenta],
        prompt_suffix = "",
        # complete = nothing,
        sticky = false)
    bf_mode.repl = repl
    hp = main_mode.hist
    hp.mode_mapping[:bf] = bf_mode
    bf_mode.hist = hp

    search_prompt, skeymap = LineEdit.setup_search_keymap(hp)
    prefix_prompt, prefix_keymap = LineEdit.setup_prefix_keymap(hp, bf_mode)

    bf_mode.on_done = (s, buf, ok) -> begin
        ok || return REPL.transition(s, :abort)
        input = String(take!(buf))
        REPL.reset(repl)
        do_cmd(repl, input)
        REPL.prepare_next(repl)
        REPL.reset_state(s)
        s.current_mode.sticky || REPL.transition(s, main_mode)
    end

    mk = REPL.mode_keymap(main_mode)

    # repl_keymap = Dict()

    b = Dict{Any, Any}[
        skeymap, #=repl_keymap,=# mk, prefix_keymap, LineEdit.history_keymap,
        LineEdit.default_keymap, LineEdit.escape_defaults
    ]
    bf_mode.keymap_dict = LineEdit.keymap(b)
    return bf_mode
end

function repl_init(repl)
    main_mode = repl.interface.modes[1]
    bf_mode = create_mode(repl, main_mode)
    push!(repl.interface.modes, bf_mode)
    org_action = main_mode.keymap_dict['\x02']
    keymap = Dict{Any, Any}(
        # "^B" => function (s, args...)
        '\x02' => function (s, args...)
            # println("^B")
            if isempty(s) || position(LineEdit.buffer(s)) == 0
                buf = copy(LineEdit.buffer(s))
                LineEdit.transition(s, bf_mode) do
                    LineEdit.state(s, bf_mode).input_buffer = buf
                end
            else
                # LineEdit.edit_insert(s, ']')
                org_action(s, args...)
            end
        end
    )
    main_mode.keymap_dict = LineEdit.keymap_merge(main_mode.keymap_dict, keymap)
    return
end

function __init__()
    if isdefined(Base, :active_repl)
        repl_init(Base.active_repl)
    else
        atreplinit() do repl
            if isinteractive() && repl isa REPL.LineEditREPL
                isdefined(repl, :interface) || (repl.interface = REPL.setup_interface(repl))
                repl_init(repl)
            end
        end
    end
end

end # module
