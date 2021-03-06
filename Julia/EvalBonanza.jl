#PcPcOnSq(k::Int,i::Int,j::Int) = pc_on_sq[k,Int((i+1)*(i)/2)+(j)] # bug
###PcPcOnSq(k::Int,i::Int,j::Int) = pc_on_sq[Int((i-1)*(i)/2)+(j-1)+1,k] # also have bugs
#########PcPcOnSq(k::Int,i::Int,j::Int) = pc_on_sq[div(((i-1)*i),2)+(j-1)+1,k]
# pc_on_sq[k][(i)*((i)+1)/2+(j)]
PcPcOnSq(k::Int,i::Int,j::Int) = pc_on_sq[(div(i*(i+1),2)+j)+1,k+1]

function showPcPcOnSqIndex(k::Int, i::Int, j::Int)
    println("["*"$k,$i,$j"*"] = "*"pc_on_sq[",(i-1)*(i)/2+(j-1)+1,",",k,"]")
end

function probeEHash(p::Board, gs::GameStatus, key::UInt64)
    #key = hash(p.square) ⊻ hash(p.WhitePiecesInHands) ⊻ hash(p.BlackPiecesInHands) ⊻ hash(p.nextMove)
    contents = get( gs.ett, key, Int64(0xdeadcafe))
    if contents == Int64(0xdeadcafe)
        return false, 0
    else
        return true, contents
    end
end

function storeEHash(p::Board, gs::GameStatus, key::UInt64, value::Int64)
    gs.ett[key] = value
end

function make_list( list0::Array{Int,1}, list1::Array{Int,1}, p::Board, gs::GameStatus)
    list2::Array{Int,1} = [0 for x=1:35]::Array{Int,1}
    nlist::Int = 15
    score::Int = 0
    sq_bk0::Int = p.kingposB
    sq_wk0::Int = p.kingposW
    sq_bk1::Int = 82 - p.kingposW
    sq_wk1::Int = 82 - p.kingposB

    zerosOffset = leading_zeros(MaskOfBoard)

    # for i = 1:14
    #     println("list0[",i,"] = ", list0[i])
    # end
    # for i = 1:14
    #     println("list1[",i,"] = ", list1[i])
    # end

    score += kkp[1+ kkp_hand_pawn  + p.WhitePiecesInHands[MJFU], sq_bk0,sq_wk0]
    # println("wFU:",score,"kpp[",1+ kkp_hand_pawn  + p.WhitePiecesInHands[MJFU],",",sq_bk0,",",sq_wk0,"]")
    score += kkp[1+ kkp_hand_lance + p.WhitePiecesInHands[MJKY], sq_bk0,sq_wk0]
    score += kkp[1+ kkp_hand_knight+ p.WhitePiecesInHands[MJKE], sq_bk0,sq_wk0]
    score += kkp[1+ kkp_hand_silver+ p.WhitePiecesInHands[MJGI], sq_bk0,sq_wk0]
    score += kkp[1+ kkp_hand_gold  + p.WhitePiecesInHands[MJKI], sq_bk0,sq_wk0]
    score += kkp[1+ kkp_hand_bishop+ p.WhitePiecesInHands[MJKA], sq_bk0,sq_wk0]
    score += kkp[1+ kkp_hand_rook  + p.WhitePiecesInHands[MJHI], sq_bk0,sq_wk0]
    # println("wall:",score)
    score -= kkp[1+ kkp_hand_pawn  + p.BlackPiecesInHands[MJFU], sq_bk1,sq_wk1]
    #println("bFU:",score,"kpp[",1+ kkp_hand_pawn  + p.BlackPiecesInHands[MJFU],",",sq_bk1,",",sq_wk1,"]")
    score -= kkp[1+ kkp_hand_lance + p.BlackPiecesInHands[MJKY], sq_bk1,sq_wk1]
    score -= kkp[1+ kkp_hand_knight+ p.BlackPiecesInHands[MJKE], sq_bk1,sq_wk1]
    score -= kkp[1+ kkp_hand_silver+ p.BlackPiecesInHands[MJGI], sq_bk1,sq_wk1]
    score -= kkp[1+ kkp_hand_gold  + p.BlackPiecesInHands[MJKI], sq_bk1,sq_wk1]
    score -= kkp[1+ kkp_hand_bishop+ p.BlackPiecesInHands[MJKA], sq_bk1,sq_wk1]
    score -= kkp[1+ kkp_hand_rook  + p.BlackPiecesInHands[MJHI], sq_bk1,sq_wk1]

    # println("after add/sub kkp: ",score,"\n")

    n2::Int = 1
    bb::BitBoard = p.bb[MJFU]
    #DisplayBitBoard(bb,false)
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = f_pawn + sq - 1
        list2[n2]    = e_pawn + ((80 - sq)+2) - 1
        #println("list0[",nlist,"]=",f_pawn + sq + 1)
        #println("list2[",n2,"]=",e_pawn + ((80 - sq)+2))
        score += kkp[kkp_pawn + sq,sq_bk0,sq_wk0]
        #println("kkp[",(kkp_pawn+sq),"][",sq_bk0,"][",sq_wk0,"] = ", kkp[kkp_pawn + sq,sq_bk0,sq_wk0])
        nlist += 1
        n2    += 1
    end

    # println("after MJFU: score= ",score)

    bb = p.bb[MJGOFU]
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = e_pawn + sq - 1
        list2[n2]    = f_pawn + ((80 - sq)+2) - 1
        # println("list0[",nlist,"]=",e_pawn + sq)
        # println("list2[",n2,"]=",f_pawn + ((80 - sq)+2))
        score -= kkp[kkp_pawn + (80 - sq)+2,sq_bk1,sq_wk1]
        # println("kkp[",(kkp_pawn+(80 - sq)+2),"][",sq_bk1,"][",sq_wk1,"] = ", -kkp[kkp_pawn + (80 - sq)+2,sq_bk1,sq_wk1])
        nlist += 1
        n2    += 1
    end

    for i = 1:(n2-1)
        list1[nlist-i] = list2[i]
        #println("list1[",nlist,"-",i," = ", nlist-i, "] = list2[",i,"]")
    end

    # println("after MJGOFU: score= ",score)

    n2 = 1
    bb = p.bb[MJKY]
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = f_lance + sq - 1
        list2[n2]    = e_lance + ((80 - sq)+2) - 1
        # println("list0[",nlist,"]=",f_lance + sq)
        # println("list2[",n2,"]=",e_lance + ((80 - sq)+2))
        score += kkp[kkp_lance + sq,sq_bk0,sq_wk0]
        # println("kkp[",(kkp_lance+sq),"][",sq_bk0,"][",sq_wk0,"] = ", kkp[kkp_lance + sq,sq_bk0,sq_wk0])
        nlist += 1
        n2    += 1
    end
    # println("after MJKY: score= ",score)
    bb = p.bb[MJGOKY]
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = e_lance + sq - 1
        list2[n2]    = f_lance + ((80 - sq)+2) - 1
        score -= kkp[kkp_lance + (80 - sq)+2,sq_bk1,sq_wk1]
        nlist += 1
        n2    += 1
    end

    for i = 1:(n2-1)
        list1[nlist-i] = list2[i]
        #println("list1[",nlist,"-",i," = ", nlist-i, "] = list2[",i,"]")
    end

    # println("after MJGOKY: score= ",score)

    n2 = 1
    bb = p.bb[MJKE]
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = f_knight + sq - 1
        list2[n2]    = e_knight + ((80 - sq)+2) - 1
        score += kkp[kkp_knight + sq,sq_bk0,sq_wk0]
        nlist += 1
        n2    += 1
    end

    # println("after MJKE: score= ",score)

    bb = p.bb[MJGOKE]
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = e_knight + sq - 1
        list2[n2]    = f_knight + ((80 - sq)+2) - 1
        score -= kkp[kkp_knight + (80 - sq)+2,sq_bk1,sq_wk1]
        nlist += 1
        n2    += 1
    end

    for i = 1:(n2-1)
        list1[nlist-i] = list2[i]
        #println("list1[",nlist,"-",i," = ", nlist-i, "] = list2[",i,"]")
    end

    # println("after MJGOKE: score= ",score)

    n2 = 1
    bb = p.bb[MJGI]
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = f_silver + sq - 1
        list2[n2]    = e_silver + ((80 - sq)+2) - 1
        score += kkp[kkp_silver + sq,sq_bk0,sq_wk0]
        nlist += 1
        n2    += 1
    end

    # println("after MJGI: score= ",score)

    bb = p.bb[MJGOGI]
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = e_silver + sq - 1
        list2[n2]    = f_silver + ((80 - sq)+2) - 1
        score -= kkp[kkp_silver + (80 - sq)+2, sq_bk1,sq_wk1]
        nlist += 1
        n2    += 1
    end

    for i = 1:(n2-1)
        list1[nlist-i] = list2[i]
        #println("list1[",nlist,"-",i," = ", nlist-i, "] = list2[",i,"]")
    end
    # println("after MJGOGI: score= ",score)
    n2 = 1
    bb = (p.bb[MJKI]|p.bb[MJTO]|p.bb[MJNY]|p.bb[MJNK]|p.bb[MJNG])
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = f_gold + sq - 1
        list2[n2]    = e_gold + ((80 - sq)+2) - 1
        score += kkp[kkp_gold + sq,sq_bk0,sq_wk0]
        nlist += 1
        n2    += 1
    end
    # println("after MJKI etc: score= ",score)
    bb = (p.bb[MJGOKI]|p.bb[MJGOTO]|p.bb[MJGONY]|p.bb[MJGONK]|p.bb[MJGONG])
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = e_gold + sq - 1
        list2[n2]    = f_gold + ((80 - sq)+2) - 1
        score -= kkp[kkp_gold + (80 - sq)+2,sq_bk1,sq_wk1]
        nlist += 1
        n2    += 1
    end

    for i = 1:(n2-1)
        list1[nlist-i] = list2[i]
        #println("list1[",nlist,"-",i," = ", nlist-i, "] = list2[",i,"]")
    end
    # println("after MJGOKI etc: score= ",score)
    n2 = 1
    bb = p.bb[MJKA]
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = f_bishop + sq - 1
        list2[n2]    = e_bishop + ((80 - sq)+2) - 1
        score += kkp[kkp_bishop + sq,sq_bk0,sq_wk0]
        nlist += 1
        n2    += 1
    end
    # println("after MJKA etc: score= ",score)
    bb = p.bb[MJGOKA]
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = e_bishop + sq - 1
        list2[n2]    = f_bishop + ((80 - sq)+2) - 1
        score -= kkp[kkp_bishop + (80 - sq)+2,sq_bk1,sq_wk1]
        nlist += 1
        n2    += 1
    end

    for i = 1:(n2-1)
        list1[nlist-i] = list2[i]
        #println("list1[",nlist,"-",i," = ", nlist-i, "] = list2[",i,"]")
    end
    # println("after MJGOKA etc: score= ",score)
    n2 = 1
    bb = p.bb[MJUM]
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = f_horse + sq - 1
        list2[n2]    = e_horse + ((80 - sq)+2) - 1
        score += kkp[kkp_horse + sq,sq_bk0,sq_wk0]
        nlist += 1
        n2    += 1
    end
    # println("after MJUM etc: score= ",score)

    bb = p.bb[MJGOUM]
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = e_horse + sq - 1
        list2[n2]    = f_horse + ((80 - sq)+2) - 1
        score -= kkp[kkp_horse + (80 - sq)+2,sq_bk1,sq_wk1]
        nlist += 1
        n2    += 1
    end

    for i = 1:(n2-1)
        list1[nlist-i] = list2[i]
        #println("list1[",nlist,"-",i," = ", nlist-i, "] = list2[",i,"]")
    end
    # println("after MJGOUM etc: score= ",score)
    n2 = 1
    bb = p.bb[MJHI]
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = f_rook + sq - 1
        list2[n2]    = e_rook + ((80 - sq)+2) - 1
        score += kkp[kkp_rook + sq,sq_bk0,sq_wk0]
        nlist += 1
        n2    += 1
    end
    # println("after MJHI etc: score= ",score)
    bb = p.bb[MJGOHI]
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = e_rook + sq - 1
        list2[n2]    = f_rook + ((80 - sq)+2) - 1
        score -= kkp[kkp_rook + (80 - sq)+2,sq_bk1,sq_wk1]
        nlist += 1
        n2    += 1
    end

    for i = 1:(n2-1)
        list1[nlist-i] = list2[i]
        #println("list1[",nlist,"-",i," = ", nlist-i, "] = list2[",i,"]")
    end
    # println("after MJGOHI etc: score= ",score)
    n2 = 1
    bb = p.bb[MJRY]
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = f_dragon + sq - 1
        list2[n2]    = e_dragon + ((80 - sq)+2) - 1
        score += kkp[kkp_dragon + sq,sq_bk0,sq_wk0]
        nlist += 1
        n2    += 1
    end
    # println("after MJRY etc: score= ",score)
    bb = p.bb[MJGORY]
    while bb > UInt128(0)
        sq::Int = trailing_zeros(bb)+1
        # println("sq=$sq, Inv(sq)=",(80 - sq+2))
        bb ⊻= BitSet[sq]
        list0[nlist] = e_dragon + sq - 1
        list2[n2]    = f_dragon + ((80 - sq)+2) - 1
        score -= kkp[kkp_dragon + (80 - sq)+2,sq_bk1,sq_wk1]
        nlist += 1
        n2    += 1
    end

    for i = 1:(n2-1)
        list1[nlist-i] = list2[i]
        #println("list1[",nlist,"-",i," = ", nlist-i, "] = list2[",i,"]")
    end
    # println("after MJGORY etc: score= ",score)
    if nlist > 53
        println("nlist is larger than 53.")
    end
    #println("makelist score =", score)
    return nlist-1, score
end

function EvalBonanza(nextMove::Int, p::Board, gs::GameStatus)
    # list0::Array{Int,1} = [0 for x=1:53]::Array{Int,1}
    # list1::Array{Int,1} = [0 for x=1:53]::Array{Int,1}
    list0 = zeros(Int, 54)::Array{Int,1}
    list1 = zeros(Int, 54)::Array{Int,1}

    # hash lookup!

    key = hash(p.square) ⊻ hash(p.WhitePiecesInHands) ⊻ hash(p.BlackPiecesInHands) ⊻ hash(p.nextMove)

    inHash, evalue = probeEHash(p, gs, key)
    if inHash == true
        if nextMove == GOTE
            evalue = -evalue
        end

        evalue = Int64(div(evalue,32))

        noise = (rand(Int64) % 10) - 5
        evalue = evalue + noise

        return evalue
    end
    #println("list0[1] = ", f_hand_pawn, "+",p.WhitePiecesInHands[MJFU])
    list0[ 1] = f_hand_pawn   + p.WhitePiecesInHands[MJFU]
    #println("list0[2] = ", e_hand_pawn, "+",p.BlackPiecesInHands[MJFU])
    list0[ 2] = e_hand_pawn   + p.BlackPiecesInHands[MJFU]

    list0[ 3] = f_hand_lance  + p.WhitePiecesInHands[MJKY]
    list0[ 4] = e_hand_lance  + p.BlackPiecesInHands[MJKY]
    list0[ 5] = f_hand_knight + p.WhitePiecesInHands[MJKE]
    list0[ 6] = e_hand_knight + p.BlackPiecesInHands[MJKE]
    list0[ 7] = f_hand_silver + p.WhitePiecesInHands[MJGI]
    list0[ 8] = e_hand_silver + p.BlackPiecesInHands[MJGI]
    list0[ 9] = f_hand_gold   + p.WhitePiecesInHands[MJKI]
    list0[10] = e_hand_gold   + p.BlackPiecesInHands[MJKI]
    list0[11] = f_hand_bishop + p.WhitePiecesInHands[MJKA]
    list0[12] = e_hand_bishop + p.BlackPiecesInHands[MJKA]
    list0[13] = f_hand_rook   + p.WhitePiecesInHands[MJHI]
    list0[14] = e_hand_rook   + p.BlackPiecesInHands[MJHI]

    list1[ 1] = f_hand_pawn   + p.BlackPiecesInHands[MJFU]
    list1[ 2] = e_hand_pawn   + p.WhitePiecesInHands[MJFU]
    list1[ 3] = f_hand_lance  + p.BlackPiecesInHands[MJKY]
    list1[ 4] = e_hand_lance  + p.WhitePiecesInHands[MJKY]
    list1[ 5] = f_hand_knight + p.BlackPiecesInHands[MJKE]
    list1[ 6] = e_hand_knight + p.WhitePiecesInHands[MJKE]
    list1[ 7] = f_hand_silver + p.BlackPiecesInHands[MJGI]
    list1[ 8] = e_hand_silver + p.WhitePiecesInHands[MJGI]
    list1[ 9] = f_hand_gold   + p.BlackPiecesInHands[MJKI]
    list1[10] = e_hand_gold   + p.WhitePiecesInHands[MJKI]
    list1[11] = f_hand_bishop + p.BlackPiecesInHands[MJKA]
    list1[12] = e_hand_bishop + p.WhitePiecesInHands[MJKA]
    list1[13] = f_hand_rook   + p.BlackPiecesInHands[MJHI]
    list1[14] = e_hand_rook   + p.WhitePiecesInHands[MJHI]

    nlist::Int = 0
    score::Int = 0

    nlist, score = make_list( list0, list1, p, gs)
    #for i = 1:nlist
    #    println("list0[",i-1,"] = ", list0[i])
    #end
    #for i = 1:nlist
    #    println("list1[",i-1,"] = ", list1[i])
    #end

    #for i = 1:nlist
    #    if list0[i] >= fe_end
    #        println("list0[",i,"]=",list0[i])
    #    end
    #    if list1[i] >= fe_end
    #        println("list1[",i,"]=",list1[i])
    #    end
    #end
    sq_bk::Int = p.kingposW - 1
    sq_wk::Int = 82 - p.kingposB - 1
    #println("sq_bk=$(sq_bk), sq_wk = $(sq_wk)")
    #println("p.kingposW = $(p.kingposW), p.kingposB = $(p.kingposB)")
    sum::Int = 0

    for i = 0:(nlist-1)
        k0::Int = list0[i+1]
        k1::Int = list1[i+1]

        for j = 0:(i)
            #println("(i,j)=($i,$j)")
            l0::Int = list0[j+1]
            l1::Int = list1[j+1]
            #try
            sum = sum + PcPcOnSq( sq_bk, k0, l0)
            #showPcPcOnSqIndex(sq_bk, k0, l0)
            #println("sq_bk=",sq_bk,",k0=",k0,",l0=",l0)

            sum = sum - PcPcOnSq( sq_wk, k1, l1)
            #showPcPcOnSqIndex(sq_wk, k1, l1)
            #println("sq_wk=",sq_wk,",k1=",k1,",l1=",l1)
            #catch
            #    quit()
            #    println("sq_bk=",sq_bk,",sq_wk=",sq_wk)
            #    println("k0=",k0,",k1=",k1)
            #    println("l0=",l0,",l1=",l1)
            #    println("i,j=",i,",",j)
            #    quit()
            #end
        end
    end

    score = score + sum
    eva = Eval( SENTE, p, gs)
    #println("MATERIAL(J) = ", eva)
    #println("sum(J) = ", sum)
    score = score + (32 * eva)

    # store eHash!
    if inHash == false # always false
        storeEHash(p, gs, key, Int64(score))
    end

    # println("Eval=", eva, ", Score=", score)

    if nextMove == GOTE
        score = -score
    end

    score = Int(div(score,32))

    #noise = (rand(Int64) % 10) - 5
    #score += noise

    #println("XXX")
    #DisplayBoard(p)
    #println("score = $(score)")

    return score
end
