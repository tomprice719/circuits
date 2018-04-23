from heap cimport *
from libc.stdlib cimport malloc, free
from libc.stdio cimport printf

cdef:
  INFINITY = float("inf")

  struct Node:
    bint terminal
    bint initial
    float dist
    Edge * edges
    Edge * best_edge
    int last_seen
    int num_edges
    HeapEm * hem
    #int id
  struct Edge:
    Node * beginning
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
        edge = &(initial_nodes[i].edges[j])
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
        edge = &(node.edges[i])
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

  void thing(Node ** initial_nodes, int num_initial_nodes, Heap * heap, int num_iterations):
    cdef int i
    for i in range(num_iterations):
      node = dijkstra(initial_nodes, num_initial_nodes, heap, i)
      while(node.initial == False):
        edge = node.best_edge
        edge.current += 1
        edge.length = (1 + edge.current) * edge.resistance
        node = edge.beginning
      heap.size = 0
