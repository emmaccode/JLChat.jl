module JLChat
using Toolips
using ToolipsSession
using ToolipsDefaults

MESSAGES = Vector{Servable}()

``
"""
home(c::Connection) -> _
--------------------
The home function is served as a route inside of your server by default. To
    change this, view the start method below.
"""
function home(c::Connection)
    write!(c, ToolipsDefaults.sheet("styles"))
    chatbox = ToolipsDefaults.textdiv("jl_chatbox", text = "type a message")
    messagebox = div("messagebox")
    bind!(c, "Enter") do cm::ComponentModifier
        txt::String = cm[chatbox]["text"]
        push!(MESSAGES, a("text$(length(MESSAGES) + 1)", text = txt), br())
        set_children!(cm, messagebox, MESSAGES)
        rpc!(c, cm)
        set_text!(cm, chatbox, "")
        println(cm.changes)
    end
    on(c, chatbox, "dblclick") do cm::ComponentModifier
        style!(cm, chatbox, "background-color" => "lightblue")
        rpc!(c, cm)
    end
    messagebox[:children] = MESSAGES
    maincontainer = div("maincontainer")
    push!(maincontainer, messagebox, chatbox)
    bod = body("mainbody")
    push!(bod, maincontainer)
    write!(c, bod)
    if length(keys(c[:Session].peers)) < 1
        open_rpc!(c, "main")
        push!(MESSAGES,
        a("text$(length(MESSAGES) + 1)", text = "joined"), br())
    else
        join_rpc!(c, "main")
        push!(MESSAGES,
        a("text$(length(MESSAGES) + 1)", text = "joined"), br())
    end
end

fourofour = route("404") do c
    write!(c, p("404message", text = "404, not found!"))
end

routes = [route("/", home), fourofour]
extensions = Vector{ServerExtension}([Logger(), Files(), Session()])
"""
start(IP::String, PORT::Integer, ) -> ::ToolipsServer
--------------------
The start function starts the WebServer.
"""
function start(IP::String = "127.0.0.1", PORT::Integer = 8000)
     ws = WebServer(IP, PORT, routes = routes, extensions = extensions)
     ws.start(); ws
end
end # - module
