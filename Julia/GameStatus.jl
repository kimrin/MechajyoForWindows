# game status

struct TransP
    hs::UInt64
    best::Move
    depth::Float64
    flags::Int
    val::Int
end

mutable struct GameStatus
    bookfile::String
    usebook::Bool
    canponder::Bool
    hashsize::UInt32
    board::Board
    lastPV::Array{Move,1}
    lastPVLength::Int
    whiteHeuristics::Array{Int,2}
    blackHeuristics::Array{Int,2}
    inodes::Int32
    nsStart::Int
    moveBufLen::Array{Int,1}
    moveBuf::Array{Move,1}
    triangularLength::Array{Int,1}
    triangularArray::Array{Move,2}
    side::Int
    timedout::Bool
    followpv::Bool
    allownull::Bool
    pvmovesfound::Int
    depth::Float64
    AttackTableNonSlide::Array{BitBoard,2}
    FillRank::Array{BitBoard,1}
    FillFile::Array{BitBoard,1}
    fukyBitsW::BitBoard
    fukyBitsB::BitBoard
    keBitsW::BitBoard
    keBitsB::BitBoard
    MovableKoma::Array{BitBoard,2}
    SenteJin::BitBoard
    GoteJin::BitBoard
    SenteOthers::BitBoard
    GoteOthers::BitBoard
    MoveBeginIndex::Int
    tt::Dict{UInt64,TransP}
    ett::Dict{UInt64,Int64}
    remainTime::Int64
    maxThinkingTime::Int64
    GameStatus() = new()
end

function InitGS()
    gs = GameStatus()
    gs.bookfile = "./Joseki.db"
    gs.usebook  = true
    gs.canponder= true
    gs.hashsize = UInt32(256 * 1024 * 1024)
    gs.board = Board()
    gs.lastPV = [Move(0,0,0,0,0,0) for x = 1:MaxPly]::Array{Move,1}
    gs.lastPVLength = 0
    gs.whiteHeuristics = [0 for x = 1:NumSQ, y = 1:NumSQ]::Array{Int,2}
    gs.blackHeuristics = [0 for x = 1:NumSQ, y = 1:NumSQ]::Array{Int,2}
    gs.inodes = 0
    gs.nsStart = 0
    gs.moveBufLen = [0 for x = 1:MaxPly]::Array{Int,1}
    gs.moveBuf = [Move(0,0,0,0,0,0) for x = 1:MaxMoves]
    gs.triangularLength = [0 for x = 1:MaxPly]::Array{Int,1}
    gs.triangularArray  = [Move(0,0,0,0,0,0) for x = 1:MaxPly, y = 1:MaxPly]::Array{Move,2}
    gs.side = SENTE # 仮に先手として、後で書き換える
    gs.timedout = false
    gs.followpv = true
    gs.allownull = true
    gs.pvmovesfound = 0
    gs.depth = 0.0
    gs.AttackTableNonSlide = [UInt128(0) for piece=MJFU:MJGORY, sq=A9:I1]::Array{BitBoard,2}
    gs.FillRank = [UInt128(0) for r=1:9]::Array{BitBoard,1}
    gs.FillFile = [UInt128(0) for f=1:9]::Array{BitBoard,1}
    gs.fukyBitsW = UInt128(0)::BitBoard
    gs.fukyBitsB = UInt128(0)::BitBoard
    gs.keBitsW   = UInt128(0)::BitBoard
    gs.keBitsB   = UInt128(0)::BitBoard
    gs.MovableKoma = [UInt128(0) UInt128(0) UInt128(0);
                      UInt128(0) UInt128(0) UInt128(0)]::Array{BitBoard,2}
    gs.SenteJin    = UInt128(0)::BitBoard
    gs.GoteJin     = UInt128(0)::BitBoard
    gs.SenteOthers = UInt128(0)::BitBoard
    gs.GoteOthers  = UInt128(0)::BitBoard

    gs.MoveBeginIndex = 0
    gs.tt = Dict{UInt64,TransP}()
    gs.ett = Dict{UInt64,Int64}()

    gs.remainTime = 0 #rewrite by Main.jl
    gs.maxThinkingTime = MAXTHINKINGTIME

    sizehint!(gs.tt,65536*16)
    sizehint!(gs.ett,65536*16)

    #println("$gs")
    gs
end
