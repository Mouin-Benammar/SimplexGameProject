# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX
using Random
using SimpleRandom
include("generation.jl")
include("generateur_cycles.jl")
cd("C:/Users/Escanor/Desktop/ABD/TA/2eme math app/RO203/Projet_RO203/Projet_RO203/jeu1")

dir=pwd()

Tmax = 1
Imax= 1
"""
Solve an instance with CPLEX
"""
function cplexSolve(tab::Array{Int, 2})

    nl,nc=size(tab)

    sup=max(nl,nc)

    clock=time()
    list_de_cycles=cycles(nl,nc)
    println("le temps de generation des cycles d'un grille de taille (", nl, ",", nc, ") : " ,time()-clock )

    # Create the model
    m = Model(with_optimizer(CPLEX.Optimizer))

    # x[i,j,k]=1 si case (i,j) a k comme valeur
    # k=0 {case masqué}
    @variable(m, x[1:nl,1:nc,0:sup], Bin)

    # chaque case (i, j) est soit masquée soit contient la valuer initiale tab[i,j]
    @constraint(m, [i in 1:nl, j in 1:nc], x[i, j, tab[i,j]]+x[i,j,0] == 1)

    # pour chaque ligne l a au plus une case de valeur k non nul
    @constraint(m, [k in 1:sup, l in 1:nl], sum(x[l, j, k] for j in 1:nc) <= 1)

    # pour chaque colonne c a au plus une case de valeur k non nul
    @constraint(m, [k in 1:sup, c in 1:nc], sum(x[i, c, k] for i in 1:nl) <= 1)

    #les cases masquées ne soient pas adjacentes
    @constraint(m, [i in 1:nl, j in 1:nc], x[i,j,0]+0.25*(sum(x[i+p,j,0] for p in [-1,1]  if (1<=i+p<=nl))
    + sum(x[i,j+q,0] for q in [-1,1] if (1<=j+q<=nc)) ) <=1)

    #l’ensemble des cases visibles est connexe est garenti si :
    # tout cycles elementaire de cases diagonaux contient au moins une case non masquée
    @constraint(m,[C in list_de_cycles], sum(1-x[i,j,0] for (i,j) in C) >=1)

    #masquer le moins possible des cases
    @objective(m, Min, sum(x[i,j,0] for i in 1:nl for j in 1:nc))

    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start, x[:,:,0]

end

function NoDuplicates(t::Array{Int, 2})
    n = size(t, 1)
    n2= size(t, 2)
    maxi=max(n,n2)
    for r in 1:n
        counter=zeros(Int64,maxi)
        for c in 1:n2
            if (t[r,c]!=0)
            counter[t[r,c]]+=1
            if (maximum(counter)>=2)
                return false
            end
        end
        end
    end
    for c in 1:n2
        counter=zeros(Int64,maxi)
        for r in 1:n
                if (t[r,c]!=0)
                counter[t[r,c]]+=1
                if (maximum(counter)>=2)
                    return false
                end
            end
        end
    end
    return true
end


function Adjacency(t::Array{Int, 2})
    n = size(t, 1)
    n2= size(t, 2)
    maxi=max(n,n2)

    indices=Tuple{Int64,Int64}[]
    for r in 1:n

        for c in 1:n2
            if(t[r,c]==0)
                push!(indices,(r,c))
            end
        end
       x=size(indices,1)
       if x>1
           for i in 1:x-1
               if abs(indices[i][1]-indices[i+1][1])+abs(indices[i][2]-indices[i+1][2])<2
                   return false
               end
           end
       end
    end
for c in 1:n2

        for r in 1:n
            if(t[r,c]==0)
                push!(indices,(r,c))
            end
        end
       x=size(indices,1)
       if  x>1
           for i in 1:x-1
               if abs(indices[i][1]-indices[i+1][1])+abs(indices[i][2]-indices[i+1][2])<2
                   return false
               end
           end
       end
end
return true
end
"""
Heuristically solve an instance
"""
function heuristicSolve(t::Array{Int, 2})
    temp=time()
    n = size(t, 1)
    n2= size(t, 2)
    maxi=max(n,n2)
    tCopy= copy(t)
    isSolved=NoDuplicates(tCopy)
    adj=Adjacency(tCopy)
    if (isSolved)
        return tCopy
    end
    cycl=cycles(n,n2)
NO=false
date=time()
        while((!isSolved)||(!adj))&&(time()-date<=Tmax)
    	    tCopy = copy(t)
NO=true

    	    for num in 1:maxi

    		        for r in 1:n
    				    counter=0
                        indices=Tuple{Int64,Int64}[]

                        for c in 1:n2
                            if(t[r,c]==num)
                                  counter+=1
                                  push!(indices,(r,c))
                              end
                        end

    		            if(counter>=2)
                            l=Array{Int}(undef, counter)
                            for i in 1:counter
                                append!(l,i)
                            end
                            zeroing=indices[rand(1:length(indices), counter-1)]
                            for i in zeroing
                                tCopy[i[1],i[2]]=0
                            end
                        end
                    end
    		        for c in 1:n2
    				    counter=0
                        indices=Tuple{Int64,Int64}[]

                        for r in 1:n
                            if(t[r,c]==num)
                                  counter+=1
                                  push!(indices,(r,c))
                              end
                        end

    		            if(counter>=2)
                            l=Array{Int}(undef, counter)
                            for i in 1:counter
                                append!(l,i)
                            end
                            zeroing=indices[rand(1:length(indices), counter-1)]
                            for i in zeroing
                                tCopy[i[1],i[2]]=0
                            end
                        end
                    end
    		end





            for k in 1:maxi

                             zero=Set{Tuple{Int64,Int64}}()
                               for i in 1:n
                                   for j in 1:n2
                                       if t[i,j]==k
                                           push!(zero,(i,j))

                                       end
                                   end
                               end

                               for i in cycl
                                  E=Set{Tuple{Int64,Int64}}()
                                  for l in i
                                      push!(E,l)
                                  end
                                   if E<= zero
                                       NO=false
                                       break

                                   end
                               end
            end
                	isSolved=NoDuplicates(tCopy)
                    adj=Adjacency(tCopy)

    	end
            return NO, tCopy
    end


    test=[7 8 10 3 5 7 6 9 4 8;
        5 2 10 10 4 7 1 8 8 3;
         5 3 1 3 7 8 5 1 8 7;
         8 5 1 4 10 1 4 6 9 7;
         4 3 8 7 9 3 9 8 10 10;
         2 10 5 8 8 10 4 7 3 1;
         8 8 6 9 6 10 10 1 9 5;
         1 7 6 8 3 3 10 4 2 8;
         7 4 3 10 9 8 7 9 5 10;
         10 9 5 5 2 1 8 3 1 3]

saveInstance(test,dir*"/data/instanceTest.txt")


function solveDataSet()

        dataFolder = dir*"/data/"
        resFolder = dir*"/res/"

        resolutionMethod = ["cplex", "heuristique"]
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
                        while (!isOptimal)&&(i<=Imax)
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
