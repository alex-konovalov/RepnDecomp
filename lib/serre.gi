# These are the implementations of Serre's formulas from his book
# Linear Representations of Finite Groups.

MatrixImage@ := function(p, V)
    local F;

    # F is the base field of V
    F := LeftActingDomain(V);

    # We return the span of the images of the basis under p, which
    # gives p(V)
    return VectorSpace(F,
                       List(Basis(V), v -> p * v),
                       Zero(V));
end;

InstallGlobalFunction( DecomposeRepresentationCanonical, function(rho, arg...)
    local G, F, n, V, irreps, chars, char_to_proj, canonical_projections, canonical_summands;

    # The group we are taking representations of
    G := Source(rho);

    # The field we are working over: it's always the Cyclotomics
    F := Cyclotomics;

    # The dimension of the V in rho : G -> GL(V). Since we have the
    # images of rho as matrices, this is just the width or height of
    # any image of any generator of G.
    n := Length(Range(rho).1);

    # The vector space that the linear maps act on
    V := F^n;

    # The full list of irreps W_i of G over F
    #
    # If we are given a list of irreps, we use that instead of
    # calculating it
    if Size(arg) > 0 then
        irreps := arg[1];
    else
        irreps := IrreducibleRepresentations(G, F);
    fi;

    return List(irreps, function (irrep)
                   local character, degree, projection, canonical_summand;

                   # In Serre's text, irrep is called W_i, this character is chi_i
                   character := GroupHomomorphismByFunction(G, F, g -> Trace(Image(irrep, g)));
                   degree := Image(character, One(G));

                   # Calculate the projection map from V to irrep using Theorem 8 (Serre)
                   # Given as a matrix, p_i
                   projection := (degree/Order(G)) * Sum(G, t -> ComplexConjugate(Image(character, t)) * Image(rho, t));

                   # Calculate V_i, the canonical summand
                   canonical_summand := MatrixImage@(projection, V);
                   return canonical_summand;
               end );
end );

# Decomposes the representation V_i into a direct sum of some number
# (maybe zero) of spaces, all isomorphic to W_i. W_i is the space
# corresponding to the irrep : G -> GL(W_i). rho is the "full"
# representation that we're decomposing.
DecomposeCanonicalSummand@ := function(rho, irrep, V_i)
    local projections, p_11, V_i1, basis, n, step_c, G, H, F, V, m;

    G := Source(irrep);

    # This is the general linear group of some space, we don't really
    # know or care what the space actually is
    H := Range(irrep);

    # This gives the dimension of the space of which W is the general
    # linear group (the size of the matrices representing the maps)
    n := Length(H.1);

    m := Length(Range(rho).1);
    F := Cyclotomics;
    V := F^m;

    # First compute the projections p_ab. We only actually use projections with
    # a=1..n and b=1, so we can just compute those. projections[a] is p_{a1}
    # from Serre.
    projections := List([1..n], a -> (n/Order(G)) * Sum(G, t -> Image(irrep,t^-1)[1][a]*Image(rho,t)));

    p_11 := projections[1];
    V_i1 := MatrixImage@(p_11, V_i);
    basis := Basis(V_i1);

    # Now we define the map taking x to W(x), a subrepresentation of
    # V_i isomorphic to W_i. (This is step (c) of Proposition 8)
    step_c := function(x1)
        # This is the list of basis vectors for W(x1)
        return List([1..n], alpha -> projections[alpha] * x1);
    end;

    # If x1^1 .. x1^m is a basis for V_i1 (this is in the `basis`
    # variable), then V_i decomposes into the direct sum W(x1^1)
    # ... W(x1^m), each isomorphic to W_i.
    #
    # We return a list of lists of (vector space, basis) pairs where
    # the basis (TODO: confirm this?) has the special property
    return List(basis, function(x)
                   local b;
                   b := step_c(x);
                   return rec(space := VectorSpace(F, b, Zero(V)), basis := b);
               end);
end;

# Converts rho to a matrix representation if necessary
ConvertRhoIfNeeded@ := function(rho)
    local gens, ims, high, new_ims, new_range, new_rho, G;
    G := Source(rho);
    # We want rho to be a homomorphism to a matrix group since this
    # algorithm works on matrices. We convert a permutation group into
    # an isomorphic matrix group so that this is the case. If we don't
    # know how to convert to a matrix group, we just fail.
    new_rho := rho;
    if not IsMatrixGroup(Range(rho)) then
        if IsPermGroup(Range(rho)) then
            gens := GeneratorsOfGroup(G);
            ims := List(gens, g -> Image(rho, g));
            high := LargestMovedPoint(ims);
            new_ims := List(ims, i -> PermutationMat(i, high));
            new_range := Group(new_ims);
            new_rho := GroupHomomorphismByImages(G, new_range, gens, new_ims);
        else
            Error("rho is not a matrix or permutation group!");
        fi;
    fi;
    return new_rho;
end;

# Decompose rho into irreducible representations with the reps that
# are isomorphic collected together. This returns a list of lists of
# vector spaces (L) with each element of L being a list of vector
# spaces arising from the same irreducible.
DecomposeIsomorphicCollected@ := function(orig_rho, arg...)
    local irreps, N, canonical_summands, full_decomposition, G, F, n, V, gens, ims, high, new_ims, new_range, rho;

    rho := ConvertRhoIfNeeded@(orig_rho);
    G := Source(rho);

    F := Cyclotomics;
    n := Length(Range(rho).1);
    V := F^n;

    # Use the list of irreps if given
    if Size(arg) > 0 then
        irreps := arg[1];
    else
        irreps := IrreducibleRepresentations(G, F);
    fi;

    N := Size(irreps);

    # This gives a list of vector spaces, each a canonical summand
    # Try to use a precomputed decomposition, if given
    if Size(arg) > 1 then
        canonical_summands := arg[2];
    else
        canonical_summands := DecomposeRepresentationCanonical(rho, irreps);
    fi;

    # This gives a list of lists of vector spaces, each a
    # decomposition of a canonical summand into irreducibles.
    full_decomposition := List([1..N],
                               i -> DecomposeCanonicalSummand@(rho, irreps[i], canonical_summands[i]));

    # Here we return the rho we actually used i.e. after we convert to
    # an isomorphic rep that goes to a matrix group (not a permutation
    # group)
    return rec(decomp := full_decomposition, used_rho := rho);
end;

# Gives the list of vector spaces in the direct sum decomposition of
# rho : G -> GL(V) into irreducibles.
InstallGlobalFunction( DecomposeRepresentationIrreducible, function(orig_rho, arg...)
    local irreps, canonical_summands, rho;
    rho := ConvertRhoIfNeeded@(orig_rho);

    # Use the list of irreps if given
    if Size(arg) > 0 then
        irreps := arg[1];
    else
        irreps := IrreducibleRepresentations(Source(rho), Cyclotomics);
    fi;

    # Try to use a precomputed decomposition, if given
    if Size(arg) > 1 then
        canonical_summands := arg[2];
    else
        canonical_summands := DecomposeRepresentationCanonical(rho, irreps);
    fi;

    # We only want to return the vector spaces here
    return Flat(List(DecomposeIsomorphicCollected@(rho, irreps, canonical_summands).decomp,
                     rec_list -> List(rec_list, r -> r.space)));
end );