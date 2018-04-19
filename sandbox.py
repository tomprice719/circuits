from dijkstra import dijkstra_test
from numpy.random import permutation, random

threshold_a = 1000
threshold_b = 2000
connection_prob = 0.003
initial_node_indices = [0]
terminal_node_indices = [threshold_b - 1]

edges = []

for i in range(threshold_a):
    for j in range(i):
        if random() < connection_prob:
            edges.append((i, j, 1))
        if random() < connection_prob:
            edges.append((j, i, 1))

for i in range(threshold_a, threshold_b - 1):
    edges.append((i, i+1, 1))

edges.append((0, threshold_a, 1))

edges = [edges[x] for x in permutation(range(len(edges)))]

#print edges

dijkstra_test(threshold_b, initial_node_indices, terminal_node_indices, edges)
