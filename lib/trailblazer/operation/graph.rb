module Trailblazer
  # Note that Graph is a superset of a real directed graph. For instance, it might contain detached nodes.
  # == Design
  # * This class is designed to maintain a graph while building up a circuit step-wise.
  # * It can be imperformant as this all happens at compile-time.
  module Operation::Graph
    class Edge
      def initialize(data)
        yield self, data if block_given?
        @data = data
      end

      def [](key)
        @data[key]
      end
    end

    class Node < Edge
      # Single entry point for adding nodes and edges to the graph.
      private def connect_for!(source, edge, target)
        self[:graph][source] ||= {}
        self[:graph][target] ||= {} # keep references to all nodes, even when detached.
        self[:graph][source][edge] = target
      end

      # Builds a node from the provided `:node` argument array.
      def attach!(target:raise, edge:raise)
        target = target.kind_of?(Node) ? target : Node(*target)

        connect!(target: target, edge: edge)
      end

      def connect!(target:raise, edge:raise, source:self)
        target = target.kind_of?(Node) ? target : (find_all { |_target| _target[:id] == target }[0] || raise( "#{target} not found"))
        source = source.kind_of?(Node) ? source : (find_all { |_source| _source[:id] == source }[0] || raise( "#{source} not found"))


        edge = source.Edge(*edge)

        connect_for!(source, edge, target)

        target
      end

      def insert_before!(old_node, node:raise, outgoing:nil, incoming:raise)
        old_node = find_all(old_node)[0] || raise( "#{old_node} not found") unless old_node.kind_of?(Node)

        new_node            = Node(*node)
        incoming_tuples     = old_node.predecessors
        rewired_connections = incoming_tuples.find_all { |(node, edge)| incoming.(edge) }

        # rewire old_task's predecessors to new_task.
        rewired_connections.each { |(node, edge)| connect_for!(node, edge, new_node) }

        # connect new_task --> old_task.
        if outgoing
          edge = Edge(*outgoing)

          connect_for!(new_node, edge, old_node)
        end

        return new_node
      end

      def find_all(id=nil, &block)
        nodes = self[:graph].keys + self[:graph].values.collect(&:values).flatten
        nodes = nodes.uniq

        block ||= ->(node) { node[:id] == id }

        nodes.find_all(&block)
      end

      def Edge(wrapped, options)
        edge = Edge.new(options.merge( graph: self[:graph], _wrapped: wrapped ))
      end

      def Node(wrapped, options)
        Node.new( options.merge( graph: self[:graph], _wrapped: wrapped ) )
      end

      # private
      def predecessors
        self[:graph].each_with_object([]) do |(node, connections), ary|
          connections.each { |edge, target| target == self && ary << [node, edge] }
        end
      end

      def successors
        ( self[:graph][self] || {} ).values
      end

      def to_h(include_leafs:true)
        hash = ::Hash[
          self[:graph].collect do |node, connections|
            connections = connections.collect { |edge, node| [ edge[:_wrapped], node[:_wrapped] ] }

            [ node[:_wrapped], ::Hash[connections] ]
          end
        ]

        if include_leafs == false
          hash = hash.select { |node, connections| connections.any? }
        end

        hash
      end
    end

    def self.Node(wrapped, data={})
      Node.new( { _wrapped: wrapped, graph: {} }.merge(data) ) { |node, data| data[:graph][node] = {} }
    end
  end # Graph
end