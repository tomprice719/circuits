import numpy as np
from numpy.linalg import solve

def get_resistance(num_nodes, in_node, out_node, edges):

    A = np.zeros((num_nodes, num_nodes))
    B = np.zeros(num_nodes)

    for i, j, resistance in edges:
        if i != out_node:
            A[i, i] += 1.0 / resistance
            A[i, j] -= 1.0 / resistance
        if j != out_node:
            A[j, j] += 1.0 / resistance
            A[j, i] -= 1.0 / resistance
    A[out_node, out_node] = 1.0

    #print A
    B[in_node] = 1.0

    voltage = solve(A, B)

    return voltage[in_node]

edges = ((0, 1, 1.0), (0, 2, 3.0), (1, 2, 1.0))

# edges = ((0, 1, 1.0), (0, 2, 1.0), (1, 2, 1.0), (1, 3, 1.0), (2, 3, 1.0))
# print get_resistance(4, 0, 3, edges)
