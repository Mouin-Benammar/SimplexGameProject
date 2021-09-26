# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
using Random
using SimpleRandom
include("generation.jl")
include("generateur_cycles.jl")
cd("C:/Users/Escanor/Desktop/ABD/TA/2eme math app/RO203/Projet_RO203/Projet_RO203/jeu2")

dir=pwd()

Tmax = 2
Imax = 2

"""
Solve an instance with CPLEX
"""
function cplexSolve(tab::Array{Int, 2})

    nl,nc=size(tab)

    clock=time()
    list_de_cycles=cycles(nl,nc)

    println("le temps de generation des cycles d'un grille de taille (", nl, ",", nc, ") : " ,time()-clock )

    # Create the model
    m = Model(with_optimizer(CPLEX.Optimizer))

    # x[i,j]=1 si la case (i,j) est masquée, 0 sinon
    @variable(m, x[1:nl,1:nc], Bin)

    # z[l,j,k]=1 si (l,j) et (l,k) se voient (2 cases sur la meme ligen l ), 0 sinon
    @variable(m, z[1:nl,1:nc,1:nc], Bin)

    # y[i,k,c]=1 si (i,c) et (k,c) se voinet (2 cases sur le meme colonne c ), 0 sinon
    @variable(m, y[1:nl,1:nl,1:nc], Bin)

    # on ne peut pas masqué une case contienant un valeur
    @constraint(m, [i in 1:nl, j in 1:nc; tab[i,j]>1], x[i, j] == 0)
    #tab[i,j]=1 signifie case visible initialement


    # sur chaque ligne l, (l,j) et (l,k) se voient ssi il n'y a pas des cases masquées entre eux
    # formellement: pour tout l et j<=k, z[l,j,k]=1 <-> sum(x[l,i] for i in j:k)=0

    # z[l,j,k]=1 <- sum(x[l,i] for i in j:k)=0
    @constraint(m, [ l in 1:nl, j in 1:nc, k in j:nc], 1<= z[l,j,k]+sum(x[l, i] for i in j:k))

    #z[l,j,k]=1 -> sum(x[l,i] for i in j:k)=0
    @constraint(m, [ l in 1:nl, j in 1:nc, k in j:nc], z[l,j,k]+sum(x[l, i] for i in j:k)/(1+k-j)<=1)

    # sur chaque ligne l, (l,j) voit (l,k) ssi (l,k) voit (l,j)
    @constraint(m, [ l in 1:nl, j in 1:nc, k in 1:j-1], z[l,k,j]==z[l,j,k])

    # sur chaque colonne c, (j,c) et (k,c) se voient ssi il n'y a pas des cases masquées entre eux
    # formellement: pour tout c et i<=k, y[i,k,c]=1 <-> sum(x[j,c] for j in i:k)=0

    #y[i,k,c]=1 <- sum(x[j,c] for j in i:k)=0
    @constraint(m, [ c in 1:nc, i in 1:nl, k in i:nl], 1<= y[i,k,c]+sum(x[j,c] for j in i:k))

    #y[i,k,c]=1 -> sum(x[j,c] for j in i:k)=0
    @constraint(m, [ c in 1:nc, i in 1:nl, k in i:nl], y[i,k,c]+sum(x[j,c] for j in i:k)/(1+k-i)<=1)

    # sur chaque colonne c, (i,c) voit (k,c) ssi (k,c) voit (i,c)
    @constraint(m, [ c in 1:nc, i in 1:nl, k in 1:i-1], y[k,i,c]==y[i,k,c])

    # si la case (l,c) contient une valeur strictement positive tab[l,c] alors (l,c) voit exacement tab[l,c] cases
    @constraint(m, [l in 1:nl, c in 1:nc; tab[l,c]>1], sum(y[i,l, c] for i in 1:nl)+sum(z[l,c,j] for j in 1:nc)-1 == tab[l,c])
    # -1" car x[l,c] voit elle meme sur la ligne l et la colonne c

    #les cases masquées ne soient pas adjacentes
    @constraint(m, [i in 1:nl, j in 1:nc], x[i,j]+0.25*(sum(x[i+p,j] for p in [-1,1]  if (1<=i+p<=nl))
    + sum(x[i,j+q] for q in [-1,1] if (1<=j+q<=nc)) ) <=1)

    #l’ensemble des cases visibles est connexe est garenti si :
    # tout cycles elementaire de cases diagonaux contient au moins une case non masquée
    @constraint(m,[C in list_de_cycles], sum(1-x[i,j] for (i,j) in C) >=1)

    #masquer le moins possible des cases
    @objective(m, Min, sum(x[i,j] for i in 1:nl for j in 1:nc))

    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start, x

end


"""
Heuristically solve an instance
"""

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""

test=[1   1  1  9   8  1   1  1  1  1;
    1   1  1  1   1  6  10  1  1  6;
    13   1  5  1   1  1   1  6  1  9;
    1   1  1  1   1  5   1  1  1  1;
    1   1  1  1   1  1   1  1  4  1;
    1  10  1  1   1  1   1  1  1  1;
    1   1  1  1   7  1   1  1  1  1;
    11   1  4  1   1  1   1  8  1  6;
    9   1  1  9  12  1   1  1  1  1;
    1   1  1  1   1  6   7  1  1  1]

saveInstance(test,dir*"/data/instanceTest.txt")

function solveDataSet()

        dataFolder = dir*"/data/"
        resFolder = dir*"/res/"

        resolutionMethod = ["cplex"]#, "heuristique"]
        resolutionFolder = resFolder .* resolutionMethod

        for folder in resolutionFolder
            if !isdir(folder)
                mkdir(folder)
            end
        end

        global isOptimal = false
        global solveTime = -1

        # For each input file
        # (for each file in folder dataFolder which ends by ".txt")
        for file in filter(x->occursin(".txt", x), readdir(dataFolder))

            println("-- Resolution of ", file)
            t = readInputFile(dataFolder * file)

            # For each resolution method
            for methodId in 1:size(resolutionMethod, 1)

                outputFile = resolutionFolder[methodId] * "/" * file

                # If the input file has not already been solved by this method
                if !isfile(outputFile)

                    fout = open(outputFile, "w")

                    resolutionTime = -1
                    isOptimal = false

                    # If the method is cplex
                    if resolutionMethod[methodId] == "cplex"

                        # Solve it and get the results
                        isOptimal, resolutionTime,x = cplexSolve(t)

                        # Also write the solution (if any)
                        if isOptimal
                            writeSolution(fout,transformer(t,x))
                        end

                    # If the method is one of the heuristics
                    else

                        isSolved = false
                        solution = []

                        i=0

                        # While the grid is not solved and less than 100 seconds are elapsed
                        while !isOptimal && i <=Imax
                            print(".")

                            isOptimal, solution = heuristicSolve(t)

                            i+=1
                        end

                        println("")

                        # Write the solution (if any)
                        if isOptimal
                            writeSolution(fout, solution)
                        end
                    end

                    println(fout, "solveTime = ", resolutionTime)
                    println(fout, "isOptimal = ", isOptimal)
                    close(fout)
                end


                # Display the results obtained with the method on the current instance
                include(outputFile)
                println(resolutionMethod[methodId], " optimal: ", isOptimal)
                println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
            end
        end
end
