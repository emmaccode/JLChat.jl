using Pkg; Pkg.activate(".")
using Toolips
using Revise
using JLChat

IP = "127.0.0.1"
PORT = 8000
JLChatServer = JLChat.start(IP, PORT)
