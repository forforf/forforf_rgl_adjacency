require 'rgl/adjacency'
require 'rgl/traversal'

#Terminology Used
# TODO: Check for consistency
# roots   - Nodes with in-degree of 0 (i.e. no parents)
# leaves  - Nodes with out-degree of 0 (i.e., no children)
# source  - The vertex at the start of the edge
# target  - The vertex at the end of an edge
# targets - Either a set of edge targets or the set of vertices the given vertex is
#           directed towards (i.e., the children of a given vertex)
#
# Note on why I try to avoid "parent" and "child". If you're using this library to
# deal with an ancestor tree, where the newest node is the top a DAG, terms can get
# very confusing. Since the newest node is a child of it's parents (1st degree ancestors)
# but it is the top most parent of the Graph. To avoid this, I use source and target
# for graph operations.

#class MyDG < RGL::DirectedAdjacencyGraph
module ForforfRglAdjacency

  def alias_nils(nil_term = :zzznull)
    edges = self.edge_array
    return self unless edges.flatten.include? nil
    fixed_edges = edges.map{ |edge| edge.map{ |v| v || nil_term } }
    #WARNING returns a new, different object though it should be #eql?
    #to the original
    #unimplemented methods in core class prevent me 
    #from changing self itself (add/remove vertex)
    fixed_dg = self.class[*fixed_edges.flatten]
  end
  
  #Graph identity is based on edges
  def hash
    a = self.alias_nils.edge_array
    h = a.hash
  end
 
  #Graphs are #eql? if edges are equal
  #TODO update the other equality methods
  def eql?(other)
    self.hash == other.hash
  end

  #A rough hack to get the in-degree for a vertex
  #nil vertices are not counted (TODO Prevent nil verts in RGL)
  #There's probably a better way than #reverse
  #but I lack the chops for it
  def in_degree(v)
    rdg = self.reverse
    rdg.out_degree(v)
  end

  #  out_degree is already defined in base class
  #def out_degree(v)
  #  self.adjacent_vertices(v).size
  #end
  
  #Find nodes with #in_degree of 0
  #Although roots isn't strictly a digraph term (it's for trees)
  #it has the right connotation
  def roots
    top_nodes = []
    self.each_vertex do |v|
      if in_degree(v) == 0
        top_nodes << v
      end
    end
    top_nodes
  end
  #deprecated method name
  alias :nodes_with_no_parents :roots
  
  #selects the vertices with the maximum tree size (not just out degree)
  def best_top_vertices
    top_nodes = {}
    self.each_vertex do |v|
      top_nodes[v] = self.bfs_search_tree_from(v).size
    end
    max = top_nodes.values.max
    top_verts = top_nodes.select{|k,v| v == max}.keys
  end
  #deprecated method name
  alias :best_top_nodes :best_top_vertices

  #returnes edges as a nested array
  # [ [from, to], [from, to] ... ]
  def edge_array
    self.edges.map{|edge| edge.to_a}
  end
  
  #find parents to a given vertex
  def source_vertices(v)
    rdg = self.reverse
    rdg.adjacent_vertices(v)
  end
  
  #determines if current digraph overlaps
  #with another digraph (i.e. any shared vertices)
  def connected_to?(dg)
    self_verts = self.vertices
    dg_verts = dg.vertices
    connected = if (self_verts & dg_verts).empty?
        false
    else
      true
    end
    connected
  end
  
  #merge with another digraph
  def merge(other)
    self.add_edges(*other.edge_array)
    self
  end
  
  #test for edges that connect, note: returns union of the edges.
  def connected_edges?(this_edges, other_edges)
    intersection = this_edges.flatten & other_edges.flatten
    if intersection.nil? || intersection.empty? 
      nil
    else
      res = this_edges | other_edges
    end
  end
  
  #This breaks the graph down and returns an array of 
  #its component digraphs, where each edge forms a single digraph
  #(i.e., an array of digraphs, each with two vertices)
  def atomic_graphs
    edges = self.edge_array
    uniq_dgs = edges.map {|edge| MyDG[*edge] }
    uniq_dgs
  end
 
  #Takes a list of digraphs and determines if they have any overlap
  #and combines any overlapped digraphs into a common digraph 
  #returns a list of dgs that are unconnected to each other
  def find_connected_graphs(dgs=self.atomic_graphs)
    #dg = directed graph
    merged_dgs = Marshal.load(Marshal.dump(dgs))
    uniq_dgs = []
    
    until  merged_dgs.empty? do

      eval_dg = merged_dgs.shift
      uniq = true
      
      #check and see if the dg under eval should be merged into 
      #one of the other dgs
      merged_dgs.each do |other_dg| #merge loop

        if eval_dg.connected_to? other_dg
          uniq = false
          other_dg.merge(eval_dg)
          #eval_dg is now part of an existing dg in the merged_dgs array
          
          #we are now merged, and the new merged dg will be checked against the
          #remaining dgs, so there's no reason to continue the loop
          break #exit merge loop
        end
      end
      
      
      if uniq == true #means we went through the entire array without a match
        uniq_uniq = true
        #see if it merges with any thing in the uniq list so far
        uniq_dgs.each do |u_dg|
          if eval_dg.connected_to? u_dg
            uniq_uniq = false
            u_dg.merge(eval_dg)
          end
        end
        uniq_dgs << eval_dg if uniq_uniq
      end
    end
    uniq_dgs.uniq
  end
end

class MyDG < RGL::DirectedAdjacencyGraph
  include ForforfRglAdjacency
end
