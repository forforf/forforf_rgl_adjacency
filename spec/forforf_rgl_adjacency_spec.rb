require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module DAGSpecH

 
  ComplexGraph = [ [:aa, :a], [:bc, :bbb], [:bc,:b], [:aaa, :aa], [:b, nil], [:ba,:b],
                 [:ba, :ab], [:ac, :a], [:bbb, :bb], [:bbb, :aaa], [:a, :aa],
                 [:ab, :a], [:ab, :aaa], [:ab, :bb], [:bcc, :bc], [:bb, :b],
                 #this edge is unconnected to the rest of the graph
                 [:cc, :c], [nil, nil], [nil, :d], [:d, nil ] ]
   CGInDegree = { :a   => 3, :b   => 3, :c   => 1,
                  :aa  => 2, :ab  => 1, :ac  => 0,
                  :aaa => 2, 
                  :ba  => 0, :bb  => 2, :bc  => 1,
                  :bbb => 1, :bcc => 0,
                  :cc  => 0,
                  :d => 1,
                  nil => 3 } 

   CGOutDegree = { :a   => 1, :b   => 1, :c   => 0,
                   :aa  => 1, :ab  => 3, :ac  => 1,
                   :aaa => 1,
                   :ba  => 2, :bb  => 1, :bc  => 2,
                   :bbb => 2, :bcc => 1,
                   :cc => 1,
                   :d => 1,
                   nil => 2 } 

   CGTopNodes = [:ba, :ac, :bcc, :cc] 
   CGBestTopNodes = [:bcc] #underneath :bcc => :bc, :bbb, :aaa, :aa, :a, :bb, :b, nil, :d 
   SimpleGraph = [ [:a, :aa], [:a, :ab], [:b, :ba], [:b, :bb] ]
   SimpleGraphCopy = [ [:a, :aa], [:a, :ab], [:b, :ba], [:b, :bb] ]
   SimpleGraphReverse = [ [:aa, :a], [:ab, :a], [:ba, :b], [:bb, :b] ]
   ConnectRootsGraph = [[:e, :bcc], [:e, :cc], [:e, :ba], [:e, :ac] ]
   ConnectLoopGraph = [[:d, :f], [:a, :f], [:f, :bcc] ]
   UnconnectedGraph = [[:x, :xx], [:z, :zz]]
   NilGraph = [[nil, nil]]
end

describe "ForforfRglAdjacency" do
  include DAGSpecH

  before(:each) do
    @complex = ComplexGraph
    @rgl_complex = @complex.flatten
    @complex_indegree = CGInDegree
    @complex_outdegree =CGOutDegree
    @complex_top_nodes = CGTopNodes
    @complex_best_top_nodes = CGBestTopNodes
    @simple = SimpleGraph
    @rgl_simple = @simple.flatten
    @simple_copy = SimpleGraphCopy
    @rgl_simple_copy = @simple_copy.flatten
    @simple_reverse = SimpleGraphReverse
    @rgl_simple_reverse = @simple_reverse.flatten
    @connect_roots = ConnectRootsGraph
    @rgl_connect_roots = @connect_roots.flatten
    @connect_loop = ConnectLoopGraph
    @rgl_connect_loop = @connect_loop.flatten
    @unconnected_graph = UnconnectedGraph
    @rgl_unconnected_graph = @unconnected_graph.flatten
    @nil_graph = NilGraph
    @rgl_nil_graph = @nil_graph.flatten
  end

  it "should initialize" do
    MyDG[*@rgl_complex].should_not == nil
  end

  it "should be able to alias nils" do
    dg_w_nils = MyDG[*@rgl_complex]
    dg_w_nils.edge_array.flatten.should include nil
    dg = dg_w_nils.alias_nils
    dg.edge_array.flatten.should_not include nil
  end

  it "tests for equality" do
    dg_orig = MyDG[*@rgl_simple]
    dg_copy = MyDG[*@rgl_simple_copy]
    dg_orig.hash.should == dg_copy.hash
    same = dg_orig.eql?(dg_copy)
    same.should == true
    dg_diff = MyDG[*@rgl_simple_reverse]
    diff = dg_diff.eql?(dg_orig)
    diff.should == false
  end

  it "counts in-degree" do
    dg = MyDG[*@rgl_complex]
    in_degrees = {}
    @rgl_complex.each do |vert|
      in_degrees[vert] = dg.in_degree(vert)
    end
    in_degrees.should == @complex_indegree 
  end

  it "counts out-degree" do
    dg = MyDG[*@rgl_complex]
    out_degrees = {}
    @rgl_complex.each do |vert|
      out_degrees[vert] = dg.out_degree(vert)
    end
    out_degrees.should == @complex_outdegree
  end

  it "find root vertices (vertices with no parents)" do
    dg = MyDG[*@rgl_complex]
    dg.roots.should == @complex_top_nodes
  end

  it "finds the best top vertices (vertices with the most total descendants)" do
    dg = MyDG[*@rgl_complex]
    dg.best_top_vertices.should == @complex_best_top_nodes
  end

  it "provides its edges as a nested array" do
    dg = MyDG[*@rgl_complex]
    #nils in arrays are kind of a pain
    dg_edges = dg.edge_array.flatten
    complex_edges = @complex.flatten
    #replace nils with :znull
    bye_nil = lambda{|e| e || :znull}
    dg_edges.map! &bye_nil
    complex_edges.map! &bye_nil
    dg_edges.sort.should == complex_edges.sort
  end

  it "finds the source (parent) vertices" do
    dg = MyDG[*@rgl_complex]
    dg.source_vertices(:b).sort.should == [:bc, :ba, :bb].sort
    dg.source_vertices(nil).should == [:b, nil, :d]
    dg.source_vertices(:bcc).should == []
    dg.source_vertices(:a).sort.should == [:aa, :ac, :ab].sort
    dg.source_vertices(:d).should == [nil]
  end

  it "determines if digraphs are connected" do
    base_dg = MyDG[*@rgl_complex]
    conn_root_dg = MyDG[*@rgl_connect_roots]
    unconn_dg = MyDG[*@rgl_unconnected_graph]
    nil_dg = MyDG[*@rgl_nil_graph]

    base_dg.connected_to?(conn_root_dg).should == true
    base_dg.connected_to?(unconn_dg).should == false
    base_dg.connected_to?(nil_dg).should == true 
  end

  it "merges with other graphs" do
    base_dg = MyDG[*@rgl_complex]
    conn_root_dg = MyDG[*@rgl_connect_roots]
    conn_loop_dg = MyDG[*@rgl_connect_loop]
    unconn_dg = MyDG[*@rgl_unconnected_graph]
    
    merge_new_root_dg = base_dg.merge(conn_root_dg)
    merge_new_root_dg.roots.should == [:e]

    merge_new_loop_dg = base_dg.merge(conn_loop_dg)
    merge_new_loop_dg.adjacent_vertices(:d).should include :f
    merge_new_loop_dg.adjacent_vertices(:f).should include :bcc
    merge_new_loop_dg.adjacent_vertices(:a).should include :f
    
    merge_uncon_dg = base_dg.merge(unconn_dg)
    merge_uncon_dg.vertices.should include :bb
    merge_uncon_dg.vertices.should include :cc
    merge_uncon_dg.vertices.should include :x
  end

  it "detects if two edges are connected" do
    base_edge = [:g, :h]
    conn_source = [:g, :i]
    conn_target = [:j, :h]
    linked_edge = [:h, :n]
    dup_edge = [:g, :h]
    unconn_edge = [:k, :m]
    nil_base = [nil, nil]
    nil_conn = [:o, nil]
    
    some_dg = MyDG[*[]] #this method doesn't rely on any dg structures
    some_dg.connected_edges?(base_edge, conn_source).should == [:g, :h, :i]
    some_dg.connected_edges?(base_edge, conn_target).should == [:g, :h, :j]
    some_dg.connected_edges?(base_edge, linked_edge).should == [:g, :h, :n]
    some_dg.connected_edges?(base_edge, dup_edge).should == [:g, :h]
    some_dg.connected_edges?(base_edge, unconn_edge).should == nil
    some_dg.connected_edges?(nil_base, nil_conn).should == [nil, :o]
  end

  it "breaks a graph down into its atomic digraphs" do
    base_dg = MyDG[*@rgl_simple]
    baby_dgs = base_dg.atomic_graphs

    baby_edge_matcher = [[:a, :aa], [:a, :ab], [:b, :ba], [:b, :bb]]
    baby_dgs.size.should == 4
    baby_dgs.each do |dg|
      dg.size.should == 2
      dg_edge = dg.edge_array.flatten #or could have used #first
      baby_edge_matcher.should include dg_edge
      baby_edge_matcher.delete(dg_edge) #makes sure there are no duplicates
    end
  end

  it "can find connected graphs" do
    #simple default test
    base_dg = MyDG[*@rgl_simple]
    base_baby_graphs = base_dg.find_connected_graphs
    base_baby_graphs.size.should == 2
    new_graph = base_baby_graphs.first.merge(base_baby_graphs.last)
    new_graph.should == base_dg

    #complex default test
    complex_dg = MyDG[*@rgl_complex] 
    complex_baby_graphs = complex_dg.find_connected_graphs

    new_complex_graph = complex_baby_graphs.inject(MyDG[*[]]) {|memo, dg| memo.merge(dg)}
    new_complex_graph.should == complex_dg

    #non-default test
    simp_dg = MyDG[*@rgl_simple]
    baby_dgs = simp_dg.atomic_graphs
    baby_dgs.size.should == 4

    some_dg = MyDG[*[]]
    merged_graphs = some_dg.find_connected_graphs(baby_dgs)
    merged_graphs.size.should == 2
    
    full_graph = merged_graphs.first.merge(merged_graphs.last)
    full_graph.should == simp_dg 
  end
end
