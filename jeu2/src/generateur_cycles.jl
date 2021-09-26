
function Mat_Adj(nl::Int64,nc::Int64)
# on associe la grille à une graphe telque chaque case est une sommet
# et deux sommets diametriquement adjacences sont liées par une arrete
# calcule la matrice d'adjacence symetrique car le graphe est non orienté
# la sommet (i,j) du grille correspond au sommet numéro (i-1)*nc+j au graphe
    MatAdj= zeros(Int64,nl*nc+1,nl*nc+1)
    for i in 1:nl
        for j in 1:nc
            if (i==1)|(i==nl)|(j==1)|(j==nc)
                # Si la case est au bord du grille alors elle liée à l'exterieur (sommet numéro nl*nc+1)
                MatAdj[(i-1)*nc+j,nl*nc+1]=1
                MatAdj[nl*nc+1,(i-1)*nc+j]=1
            end
            for p in [i+e for e in [1,-1] if 0<i+e<=nl]
                for q in [j+e for e in [1,-1] if 0<j+e<=nc]
                    # sommet (i,j) {(i-1)*nc+j} est liée aux 4 sommet au plus (i-1,j-1),(i-1,j+1),(i+1,j-1) et (i+1,j+1)
                    # à condition qu'elles soient à l'interieur du grille
                    MatAdj[(i-1)*nc+j,(p-1)*nc+q]=1
                    MatAdj[(p-1)*nc+q,(i-1)*nc+j]=1
                end
            end
        end
    end
    return MatAdj
end


function prof_cycles(chemin::Array{Int64,1},explore::Array{Int64,1},MA::Array{Int64,2},fich::IOStream)
    # chercher les cycles elementaires du grphe en utilisant le parcours en profondeur et les stock dans une fichier
    m=size(MA,1)
    l=length(chemin)
    tail=length(explore)
    for s in 1:m
        if (MA[chemin[end],s]>0)
        #pour tous s dans les voisins de dernière sommet de chemin
            if (s==chemin[1])&(l>2)
            # si la longeur de chemin superieur à 2 (car la graphe est simple donc les cycles contient au moins 3 sommets)
            # les sommets de l'extrimités sont identiques et différents des sommets intermédiaires
            # donc c'est une cycle élementaire et on l'enrgistre
            println(fich,string(chemin)[2:end-1])# on elmine les symboles "[" et "]"

        elseif !((s in chemin)|(s in explore))&((s==m)|(length([1 for x in chemin if MA[x,m]>0])<2))
            # si s n'est pas exploité ç-à-d on n'a pas compter les cycles passsant par s
            # si la sommet s n'est pas présent dans le chemin
            # alors elle peut fommer une cycle
            # chemin ne doit pas touche la fontière plus que 2 fois
            # s'il touche la frontière 2 fois alors il doit sortir à l'exterieur "m"


            # on avance en l'ajoutant au chemin
            push!(chemin,s)
            # on explore les cycles à partir de nouveau chemin
            prof_cycles(chemin,explore,MA,fich)
            # on recule en le retirant du chemin
            pop!(chemin)
            push!(explore,s) # on marque s comme exploité
            end
        end
    end
    deleteat!(explore,tail+1:length(explore)) # on retire les sommets exploités sur cette branche

    # on passe au sommet suivant
end

function readCyclesFile(inputFile::String,m::Int64,nb::Int64)

    # on ouvre le fichier et on stocke les lignes puis on le ferme
    datafile = open(inputFile)
    data = readlines(datafile)
    close(datafile)

    listresult=Set{Vector{Tuple{Int64, Int64}}}() #on initialise l'ensemble des resultats

    # pour tout ligne
    for ligne in data
        #on decompse la ligne suivant "," on transforme leurs elements en eniter
        # on la stocke d'une cycle u
        ligneSplit = split(ligne, ",")

        v=Tuple{Int64, Int64}[] # on initialise le chemin

        for k in ligneSplit
            k=parse(Int64,k)
            #elemine la sommet "exterieur" si elle present dans la liste
            # "exterieur"=m=nl*nc+1
            if k!=m
                # il s'agit de transformer le sommet (i-1)*nb+j en (i,j)
                # on retouve (i,j) à l'aide de l'unicité et l'existance de la division euclidienne
                i=div(k,nb)+1
                j=rem(k,nb)
                if j==0 # 1<=j<=nb
                    #j=0[nb] -> j=nb
                    j=nb
                    # s=(i-1)*nb+j=i*nb -> i=s|nb
                    i-=1
                end
                push!(v,(i,j)) # on ajoute au (i,j) au figure v
            end
        end
        push!(listresult,v) # on ajoute le chemin à l'ensemble des resultats
    end
    return listresult
end


function cycles(nl::Int64,nc::Int64)
#determine la liste de figures interdies à partir des dimensions du grille

    nom="cycles du grille ("*string(nl)*","*string(nc)*").txt"
    nn_ex= true # vari ssi le ficher nom n'existe pas
    dir=pwd()*"/cycles/"
    if ispath(dir)# s'il existe
        nn_ex=!(nom in readdir(dir)) # on cherche si le fichier nom existe
    else
        mkdir(dir) #sinon on le crée
    end
    nom=dir*nom
    if nn_ex # si on n'a pas calculer les cycles de (nl,nc)
        Mat=Mat_Adj(nl,nc) #calcule matrice d'adjacence
        visite=Int64[] # l'ensemble des sommets visitées
        f= open(nom, "w") # on ouvre le fichier de stockage
        for k in 1:nl*nc-1
            chaine=[k] # chemin commence en k
            prof_cycles(chaine,visite,Mat,f) # on cherche les cycles du grapheshe. C'est etape le plus lord en terme de temps de calcul
            push!(visite,k)# k déja visité
        end
        close(f) # on ferme le fichier
    end
    return readCyclesFile(nom,nl*nc+1,nc) # on filtre les cycles
end
