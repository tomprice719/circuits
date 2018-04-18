from heap cimport *

cdef:
  INFINITY = float("inf")

  struct Node:
    bint terminal
    float dist
    Edge * edges
    int num_edges
    HeapEm * hem
  struct Edge:
    Node * end
    float length

  float shortest_distance(Node* initial_nodes, int num_initial_nodes, Heap* heap):
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
          heap_push(end_node.hem, heap)
        elif edge.length < end_node.dist:
          end_node.dist = edge.length
          end_node.hem.priority = -end_node.dist
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
          heap_push(end_node.hem, heap)
        elif node.dist + edge.length < end_node.dist:
          end_node.dist = node.dist + edge.length
          end_node.hem.priority = -end_node.dist
          bubble_up(end_node.hem, heap)
    return -1.0
