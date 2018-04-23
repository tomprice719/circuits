from heap cimport *
from libc.stdlib cimport malloc, free
from libc.stdio cimport printf

#TODO: single initial and terminal node

cdef:
  INFINITY = float("inf")

  struct Node:
    bint terminal
    bint initial
    float dist
    Edge * edges
    int num_edges
    HeapEm * hem
    Edge * best_edge
    int last_seen
    #int id
  struct Edge:
    Node * start
    Node * end
    float length
    int current
    float resistance

  inline void update_node(Node *node, Edge *edge, float distance, current_iteration):
    node.dist = distance
    node.hem.priority = -distance
    node.best_edge = edge
    node.last_seen = current_iteration

  Node * dijkstra(Node** initial_nodes, int num_initial_nodes, Heap* heap, int current_iteration):
    cdef Edge * edge
    cdef Node * node
    cdef Node * end_node

    for i in range(num_initial_nodes):
      if initial_nodes[i].terminal:
        printf("Short circuit! A node is both initial and terminal.")
        return NULL
      for j in range(initial_nodes[i].num_edges):
        edge = &initial_nodes[i].edges[j]
        end_node = edge.end
        if end_node.last_seen < current_iteration:
          update_node(end_node, edge, edge.length, current_iteration)
          heap_push(end_node.hem, heap)
        elif edge.length < end_node.dist:
          update_node(end_node, edge, edge.length, current_iteration)
          #print initial_nodes[i].id, end_node.id
          bubble_up(end_node.hem, heap)

    while(heap.size > 0):
      node = <Node*>heap_pop(heap).data
      if node.terminal == True:
        return node
      for i in range(node.num_edges):
        edge = &node.edges[i]
        end_node = edge.end
        if end_node.last_seen < current_iteration:
          update_node(end_node, edge, node.dist + edge.length, current_iteration)
          #print node[i].id, end_node.id
          heap_push(end_node.hem, heap)
        elif node.dist + edge.length < end_node.dist:
          update_node(end_node, edge, node.dist + edge.length, current_iteration)
          #print node[i].id, end_node.id
          bubble_up(end_node.hem, heap)
    return NULL

  #TODO: handle error for when no path is found

  void determine_flow(Node ** initial_nodes, int num_initial_nodes, Heap * heap, int num_iterations):
    cdef int i
    for i in range(num_iterations):
      node = dijkstra(initial_nodes, num_initial_nodes, heap, i)
      while(node.initial == False):
        edge = node.best_edge
        edge.current += 1
        edge.length = (1 + edge.current) * edge.resistance
        node = edge.start
      heap.size = 0

def circuit_test(num_nodes, initial_node_indices, terminal_node_indices, edges, num_iterations):
  cdef Node * nodes = <Node *> malloc(num_nodes * sizeof(Node))
  cdef Node ** initial_nodes = <Node **> malloc(len(initial_node_indices) * sizeof(Node*))
  cdef HeapEm* hems = <HeapEm*> malloc(num_nodes * sizeof(HeapEm))
  cdef Heap heap
  cdef Edge * edge
  cdef float power = 0.0

  heap.inv_location = <HeapEm**> malloc(num_nodes * sizeof(HeapEm*))
  heap.size = 0

  for i, initial_node_index in enumerate(initial_node_indices):
    initial_nodes[i] = &nodes[initial_node_index]

  for i in range(num_nodes):
    if i in initial_node_indices:
      nodes[i].initial = True
    else:
      nodes[i].initial = False
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
    nodes[i].best_edge = NULL
    nodes[i].last_seen = -1
  for start, end, resistance in edges:
    nodes[start].num_edges += 1
  for i in range(num_nodes):
    nodes[i].edges = <Edge *>malloc(nodes[i].num_edges * sizeof(Edge))
    nodes[i].num_edges = 0
  for start, end, resistance in edges:
    edge = &nodes[start].edges[nodes[start].num_edges]
    edge.start = &nodes[start]
    edge.end = &nodes[end]
    edge.resistance = resistance
    edge.length = resistance
    edge.current = 0
    nodes[start].num_edges += 1
  print "done preparing"

  determine_flow(initial_nodes, len(initial_node_indices), &heap, num_iterations)

  for i in range(num_nodes):
    for j in range(nodes[i].num_edges):
      edge = &nodes[i].edges[j]
      print edge.resistance, edge.current
      power += edge.resistance * edge.current ** 2

  print power / num_iterations ** 2

  for i in range(num_nodes):
    free(nodes[i].edges)
  free(heap.inv_location)
  free(hems)
  free(initial_nodes)
  free(nodes)
