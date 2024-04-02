module JLChat
using Toolips
using Toolips.Components
using ToolipsSession
# extensions
logger = Toolips.Logger()
session = Session(["/"])

mutable struct Chat <: Components.Servable
    name::String
    host::String
    members::Vector{String}
    messages::Vector{Pair{String, String}}
end

mutable struct ChatService <: Toolips.AbstractExtension
    usernames::Dict{String, Pair{String, String}}
    chats::Vector{Chat}
    ChatService() = new(Dict{String, String}(), Vector{Chat}())::ChatService
end

chat = ChatService()

function jlchat_header()
    headbox = div("mainheader", align = "center")
    style!(headbox, "padding" => 8px, "margin-top" => 6percent, "transition" => 1s)
    txt = h4("jlchathead", text = "JL Chat", align = "center")
    style!(txt, "color" => "#333333", "font-weight" => "bold", "font-size" => 25pt, "transition" => 800ms, 
    "transform" => "translateY(9%)", "opacity" => 0percent, "padding" => 3px)
    svgbox = svg("bubblebox", width = 500, height = 100)
    set_children!(svgbox, [begin
        circ = Component{:circle}("jlcircl$e", r = 18, cx = 400, cy = 50)
        style!(circ, "fill" => color, "opacity" => 0percent, 
        "transition" => "$(e * 600)ms")
        circ
    end for (e, color) in enumerate(("#D5635C", "#AA79C1", "#60AD51"))])
    push!(headbox, txt, svgbox)
    headbox::Component{:div}
end

function build_main(c::Connection, cm::ComponentModifier)
    chatnav = div("chatnav")
    style!(chatnav, "display" => "inline-block", "width" => 20percent)
    active_box = div("active-chats")
    style!(active_box, "width" => 100percent)
    inactive_box = div("inactive-chats")
    style!(inactive_box, "width" => 100percent)
    create_chat = button("create-chat", text = "create chat")
    style!(create_chat, "color" => "white", "background-color" => "#AA336A", "width" => 100percent, 
    "padding" => 5px, "font-size" => 16pt, "font-weight" => "bold")
    push!(chatnav, create_chat, active_box, inactive_box)
    name::String = chat.usernames[get_ip(c)][1]
    for (e, active_chat) in enumerate(chat.chats)
        comp = div("chat$(e)")
        style!(comp, "cursor" => "pointer")
        cname = a("chname$(e)", text = active_chat.name)
        chost = a("chost$(e)", text = "")
        cnt = a("count$(e)", text = length(active_chat.members))
        style!(cname, "margin-right" => 5px)
        style!(chost, "margin-right" => 10px)
        push!(comp, cname, chost, cnt)
        if name in active_chat.members
            push!(active_box, comp)
            continue
        end
        push!(inactive_box, comp)
    end
    main = div("jlchat-main")
    content = div("chat-content")
    style!(content, "background-color" => "#2e111a")
    style!(content, "display" => "inline-block")
    push!(main, chatnav, content)
    main::Component{:div}
end

function login!(c::Connection, cm::ComponentModifier)
    name = cm["logname"]["text"]
    color = cm["logcolor"]["value"]
    if name == ""
        return
    elseif contains(name, " ")
        return
    elseif length(findall("f", color)) > 4
        return
    end
    push!(chat.usernames, get_ip(c) => name => color)
    style!(cm, "jlchatbod", "background-color" => "#FFB3B2")
    style!(cm, "loginbox", "opacity" => 0percent, "top" => 120percent, "position" => "absolute")
    style!(cm, "jlchathead", "height" => 0percent, "opacity" => 0percent, "transition" => 1s)
    [begin
        style!(cm, "jlcircl$e", "opacity" => 0percent, "transition" => 600ms)
        cm["jlcircl$e"] = "cx" => 0
    end for e in 1:3]
    next!(c, cm, "jlchatbod") do cm::ComponentModifier
        remove!(cm, "splash-content")
        remove!(cm, "jlchathead")
        cm["mainheader"] = "align" => "left"
        [begin
            cm["jlcircl$e"] = "cy" => 20
            style!(cm, "jlcircl$e", "opacity" => 100percent)
            cm["jlcircl$e"] = "cx" => (20, 70, 120)[e]
        end for e in 1:3]
        style!(cm, "mainheader", "margin-top" => 0px, "transition" => 0s, "padding" => 0px)
        fired = false
        next!(c, cm, "jlcircl3") do cm::ComponentModifier
            if ~(fired)
                append!(cm, "jlchatbod", build_main(c, cm))
                fired = true
            end
        end
    end
end

function splash_screen(c::Connection)
    mainbod = body("jlchatbod")
    style!(mainbod, "transtion" => 2s)
    splash_content = div("splash-content", align = "center")
    loginbox = div("loginbox", align = "left")
    push!(splash_content, loginbox)
    welcomehead = h2("welcomehead", text = "welcome!", align = "center")
    style!(welcomehead, "color" => "#D5635C", "font-weight" => "bold", "font-size" => 26pt)
    loginhead = h3("loghead", text = "please enter a name and select a color!")
    style!(loginhead, "color" => "#141414")
    style!(loginbox, "border" => "2px solid #333333", "border-radius" => 2px, "background-color" => "#FFB3B2", 
    "opacity" => 0percent, "transition" => 1s, "transform" => translateY(10percent), "padding" => 20px, 
    "width" => 20percent)
    nameenter = textdiv("logname")
    style!(nameenter, "border-radius" => 2px, "border" => "2px solid #333333", "background-color" => "white", "font-size" => 17pt, "padding" => 3px)
    colorenter = colorinput("logcolor", value = "#333333", "width" => 2percent, "height" => 2percent)
    submitb = button("logsub", text = "chat !")
    style!(submitb, "border-radius" => 4px, "background-color" => "#5cdb5c", "color" => "white", "font-size" => 12pt, "font-weight" => "bold")
    style!(colorenter, "background-color" => "white", "border" => "none")
    buttons = div("buttonsdiv", align = "right")
    on(c, submitb, "click") do cm::ComponentModifier
        login!(c, cm)
    end
    ToolipsSession.bind(c, nameenter, "Enter") do cm::ComponentModifier
        login!(c, cm)
    end
    style!(buttons, "display" => "flex", "margin-left" => 65percent, "margin-top" => 7px)
    push!(buttons, colorenter, submitb)
    push!(loginbox, welcomehead, loginhead, nameenter, buttons)
    head = jlchat_header()
    push!(mainbod, head, splash_content)
    write!(c, mainbod)
    on(c, "load") do cm::ComponentModifier
        style!(cm, "jlchathead", "opacity" => 100percent, "transform" => "translateY(0%)")
        [begin
            style!(cm, "jlcircl$e", "opacity" => 100percent)
            cm["jlcircl$e"] = "cx" => (200, 250, 300)[e]
        end for e in 1:3]
        next!(c, cm, "jlcircl3") do cm::ComponentModifier  
            style!(cm, loginbox, "opacity" => 100percent, "transform" => translateY(0percent))
            next!(c, cm, loginbox) do cm::ComponentModifier
                focus!(cm, "logname")
            end
        end
    end
end

main = route("/") do c::Connection
    if ~(get_ip(c) in keys(chat.usernames))
        splash_screen(c)
        return
    end
end

export main
export logger, session
end # - module