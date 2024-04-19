module JLChat
using Toolips
using Toolips.Components
using ToolipsSession
import Toolips: AbstractConnection
# extensions
logger = Toolips.Logger()
session = Session(["/"], timeout = 1)

mutable struct Chat <: Components.Servable
    name::String
    host::String
    members::Vector{String}
    messages::Vector{Pair{String, String}}
    Chat(c::AbstractConnection, name::String) = begin
        ip = get_ip(c)
        members = [ip]
        new(name, ip, members, Vector{Pair{String, String}}())
    end
    Chat(name::String, host::String) = begin
        new(name, host, Vector{String}(), messages::Vector{Pair{String, String}})
    end
end

mutable struct ChatService <: Toolips.AbstractExtension
    usernames::Dict{String, Pair{String, String}}
    chats::Vector{Chat}
    ChatService() = new(Dict{String, String}(), Vector{Chat}())::ChatService
end

chat = ChatService()

function chat_builder(c::AbstractConnection)
    main_dialog = div("new-chat", align = "center")
    style!(main_dialog, "width" => 10percent, "left" => 40percent, "top" => 20percent, "height" => 25percent, 
    "background-color" => "#333333", "padding" => 15px, "z-index" => 4, "position" => "absolute")
    name_header = h2("make-header", text = "name for new chat")
    style!(name_header, "color" => "white", "font-size" => 22pt)
    make_chat = textdiv("makerchat")
    style!(make_chat, "display" => "inline-block", "background-color" => "white", "color" => "#333333", 
    "width" => 85percent)
    subm = button("submit-new", text = "submit")
    style!(subm, "background-color" => "black", "color" => "white", "width" => 85percent)
    on(c, subm, "click") do cm::ComponentModifier
        cname = cm[make_chat]["text"]
        chat = create_chat!(c, cname)
        append!(cm, "chat-content", build_chat(c, cm, cname))
        remove!(cm, "new-chat")
        open_rpc!(c, cm)
        script!(c, cm) do cm::ComponentModifier
            append!(cm, "chat-messages", build_message(chat, "room opened!"))
            rpc!(c, cm)
        end
    end
    push!(main_dialog, name_header, make_chat, subm)
    main_dialog::Component{:div}
end

function build_message(chat::Chat, message::String)
    n = length(chat.messages) + 1
    mainmessage = div("chat$n")
    firstsep = a("firstsep", text = "[")
    secondsep = a("secondsep", text = "]: ")
    nmindc = a("nameindicator", text = chat.name)
    style!(nmindc, "color" => "#333333")
    msg = a("msg", text = message)
    push!(mainmessage, firstsep, nmindc, secondsep, msg)
    mainmessage::Component{:div}
end

function build_message(c::AbstractConnection, active::Chat, message::String)
    n = length(active.messages) + 1
    mainmessage = div("chat$n")
    client = chat.usernames[get_ip(c)]
    firstsep = a("firstsep", text = "[")
    secondsep = a("secondsep", text = "]: ")
    nmindc = a("nameindicator", text = client[1])
    style!(nmindc, "color" => client[2])
    msg = a("msg", text = message)
    push!(mainmessage, firstsep, nmindc, secondsep, msg)
    push!(active.messages, client[1] => message)
    mainmessage::Component{:div}
end

function create_chat!(c::AbstractConnection, name::String)
    newchat = Chat(c, name)
    push!(newchat.members, chat.usernames[get_ip(c)][1])
    push!(chat.chats, newchat)
    newchat::Chat
end

function build_chat(c::AbstractConnection, cm::ComponentModifier, name::String)
    chat_div = div("chatmain")
    style!(chat_div, "display" => "inline-block", "margin-left" => 1per, "width" => 99per)
    messagesbox = div("chat-messages")
    newmessage = textdiv("chat-new", text = "Shift + Enter to send your message")
    ToolipsSession.bind(c, cm, newmessage, "Enter", :shift) do cm::ComponentModifier
        person = chat.usernames[get_ip(c)][1]
        activ = findfirst(c -> person in c.members, chat.chats)
        newmsg = build_message(c, chat.chats[activ], cm[newmessage]["text"])
        append!(cm, messagesbox, newmsg)
        rpc!(c, cm)
        set_text!(cm, newmessage, "")
    end
    on(newmessage, "focusenter") do cl::ClientModifier
        set_text!(cl, newmessage, "")
    end
    boxcommon = ("width" => 100percent, "background-color" => "white", "border" => "2px solid #333333", 
    "border-radius" => 3px, "padding" => 3px)
    style!(newmessage, "height" => 3percent, "margin-top" => 9px, boxcommon ...)
    style!(messagesbox, "height" => 80percent, boxcommon ...)
    push!(chat_div, messagesbox, newmessage)
    chat_div::Component{:div}
end

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

function build_main(c::AbstractConnection, cm::ComponentModifier)
    chatnav = div("chatnav")
    style!(chatnav, "position" => "absolute", "width" => 10percent)
    active_box = div("active-chats")
    style!(active_box, "width" => 100percent)
    inactive_box = div("inactive-chats")
    style!(inactive_box, "width" => 100percent)
    create_chat = button("create-chat", text = "create chat")
    on(c, create_chat, "click") do cm::ComponentModifier
        append!(cm, "jlchatbod", chat_builder(c))
        focus!(cm, "makerchat")
    end
    style!(create_chat, "color" => "white", "background-color" => "#AA336A", "width" => 100percent, 
    "padding" => 5px, "font-size" => 16pt, "font-weight" => "bold")
    push!(chatnav, create_chat, active_box, inactive_box)
    name::String = chat.usernames[get_ip(c)][1]
    for (e, active_chat) in enumerate(chat.chats)
        chtmen = build_chatmenu(c, e, active_chat)
        if name in active_chat.members
            push!(active_box, chtmen)
            continue
        end
        push!(inactive_box, chtmen)
    end
    main = div("jlchat-main")
    content = div("chat-content")
    style!(content, "display" => "inline-block", "margin-left" => 10percent, 
    "width" => 80per)
    push!(main, chatnav, content)
    main::Component{:div}
end

function build_chatmenu(c::Connection, e::Int64, active_chat::Chat)
    comp = div("chat$(e)")
    style!(comp, "background-color" => "white", "padding" => 6px, "cursor" => "pointer")
    on(c, comp, "click") do cm::ComponentModifier
        name = chat.usernames[get_ip(c)]
        if ~(name[1] in active_chat.members)
            join_rpc!(c, cm, active_chat.host)
            append!(cm, "chat-content", build_chat(c, cm, active_chat.name))
            push!(active_chat.members, chat.usernames[get_ip(c)][1])
        end
    end
    cname = a("chname$(e)", text = active_chat.name)
    chost = a("chost$(e)", text = "")
    cnt = a("count$(e)", text = length(active_chat.members))
    style!(cname, "margin-right" => 5px)
    style!(chost, "margin-right" => 10px)
    push!(comp, cname, chost, cnt)
    comp::Component{:div}
end

function login!(c::AbstractConnection, cm::ComponentModifier)
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

function splash_screen(c::AbstractConnection)
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

main = route("/") do c::AbstractConnection
    if ~(get_ip(c) in keys(chat.usernames))
        splash_screen(c)
        return
    end
    mainbod = body("jlchatbod")
    style!(mainbod, "transtion" => 2s, "background-color" => "#FFB3B2")
    write!(c, mainbod)
    on(c, "load") do cm::ComponentModifier
        append!(cm, "jlchatbod", build_main(c, cm))
        active_chat = findfirst(cht::Chat -> get_ip(c) in cht.members, chat.chats)
        if ~(isnothing(active_chat))
            append!(cm, "chat-content", build_chat(c, cm, chat.chats[active_chat].name))
        end
    end
end

export main
export logger, session
end # - module