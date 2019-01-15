from sage.combinat.symmetric_group_representations import *

# Prints a sage matrix as a list of lists
def to_list_list(mat):
    return [list(row) for row in list(mat)]

# Need to define function to convert from Sage representation to GAP
# representation, i.e. from a SpechtRepresentation to a GAP
# homomorphism. This gives a string you can pass to libgap()
def to_gap_homo(m, irrep):
    G = SymmetricGroup(m)
    gens = G.gens()
    imgs = [irrep.representation_matrix(Permutation(g)) for g in gens]
    imgs = [to_list_list(mat) for mat in imgs]
    H = "Group({})".format(imgs)
    return "GroupHomomorphismByImages(SymmetricGroup({}), {}, {}, {})".format(
        m,
        H,
        str(gens),
        str(imgs))

# Converts the list of irreps of S_m into a GAP string
def gap_all_irreps(m):
    irreps = SymmetricGroupRepresentations(m)
    gapped = [to_gap_homo(m, irrep) for irrep in irreps]
    return "[{}]".format(", ".join(gapped))

# Converts a matrix to one over RR
def real_mat(mat):
    return matrix(RR, mat.nrows(), mat.ncols(), lambda i, j: mat[i][j].n().real())

# Computes the nice basis to use (that block diagonalises the
# centralizer ring), using my GAP package
def compute_alpha(m):
    irreps_s_m = libgap.eval("irreps_s_m := {};".format(gap_all_irreps(m)))

    # the irreps of s_2
    irreps_s_2 = libgap.eval("irreps_s_2 := [ GroupHomomorphismByImages( SymmetricGroup( [ 1 .. 2 ] ), Group([ [ [ 1 ] ] ]), [ (1,2) ], [ [ [ 1 ] ] ] ), GroupHomomorphismByImages( SymmetricGroup( [ 1 .. 2 ] ), Group([ [ [ -1 ] ] ]), [ (1,2) ], [ [ [ -1 ] ] ] ) ];")

    # list of irreps of the whole group
    irreps_G = libgap.eval("irreps_G := TensorProductRepLists(irreps_s_m, irreps_s_2);")

    # Calculates the matrices needed for the (reduced version of the)
    # semidefinite program
    libgap.eval("sdp := CalculateSDP({}, irreps_G);".format(m))

    B = [matrix(mat) for mat in libgap.eval("sdp.centralizer_basis;").sage()]
    basis = libgap.eval("sdp.nice_basis;").sage()
    Q = matrix(libgap.eval("Qmatrix({}).matrix".format(m)).sage())
    basis_change = matrix(libgap.eval("TransposedMat(sdp.nice_basis)").sage())
    Q_block_diag = basis_change^-1 * Q * basis_change
    J = matrix(len(basis), len(basis), lambda i,j: 1)
    J_block_diag = basis_change^-1 * J * basis_change
    L = [matrix(mat) for mat in libgap.eval("sdp.param_matrices;").sage()]

    # Our matrices are all real, but largely irrational. This is ok
    # except the irrationals are represented as sums of
    # cyclotomics. Sage doesn't know they are real. We have to
    # truncate the imaginary parts.
    B = [real_mat(mat) for mat in B]
    Q_block_diag = real_mat(Q_block_diag)
    J_block_diag = real_mat(J_block_diag)
    L = [real_mat(mat) for mat in L]

    #import pdb; pdb.set_trace()

    # See the paper https://homepages.cwi.nl/~lex/files/symm.pdf for
    # some explanation of this program
    prog = SemidefiniteProgram(maximization=False)
    x = prog.new_variable()

    d = len(L)

    prog.set_objective(sum((Q_block_diag * B[i]).trace()*x[i] for i in range(d)))

    constraint0 = sum(x[i] * L[i] for i in range(d)) >= 0

    # This is what this means, but I need the matrices to avoid type errors
    # constraint1 = sum((J_block_diag * B[i]).trace()*x[i] for i in range(d)) == 1

    one = matrix([[1]])
    constraint1 = sum((J_block_diag * B[i]).trace()*x[i]*one for i in range(d)) == one

    prog.add_constraint(constraint0)
    prog.add_constraint(constraint1)

    print(prog.solve())

# Make sure your gap_cmd etc are set up properly so that my package is
# available
libgap.eval('LoadPackage("RepnDecomp");')

# read the file that computes action_hom, the regular
# representation of the group action of G on the m cycles
libgap.eval('Read("crossing.g");')
