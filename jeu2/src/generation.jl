# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(n::Int64,n2::Int64,density::Float64)

    t = ones(Int64,n,n2)# 1 : visible (case blanc)
    x=max(n,n2)
    i=0
    while i< n*n2*density
        v=ceil.(Int, x * rand())
        l = ceil.(Int, n * rand())
        c = ceil.(Int, n2 * rand())
        if (v!=1)&(t[l,c]==1)
            t[l,c]=v
            i+=1
        end
    end
    return t
end

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    for size in [(i,j) for i in 2:10 for j in 2:10]

        # For each grid density considered


            # Generate 5 instances
            for instance in 1:10

                fileName = dir*"/data/instance_t" * string(size)* "_" * string(instance) * ".txt"

                if !isfile(fileName)
                    println(dir*"Generating file " * fileName)
                    saveInstance(generateInstance(size[1],size[2],0.08*instance), fileName)
                end


    end
end
end
