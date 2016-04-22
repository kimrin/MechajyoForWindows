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
# 酒井　美由紀（裁縫顧問）様
# 　メカみゅーん
# T.R.　（女子大学院生）様
#   メカりえぽん
# 木村　健（メカウーサーメカ担当、実装責任者）
#   メカきむりん、プロジェクトリーダー、小五女子w
#
#

const MECHA_JYOSHI_SHOGI = 1
const MECHAJYO_VERSION = "BlackMechajyo"

const THINK_TIME_IN_NS = UInt64(1000000000*14)
const THINK_BYOYOMI_IN_NS = UInt64(1000000000*8)
const BEGIN_BYOYOMI_IN_NS = UInt64(1000000000*60)

srand(1234)

#using IProfile

include("BoardConsts.jl")
include("Board.jl")
include("Move.jl")
include("GameStatus.jl")
include("OldGenMove.jl")
include("BitBoard.jl")
include("fvbin.jl")
include("Eval.jl")
include("EvalBonanza.jl")
include("GenMove.jl")
include("Search.jl")
include("PVS.jl")

# おまじない
function setupIO()
    stdinx::Ptr{UInt8} = 0
    stdoutx::Ptr{UInt8} = 0
    #ret = ccall((:setunbuffering, "../lib/libMJ.so.1"), Int32, ())

    gs = InitGS()
    InitTables(gs)
    #BBTest2(gs)
    #BBTestForMoveGeneration(gs)
    return gs
end

#println(x...) = (for a in x; print(a); end; print("\r\n"))

function producer()
  if length(ARGS) == 1
    if ARGS[1] == "stdio"
      sock  = STDOUT
      stdin = STDIN
      ret = main(stdin,sock)
    end
  end
  if (length(ARGS) == 2) && (ARGS[1] == "tcp")
    addr = ARGS[2]
    println("establish server (", addr, ") port: ", "4091")
    begin
      #server = listen(getaddrinfo("127.0.0.1"), parse(UInt32,"4091"))
      server = listen(getaddrinfo(addr), parse(UInt32,"4091"))
      while true
        println("waiting for connection...")
        sock  = accept(server)
        println("establish connection!")
        while true
          ret = main(sock,sock)
          break
        end
        close(sock)
        break
      end
    end
  end
end

function main(stdin, sock)
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
        st = readline(stdin) #consume(t)
        st = chomp(st)
        #println(sock,"consumed $st")
        if st == "quit" || st == "exit"
            break
        elseif st == "usi"
            println(sock,"id name Mecha Jyoshi Shogi ",MECHAJYO_VERSION)
            println(sock,"id author Sayuri TAKEBE, Mio WATANABE, Miyuki SAKAI, Rieko TSUJI and Takeshi KIMURA")
            println(sock,"option name BookFile type string default $(gs.bookfile)")
            println(sock,"option name UseBook type check default $(gs.usebook)")
            println(sock,"usiok");
        elseif st == "isready"
            srand(time_ns())
            println(sock,"readyok")
        elseif startswith(st,"setoption")
            if startswith(st,"setoption name USI_Ponder value true")
                gs.canponder = true
            elseif startswith(st,"setoption name USI_Ponder value false")
                gs.canponder = false
            elseif startswith(st,"setoption name USI_Hash value ")
                gs.hashsize = parse(UInt32,st[length("setoption name USI_Hash value "):end])
            elseif startswith(st,"setoption name BookFile value ")
                gs.bookfile = st[length("setoption name BookFile value "):end]
            else
            end
        elseif startswith(st,"usinewgame")
            # do nothing
            out = [Move(0,0,0,0,0,0) for n = 1:30000]
            history = [0 for x = 1:NumSQ, y = 1:NumSQ]
        elseif startswith(st,"position startpos")
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
        elseif startswith(st,"position sfen")
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
        elseif startswith(st,"go")
            li2 = split(st)
            start, goal, isByoyomi, thinkTime = parseGo(li2,side)
            count2 = generateMoves(gs.board, out, side, 0, gs)
            count3 = generateBB(gs.board, out, side, 0, gs)
            if count2 == 0
              println(sock,"bestmove resign")
            else
              # chose random moves
              #randomIndex::Int = rand(UInt32) % (count2)
              Index::Int = -1
              #m::Move = think(side,gs)
              gs.maxThinkingTime = thinkTime
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
                  # println("check!")
                end
                println(sock,"bestmove ",move2USIString(out[Index]))
              end
            end
        elseif startswith(st,"gameover")
            # do nothing
        else
            println("debug COMMAND NOT FOUND($st)")
        end
        #println(sock,"COMMAND: $st")
    end
    return "quit"
end

function parseGo(list,side)
  i = 1
  btime = 0
  wtime = 0
  byoyomi = 0
  winc = 0
  binc = 0
  for x in list
    if btime == -1
      btime = parse(UInt64,x*"000000")
    end
    if wtime == -1
      wtime = parse(UInt64,x*"000000")
    end
    if byoyomi == -1
      byoyomi = parse(UInt64,x*"000000")
    end
    if winc == -1
      winc = parse(UInt64,x*"000000")
    end
    if binc == -1
      binc = parse(UInt64,x*"000000")
    end

    if x == "btime"
      btime = -1
    elseif x == "wtime"
      wtime = -1
    elseif x == "byoyomi"
      byoyomi = -1
    elseif x == "winc"
      winc = -1
    elseif x == "binc"
      binc = -1
    end
    i = i + 1
  end

  isByoyomi = (side == SENTE) ? (btime < BEGIN_BYOYOMI_IN_NS):  (wtime < BEGIN_BYOYOMI_IN_NS)

  remainTime = (side == SENTE)? btime: wtime

  println("remain time = ", remainTime)

  minByoyomi = 2 # 2 secs
  thinkTime = 10
  if isByoyomi
    if (winc > 0)&&(binc > 0) # fisher rule
      thinkTime = Int64(remainTime * 0.8)
    else
      if byoyomi < Int64(1000000000 * minByoyomi)
        thinkTime = Int64(UInt64(byoyomi >>> 1))
      else
        thinkTime = byoyomi - Int64(1000000000 * minByoyomi)
      end
    end
  else
    thinkTime = THINK_TIME_IN_NS
  end
  start = time_ns() # sampling time value
  goal = start + thinkTime
  tObj = (start,goal,isByoyomi,thinkTime)
  println(tObj)
  return tObj
end

producer()
#@iprofile report
