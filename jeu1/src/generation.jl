# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")


"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(n::Int64,n2::Int64)

    t = Array{Int64}(undef,n,n2)
    x=max(n,n2)
    for i in 1:n
        for j in 1:n2
            t[i, j]=floor.(Int, x * rand()) + 1
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

            # Generate 10 instances
            for instance in 1:10

                fileName = dir*"/data/instance_t" * string(size)* "_" * string(instance) * ".txt"

                if !isfile(fileName)
                    println(dir*"Generating file " * fileName)
                    saveInstance(generateInstance(size[1],size[2]), fileName)
                end


    end
end
end
