module JLChat
using Toolips
using ToolipsSession
using ToolipsDefaults
using ToolipsSVG: circle

MESSAGES = Vector{Servable}()
PEOPLE = Dict{String, Pair{String, String}}()

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
    headerbox = div("headerbox")
    newsvg = svg("jlballs", align = "center", width = 100percent, height = 10percent)
    red_circ = circle("red-circ", cx = 0, cy = 10, r = 10)
    blue_circ = circle("blue-circ", cx = 0, cy = 10, r = 10)
    green_circ = circle("green-circ", cx = 0, cy = 10, r = 10)
    style!(red_circ, "fill" => "#D5635C", "transition" => "1.6s", "opacity" => 0percent)
    style!(blue_circ, "fill" => "#AA79C1", "transition" => "1.3s", "opacity" => 0percent)
    style!(green_circ, "fill" => "#60AD51", "transition" => "1s", "opacity" => 0percent)
    push!(newsvg, red_circ, blue_circ, green_circ)
    jlchatheader = h("jlchatheader", 1, text = "jlchat", align = "center")
    style!(jlchatheader, "opacity" => 0percent, "transition" => "2s")
    push!(headerbox, jlchatheader, newsvg)
    namedialog = ToolipsDefaults.dialog(c, "namedialog", label = "name yourself")
    namebox = ToolipsDefaults.textdiv("namebox", text = "")
    style!(namedialog, "opacity" => "0%", "transition" => 2seconds)
    namelabel = h("namelabel", 2, text = "please enter a name:")
    push!(namedialog, namelabel, namebox)

    bind!(c, chatbox, "Enter", :shift) do cm::ComponentModifier
        txt::String = cm[chatbox]["text"]
        userinfo = PEOPLE[getip(c)]
        message = a("text$(length(MESSAGES) + 1)", text = txt)
        style!(message, "color" => userinfo[2])
        push!(MESSAGES, a("text$(length(MESSAGES) + 1)",
         text = "$(userinfo[1]) : "), message, br())
        set_children!(cm, messagebox, MESSAGES)
        rpc!(c, cm)
        set_text!(cm, chatbox, " ")
    end
    on(c, "load") do cm::ComponentModifier
        style!(cm, namedialog, "opacity" => "100%", "margin-top" => 2percent)
        cm[red_circ] = "cx" => "45%"
        cm[blue_circ] = "cx" => "50%"
        cm[green_circ] = "cx" => "55%"
        style!(cm, red_circ, "opacity" => 100percent)
        style!(cm, green_circ, "opacity" => 100percent)
        style!(cm, blue_circ, "opacity" => 100percent)
        style!(cm, jlchatheader, "opacity" => 100percent)
    end
    colorchooser = ToolipsDefaults.colorinput("colorchooser")
    colorchooser[:text] = "choose your color!"
    style!(colorchooser, "background-color" => "white", "margin" => 10px)
    push!(namedialog, colorchooser, br())
    messagebox[:children] = MESSAGES
    maincontainer = div("maincontainer")
    style!(messagebox, "border-color" => "lightgray", "border-style" => "solid",
    "overflow-y" => "scroll", "height" => "50%", "margin" => 10px)
    style!(chatbox, "border-bottom" => "1px solid")
    style!(namebox, "border-width" => 2px, "border-color" => "lightblue",
    "border-style" => "solid")
    style!(namedialog, "border" => "2px solid", "border-radius" => 5px)
    push!(maincontainer, messagebox, chatbox)
    bod = body("mainbody")
    login_button = button("loginbutton", text = "chat !")
    on(c, login_button, "click") do cm::ComponentModifier
        uname = cm[namebox]["text"]
        color = cm[colorchooser]["value"]
        push!(PEOPLE, getip(c) => uname => color)
        message = a("text$(length(MESSAGES) + 1)",
       text = "$uname ")
       message2 = a("joined2$(length(MESSAGES) + 1)", text = "joined")
       style!(message2, "color" => "blue")
       style!(message, "color" => color)
        push!(MESSAGES, message, message2, br())
        try
            set_children!(cm, messagecontainer, MESSAGES)
            rpc!(c, cm)
        catch
        end
        set_children!(cm, bod, [ToolipsDefaults.sheet("styles"), maincontainer])
        bind!(c, cm, chatbox, "Enter", :shift) do cm2::ComponentModifier
            txt::String = cm2[chatbox]["text"]
            userinfo = PEOPLE[getip(c)]
            message = a("text$(length(MESSAGES) + 1)", text = txt)
            if length(MESSAGES) > 30
                deleteat!(MESSAGES, 1:3)
            end
            style!(message, "color" => userinfo[2])
            push!(MESSAGES, a("text$(length(MESSAGES) + 1)",
             text = "$(userinfo[1]) : "), message, br())
            set_children!(cm2, messagebox, MESSAGES)
            rpc!(c, cm2)
            set_text!(cm2, chatbox, " ")
        end
    end
    push!(namedialog, login_button)
    push!(bod, headerbox, namedialog)
    write!(c, bod)
    if length(keys(c[:Session].peers)) < 1
        open_rpc!(c, "main")
    else
        join_rpc!(c, "main")
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
