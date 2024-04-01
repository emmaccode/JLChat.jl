module JLChat
using Toolips
# extensions
logger = Toolips.Logger()
session = Session(["/"])

mutable struct Chat <: Toolips.Servable
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

main = route("/") do c::Connection
    if ~(get_ip(c) in keys(chat.usernames))

    end
end

export home
export logger, session
end # - module