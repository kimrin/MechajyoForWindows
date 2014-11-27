#!/usr/local/bin/julia
# 
# メカ女子将棋システム (C) 2013 メカ女子将棋部☆
# 
# メカ女子将棋部：
# 
# 竹部　さゆり（女流三段）様
#   メカさゆりん
# 渡辺　弥生（女流一級）様
#   メカみおたん
# T.R.　（女子大学院生）様
#   メカりえぽん
# 木村　健（メカウーサーメカ担当、実装責任者）
#   メカきむりん、プロジェクトリーダー、小五女子w
# 
#

const MECHA_JYOSHI_SHOGI = 1
const MECHAJYO_VERSION = "1.0.2"

srand(1234)

#require("Profile")
#using IProfile

require("BoardConsts.jl")
require("Board.jl")
require("Move.jl")
require("GameStatus.jl")
require("OldGenMove.jl")
require("BitBoard.jl")
require("fvbin.jl")
require("Eval.jl")
require("EvalBonanza.jl")
require("GenMove.jl")
require("Search.jl")
require("PVS.jl")

# おまじない
function setupIO()
    stdinx::Ptr{Uint8} = 0
    stdoutx::Ptr{Uint8} = 0
    #ret = ccall((:setunbuffering, "../lib/libMJ.so.1"), Int32, ())

    gs = InitGS()
    InitTables(gs)
    #BBTest2(gs)
    #BBTestForMoveGeneration(gs)
    return gs
end

#println(x...) = (for a in x; print(a); end; print("\r\n"))

global sock

function producer()
    println("establish server (127.0.0.1) port: ", "4091")

    begin
        server = listen(getaddrinfo("127.0.0.1"), int("4091"))
        while true
            println("waiting for connection...")
            sock = accept(server)
            println("establish connection!")
            while true
                ret = main(sock)
                #if ret == "quit"
                    break
                #end
            end
            close(sock)
        end
        #@iprofile report
    end
end

function main(sock)
    sfenHirate = "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1"
    li::Array{ASCIIString,1} = ["" for x = 1:100]::Array{ASCIIString,1}
    li2::Array{ASCIIString,1} = ["" for x = 1:100]::Array{ASCIIString,1}
    lilen = 0
    lilen2 = 0
    side::Int = SENTE # default
    count::Int = 0
    count2::Int = 0
    gs = setupIO()
    #GenMoveTest(gs)
    ###t = Task(producer)
    while true
        st = readline(sock) #consume(t)
        st = chomp(st)
        #println(sock,"consumed $st")
        if st == "quit" || st == "exit"
            break
        elseif st == "usi"
            println(sock,"id name Mecha Jyoshi Shogi NEW ",MECHAJYO_VERSION)
            println(sock,"id author Sayuri TAKEBE, Mio WATANABE, Rieko TSUJI and Takeshi KIMURA")
            println(sock,"option name BookFile type string default $(gs.bookfile)")
            println(sock,"option name UseBook type check default $(gs.usebook)")
            println(sock,"usiok");
        elseif st == "isready"
            srand(time_ns())
            println(sock,"readyok")
        elseif beginswith(st,"setoption")
            if beginswith(st,"setoption name USI_Ponder value true")
                gs.canponder = true
            elseif beginswith(st,"setoption name USI_Ponder value false")
                gs.canponder = false
            elseif beginswith(st,"setoption name USI_Hash value ")
                gs.hashsize = uint32(st[length("setoption name USI_Hash value "):end])
            elseif beginswith(st,"setoption name BookFile value ")
                gs.bookfile = st[length("setoption name BookFile value "):end]
            else
            end
        elseif beginswith(st,"usinewgame")
            # do nothing
            out = [Move(0,0,0,0,0,0) for n = 1:30000]
            history = [0 for x = 1:NumSQ, y = 1:NumSQ]
        elseif beginswith(st,"position startpos")
            li = split(st)
            count = 0
            count2 = 0
            if li[2] == "startpos" # 平手
                if size(li,1) == 2 # 初手
                    gs.board = InitSFEN(sfenHirate, gs.board)
                    count = 0
                    side = SENTE
                else
                    if size(li,1) == 4
                        side = GOTE
                    end
                    gs.board = InitSFEN(sfenHirate, gs.board)
                    count = 0

                    for x = 4:size(li,1)
                        count = 0
                        if iseven(x) # 先手
                            count2 = generateMoves(gs.board, out, SENTE, count, gs)
                            idx = findIndex(out,li[x],SENTE,count+1,count2)
                            if idx == -1
                                idx = 1
                                println(sock,"Warning: cannot find move:", li[x])
                            elseif idx == 0 # resign
                                # do nothing
                                println(sock,"Warning: invalid moves:", li[x])
                            else
                                #println(sock,"index = ", idx)
                                makeMove(gs.board,
		                         idx,
		                         out,
		                         SENTE)
                                #println(sock,"move=",move2USIString(out[idx]))
                            end
                        else # 後手
                            count2 = generateMoves(gs.board, out, GOTE, count, gs)
                            idx = findIndex(out,li[x],GOTE,count+1,count2)
                            if idx == -1
                                idx = 1
                                println(sock,"Warning: cannot find move:", li[x])
                            elseif idx == 0 # resign
                                # do nothing
                                println(sock,"Warning: invalid moves:", li[x])
                            else
                                #println(sock,"index = ", idx)
                                makeMove(gs.board,
		                         idx,
		                         out,
		                         GOTE)
                                #println(sock,"move=",move2USIString(out[idx]))
                            end
                        end
                        
                    end
                end
                #DisplayBoard(gs.board)
            end
        elseif beginswith(st,"position sfen")
            li = split(st)
            count = 0
            count2 = 0
            sfen = join(li[3:6]," ")
            #println(sock,"sfen=",sfen)
            if li[2] == "sfen" # 平手
                if size(li,1) == 6 # 初手
                    gs.board = InitSFEN(sfen, gs.board)
                    count = 0
                    side = SENTE
                else
                    if size(li,1) == 8
                        side = GOTE
                    end
                    gs.board = InitSFEN(sfen, gs.board)
                    count = 0
                    
                    for x = 8:size(li,1)
                        count = 0
                        if iseven(x) # 先手
                            count2 = generateMoves(gs.board, out, SENTE, count, gs)
                            idx = findIndex(out,li[x],SENTE,count+1,count2)
                            if idx == -1
                                idx = 1
                                println(sock,"Warning: cannot find move:", li[x])
                            elseif idx == 0 # resign
                                # do nothing
                                printlpn("Warning: invalid moves:", li[x])
                            else
                                #println(sock,"index = ", idx)
                                makeMove(gs.board,
		                         idx,
		                         out,
		                         SENTE)
                                #println(sock,"move=",move2USIString(out[idx]))
                            end
                        else # 後手
                            count2 = generateMoves(gs.board, out, GOTE, count, gs)
                            idx = findIndex(out,li[x],GOTE,count+1,count2)
                            if idx == -1
                                idx = 1
                                println(sock,"Warning: cannot find move:", li[x])
                            elseif idx == 0 # resign
                                # do nothing
                                println(sock,"Warning: invalid moves:", li[x])
                            else
                                #println(sock,"index = ", idx)
                                makeMove(gs.board,
		                         idx,
		                         out,
		                         GOTE)
                                #println(sock,"move=",move2USIString(out[idx]))
                            end
                        end
                    end
                end
            end
            #DisplayBoard(gs.board)
        elseif beginswith(st,"go")
            li2 = split(st)
            btime::Int = parseint(li2[3],10)
            wtime::Int = parseint(li2[5],10)
            byoyomi::Int = parseint(li2[7],10)
            #if in_check( side, gs.board)
            #    println(sock,"check!")
            #end
            count2 = generateMoves(gs.board, out, side, 0, gs)
            count3 = generateBB(gs.board, out, side, 0, gs)

            if count2 == 0
                println(sock,"bestmove resign")
            else
                # chose random moves
                #randomIndex::Int = rand(Uint32) % (count2)
                Index::Int = -1
                #m::Move = think(side,gs)
                gs.remainTime = (side == SENTE)? btime: wtime
                if gs.remainTime < 60000
                     gs.maxThinkingTime = (1000000000*8)
                else
                     gs.maxThinkingTime = MAXTHINKINGTIME
                end
                println("btime=",btime,", wtime=", wtime, ", remainTime = ",gs.remainTime)
                m::Move = thinkASP(side,gs,sock)
                #println(sock,"move=",m)
                for q = 1:count2
                    if out[q].move == m.move
                        Index = q
                        break
                    end
                end
                if Index == -1
                    println(sock,"bestmove resign")
                else
                    makeMove(gs.board,Index,out,side)
                    if in_check( side, gs.board)
                        println("check!")
                    end
                    println(sock,"bestmove ",move2USIString(out[Index]))
                    #@iprofile report
                end
            end
        elseif beginswith(st,"gameover")
            # do nothing
        else
            println("COMMAND NOT FOUND($st)")
        end
        #println(sock,"COMMAND: $st")
    end
    return "quit"
end

producer()
#@iprofile report
