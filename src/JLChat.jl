module JLChat
using Toolips
using Toolips.Components
using ToolipsSession
# extensions
logger = Toolips.Logger()
session = Session(["/"])

mutable struct Chat <: Components.Servable
    name::String
    members::Vector{String}
    messages::Vector{Pair{String, String}}
end

mutable struct ChatService <: Toolips.AbstractExtension
    usernames::Dict{String, String}
    chats::Dict{String, Vector{Chat}}
    ChatService() = new(Dict{String, String}(), Dict{String, Vector{Chat}}())::ChatService
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

function splash_screen(c::Connection)
    mainbod = body("jlchatbod")
    loginbox = div("loginbox")
    loginhead = h3("loghead", text = "welcome! please enter a name and select a color!")
    style!(loginbox, "border" => "2px solid #333333", "border-radius" => 2px, "background-color" => "#FFB3B2")
    nameenter = textdiv("logname")
    style!(nameenter, "border-radius" => 2px, "border" => "2px solid #333333")
    colorenter = colorinput("logcolor", value = "#333333")
    submitb = button("logsub", text = "chat !")
    style!(submitb, "border-radius" => 4px, "background-color" => "darkblue", "color" => "white")
    style!(colorenter, "background" => "transparent")
    push!(loginbox, loginhead, nameenter, colorenter, submitb)
    head = jlchat_header()
    push!(mainbod, head)
    write!(c, mainbod)
    on(c, "load") do cm::ComponentModifier
        style!(cm, "jlchathead", "opacity" => 100percent, "transform" => "translateY(0%)")
        [begin
            style!(cm, "jlcircl$e", "opacity" => 100percent)
            cm["jlcircl$e"] = "cx" => (200, 250, 300)[e]
            next!(c, cm, "jlcircl3") do cm::ComponentModifier
                Components.insert!(cm, mainbod, loginbox)
            end
        end for e in 1:3]
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