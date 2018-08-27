# Generators of our group
gens := [(1,2)];

# The group we are taking representations of
G := Group(gens);

# The base field of our vector spaces. Must be some subfield of the complex
# numbers, since we take conjugates sometimes. We just use the cyclotomic
# numbers, since this is the closest to C we can actually get in GAP.
F := Cyclotomics;

# Dimension of the vector space we want
n := 2;

# This is the vector space our linear maps will act on.
V := F^n;

# Images of the generators of G in GL(V) (matrix form)
images := [ [[-1, 0], [0, -1]] ];

# We can't actually concretely have GL(V) in GAP, so we limit ourselves to the
# subgroup generated by the images
H := Group(images);

# The representation we will decompose
rho := GroupHomomorphismByImages(G, H, gens, images);

DecomposeRepresentationSerre := function(rho)
    local irreps, chars, char_to_proj, canonical_projections, matrix_image, zero, canonical_summands, decompose_summand, N, full_decomposition;

    # The group we are taking representations of
    G := Source(rho);

    # The field we are working over: it's always the Cyclotomics
    F := Cyclotomics;

    # The full list of irreps W_i of G over F
    irreps := IrreducibleRepresentations(G, F);

    # The characters chi_i of each irrep W_i
    chars := List(irreps,
                  irrep -> GroupHomomorphismByFunction(G, F,
                                                       g -> Trace(Image(irrep, g))));

    # Given a character chi_i, calculate the projection onto V_i using Theorem 8
    # This is given as a matrix
    char_to_proj := function(char)
        local degree;

        # The degree n_i of char
        degree := Image(char, One(G));
        return (degree/Order(G)) * Sum(G,
                                       t -> ComplexConjugate(Image(char, t)) * Image(rho, t));
    end;

    # The list of the p_i in matrix form
    canonical_projections := List(chars, char_to_proj);

    # Calculates p(space) for p a linear map (given as a matrix in the
    # standard basis) and a vector space
    matrix_image := function(p, space, zero)
        return VectorSpace(F, List(Basis(space), v -> p * v), zero);
    end;

    # The zero of our space (need this for when bases are empty)
    zero := List([1..n], _ -> 0);

    # The list of the V_i
    canonical_summands := List(canonical_projections, p -> matrix_image(p, V, zero));

    # Now we need to, given each V_i, decompose it into the W(x_1^j) (summing over
    # j), which are the actual vector subspaces isomorphic to W_i.

    decompose_summand := function(irrep, V_i)
        local projection, p_11, V_i1, basis, W, n, step_c;

        # This is the general linear group of some space, we don't really
        # know or care what the space actually is
        W := Range(irrep);

        # This gives the dimension of the space of which W is the general
        # linear group (the size of the matrices representing the maps)
        n := Length(W.1);

        # First compute the projections p_ab
        projection := function(a, b)
            return (n/Order(G))*Sum(Elements(G),
                                    t -> Image(irrep,t^-1)[b][a]*Image(rho,t));
        end;

        p_11 := projection(1, 1);
        V_i1 := matrix_image(p_11, V_i, zero);
        basis := Basis(V_i1);

        # Now we define the map taking x to W(x), a subrepresentation of
        # V_i isomorphic to W_i. (This is step (c) of Proposition 8)
        step_c := function(x1)
            # This is the list of basis vectors for W(x1)
            return List([1..n],
                        alpha -> projection(alpha, 1) * x1);
        end;

        # If x1^1 .. x1^m is a basis for V_i1 (this is in the `basis`
        # variable), then V_i decomposes into the direct sum W(x1^1)
        # ... W(x1^m), each isomorphic to W_i.
        #
        # We give this decomposition as a list of bases for each W(x1^j).

        return List(basis, step_c);
    end;

    # Now we decompose each V_i into a list of lists of basis vectors for
    # each W(x1^j).

    N := Size(irreps);

    full_decomposition := List([1..N],
                               i -> decompose_summand(irreps[i], canonical_summands[i]));

    return full_decomposition;
end;
