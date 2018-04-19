from heap cimport *
from libc.stdlib cimport malloc, free

cdef:
  INFINITY = float("inf")

  struct Node:
    bint terminal
    float dist
    Edge * edges
    int num_edges
    HeapEm * hem
    #int id
  struct Edge:
    Node * end
    float length

  float shortest_distance(Node** initial_nodes, int num_initial_nodes, Heap* heap):
    cdef Edge * edge
    cdef Node * node
    cdef Node * end_node

    for i in range(num_initial_nodes):
      for j in range(initial_nodes[i].num_edges):
        edge = &(initial_nodes[i].edges[j])
        end_node = edge.end
        if end_node.dist == INFINITY:
          end_node.dist = edge.length
          end_node.hem.priority = -end_node.dist
          #print initial_nodes[i].id, end_node.id
          heap_push(end_node.hem, heap)
        elif edge.length < end_node.dist:
          end_node.dist = edge.length
          end_node.hem.priority = -end_node.dist
          #print initial_nodes[i].id, end_node.id
          bubble_up(end_node.hem, heap)

    while(heap.size > 0):
      node = <Node*>heap_pop(heap).data
      if node.terminal == True:
        return node.dist
      for i in range(node.num_edges):
        edge = &(node.edges[i])
        end_node = edge.end
        if end_node.dist == INFINITY:
          end_node.dist = node.dist + edge.length
          end_node.hem.priority = -end_node.dist
          #print node[i].id, end_node.id
          heap_push(end_node.hem, heap)
        elif node.dist + edge.length < end_node.dist:
          end_node.dist = node.dist + edge.length
          end_node.hem.priority = -end_node.dist
          #print node[i].id, end_node.id
          bubble_up(end_node.hem, heap)
    return -1.0

def dijkstra_test(num_nodes, initial_node_indices, terminal_node_indices, edges):
  cdef Node * nodes = <Node *> malloc(num_nodes * sizeof(Node))
  cdef Node ** initial_nodes = <Node **> malloc(len(initial_node_indices) * sizeof(Node*))
  cdef HeapEm* hems = <HeapEm*> malloc(num_nodes * sizeof(HeapEm))
  cdef Heap heap
  cdef Edge * edge

  heap.inv_location = <HeapEm**> malloc(num_nodes * sizeof(HeapEm*))
  heap.size = 0

  for i, initial_node_index in enumerate(initial_node_indices):
    initial_nodes[i] = &nodes[initial_node_index]

  for i in range(num_nodes):
    if i in terminal_node_indices:
      nodes[i].terminal = True
    else:
      nodes[i].terminal = False
    if i in initial_node_indices:
      nodes[i].dist = 0.0
    else:
      nodes[i].dist = INFINITY
    nodes[i].num_edges = 0
    nodes[i].hem = &hems[i]
    #nodes[i].id = i
    #nodes[i].sp_in = NULL
    hems[i].data = &(nodes[i])
  for start, end, length in edges:
    nodes[start].num_edges += 1
  for i in range(num_nodes):
    nodes[i].edges = <Edge *>malloc(nodes[i].num_edges * sizeof(Edge))
    nodes[i].num_edges = 0
  for start, end, length in edges:
    edge = &(nodes[start].edges[nodes[start].num_edges])
    edge.end = &(nodes[end])
    edge.length = length
    nodes[start].num_edges += 1
  print "done preparing"
  print shortest_distance(initial_nodes, len(initial_node_indices), &heap)

  for i in range(num_nodes):
    free(nodes[i].edges)
  free(heap.inv_location)
  free(hems)
  free(initial_nodes)
  free(nodes)
