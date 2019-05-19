#from dijkstra import dijkstra_test
from numpy.random import permutation, random
import circuit1
import circuit2
from random import uniform
import symmetric_circuit

# threshold_a = 2000
# threshold_b = 3050
# connection_prob = 0.003
#
# edges = []
#
# for i in range(threshold_a):
#     for j in range(i):
#         if random() < connection_prob:
#             edges.append((i, j, 1))
#         if random() < connection_prob:
#             edges.append((j, i, 1))
#
# for i in range(threshold_a, threshold_b - 1):
#     edges.append((i, i+1, 1))
#
# edges.append((0, threshold_a, 1))
#
# edges = [edges[x] for x in permutation(range(len(edges)))]
#
# dijkstra_test(threshold_b, 0, threshold_b - 1, edges)

num_nodes = 20

edges1 = []
edges2 = []

for i in range(num_nodes):
    for j in range(i + 1, num_nodes):
        r = uniform(0, 1)
        edges1.append((i, j, r))
        edges2.append((i, j, r))
        edges2.append((j, i, r))

edges = ((0, 1, 1.0), (0, 2, 1.0), (1, 2, 1.0))

circuit1.circuit_test(num_nodes, 0, num_nodes - 1, edges2, 1000000)
circuit2.circuit_test(num_nodes, 0, num_nodes - 1, edges2, 1000000)
print symmetric_circuit.get_resistance(num_nodes, 0, num_nodes - 1, edges1)
